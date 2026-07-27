import 'package:get/get.dart';

import '../../../../utils/app_config.dart';
import '../../../../utils/dummy_helper.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/redemption_code_model.dart';
import '../../../data/repositories/marketplace_repository.dart';
import '../../../data/services/auth_service.dart';

class CustomerHistoryController extends GetxController {
  final RxList<RedemptionCodeModel> customerRedemptionCodes = <RedemptionCodeModel>[].obs;
  final RxMap<String, int> redemptionCodeRatings = <String, int>{}.obs;
  final RxString walletCode = ''.obs;
  final RxString walletStatus = 'Activa'.obs;
  final RxBool loadingWallet = true.obs;
  final RxBool loadingHistory = false.obs;

  final Rxn<OrdersPage> ordersPage = Rxn<OrdersPage>();
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxBool loadingOrders = false.obs;
  final RxBool loadingMoreOrders = false.obs;
  static const int _ordersPageSize = 10;

  @override
  void onInit() {
    super.onInit();
    _loadWalletData();
    _loadCustomerHistory();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    loadingOrders.value = true;
    try {
      final page = await MarketplaceRepository.instance
          .fetchOrders(page: 1, pageSize: _ordersPageSize);
      ordersPage.value = page;
      orders.assignAll(page.data);
    } catch (_) {
      ordersPage.value = null;
      orders.clear();
    } finally {
      loadingOrders.value = false;
    }
  }

  Future<void> loadMoreOrders() async {
    final current = ordersPage.value;
    if (current == null) return;
    if (loadingOrders.value || loadingMoreOrders.value) return;
    if (!current.meta.hasMore) return;
    loadingMoreOrders.value = true;
    try {
      final next = await MarketplaceRepository.instance.fetchOrders(
        page: current.meta.page + 1,
        pageSize: _ordersPageSize,
      );
      orders.addAll(next.data);
      ordersPage.value = next;
    } catch (_) {
      // mantiene la página actual
    } finally {
      loadingMoreOrders.value = false;
    }
  }

  Future<void> _loadWalletData() async {
    loadingWallet.value = true;
    final card = await AuthService.fetchAssignedVirtualCard();
    walletCode.value =
        (card['number'] ?? '0000 0000 0000 0000').replaceAll(' ', '');
    walletStatus.value = 'Activa';
    loadingWallet.value = false;
  }

  /// Trae los redemptionCodes del usuario desde GET /api/v1/marketplace/redemptionCodes/.
  /// Si falla, hace fallback a los redemptionCodes locales (DummyHelper).
  Future<void> _loadCustomerHistory() async {
    loadingHistory.value = true;
    try {
      final remote = await MarketplaceRepository.instance.fetchRedemptionCodes();
      customerRedemptionCodes.assignAll(remote);
      return;
    } catch (_) {
      // continua con fallback
    } finally {
      loadingHistory.value = false;
    }

    // En builds reales no se inventa historial: se queda vacío ante fallo.
    if (!AppConfig.useDummyData) return;

    final userEmail =
        AuthService.currentUserEmail ?? 'cliente@marketplace.com';
    final customerId = DummyHelper.customerIdForEmail(userEmail);
    final values = DummyHelper.redemptionCodes
        .where((redemptionCode) => redemptionCode.customerUserId == customerId)
        .toList();

    if (values.isEmpty) {
      final fallbackCustomerId =
          DummyHelper.customerIdForEmail('cliente@marketplace.com');
      customerRedemptionCodes.assignAll(
        DummyHelper.redemptionCodes
            .where(
              (redemptionCode) => redemptionCode.customerUserId == fallbackCustomerId,
            )
            .toList(),
      );
      return;
    }

    customerRedemptionCodes.assignAll(values);
  }

  List<RedemptionCodeModel> get walletMovements {
    final copy = customerRedemptionCodes.toList();
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  String statusLabel(RedemptionCodeModel redemptionCode) {
    if (redemptionCode.isRedeemed) {
      return 'Entregado';
    }
    if (redemptionCode.isIncident) {
      return 'Incidencia';
    }
    final expiredByDate = redemptionCode.expiresAt != null &&
        redemptionCode.expiresAt!.isBefore(DateTime.now());
    if (redemptionCode.isExpired || expiredByDate) {
      return 'Expirado';
    }
    if (redemptionCode.isInProgress) {
      return 'En proceso';
    }
    return 'Pendiente';
  }

  String remainingTime(RedemptionCodeModel redemptionCode) {
    if (statusLabel(redemptionCode) != 'Pendiente' || redemptionCode.expiresAt == null) {
      return '-';
    }
    final diff = redemptionCode.expiresAt!.difference(DateTime.now());
    if (diff.isNegative) {
      return 'Expirado';
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    return '${days}d ${hours}h restantes';
  }

  String discountText(RedemptionCodeModel redemptionCode) {
    return '${redemptionCode.discountPercent.toStringAsFixed(0)}%';
  }

  String productNameFor(RedemptionCodeModel redemptionCode) {
    return redemptionCode.productName ?? DummyHelper.productNameById(redemptionCode.productId);
  }

  bool canRate(RedemptionCodeModel redemptionCode) {
    return redemptionCode.isRedeemed;
  }

  int ratingFor(String redemptionCodeId) {
    return redemptionCodeRatings[redemptionCodeId] ?? 0;
  }

  void rateRedemptionCode(String redemptionCodeId, int rating) {
    redemptionCodeRatings[redemptionCodeId] = rating;
    redemptionCodeRatings.refresh();
  }
}
