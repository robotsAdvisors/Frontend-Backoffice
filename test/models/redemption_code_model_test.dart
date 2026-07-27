import 'package:flutter_test/flutter_test.dart';
import 'package:letdem/app/data/models/redemption_code_model.dart';

void main() {
  group('RedemptionCodeModel._parseStatus', () {
    test('mapea todos los estados conocidos (case-insensitive)', () {
      expect(RedemptionCodeModel.fromJson({'status': 'paid'}).status,
          RedemptionCodeStatus.paid);
      expect(RedemptionCodeModel.fromJson({'status': 'REDEEMED'}).status,
          RedemptionCodeStatus.redeemed);
      expect(RedemptionCodeModel.fromJson({'status': 'Expired'}).status,
          RedemptionCodeStatus.expired);
      expect(RedemptionCodeModel.fromJson({'status': 'cancelled'}).status,
          RedemptionCodeStatus.cancelled);
    });

    test('estado desconocido o ausente cae en pending', () {
      expect(RedemptionCodeModel.fromJson({'status': 'wat'}).status,
          RedemptionCodeStatus.pending);
      expect(RedemptionCodeModel.fromJson({}).status, RedemptionCodeStatus.pending);
    });
  });

  group('RedemptionCodeModel objetos anidados', () {
    test('extrae ids de user/store/product como objetos', () {
      final v = RedemptionCodeModel.fromJson({
        'id': 'v1',
        'user': {'id': 'u1', 'name': 'Juan', 'email': 'j@x.com'},
        'store': {'id': 's1', 'name': 'Tienda'},
        'product': {'id': 'p1', 'name': 'Café', 'sku': 'CAF'},
      });
      expect(v.customerUserId, 'u1');
      expect(v.storeId, 's1');
      expect(v.productId, 'p1');
      expect(v.customerName, 'Juan');
      expect(v.storeName, 'Tienda');
      expect(v.productName, 'Café');
      expect(v.productSku, 'CAF');
    });

    test('extrae ids cuando vienen como valor plano', () {
      final v = RedemptionCodeModel.fromJson({
        'user': 'u9',
        'store': 's9',
        'product': 'p9',
      });
      expect(v.customerUserId, 'u9');
      expect(v.storeId, 's9');
      expect(v.productId, 'p9');
      expect(v.customerName, isNull);
    });
  });

  group('RedemptionCodeModel getters', () {
    test('isRedeemed refleja el estado', () {
      expect(RedemptionCodeModel.fromJson({'status': 'redeemed'}).isRedeemed, true);
      expect(RedemptionCodeModel.fromJson({'status': 'pending'}).isRedeemed, false);
    });

    test('isExpired true si estado es expired', () {
      final v = RedemptionCodeModel.fromJson({'status': 'expired'});
      expect(v.isExpired, true);
    });

    test('isExpired true si expires_at es pasado', () {
      final v = RedemptionCodeModel.fromJson({
        'expires_at':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      });
      expect(v.isExpired, true);
    });

    test('isExpired false para expires_at futuro y estado activo', () {
      final v = RedemptionCodeModel.fromJson({
        'status': 'paid',
        'expires_at':
            DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      });
      expect(v.isExpired, false);
    });

    test('createdAt es alias de issuedAt', () {
      final iso = '2025-01-01T10:00:00.000';
      final v = RedemptionCodeModel.fromJson({'issued_at': iso});
      expect(v.createdAt, v.issuedAt);
      expect(v.issuedAt, DateTime.parse(iso));
    });

    test('acepta discount_percentage o discount_percent', () {
      expect(
          RedemptionCodeModel.fromJson({'discount_percentage': 15}).discountPercent,
          15);
      expect(RedemptionCodeModel.fromJson({'discount_percent': 20}).discountPercent,
          20);
    });
  });
}
