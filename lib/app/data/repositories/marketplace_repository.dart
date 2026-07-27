import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../utils/api_config.dart';
import '../models/admin_user_model.dart';
import '../models/audit_log_model.dart';
import '../models/campaign_model.dart';
import '../models/category_model.dart';
import '../models/data_subject_request_model.dart';
import '../models/gdpr_request_model.dart';
import '../models/legal_consent_model.dart';
import '../models/legal_stats_response.dart';
import '../models/legal_version_model.dart';
import '../models/kybc_stats_model.dart';
import '../models/sensitive_policy_model.dart';
import '../models/stripe_dispute_model.dart';
import '../models/review_model.dart';
import '../models/role_definition_model.dart';
import '../models/order_model.dart';
import '../models/paginated.dart';
import '../models/product_model.dart';
import '../models/store_model.dart';
import '../models/store_user_model.dart';
import '../models/redemption_code_model.dart';
import '../services/http/api_client.dart';

/// Repositorio del modulo marketplace contra el backend Django Letdem.
class MarketplaceRepository {
  MarketplaceRepository._();
  static final MarketplaceRepository instance = MarketplaceRepository._();

  final _dio = ApiClient.instance.dio;

  // ---------- CATALOGO ----------

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _dio.get(ApiConfig.categories);
      return _toList(response.data)
          .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Versión paginada de [fetchCategories] que expone el `meta`.
  Future<Paginated<CategoryModel>> fetchCategoriesPage({int? page, int? pageSize}) async {
    return _fetchPage(
      url: ApiConfig.categories,
      page: page,
      pageSize: pageSize,
      fromJson: CategoryModel.fromJson,
    );
  }

