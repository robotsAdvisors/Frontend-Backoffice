import 'package:flutter_test/flutter_test.dart';
import 'package:letdem/utils/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('apiBaseUrl concatena baseUrl + apiPrefix', () {
      expect(ApiConfig.apiBaseUrl, '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}');
      expect(ApiConfig.apiBaseUrl, endsWith('/api/v1'));
    });

    test('endpoints de auth llevan trailing slash', () {
      expect(ApiConfig.authLogin, endsWith('/'));
      expect(ApiConfig.authSignup, endsWith('/'));
      expect(ApiConfig.tokenRefresh, endsWith('/'));
    });

    test('rutas /users/me... sin trailing slash', () {
      expect(ApiConfig.me, '/users/me');
      expect(ApiConfig.authChangePassword, '/users/me/change-password');
    });

    test('builders parametrizados insertan el id', () {
      expect(ApiConfig.storeDetail('42'), '/marketplace/stores/42/');
      expect(ApiConfig.adminUserDetail('u9'), '/admin/users/u9/');
      // La incidencia la registra la tienda sobre un canje suyo → cuelga de stores/.
      expect(ApiConfig.redemptionCodeIncident('v3'),
          '/marketplace/stores/redemption-codes/v3/incident/');
    });

    test('storeUserDetail combina dos ids', () {
      expect(ApiConfig.storeUserDetail('s1', 'u2'),
          '/marketplace/stores/s1/users/u2/');
    });
  });
}
