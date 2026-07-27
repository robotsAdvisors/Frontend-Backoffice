import 'package:flutter_test/flutter_test.dart';
import 'package:letdem/app/data/models/store_user_model.dart';

/// Verifica [StoreUserModel] contra los items REALES de
/// GET /marketplace/stores/{id}/users/ (envelope {store_id, members:[...]}).
/// Cubre el dueño (OWNER, invited_by null) y un invitado (ADMIN).
void main() {
  group('StoreUserModel.fromJson — miembros reales', () {
    final owner = <String, dynamic>{
      'user_id': 3,
      'email': 'tienda1@lentend.com',
      'name': 'Carlos García',
      'role': 'OWNER',
      'permissions': ['products', 'redemption_codes', 'analytics', 'team', 'settings'],
      'invited_by': null,
      'joined_at': '2026-07-17T12:26:08.987155Z',
    };

    final invited = <String, dynamic>{
      'user_id': 5,
      'email': 'usuario1@lentend.com',
      'name': 'Pedro López',
      'role': 'ADMIN',
      'permissions': ['products', 'redemption_codes', 'analytics', 'team', 'settings'],
      'invited_by': 'tienda1@lentend.com',
      'joined_at': '2026-07-17T15:51:48.019219Z',
    };

    test('OWNER: user_id, name, role, invited_by null', () {
      final u = StoreUserModel.fromJson(owner);
      expect(u.id, '3'); // user_id, no id
      expect(u.email, 'tienda1@lentend.com');
      expect(u.name, 'Carlos García'); // name, no full_name
      expect(u.role, 'OWNER');
      expect(u.isOwner, true);
      expect(u.invitedBy, isNull);
      expect(u.permissions, hasLength(5));
      expect(u.permissions, contains('settings'));
      // Sin is_active en el payload → default true.
      expect(u.isActive, true);
      // joined_at → createdAt (no cae a now()).
      expect(u.createdAt.year, 2026);
    });

    test('ADMIN invitado: invited_by es el email del que invitó', () {
      final u = StoreUserModel.fromJson(invited);
      expect(u.id, '5');
      expect(u.name, 'Pedro López');
      expect(u.role, 'ADMIN');
      expect(u.isOwner, false);
      expect(u.invitedBy, 'tienda1@lentend.com');
      expect(u.permissions, hasLength(5));
    });

    test('roleLabel traduce los roles del backend', () {
      expect(StoreUserModel.fromJson(owner).roleLabel, 'Propietario');
      expect(StoreUserModel.fromJson(invited).roleLabel, 'Administrador');
    });
  });
}
