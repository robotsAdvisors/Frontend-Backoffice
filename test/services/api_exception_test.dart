import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letdem/app/data/services/http/api_client.dart';

DioException _dioError({dynamic data, int? status, String? message}) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    message: message,
    response: data == null && status == null
        ? null
        : Response(
            requestOptions: req,
            data: data,
            statusCode: status,
          ),
  );
}

void main() {
  group('toApiException', () {
    test('devuelve el mismo ApiException si ya lo es', () {
      final original = ApiException('boom', statusCode: 400);
      expect(identical(toApiException(original), original), true);
    });

    test('contrato de error: lee error_code, message y details', () {
      final ex = toApiException(
        _dioError(
          data: {
            'error_code': 'INSUFFICIENT_POINTS',
            'message': 'No tienes suficientes puntos',
            'details': {'needed': 500, 'available': 120},
          },
          status: 400,
        ),
      );

      expect(ex.message, 'No tienes suficientes puntos');
      expect(ex.errorCode, 'INSUFFICIENT_POINTS');
      expect(ex.details, {'needed': 500, 'available': 120});
      // Lo que la UI necesita para decir "te faltan 380".
      expect(ex.missingPoints, 380);
    });

    test('missingPoints es null cuando el error es otro', () {
      final ex = toApiException(
        _dioError(
          data: {'error_code': 'NOT_FOUND', 'message': 'No existe'},
          status: 404,
        ),
      );

      expect(ex.errorCode, 'NOT_FOUND');
      expect(ex.details, isEmpty);
      expect(ex.missingPoints, isNull);
    });

    // Lo de abajo ya no lo emite el backend (todo error >= 400 pasa por el
    // contrato), pero se tolera por si algo se lo salta: nginx, una página HTML.
    test('extrae {detail: ...} (formato DRF)', () {
      final ex = toApiException(
        _dioError(data: {'detail': 'No autorizado'}, status: 401),
      );
      expect(ex.message, 'No autorizado');
      expect(ex.statusCode, 401);
    });

    test('extrae {error: ...}', () {
      final ex = toApiException(_dioError(data: {'error': 'Fallo'}, status: 400));
      expect(ex.message, 'Fallo');
    });

    test('serializa errores por campo cuando no hay detail/error', () {
      final ex = toApiException(_dioError(
        data: {
          'email': ['requerido'],
          'password': ['muy corto'],
        },
        status: 400,
      ));
      expect(ex.message, contains('email:'));
      expect(ex.message, contains('password:'));
      expect(ex.message, contains(' | '));
    });

    test('oculta páginas HTML de error crudas', () {
      final ex = toApiException(_dioError(
        data: '<html><body>500 Internal Server Error</body></html>',
        status: 500,
      ));
      expect(ex.message, 'Error del servidor (500)');
      expect(ex.message, isNot(contains('<html>')));
    });

    test('trunca texto plano largo a ~200 chars', () {
      final long = 'x' * 500;
      final ex = toApiException(_dioError(data: long, status: 400));
      expect(ex.message.length, lessThanOrEqualTo(201));
      expect(ex.message, endsWith('…'));
    });

    test('usa el message del DioException si no hay data', () {
      final ex = toApiException(_dioError(message: 'timeout'));
      expect(ex.message, 'timeout');
    });

    test('error genérico no-Dio cae a toString()', () {
      final ex = toApiException(StateError('algo raro'));
      expect(ex.message, contains('algo raro'));
    });
  });
}
