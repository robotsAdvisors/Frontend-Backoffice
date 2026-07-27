import 'package:flutter_test/flutter_test.dart';
import 'package:letdem/app/data/models/store_model.dart';

/// Verifica el parseo de [StoreModel] contra el JSON REAL del backend
/// (GET /marketplace/admin/stores/{id}/), fijando los nombres de campo que
/// difieren del contrato antiguo: image_url, phone, created, is_active, category.
void main() {
  group('StoreModel.fromJson — payload real del backend', () {
    final json = <String, dynamic>{
      'id': 4,
      'name': 'Luxe Vintage',
      'description': 'Moda vintage de lujo con prendas únicas y exclusivas',
      'category': {
        'id': 4,
        'name': 'fashion',
        'display_name': 'Moda',
        'icon': '👗',
        'color': null,
      },
      'image_url': '',
      'banner': null,
      'email': null,
      'website': null,
      'latitude': 40.418,
      'longitude': -3.701,
      'address': 'Calle Fuencarral, 55, Madrid',
      'phone': '+34 900 456 789',
      'fiscal_id': null,
      'legal_name': '',
      'billing_address': null,
      'bank_iban': '',
      'bank_holder': '',
      'is_open': true,
      'opening_hours': {
        'weekdays': '11:00 - 21:00',
        'weekends': '12:00 - 20:00',
      },
      'rating': 4.7,
      'review_count': 980,
      'is_active': true,
      'owner_email': 'tienda2@lentend.com',
      'kyc_status': 'pending',
      'created': '2026-07-17T09:26:07.628479-03:00',
      'modified': '2026-07-17T09:26:09.000865-03:00',
    };

    final store = StoreModel.fromJson(json);

    test('id entero se normaliza a string', () => expect(store.id, '4'));
    test('nombre y descripción', () {
      expect(store.name, 'Luxe Vintage');
      expect(store.description, contains('vintage'));
    });
    test('owner_email → ownerEmail', () => expect(store.ownerEmail, 'tienda2@lentend.com'));
    test('kyc_status', () => expect(store.kycStatus, 'pending'));
    test('rating y review_count', () {
      expect(store.rating, 4.7);
      expect(store.reviewCount, 980);
    });
    test('coordenadas GPS', () {
      expect(store.latitude, 40.418);
      expect(store.longitude, -3.701);
    });
    test('phone → billingPhone (antes se perdía)', () {
      expect(store.billingPhone, '+34 900 456 789');
    });
    test('created → createdAt con offset -03:00 (no cae a now)', () {
      expect(store.createdAt.year, 2026);
      expect(store.createdAt.month, 7);
    });
    test('is_active → isPublished', () => expect(store.isPublished, true));
    test('category (objeto) → categories con el nombre legible', () {
      expect(store.categories, ['Moda']);
    });
    test('opening_hours', () => expect(store.openingHours['weekdays'], '11:00 - 21:00'));

    test('image_url poblado sí llega a logoUrl', () {
      final withImg = StoreModel.fromJson({...json, 'image_url': 'https://x/l.png'});
      expect(withImg.logoUrl, 'https://x/l.png');
    });
  });
}