  Future<List<ProductModel>> fetchProducts({
    String? storeId,
    String? search,
    String? categoryName,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.products,
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'store': storeId,
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryName != null && categoryName.isNotEmpty)
            'category': categoryName,
        },
      );
      return _toList(response.data)
          .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Versión paginada de [fetchProducts] que expone el `meta`.
  Future<Paginated<ProductModel>> fetchProductsPage({
    String? storeId,
    String? search,
    String? categoryName,
    int? page,
    int? pageSize,
    // MISSING ENDPOINT: ordering param — backend must support ?ordering= on
    // GET /marketplace/admin/products/ (e.g. name, -name, price, -price, stock, -stock)
    String? ordering,
  }) async {
    return _fetchPage(
      url: ApiConfig.products,
      page: page,
      pageSize: pageSize,
      query: {
        if (storeId != null && storeId.isNotEmpty) 'store': storeId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryName != null && categoryName.isNotEmpty) 'category': categoryName,
        if (ordering != null && ordering.isNotEmpty && ordering != 'name') 'ordering': ordering,
      },
      fromJson: ProductModel.fromJson,
    );
  }

  Future<ProductModel?> fetchProductDetail(String productId) async {
    try {
      final response = await _dio.get('${ApiConfig.products}$productId/');
      if (response.statusCode == 200 && response.data is Map) {
        return ProductModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  Future<List<StoreModel>> fetchStores({
    String? search,
    String? category,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.stores,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      return _toList(response.data)
          .map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Versión paginada de [fetchStores] que devuelve modelos tipados.
  Future<Paginated<StoreModel>> fetchStoresPage({
    String? search,
    String? category,
    int? page,
    int? pageSize,
  }) async {
    return _fetchPage(
      url: ApiConfig.stores,
      page: page,
      pageSize: pageSize,
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
      },
      fromJson: StoreModel.fromJson,
    );
  }

  Future<StoreModel?> fetchStoreDetail(String storeId) async {
    try {
      final response = await _dio.get('${ApiConfig.stores}$storeId/');
      if (response.statusCode == 200 && response.data is Map) {
        return StoreModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Lista de tiendas para el BACKOFFICE GENERAL: todas las creadas, publicadas
  /// o no. Usa el endpoint admin, a diferencia de [fetchStores] (catálogo público
  /// que solo expone las publicadas).
  /// GET /marketplace/admin/stores/
  Future<List<StoreModel>> fetchAdminStores({String? search}) async {
    try {
      final response = await _dio.get(
        ApiConfig.adminStores,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return _toList(response.data)
          .whereType<Map>()
          .map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ---------- REDEMPTION_CODES ----------

  Future<List<RedemptionCodeModel>> fetchRedemptionCodes({
    String? status,
    String? redeemType,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.redemptionCodes,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (redeemType != null && redeemType.isNotEmpty)
            'redeem_type': redeemType,
        },
      );
      return _toList(response.data)
          .map((e) => RedemptionCodeModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Versión paginada para el BACKOFFICE DE TIENDA: los canjes del comercio.
  /// Usa la ruta scopeada a tienda (`stores/redemption-codes/`), no la genérica
  /// del usuario, que devolvería los canjes donde la tienda es cliente.
  Future<Paginated<RedemptionCodeModel>> fetchRedemptionCodesPage({
    String? status,
    String? redeemType,
    int? page,
    int? pageSize,
    // ISO date string YYYY-MM-DD — filters by created__date on backend
    String? date,
  }) async {
    return _fetchPage(
      url: ApiConfig.storeRedemptionCodes,
      page: page,
      pageSize: pageSize,
      query: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (redeemType != null && redeemType.isNotEmpty) 'redeem_type': redeemType,
        if (date != null && date.isNotEmpty) 'date': date,
      },
      fromJson: RedemptionCodeModel.fromJson,
    );
  }

  Future<RedemptionCodeModel?> createRedemptionCodeOnline({
    required String storeId,
    required String productId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.redemptionCodesCreateOnline,
        data: {
          'store_id': storeId,
          'product_id': productId,
        },
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map) {
        return RedemptionCodeModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Reporta una incidencia sobre un código de canje.
  /// POST /marketplace/redemption-codes/<id>/incident/  body: {reason, notes}
  /// Response 201: {ticket_id, redemption_code, reason, notes, status, created_at}
  Future<Map<String, dynamic>> reportRedemptionCodeIncident(String redemptionCodeId,
      {required String reason, String notes = ''}) async {
    try {
      final response = await _dio.post(
        ApiConfig.redemptionCodeIncident(redemptionCodeId),
        data: {'reason': reason, if (notes.isNotEmpty) 'notes': notes},
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Preview de un código de canje (sin canjearlo).
  /// GET /marketplace/redemption-codes/preview/?code=X
  /// Retorna el RedemptionCodeModel con datos del producto, cliente y pago.
  Future<RedemptionCodeModel?> previewRedemptionCode(String code) async {
    try {
      final response = await _dio.get(
        ApiConfig.redemptionCodesPreview,
        queryParameters: {'code': code},
      );
      if (response.statusCode == 200 && response.data is Map) {
        return RedemptionCodeModel.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Inicia un pago Stripe para un código de canje con precio monetario.
  /// POST /marketplace/redemption-codes/{code}/initiate-payment/
  /// Body opcional: { "payment_method_id": "pm_xxx" }
  /// Respuesta: { client_secret, payment_intent_id, amount_eur, status }
  Future<Map<String, dynamic>> initiateRedemptionCodePayment(String code,
      {String? paymentMethodId}) async {
    try {
      final response = await _dio.post(
        ApiConfig.redemptionCodeInitiatePayment(code),
        data: {
          if (paymentMethodId != null && paymentMethodId.isNotEmpty)
            'payment_method_id': paymentMethodId,
        },
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Valida un código en el mostrador (ST-CJ-02): el código pasa a IN_PROGRESS.
  /// No consume puntos todavía; eso es la entrega.
  /// POST /marketplace/stores/redemption-codes/validation/  body: {code, pin?}
  /// El PIN se envía solo si la tienda tiene uno definido; el backend lo exige
  /// en ese caso y responde 403 si falta o es incorrecto.
  Future<Map<String, dynamic>?> validateRedemptionCode(String code,
      {String? pin}) async {
    try {
      final response = await _dio.post(
        ApiConfig.redemptionCodesValidate,
        data: {
          'code': code,
          if (pin != null && pin.isNotEmpty) 'pin': pin,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Entrega un código ya validado (ST-CJ-03): pasa a DELIVERED y el backend
  /// consume los puntos bloqueados. Falla con 400 si el código no está en
  /// IN_PROGRESS (no se puede entregar sin validar antes).
  /// POST /marketplace/stores/redemption-codes/<id>/delivery/  (sin body)
  Future<Map<String, dynamic>?> deliverRedemptionCode(String redemptionCodeId) async {
    try {
      final response = await _dio.post(
        ApiConfig.redemptionCodeDelivery(redemptionCodeId),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  // ---------- ORDERS ----------

  /// Ventas de la tienda.
  /// GET /marketplace/store/orders/?store_id=X&status=X&page=N
  /// meta: {total, page, last_page, total_revenue, total_points_used}
  Future<Map<String, dynamic>> fetchStoreOrders({
    required String storeId,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.storeOrders,
        queryParameters: {
          if (storeId.isNotEmpty) 'store_id': storeId,
          if (status != null && status.isNotEmpty) 'status': status,
          'page': page,
          'page_size': pageSize,
        },
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Devuelve el envelope tipado `{data, meta:{total, page, lastPage, stats}}`
  /// del endpoint `GET /marketplace/orders/`.
  Future<OrdersPage> fetchOrders({int? page, int? pageSize}) async {
    try {
      final response = await _dio.get(
        ApiConfig.orders,
        queryParameters: {
          if (page != null) 'page': page,
          if (pageSize != null) 'page_size': pageSize,
        },
      );
      final raw = Map<String, dynamic>.from(response.data as Map);
      return OrdersPage.fromJson(raw);
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ---------- PURCHASE ----------

  /// Compra con canje de puntos (30% off por 500 puntos).
  Future<Map<String, dynamic>> purchaseWithRedeem({
    required String productId,
    int quantity = 1,
    String? paymentIntentId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.purchaseWithRedeem,
        data: {
          'product_id': productId,
          'quantity': quantity,
          if (paymentIntentId != null) 'payment_intent_id': paymentIntentId,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Compra a precio completo, sin uso de puntos.
  Future<Map<String, dynamic>> purchaseWithoutRedeem({
    required String productId,
    int quantity = 1,
    String? paymentIntentId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.purchaseWithoutRedeem,
        data: {
          'product_id': productId,
          'quantity': quantity,
          if (paymentIntentId != null) 'payment_intent_id': paymentIntentId,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ---------- ADMIN ----------

  Future<Map<String, dynamic>?> adminCreateProduct(
      Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(ApiConfig.adminProducts, data: payload);
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// PUT /marketplace/admin/products/<id>/
  Future<Map<String, dynamic>?> adminUpdateProduct(
      String productId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.adminProducts}$productId/',
        data: payload,
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// DELETE /marketplace/admin/products/<id>/
  Future<void> adminDeleteProduct(String productId) async {
    try {
      await _dio.delete('${ApiConfig.adminProducts}$productId/');
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<StoreModel?> adminCreateStore(
      Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(ApiConfig.adminStores, data: payload);
      if (response.data is Map) {
        return StoreModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  Future<Map<String, dynamic>?> adminCreateCategory(
      Map<String, dynamic> payload) async {
    try {
      final response =
          await _dio.post(ApiConfig.adminCategories, data: payload);
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Canjes por día para la tienda.
  /// GET /marketplace/analytics/redemption-codes/daily/?store_id=X&days=30
  Future<List<Map<String, dynamic>>> fetchAnalyticsRedemptionCodesDaily(
      String storeId, {
      int days = 30,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.analyticsRedemptionCodesDaily,
        queryParameters: {
          if (storeId.isNotEmpty) 'store_id': storeId,
          'days': days,
        },
      );
      return _toList(response.data)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Desglose de canjes por estado para la tienda.
  /// GET /marketplace/analytics/redemption-codes/by-status/?store={id}
  /// Retorna: { entregados, pendientes, expirados }
  Future<Map<String, dynamic>> fetchRedemptionCodesByStatus(String storeId) async {
    try {
      final response = await _dio.get(
        ApiConfig.analyticsRedemptionCodesByStatus,
        queryParameters: {if (storeId.isNotEmpty) 'store': storeId},
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Productos más canjeados de la tienda.
  /// GET /marketplace/analytics/products/top-redeemed/?store={id}&limit=5
  /// Retorna: [{ id, name, redeemed_count, stock }]
  Future<List<Map<String, dynamic>>> fetchTopRedeemedProducts(
    String storeId, {
    int limit = 5,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.analyticsTopRedeemed,
        queryParameters: {
          if (storeId.isNotEmpty) 'store': storeId,
          'limit': limit.clamp(1, 50),
        },
      );
      return _toList(response.data)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Resumen mensual con growth % para la tienda.
  /// GET /marketplace/analytics/summary/?store_id=X
  Future<Map<String, dynamic>> fetchAnalyticsSummary(String storeId) async {
    try {
      final response = await _dio.get(
        ApiConfig.analyticsSummary,
        queryParameters: {
          if (storeId.isNotEmpty) 'store_id': storeId,
        },
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ---------- PRODUCT IMAGE UPLOAD ----------

  /// GET /marketplace/admin/products/export/?store=<id>&format=csv
  /// Returns raw UTF-8+BOM bytes ready to write as a .csv file.
  Future<List<int>> exportProductsCsv(String storeId) async {
    try {
      final response = await _dio.get<List<int>>(
        ApiConfig.adminProductExport,
        queryParameters: {
          if (storeId.isNotEmpty) 'store': storeId,
          'format': 'csv',
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /marketplace/admin/products/upload-image/ (multipart/form-data)
  /// Campo: image (JPEG / PNG / WEBP / GIF)
  /// Respuesta: { "image_url": "https://..." }
  /// Sube la imagen de un producto. El backend exige `product_id` + `image`,
  /// así que el producto debe existir antes (crear/editar → subir con su id).
  Future<String> uploadProductImage(XFile file, {String? productId}) async {
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        // Dio infers MIME type from filename; no need for http_parser.
        'image': MultipartFile.fromBytes(bytes, filename: file.name),
        if (productId != null && productId.isNotEmpty) 'product_id': productId,
      });
      final response = await _dio.post(
        ApiConfig.adminProductUploadImage,
        data: formData,
      );
      if (response.data is Map) {
        final url = ApiConfig.absoluteMedia(
            (response.data['image_url'] ?? response.data['image'])?.toString());
        if (url.isNotEmpty) return url;
      }
      throw ApiException('El servidor no devolvió una URL de imagen.');
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ---------- STORE SETTINGS ----------

  /// POST /marketplace/stores/<id>/upload-banner/  field: "banner"
  /// Retorna: {banner_url}  — el endpoint ya actualiza store.banner
  Future<String?> uploadStoreBanner(String storeId, XFile file) async {
    try {
      final bytes    = await file.readAsBytes();
      final formData = FormData.fromMap({
        'banner': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final response = await _dio.post(
        ApiConfig.storeBannerUpload(storeId), data: formData);
      if (response.data is Map) {
        final d = response.data as Map;
        return ApiConfig.absoluteMedia((d['banner_url'] ??
                d['banner'] ??
                d['banner_image'] ??
                d['image_url'] ??
                d['url'])
            ?.toString());
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// POST /marketplace/stores/<id>/upload-logo/  field: "logo"
  /// Retorna: {logo_url}  — el endpoint ya actualiza store.image_url
  Future<String?> uploadStoreLogo(String storeId, XFile file) async {
    try {
      final bytes    = await file.readAsBytes();
      final formData = FormData.fromMap({
        'logo': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final response = await _dio.post(
        ApiConfig.storeLogoUpload(storeId), data: formData);
      if (response.data is Map) {
        final d = response.data as Map;
        return ApiConfig.absoluteMedia((d['logo_url'] ??
                d['logo'] ??
                d['image_url'] ??
                d['url'])
            ?.toString());
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// GET /location/reverse-geocode/?lat=X&lng=Y → {address: "..."}
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        ApiConfig.locationReverseGeocode,
        queryParameters: {'lat': lat, 'lng': lng},
      );
      if (response.data is Map) {
        return response.data['address']?.toString();
      }
    } catch (_) {}
    return null;
  }

  /// GET /location/geocode/?address=X → {lat: X, lng: Y}
  Future<Map<String, double>?> geocode(String address) async {
    try {
      final response = await _dio.get(
        ApiConfig.locationGeocode,
        queryParameters: {'address': address},
      );
      if (response.data is Map) {
        final lat = _parseCoord(response.data['lat']);
        final lng = _parseCoord(response.data['lng']);
        if (lat != null && lng != null) return {'lat': lat, 'lng': lng};
      }
    } catch (_) {}
    return null;
  }

  static double? _parseCoord(dynamic v) {
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    return double.tryParse('${v ?? ''}');
  }

  /// PATCH /marketplace/stores/<id>/ — actualiza info de la tienda.
  Future<StoreModel?> updateStore(
      String storeId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.patch(
        ApiConfig.storeDetail(storeId),
        data: payload,
      );
      if (response.data is Map) {
        return StoreModel.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// GET /marketplace/stores/<id>/users/ — lista usuarios con roles.
  Future<List<StoreUserModel>> fetchStoreUsers(String storeId) async {
    try {
      final response = await _dio.get(ApiConfig.storeUsers(storeId));
      final data = response.data;
      // Este endpoint envuelve distinto: {store_id, members: [...]}. No es el
      // envelope canónico (results/data), así que _toList no lo desenvuelve.
      final rawList = data is Map && data['members'] is List
          ? data['members'] as List
          : _toList(data);
      return rawList
          .whereType<Map>()
          .map((e) => StoreUserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /marketplace/stores/<id>/users/ — invita a un usuario por email y rol.
  /// El mismo endpoint que GET /users/ — el backend distingue por método HTTP.
  Future<void> inviteStoreUser(
      String storeId, String email, String role) async {
    try {
      await _dio.post(
        ApiConfig.storeUsers(storeId),
        data: {'email': email, 'role': role},
      );
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// PATCH /marketplace/stores/<storeId>/users/<userId>/ — cambia rol de un usuario.
  Future<void> updateStoreUserRole(
      String storeId, String userId, String role) async {
    try {
      await _dio.patch(
        ApiConfig.storeUserDetail(storeId, userId),
        data: {'role': role},
      );
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// DELETE /marketplace/stores/<storeId>/users/<userId>/ — elimina usuario de la tienda.
  Future<void> removeStoreUser(String storeId, String userId) async {
    try {
      await _dio.delete(ApiConfig.storeUserDetail(storeId, userId));
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<RoleDefinitionModel>> fetchStoreRolesPermissions(String storeId) async {
    try {
      final response = await _dio.get(ApiConfig.storeRolesPermissions(storeId));
      final data = response.data;
      final rolesRaw = (data is Map ? data['roles'] : data) as List? ?? [];
      return rolesRaw
          .whereType<Map>()
          .map((e) => RoleDefinitionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /marketplace/stores/<id>/change-pin/ — cambia el PIN de la tienda.
  Future<void> changeStorePin(
      String storeId, String currentPin, String newPin) async {
    try {
      await _dio.post(
        ApiConfig.storeChangePIN(storeId),
        data: {'current_pin': currentPin, 'new_pin': newPin},
      );
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// PATCH /marketplace/stores/<id>/security/ — activa o desactiva 2FA.
  Future<void> updateStoreSecurity(
      String storeId, {required bool twoFactorEnabled}) async {
    try {
      await _dio.patch(
        ApiConfig.storeSecurity(storeId),
        data: {'two_factor_enabled': twoFactorEnabled},
      );
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Feed de actividad de una tienda específica.
  /// GET /marketplace/stores/<id>/activity/?limit=N
  /// Devuelve {activities: [...], ...} — tipos: redemption_code_redeemed, product_added, system_update
  Future<List<Map<String, dynamic>>> fetchStoreActivity(
    String storeId, {
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.storeActivity(storeId),
        queryParameters: {'limit': limit},
      );
      final data = response.data;
      // Backend retorna envelope {activities: [...], ...}
      if (data is Map && data['activities'] is List) {
        return (data['activities'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return _toList(data)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Configuración de umbrales de la tienda.
  /// GET /marketplace/stores/<id>/settings/
  /// Retorna: {low_stock_threshold, expiry_warning_days}
  Future<Map<String, dynamic>> fetchStoreSettings(String storeId) async {
    try {
      final response = await _dio.get(ApiConfig.storeSettings(storeId));
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Estadísticas de inventario de la tienda.
  /// GET /marketplace/admin/inventory/stats/?store=<id>
  /// Retorna: {total_products, total_stock, out_of_stock, low_stock, low_stock_items}
  Future<Map<String, dynamic>> fetchInventoryStats(String storeId) async {
    try {
      final response = await _dio.get(
        ApiConfig.adminInventoryStats,
        queryParameters: {'store': storeId},
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// PIN actual de la tienda (masked).
  /// GET /marketplace/stores/<id>/pin/
  /// Retorna: {pin_masked, pin_configured}
  Future<Map<String, dynamic>> fetchStorePIN(String storeId) async {
    try {
      final response = await _dio.get(ApiConfig.storePIN(storeId));
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Regenera el PIN de la tienda (lo muestra UNA sola vez).
  /// POST /marketplace/stores/<id>/pin/regenerate/
  /// Retorna: {pin, pin_masked}
  Future<Map<String, dynamic>> regenerateStorePIN(String storeId) async {
    try {
      final response = await _dio.post(ApiConfig.storePINRegenerate(storeId));
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Log de seguridad de la tienda.
  /// GET /marketplace/stores/<id>/security-log/?limit=N
  /// Tipos de evento: pin_changed, password_changed, role_added
  Future<List<Map<String, dynamic>>> fetchSecurityLog(
    String storeId, {
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.storeSecurityLog(storeId),
        queryParameters: {'limit': limit},
      );
      return _toList(response.data)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Meta mensual de fidelización de una tienda.
  /// GET /marketplace/stores/<id>/monthly-goal/
  /// Retorna: {monthly_goal_current, monthly_goal_target,
  ///           monthly_goal_days_remaining, monthly_goal_prize}
  Future<Map<String, dynamic>> fetchMonthlyGoal(String storeId) async {
    try {
      final response = await _dio.get(ApiConfig.storeMonthlyGoal(storeId));
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ---------- REVIEWS ----------

  /// GET /marketplace/stores/<id>/reviews/?filter=X&sort=X&page=N
  /// filter: unanswered | hidden | in_review | all
  /// sort:   recent | oldest | highest | lowest
  Future<Paginated<ReviewModel>> fetchStoreReviews(
    String storeId, {
    String? filter,
    String sort = 'recent',
    int page = 1,
    int pageSize = 10,
  }) async {
    return _fetchPage(
      url: ApiConfig.storeReviews(storeId),
      page: page,
      pageSize: pageSize,
      query: {
        if (filter != null && filter.isNotEmpty) 'filter': filter,
        'sort': sort,
      },
      fromJson: ReviewModel.fromJson,
    );
  }

  /// GET /marketplace/stores/<id>/reviews/stats/
  Future<ReviewsStats> fetchReviewStats(String storeId) async {
    try {
      final response = await _dio.get(ApiConfig.storeReviewStats(storeId));
      if (response.data is Map) {
        return ReviewsStats.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return const ReviewsStats();
  }

  /// POST /marketplace/reviews/<id>/reply/  body: {message}
  Future<bool> replyToReview(String reviewId, String message) async {
    try {
      final response = await _dio.post(
        ApiConfig.reviewReply(reviewId),
        data: {'message': message},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /marketplace/reviews/<id>/report/  body: {reason}
  Future<bool> reportReview(String reviewId, String reason) async {
    try {
      final response = await _dio.post(
        ApiConfig.reviewReport(reviewId),
        data: {'reason': reason},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// PATCH /marketplace/reviews/<id>/hide/
  Future<bool> hideReview(String reviewId, {bool hide = true}) async {
    try {
      final response = await _dio.patch(
        ApiConfig.reviewHide(reviewId),
        data: {'is_hidden': hide},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ---------- GDPR ----------

  /// Lista paginada de solicitudes GDPR.
  /// GET /gdpr/requests/?status=X&type=X&filter=X&page=N
  Future<Paginated<GdprRequestModel>> fetchGdprRequests({
    String? status,
    String? type,
    String? filter, // 'overdue' | 'due_1day' | 'due_3days' | 'resolved'
    int page = 1,
    int pageSize = 20,
  }) async {
    return _fetchPage(
      url: ApiConfig.gdprRequests,
      page: page,
      pageSize: pageSize,
      query: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (type   != null && type.isNotEmpty)   'type':   type,
        if (filter != null && filter.isNotEmpty) 'filter': filter,
      },
      fromJson: GdprRequestModel.fromJson,
    );
  }

  /// Stats del panel GDPR.
  /// GET /gdpr/requests/stats/
  Future<GdprStats> fetchGdprStats() async {
    try {
      final response = await _dio.get(ApiConfig.gdprStats);
      if (response.data is Map) {
        return GdprStats.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return const GdprStats();
  }

  /// Actualiza el estado de una solicitud GDPR.
  /// PATCH /admin/gdpr/requests/<id>/  body: {status, assigned_to (email), notes}
  Future<GdprRequestModel?> updateGdprRequest(
      String id, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.patch(
        ApiConfig.gdprRequestDetail(id), data: payload);
      if (response.data is Map) {
        return GdprRequestModel.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// 6 formatos RGPD con artículo, descripción y plazo.
  /// GET /admin/gdpr/formats/
  Future<List<GdprFormat>> fetchGdprFormats() async {
    try {
      final response = await _dio.get(ApiConfig.gdprFormats);
      return _toList(response.data)
          .whereType<Map>()
          .map((e) => GdprFormat.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Exporta solicitudes GDPR como CSV.
  /// GET /admin/gdpr/requests/export/?status=&type=
  Future<List<int>> exportGdprReport({String? status, String? type}) async {
    try {
      final response = await _dio.get<List<int>>(
        ApiConfig.gdprExport,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (type   != null && type.isNotEmpty)   'type':   type,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ---------- BACKOFFICE USERS ----------

  /// Lista de usuarios (vista admin).
  /// GET /admin/users/?page=N&search=X
  Future<List<AdminUserModel>> fetchAdminUsers({String? search, int? page}) async {
    try {
      final response = await _dio.get(
        ApiConfig.adminUsers,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (page != null) 'page': page,
        },
      );
      return _toList(response.data)
          .whereType<Map>()
          .map((e) => AdminUserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Ficha completa de un usuario (perfil + compliance + actividad).
  /// GET /admin/users/<id>/
  Future<AdminUserModel?> fetchAdminUserDetail(String userId) async {
    try {
      final response = await _dio.get(ApiConfig.adminUserDetail(userId));
      if (response.statusCode == 200 && response.data is Map) {
        return AdminUserModel.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Registro de auditoría de un usuario.
  /// GET /admin/users/<id>/audit-log/?limit=N
  Future<List<AuditLogModel>> fetchAuditLog(String userId, {int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.adminUserAuditLog(userId),
        queryParameters: {'limit': limit},
      );
      return _toList(response.data)
          .whereType<Map>()
          .map((e) => AuditLogModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Suspende la cuenta de un usuario.
  /// POST /admin/users/<id>/suspend/  body: {reason}
  Future<bool> suspendUser(String userId, {String reason = ''}) async {
    try {
      final response = await _dio.post(
        ApiConfig.adminUserSuspend(userId),
        data: reason.isNotEmpty ? {'reason': reason} : null,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Edita el perfil de un usuario (admin).
  /// PUT /admin/users/<id>/  body: {first_name, last_name, email, language, is_staff}
  Future<AdminUserModel?> editAdminUser(
      String userId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(ApiConfig.adminUserDetail(userId), data: payload);
      if (response.data is Map) {
        return AdminUserModel.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Marca a un usuario como auditado.
  /// POST /admin/users/<id>/audit/  body: {notes}
  Future<bool> auditUser(String userId, {String notes = ''}) async {
    try {
      final response = await _dio.post(
        ApiConfig.adminUserAudit(userId),
        data: {'notes': notes},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Revela el documento de identidad con trazabilidad.
  /// POST /admin/users/<id>/reveal-document/  body: {reason}
  /// Retorna: {document_number, document_type}
  Future<Map<String, dynamic>> revealUserDocument(
      String userId, {required String reason}) async {
    try {
      final response = await _dio.post(
        ApiConfig.adminUserRevealDoc(userId),
        data: {'reason': reason},
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// GET /admin/users/<id>/subscription/
  Future<Map<String, dynamic>?> fetchUserSubscription(String userId) async {
    try {
      final response = await _dio.get(ApiConfig.adminUserSubscription(userId));
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// GET /admin/users/<id>/benefits/
  Future<Map<String, dynamic>?> fetchUserBenefits(String userId) async {
    try {
      final response = await _dio.get(ApiConfig.adminUserBenefits(userId));
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// GET /admin/users/<id>/transactions/
  Future<List<Map<String, dynamic>>> fetchUserTransactions(String userId, {int limit = 50}) async {
    try {
      final response = await _dio.get(
        ApiConfig.adminUserTransactions(userId),
        queryParameters: {'limit': limit},
      );
      final raw = response.data;
      if (raw is List) {
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      if (raw is Map) {
        final results = raw['results'] ?? raw['data'] ?? raw['transactions'];
        if (results is List) {
          return results.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      throw toApiException(e);
    }
    return [];
  }

  /// GET /admin/users/<id>/kyc/
  Future<Map<String, dynamic>?> fetchUserKyc(String userId) async {
    try {
      final response = await _dio.get(ApiConfig.adminUserKyc(userId));
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// PATCH /admin/users/<id>/kyc/  body: {action: 'restart'|'approve'|'reject', reason?}
  Future<Map<String, dynamic>?> updateUserKyc(String userId, {
    required String action,
    String? reason,
  }) async {
    try {
      final response = await _dio.patch(
        ApiConfig.adminUserKyc(userId),
        data: {
          'action': action,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// POST /admin/users/<id>/deactivation/  body: {action: 'soft_delete'|'restore', reason?}
  Future<bool> updateUserDeactivation(String userId, {
    required String action,
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.adminUserDeactivation(userId),
        data: {
          'action': action,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ---------- LEGAL & CONSENTS (ver métodos completos al final) ----------

  /// GET /marketplace/admin/stats/
  Future<Map<String, dynamic>?> fetchAdminStats() async {
    try {
      final response = await _dio.get(ApiConfig.adminStats);
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Estadísticas del dashboard ejecutivo del backoffice.
  /// GET /marketplace/admin/dashboard/stats/
  Future<Map<String, dynamic>?> fetchDashboardStats() async {
    try {
      final response = await _dio.get(ApiConfig.adminDashboardStats);
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Alertas críticas activas (tickets escalados, disputas abiertas, reportes de reseñas).
  /// GET /marketplace/admin/alerts/
  Future<List<Map<String, dynamic>>> fetchAdminAlerts() async {
    try {
      final response = await _dio.get(ApiConfig.adminAlerts);
      final raw = response.data;
      if (raw is List) {
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      if (raw is Map) {
        final results = raw['results'] ?? raw['data'] ?? raw['alerts'];
        if (results is List) {
          return results.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      throw toApiException(e);
    }
    return [];
  }

  /// Registro global de auditoría.
  /// GET /marketplace/admin/audit-log/
  Future<List<Map<String, dynamic>>> fetchGlobalAuditLog({
    String? model,
    String? action,
    String? userId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(ApiConfig.adminAuditLog, queryParameters: {
        if (model != null) 'model': model,
        if (action != null) 'action': action,
        if (userId != null) 'user_id': userId,
        'page': page,
        'page_size': pageSize,
      });
      final raw = response.data;
      if (raw is List) {
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      if (raw is Map) {
        final results = raw['results'] ?? raw['data'] ?? raw['entries'];
        if (results is List) {
          return results.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      throw toApiException(e);
    }
    return [];
  }

  /// Salud del sistema (DB, microservicios, latencia, storage, cache).
  /// GET /marketplace/admin/system/health/
  Future<Map<String, dynamic>?> fetchSystemHealth() async {
    try {
      final response = await _dio.get(ApiConfig.adminSystemHealth);
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Métricas por dominio operacional (Soporte, Cumplimiento, Pagos, Moderación).
  /// GET /marketplace/admin/domain-stats/
  Future<Map<String, dynamic>?> fetchDomainStats() async {
    try {
      final response = await _dio.get(ApiConfig.adminDomainStats);
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Helper genérico para endpoints paginados con envelope `{data, meta}`.
  Future<Paginated<T>> _fetchPage<T>({
    required String url,
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? query,
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          ...?query,
          if (page != null) 'page': page,
          if (pageSize != null) 'page_size': pageSize,
        },
      );
      final raw = response.data;
      if (raw is Map) {
        return Paginated<T>.fromJson(Map<String, dynamic>.from(raw), fromJson);
      }
      if (raw is List) {
        final items = raw
            .whereType<Map>()
            .map((e) => fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return Paginated<T>(
          data: items,
          meta: PageMeta(total: items.length, page: 1, lastPage: 1),
        );
      }
      return Paginated<T>(data: const [], meta: const PageMeta());
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Extrae la lista del envelope canónico del backend:
  /// `{data: [...], meta: {total, page, lastPage}}`.
  /// Acepta también una lista plana por compatibilidad mínima.
  static List<dynamic> _toList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      // DRF PageNumberPagination → { "results": [...] }
      if (data['results'] is List) return List<dynamic>.from(data['results'] as List);
      // Custom envelope → { "data": [...] }
      if (data['data'] is List) return List<dynamic>.from(data['data'] as List);
    }
    return const [];
  }

  // ──────────── LEGAL CONSENTS ────────────
  /// GET /admin/legal/consents/ - Lista paginada de consentimientos
  Future<Paginated<LegalConsentModel>> fetchLegalConsents({
    String? status,
    int page = 1,
    int pageSize = 50,
  }) async {
    return _fetchPage(
      url: ApiConfig.adminLegalConsents,
      fromJson: LegalConsentModel.fromJson,
      query: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
      page: page,
      pageSize: pageSize,
    );
  }

  /// GET /admin/legal/stats/ - Estadísticas de consentimientos
  Future<LegalStatsResponse> fetchLegalStats() async {
    try {
      final response = await _dio.get(ApiConfig.adminLegalStats);
      if (response.statusCode == 200 && response.data is Map) {
        return LegalStatsResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
      return LegalStatsResponse(
        totalActive: 0,
        dailyAverage: 0.0,
        conversionRate: 0.0,
        pendingApproval: 0,
        expiredConsents: 0,
      );
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /admin/legal/consents/{id}/action/ - Actualizar estado de consentimiento
  Future<void> updateLegalConsent(
    String consentId, {
    required String action, // 'accept', 'reject'
    String? reason,
  }) async {
    try {
      await _dio.post(
        ApiConfig.adminLegalConsentAction(consentId),
        data: {
          'action': action,
          if (reason != null) 'reason': reason,
        },
      );
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ──────────── LEGAL DOCUMENTS/VERSIONS ────────────
  /// GET /admin/legal/documents/ - Lista de documentos legales con versiones
  Future<Paginated<LegalVersionModel>> fetchLegalVersions({
    int page = 1,
    int pageSize = 50,
  }) async {
    return _fetchPage(
      url: ApiConfig.adminLegalDocuments,
      fromJson: LegalVersionModel.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  /// POST /admin/legal/documents/ - Crear nuevo documento legal
  Future<LegalVersionModel?> createLegalDocument({
    required String documentType,
    required String version,
    required String title,
    required String summary,
    bool activateImmediately = false,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.adminLegalDocuments,
        data: {
          'document_type': documentType,
          'version': version,
          'title': title,
          'summary': summary,
          'is_active': activateImmediately,
        },
      );
      if (response.statusCode == 201 && response.data is Map) {
        return LegalVersionModel.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// PATCH /admin/legal/documents/{id}/ - Actualizar documento (ej: activar)
  Future<LegalVersionModel?> updateLegalDocument(String id, {bool? isActive}) async {
    try {
      final response = await _dio.patch(
        '${ApiConfig.adminLegalDocuments}$id/',
        data: {
          if (isActive != null) 'is_active': isActive,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        return LegalVersionModel.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  // ──────────── DATA SUBJECT REQUESTS (RGPD) ────────────
  /// GET /admin/gdpr/requests/ - Lista de solicitudes de derechos RGPD
  Future<Paginated<DataSubjectRequestModel>> fetchDataSubjectRequests({
    String? status,
    String? rightType,
    int page = 1,
    int pageSize = 50,
  }) async {
    return _fetchPage(
      url: ApiConfig.gdprRequests,
      fromJson: DataSubjectRequestModel.fromJson,
      query: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (rightType != null && rightType.isNotEmpty) 'right_type': rightType,
      },
      page: page,
      pageSize: pageSize,
    );
  }

  /// POST /admin/gdpr/requests/{id}/action/ - Completar/Rechazar solicitud RGPD
  Future<void> updateDataSubjectRequest(
    String requestId, {
    required String action, // 'complete', 'reject'
    String? reason,
  }) async {
    try {
      await _dio.post(
        '${ApiConfig.gdprRequests}$requestId/action/',
        data: {
          'action': action,
          if (reason != null) 'reason': reason,
        },
      );
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ──────────── ADMIN STORE MANAGEMENT ────────────

  /// GET /marketplace/admin/stores/{id}/ - Detalle admin de una tienda
  Future<StoreModel?> adminGetStoreDetail(String storeId) async {
    try {
      final response = await _dio.get(ApiConfig.adminStoreDetail(storeId));
      if (response.data is Map) {
        return StoreModel.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// PATCH /marketplace/admin/stores/{id}/ - Actualización admin de una tienda
  Future<StoreModel?> adminUpdateStore(
      String storeId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.patch(
        ApiConfig.adminStoreDetail(storeId),
        data: payload,
      );
      if (response.data is Map) {
        return StoreModel.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  // ──────────── KYBC COMPLIANCE ────────────

  /// GET /admin/kyc/stats/ - Estadísticas globales de KYBC
  Future<KybcStatsModel> fetchKycStats() async {
    try {
      final response = await _dio.get(ApiConfig.adminKycStats);
      if (response.data is Map) {
        return KybcStatsModel.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return const KybcStatsModel();
  }

  /// GET /admin/kyc/queue/?status=X&page=N - Cola de verificación KYBC
  Future<Paginated<AdminUserModel>> fetchKycQueue({
    String? status, // 'pending' | 'in_review' | 'approved' | 'rejected' | 'suspended'
    int page = 1,
    int pageSize = 20,
  }) async {
    return _fetchPage(
      url: ApiConfig.adminKycQueue,
      fromJson: AdminUserModel.fromJson,
      query: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
      page: page,
      pageSize: pageSize,
    );
  }

  /// POST /admin/users/{id}/kyc/action/ - Acción de cumplimiento (suspend_payments, reinstate)
  Future<void> executeComplianceAction(
    String userId, {
    required String action, // 'suspend_payments' | 'reinstate' | 'suspend_certification'
    String? reason,
    String? notes,
  }) async {
    try {
      await _dio.post(
        ApiConfig.adminUserComplianceAction(userId),
        data: {
          'action': action,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// GET /admin/users/{id}/compliance/history/ - Registro de sanciones
  Future<List<Map<String, dynamic>>> fetchComplianceHistory(String userId) async {
    try {
      final response = await _dio.get(ApiConfig.adminUserComplianceHistory(userId));
      final raw = response.data;
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (raw is Map) {
        final results = raw['results'] ?? raw['data'] ?? raw['history'] ?? [];
        if (results is List) {
          return results
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (e) {
      throw toApiException(e);
    }
    return [];
  }

  // ── SENSITIVE POLICIES ────────────────────────────────────────────────────

  /// GET /admin/policies/
  Future<List<SensitivePolicyModel>> fetchSensitivePolicies({
    String? status,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.adminPolicies,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (status != null) 'status': status,
        },
      );
      final raw = response.data;
      final list = raw is Map
          ? (raw['results'] ?? raw['data'] ?? []) as List
          : _toList(raw);
      return list
          .whereType<Map>()
          .map((e) => SensitivePolicyModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// GET /admin/policies/stats/
  Future<Map<String, dynamic>> fetchSensitivePoliciesStats() async {
    try {
      final response = await _dio.get(ApiConfig.adminPoliciesStats);
      if (response.data is Map) return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw toApiException(e);
    }
    return {};
  }

  /// PATCH /admin/policies/{id}/
  Future<SensitivePolicyModel?> updateSensitivePolicy(
      String id, Map<String, dynamic> payload) async {
    try {
      final response =
          await _dio.patch(ApiConfig.adminPolicyDetail(id), data: payload);
      if (response.data is Map) {
        return SensitivePolicyModel.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// POST /admin/policies/
  Future<SensitivePolicyModel?> createSensitivePolicy(
      Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(ApiConfig.adminPolicies, data: payload);
      if (response.data is Map) {
        return SensitivePolicyModel.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  // ──────────── STRIPE DISPUTES & REFUNDS ────────────

  Future<List<StripeDisputeModel>> fetchStripeDisputes({
    String? status,
    String? type,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.adminStripeDisputes,
        queryParameters: {
          if (status != null) 'status': status,
          if (type != null) 'type': type,
          'page': page,
          'page_size': pageSize,
        },
      );
      final data = response.data;
      final list = data is Map ? (data['results'] ?? data['data'] ?? []) : data;
      if (list is List) {
        return list.map((e) => StripeDisputeModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      throw toApiException(e);
    }
    return [];
  }

  Future<StripeDisputeStats> fetchStripeDisputeStats() async {
    try {
      final response = await _dio.get(ApiConfig.adminStripeDisputeStats);
      if (response.data is Map) {
        return StripeDisputeStats.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      throw toApiException(e);
    }
    return const StripeDisputeStats(totalDisputes: 0, completed: 0, successRate: 0);
  }

  Future<bool> performStripeDisputeAction(String id, {required String action, String? notes}) async {
    try {
      await _dio.post(
        ApiConfig.adminStripeDisputeAction(id),
        data: {'action': action, if (notes != null) 'notes': notes},
      );
      return true;
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ──────────── CAMPAÑAS PROMOCIONALES (superadmin) ────────────
  // Namespace points_admin (`/admin/campaigns/`). El listado es un array pelado
  // (sin envelope). Requiere IsSuperAdmin: un store admin recibe 403.

  /// GET /admin/campaigns/ — lista de campañas.
  Future<List<CampaignModel>> fetchCampaigns() async {
    try {
      final response = await _dio.get(ApiConfig.adminCampaigns);
      return _toList(response.data)
          .whereType<Map>()
          .map((e) => CampaignModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /admin/campaigns/ — crea una campaña. Devuelve la campaña con su `id`
  /// (necesario para subir luego el banner). `banner_image` también se acepta
  /// como string en el payload si ya se tiene la URL.
  Future<CampaignModel?> createCampaign(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(ApiConfig.adminCampaigns, data: payload);
      if (response.data is Map) {
        return CampaignModel.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// PATCH /admin/campaigns/{id}/ — actualiza una campaña.
  Future<CampaignModel?> updateCampaign(
      String id, Map<String, dynamic> payload) async {
    try {
      final response =
          await _dio.patch(ApiConfig.adminCampaignDetail(id), data: payload);
      if (response.data is Map) {
        return CampaignModel.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// DELETE /admin/campaigns/{id}/
  Future<void> deleteCampaign(String id) async {
    try {
      await _dio.delete(ApiConfig.adminCampaignDetail(id));
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /admin/campaigns/{id}/image/ (multipart, campo `image`).
  /// Flujo: primero crea la campaña (para tener el id), luego sube la imagen.
  /// Respuesta: { banner_image: "https://..." }.
  Future<String?> uploadCampaignImage(String campaignId, XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final response = await _dio.post(
        ApiConfig.adminCampaignImage(campaignId),
        data: formData,
      );
      if (response.data is Map) {
        final d = response.data as Map;
        return ApiConfig.absoluteMedia((d['banner_image'] ??
                d['image_url'] ??
                d['image'] ??
                d['banner'] ??
                d['url'])
            ?.toString());
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// GET /admin/campaigns/{id}/impact/ — analítica de rendimiento.
  /// Trae {campaign, affects, points_granted, points_bonus, users_reached,
  /// budget:{...}, ...}. Se devuelve crudo para la pantalla de rendimiento.
  Future<Map<String, dynamic>> fetchCampaignImpact(String id) async {
    try {
      final response = await _dio.get(ApiConfig.adminCampaignImpact(id));
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// GET /admin/campaigns/{id}/preview/ — el banner tal como lo verá el usuario
  /// y la tienda (mismo serializer del marketplace). Se devuelve crudo.
  Future<Map<String, dynamic>> fetchCampaignPreview(String id) async {
    try {
      final response = await _dio.get(ApiConfig.adminCampaignPreview(id));
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return const {};
    } catch (e) {
      throw toApiException(e);
    }
  }
}

