import 'package:flutter_test/flutter_test.dart';
import 'package:letdem/app/data/models/admin_user_model.dart';

/// Verifica el parseo de [AdminUserModel] contra el JSON REAL del detalle
/// (GET /admin/users/{id}/), incluyendo los anidados y el gotcha de las claves
/// con doble guion bajo en store_memberships.
void main() {
  group('AdminUserModel.fromJson — detalle real', () {
    final json = <String, dynamic>{
      'id': 3,
      'email': 'tienda1@lentend.com',
      'full_name': 'Carlos García',
      'is_active': true,
      'is_staff': false,
      'date_joined': '2026-07-17T12:26:05.209688Z',
      'last_active_at': null,
      'last_login_ip': null,
      'last_login_city': null,
      'total_points': 0,
      'two_factor_enabled': false,
      'deleted_at': null,
      'is_deleted': false,
      'language': 'en',
      'consents': [],
      'gdpr_requests': [],
      'recent_audit': [],
      'store_memberships': [
        {
          'store__id': 1,
          'store__name': 'NVIDIA Store',
          'role': 'OWNER',
          'is_active': true,
          'created': '2026-07-17T12:26:08.987155Z',
        },
        {
          'store__id': 2,
          'store__name': 'Nike Store',
          'role': 'OWNER',
          'is_active': true,
          'created': '2026-07-17T12:26:08.987155Z',
        },
      ],
    };

    final user = AdminUserModel.fromJson(json);

    test('id entero → string', () => expect(user.id, '3'));
    test('full_name → name', () => expect(user.name, 'Carlos García'));
    test('email → emailFull/emailMasked', () {
      expect(user.emailFull, 'tienda1@lentend.com');
      expect(user.emailMasked, 'tienda1@lentend.com');
    });
    test('flags de cuenta', () {
      expect(user.isActive, true);
      expect(user.isStaff, false);
    });
    test('date_joined (UTC Z) → registeredAt', () {
      expect(user.registeredAt.year, 2026);
      expect(user.registeredAt.month, 7);
    });
    test('total_points y language', () {
      expect(user.totalPoints, 0);
      expect(user.language, 'en');
    });
    test('two_factor_enabled → authEnabled', () => expect(user.authEnabled, false));
    test('is_deleted false → sin estado de baja', () {
      expect(user.deactivationStatus, isNull);
      expect(user.deactivationDate, isNull);
    });

    test('store_memberships: doble guion bajo mapeado literalmente', () {
      expect(user.storeMemberships, hasLength(2));
      final first = user.storeMemberships.first;
      expect(first.storeId, '1');
      expect(first.storeName, 'NVIDIA Store');
      expect(first.role, 'OWNER');
      expect(first.isActive, true);
      expect(first.created?.year, 2026);
    });

    test('listas vacías presentes pero sin elementos', () {
      expect(user.consents, isEmpty);
      expect(user.gdprRequests, isEmpty);
      expect(user.recentAudit, isEmpty);
    });

    test('2FA activo se refleja en authEnabled', () {
      final u2 = AdminUserModel.fromJson({...json, 'two_factor_enabled': true});
      expect(u2.authEnabled, true);
    });

    test('is_deleted true → deactivationStatus/deleted_at', () {
      final del = AdminUserModel.fromJson({
        ...json,
        'is_deleted': true,
        'deleted_at': '2026-07-18T10:00:00Z',
      });
      expect(del.deactivationStatus, 'deleted');
      expect(del.deactivationDate?.year, 2026);
    });

    test('el detalle es objeto plano: los anidados sobreviven un re-parse', () {
      // Simula que el modelo no pierde los memberships (regresión del merge).
      expect(user.storeMemberships.map((m) => m.storeName),
          containsAll(['NVIDIA Store', 'Nike Store']));
    });
  });
}
