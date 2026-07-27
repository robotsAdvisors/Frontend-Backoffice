import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import '../../../../utils/api_config.dart';
import '../../local/my_shared_pref.dart';

/// Cliente HTTP centralizado que se comunica con el backend Django de Letdem.
///
/// - Inyecta automaticamente el header `Authorization: Bearer <access_token>`.
/// - Si recibe 401 y existe un refresh token, intenta renovar el access token
///   (POST /accounts/token/refresh/) y reintenta la peticion una vez.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
        responseType: ResponseType.json,
        validateStatus: (status) => status != null,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final path = options.path;
          final isAuthEndpoint = path.contains('/auth/login') ||
              path.contains('/auth/signup') ||
              path.contains('/auth/social-login') ||
              path.contains('/auth/social-signup');
          if (!isAuthEndpoint) {
            final token = MySharedPref.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          final status = response.statusCode ?? 0;
          final requestPath = response.requestOptions.path;
          final isRefreshRequest = requestPath.contains('token/refresh');
          final isAuthEndpoint = requestPath.contains('/auth/login') ||
              requestPath.contains('/auth/signup') ||
              requestPath.contains('/auth/social-login') ||
              requestPath.contains('/auth/social-signup');

          if (status == 401 && !isRefreshRequest && !isAuthEndpoint) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              try {
                final cloned = await _retry(response.requestOptions);
                return handler.resolve(cloned);
              } on DioException catch (e) {
                return handler.reject(e);
              } catch (_) {
                // Cae al reject genérico de abajo con la respuesta original.
              }
            } else {
              // El refresh falló: la sesión caducó. Limpia y manda al login para
              // no dejar al usuario en pantallas vacías con 401 en todo.
              await MySharedPref.clearTokens();
              _redirectToLogin();
            }
          }

          // `validateStatus` deja pasar TODOS los estados para poder inspeccionar
          // el 401 y refrescar el token. Pero el resto de errores del backend
          // (>= 400) llegan con el contrato {error_code, message, details}: hay que
          // convertirlos en DioException para que `toApiException` los lea. Si no,
          // cada repo trataría el cuerpo del error como una respuesta OK (o lo
          // descartaría como null con un mensaje genérico), y la UI nunca vería el
          // error_code ni el `missingPoints`.
          if (status >= 400) {
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
          }

          handler.next(response);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;

  Dio get dio => _dio;

  static bool _redirecting = false;

  /// Lleva al login cuando la sesión caduca. DISPARO ÚNICO: ante la ráfaga de
  /// 401s en paralelo solo redirige una vez (un latch que se libera tras unos
  /// segundos), para no recrear/disponer el LoginController repetidamente y
  /// provocar "TextEditingController used after disposed". No interfiere con el
  /// arranque (splash) ni si ya estamos en login. Ruta literal para evitar un
  /// import circular con app_pages.
  void _redirectToLogin() {
    if (_redirecting) return;
    final route = Get.currentRoute;
    if (route == '/login' || route == '/splash' || route.isEmpty) return;
    _redirecting = true;
    Get.offAllNamed('/login');
    Get.snackbar('Sesión expirada', 'Inicia sesión de nuevo.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3));
    // Libera el latch pasado un margen: si la sesión vuelve a caducar mucho
    // más tarde, podrá redirigir de nuevo; pero la ráfaga inicial no se repite.
    Future.delayed(const Duration(seconds: 3), () => _redirecting = false);
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = MySharedPref.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final response = await Dio(
        BaseOptions(baseUrl: ApiConfig.apiBaseUrl),
      ).post(
        ApiConfig.tokenRefresh,
        data: {'refresh': refresh},
      );
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final newAccess = data['access'] as String?;
        final newRefresh = data['refresh'] as String?;
        if (newAccess != null) {
          await MySharedPref.setAccessToken(newAccess);
          if (newRefresh != null) {
            await MySharedPref.setRefreshToken(newRefresh);
          }
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}

/// Excepcion legible para la UI al fallar una llamada HTTP.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.data,
    this.errorCode = '',
    this.details = const {},
  });

  final String message;
  final int? statusCode;
  final dynamic data;

  /// `error_code` del contrato de error del backend: el código estable por el
  /// que se ramifica, sin mirar el mensaje. Vacío si la respuesta no lo trae
  /// (un 502 de nginx, una página de error HTML…).
  final String errorCode;

  /// `details` del contrato: el contexto del error. En `INSUFFICIENT_POINTS`
  /// trae `needed` y `available`; en `VALIDATION_ERROR`, los errores por campo.
  final Map<String, dynamic> details;

  /// El endpoint no está disponible en el backend: aún sin implementar o
  /// retirado (404 / 405 / 501). Sirve para degradar a un estado "no disponible"
  /// en la UI en vez de mostrar un error crudo al usuario.
  bool get isUnavailable =>
      statusCode == 404 || statusCode == 405 || statusCode == 501;

  /// Puntos que faltaban, cuando el backend devuelve `INSUFFICIENT_POINTS`.
  /// Null si el error es otro o si no vino la cifra.
  int? get missingPoints {
    if (errorCode != 'INSUFFICIENT_POINTS') return null;
    final needed = int.tryParse('${details['needed']}');
    final available = int.tryParse('${details['available']}');
    if (needed == null || available == null) return null;
    return needed - available;
  }

  @override
  String toString() => message;
}

/// Convierte cualquier error (DioException u otro) en un [ApiException].
///
/// Toda respuesta del backend con estado >= 400 tiene la misma forma:
/// `{"error_code": "...", "message": "...", "details": {...}}`. Antes había que
/// adivinar entre `detail`, `error` y los errores por campo según el endpoint.
ApiException toApiException(Object error) {
  if (error is ApiException) return error;
  if (error is DioException) {
    final data = error.response?.data;
    final status = error.response?.statusCode;
    String message = error.message ?? 'Error de red';

    if (data is Map && data['error_code'] != null) {
      message = data['message']?.toString() ?? message;
      return ApiException(
        message,
        statusCode: status,
        data: data,
        errorCode: data['error_code'].toString(),
        details: data['details'] is Map
            ? Map<String, dynamic>.from(data['details'] as Map)
            : const {},
      );
    }

    // Lo que no pasa por el contrato: nginx, páginas de error HTML de Django,
    // o algún endpoint que se lo salte. No debería ocurrir, pero si ocurre es
    // mejor un mensaje legible que un volcado del mapa.
    if (data is Map) {
      if (data['detail'] is String) {
        message = data['detail'] as String;
      } else if (data['error'] is String) {
        message = data['error'] as String;
      } else {
        message = data.entries.map((e) => '${e.key}: ${e.value}').join(' | ');
      }
    } else if (data is String && data.isNotEmpty) {
      final isHtml = data.trimLeft().startsWith('<');
      message = isHtml
          ? 'Error del servidor (${status ?? 500})'
          : data.length > 200 ? '${data.substring(0, 200)}…' : data;
    }
    return ApiException(message, statusCode: status, data: data);
  }
  return ApiException(error.toString());
}
