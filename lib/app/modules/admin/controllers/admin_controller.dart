import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../utils/app_config.dart';
import '../../../../utils/dummy_helper.dart';
import '../../../components/custom_snackbar.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/paginated.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/store_model.dart';
import '../../../data/models/store_user_model.dart';
import '../../../data/models/role_definition_model.dart';
import '../../../data/models/redemption_code_model.dart';
import '../../../data/repositories/marketplace_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/http/api_client.dart';

class AdminController extends GetxController {
  static const int _redemptionCodesPageSize = 20;

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<StoreUserModel> storeUsers = <StoreUserModel>[].obs;
  final RxList<RoleDefinitionModel> roleDefinitions = <RoleDefinitionModel>[].obs;
  final RxList<RedemptionCodeModel> redemptionCodes = <RedemptionCodeModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxSet<String> favoriteRedemptionCodeIds = <String>{}.obs;
  late StoreModel currentStore;
  final RxInt totalProducts = 0.obs;
  final RxInt totalStock = 0.obs;
  final RxDouble averagePrice = 0.0.obs;
  final RxDouble storeRating = 0.0.obs;
  final RxInt storeReviewCount = 0.obs;
  final RxString storeId = ''.obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMoreRedemptionCodes = false.obs;
  final Rx<PageMeta> redemptionCodesMeta = const PageMeta().obs;
  final RxList<Map<String, dynamic>> dailyRedemptionCodes = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>> analyticsSummary = Rx<Map<String, dynamic>>({});
  final RxList<Map<String, dynamic>> remoteActivity = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>> monthlyGoal = Rx<Map<String, dynamic>>({});

  // Validación de canjes
  final Rx<RedemptionCodeModel?> previewedRedemptionCode = Rx<RedemptionCodeModel?>(null);
  final RxBool isPreviewingRedemptionCode = false.obs;
  final RxString previewError = ''.obs;
  final Rx<Map<String, dynamic>> storePinData = Rx<Map<String, dynamic>>({});
  final RxString regeneratedPin = ''.obs;
  final RxBool isRegeneratingPin = false.obs;
  final RxList<Map<String, dynamic>> securityLog = <Map<String, dynamic>>[].obs;

  // Inventory (paginated, separate from the preloaded product list)
  final RxList<ProductModel> inventoryProducts = <ProductModel>[].obs;
  final Rx<PageMeta> inventoryMeta = const PageMeta().obs;
  final RxInt inventoryCurrentPage = 1.obs;
  final RxBool isLoadingInventory = false.obs;

  // Store settings (thresholds)
  final RxInt lowStockThreshold = 10.obs;
  final RxInt expiryWarningDays = 30.obs;

  // Inventory stats from backend
  final Rx<Map<String, dynamic>> inventoryStats = Rx<Map<String, dynamic>>({});

  // Analytics — historial panel
  final Rx<Map<String, dynamic>> redemptionCodesByStatus =
      Rx<Map<String, dynamic>>({});
  final RxList<Map<String, dynamic>> topRedeemedProducts =
      <Map<String, dynamic>>[].obs;

  // Date-filtered redemptionCodes for the historial panel
  final RxList<RedemptionCodeModel> dateFilteredRedemptionCodes = <RedemptionCodeModel>[].obs;
  final RxBool isLoadingDateFilter = false.obs;

  // Store orders (tab Ventas)
  final RxList<Map<String, dynamic>> storeOrders = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>> storeOrdersMeta = Rx<Map<String, dynamic>>({});
  final RxInt storeOrdersPage = 1.obs;
  final RxBool isLoadingOrders = false.obs;
  final RxString storeOrdersStatusFilter = ''.obs;

  final _repo = MarketplaceRepository.instance;

  @override
  void onInit() {
    super.onInit();
    _bootstrapFromDummy();
    _loadFromBackend();
  }

  // Muestra datos dummy instantáneamente mientras carga el backend.
  void _bootstrapFromDummy() {
    if (!AppConfig.useDummyData) {
      // Sin datos demo: arranca con una tienda vacía (sin nombre/PIN/códigos
      // ficticios) hasta que el backend responda. `currentStore` debe quedar
      // inicializada para no romper los getters que la usan.
      currentStore = StoreModel.fromJson(const {});
      return;
    }
    final email = AuthService.currentUserEmail ?? '';
    final resolvedId = DummyHelper.storeIdForAdminEmail(email);
    storeId.value = resolvedId ?? DummyHelper.stores.first.id;
    currentStore = DummyHelper.stores.firstWhere(
      (s) => s.id == storeId.value,
      orElse: () => DummyHelper.stores.first,
    );
    products.assignAll(
      DummyHelper.products.where((p) => p.storeId == currentStore.id).toList(),
    );
    storeUsers.assignAll(
      DummyHelper.storeUsers.where((u) => u.storeId == currentStore.id).toList(),
    );
    redemptionCodes.assignAll(
      DummyHelper.redemptionCodes.where((v) => v.storeId == currentStore.id).toList(),
    );
    _calculateStoreMetrics();
  }

  List<String> get categoryNames =>
      categories.map((c) => c.title).where((t) => t.isNotEmpty).toList();

  Future<void> _loadFromBackend() async {
    isLoading.value = true;
    try {
      final email = (AuthService.currentUserEmail ?? '').toLowerCase();

      // 1. Encontrar la tienda del admin logueado.
      final stores = await _repo.fetchStores();
      if (stores.isNotEmpty) {
        final picked = stores.firstWhere(
          (s) =>
              s.ownerEmail.toLowerCase() == email ||
              s.email.toLowerCase() == email,
          orElse: () => stores.first,
        );
        currentStore = picked;
        storeId.value = picked.id;
        storeRating.value = picked.rating;
        storeReviewCount.value = picked.reviewCount;
      }

      // Si fetchStores falló o devolvió vacío el storeId sigue siendo dummy — no llamar al backend.
      if (storeId.value.isEmpty || storeId.value.startsWith('store_')) return;

      // 2. Cargar productos, redemptionCodes, categorias, analytics, actividad y meta mensual en paralelo.
      final results = await Future.wait<dynamic>([
        _repo.fetchProducts(storeId: storeId.value),
        _repo.fetchRedemptionCodesPage(page: 1, pageSize: _redemptionCodesPageSize),
        _repo.fetchCategories().catchError((_) => <CategoryModel>[]),
        _repo.fetchAnalyticsRedemptionCodesDaily(storeId.value)
            .catchError((_) => <Map<String, dynamic>>[]),
        _repo.fetchAnalyticsSummary(storeId.value)
            .catchError((_) => <String, dynamic>{}),
        _repo.fetchStoreActivity(storeId.value)
            .catchError((_) => <Map<String, dynamic>>[]),
        _repo.fetchMonthlyGoal(storeId.value)
            .catchError((_) => <String, dynamic>{}),
        _repo.fetchStorePIN(storeId.value)
            .catchError((_) => <String, dynamic>{}),
        _repo.fetchSecurityLog(storeId.value)
            .catchError((_) => <Map<String, dynamic>>[]),
        _repo.fetchStoreSettings(storeId.value)
            .catchError((_) => <String, dynamic>{}),
        _repo.fetchInventoryStats(storeId.value)
            .catchError((_) => <String, dynamic>{}),
        _repo.fetchRedemptionCodesByStatus(storeId.value)
            .catchError((_) => <String, dynamic>{}),
        _repo.fetchTopRedeemedProducts(storeId.value)
            .catchError((_) => <Map<String, dynamic>>[]),
        _repo.fetchStoreUsers(storeId.value)
            .catchError((_) => <StoreUserModel>[]),
      ]);

      final remoteProducts      = results[0]  as List<ProductModel>;
      final redemptionCodesPage        = results[1]  as Paginated<RedemptionCodeModel>;
      final remoteCategories    = results[2]  as List<CategoryModel>;
      final remoteDailyRedemptionCodes = results[3]  as List<Map<String, dynamic>>;
      final remoteSummary       = results[4]  as Map<String, dynamic>;
      final remoteActivityList  = results[5]  as List<Map<String, dynamic>>;
      final remoteMonthlyGoal   = results[6]  as Map<String, dynamic>;
      final remotePinData       = results[7]  as Map<String, dynamic>;
      final remoteSecurityLog   = results[8]  as List<Map<String, dynamic>>;
      final remoteSettings      = results[9]  as Map<String, dynamic>;
      final remoteInvStats      = results[10] as Map<String, dynamic>;
      final remoteRedemptionCodeStatus = results[11] as Map<String, dynamic>;
      final remoteTopRedeemed   = results[12] as List<Map<String, dynamic>>;
      final remoteStoreUsers    = results[13] as List<StoreUserModel>;

      products.assignAll(remoteProducts);

      redemptionCodesMeta.value = redemptionCodesPage.meta;
      // El endpoint /marketplace/redemptionCodes/ ya filtra por tienda autenticada.
      // No filtrar adicionalmente por storeId para evitar descartar redemptionCodes
      // cuyo campo store venga en formato distinto (string vs objeto).
      redemptionCodes.assignAll(redemptionCodesPage.data);

      if (remoteCategories.isNotEmpty) categories.assignAll(remoteCategories);
      if (remoteDailyRedemptionCodes.isNotEmpty) dailyRedemptionCodes.assignAll(remoteDailyRedemptionCodes);
      if (remoteSummary.isNotEmpty) analyticsSummary.value = remoteSummary;
      if (remoteActivityList.isNotEmpty) remoteActivity.assignAll(remoteActivityList);
      if (remoteMonthlyGoal.isNotEmpty) monthlyGoal.value = remoteMonthlyGoal;
      if (remotePinData.isNotEmpty) storePinData.value = remotePinData;
      if (remoteSecurityLog.isNotEmpty) securityLog.assignAll(remoteSecurityLog);

      if (remoteSettings.isNotEmpty) {
        final threshold = remoteSettings['low_stock_threshold'];
        final days      = remoteSettings['expiry_warning_days'];
        if (threshold is int) lowStockThreshold.value = threshold;
        if (days      is int) expiryWarningDays.value = days;
      }
      if (remoteInvStats.isNotEmpty)      inventoryStats.value  = remoteInvStats;
      if (remoteRedemptionCodeStatus.isNotEmpty) redemptionCodesByStatus.value = remoteRedemptionCodeStatus;
      if (remoteTopRedeemed.isNotEmpty)   topRedeemedProducts.assignAll(remoteTopRedeemed);
      if (remoteStoreUsers.isNotEmpty)    storeUsers.assignAll(remoteStoreUsers);

      _calculateStoreMetrics();
    } catch (_) {
      // Silencio: se mantienen los datos dummy.
    } finally {
      isLoading.value = false;
    }
  }

  /// Carga redemptionCodes filtrados por fecha ISO (YYYY-MM-DD) usando el backend.
  /// Limpia los resultados si [date] está vacío.
  Future<void> loadRedemptionCodesForDate(String date) async {
    if (date.isEmpty) {
      dateFilteredRedemptionCodes.clear();
      return;
    }
    if (isLoadingDateFilter.value) return;
    isLoadingDateFilter.value = true;
    try {
      final page = await _repo.fetchRedemptionCodesPage(
        page: 1,
        pageSize: 200,
        date: date,
      );
      dateFilteredRedemptionCodes.assignAll(page.data);
    } catch (_) {
      dateFilteredRedemptionCodes.clear();
    } finally {
      isLoadingDateFilter.value = false;
    }
  }

  Future<void> loadMoreRedemptionCodes() async {
    if (isLoadingMoreRedemptionCodes.value || !redemptionCodesMeta.value.hasMore) return;
    isLoadingMoreRedemptionCodes.value = true;
    try {
      final next = redemptionCodesMeta.value.page + 1;
      final page = await _repo.fetchRedemptionCodesPage(
        page: next,
        pageSize: _redemptionCodesPageSize,
      );
      redemptionCodesMeta.value = page.meta;
      redemptionCodes.addAll(
        page.data.where((v) => v.storeId.isEmpty || v.storeId == storeId.value),
      );
    } catch (_) {
      // El usuario puede reintentar.
    } finally {
      isLoadingMoreRedemptionCodes.value = false;
    }
  }

  void _calculateStoreMetrics() {
    totalProducts.value = products.length;
    totalStock.value = products.fold<int>(0, (sum, p) => sum + p.quantity);
    averagePrice.value = products.isNotEmpty
        ? products.fold<double>(0.0, (sum, p) => sum + p.discountPrice) /
            products.length
        : 0.0;
  }

  // ── Inventory stats ───────────────────────────────────────────────────────

  int get lowStockCount => products
      .where((p) => p.quantity > 0 && p.quantity < lowStockThreshold.value)
      .length;

  int get expiringSoonCount {
    final cutoff = DateTime.now().add(Duration(days: expiryWarningDays.value));
    return products
        .where((p) =>
            p.expiryDate != null &&
            !p.isExpired &&
            p.expiryDate!.isBefore(cutoff))
        .length;
  }

  int get activeCategoriesCount => categories.length;

  /// Carga una página paginada del inventario (con búsqueda opcional).
  Future<void> loadInventoryPage({
    int page = 1,
    String search = '',
    String? category,
    String ordering = 'name',
  }) async {
    if (storeId.value.isEmpty || storeId.value.startsWith('store_')) return;
    if (isLoadingInventory.value) return;
    isLoadingInventory.value = true;
    try {
      final result = await _repo.fetchProductsPage(
        storeId: storeId.value,
        page: page,
        pageSize: 10,
        search: search.isNotEmpty ? search : null,
        categoryName: category,
        ordering: ordering,
      );
      inventoryProducts.assignAll(result.data);
      inventoryMeta.value = result.meta;
      inventoryCurrentPage.value = page;
    } catch (_) {
      // Si falla, usar los productos ya cargados en memoria
      final all = products.where((p) {
        if (search.isNotEmpty &&
            !p.name.toLowerCase().contains(search.toLowerCase()) &&
            !p.sku.toLowerCase().contains(search.toLowerCase())) {
          return false;
        }
        if (category != null && category.isNotEmpty && p.category != category) {
          return false;
        }
        return true;
      }).toList();
      final start = (page - 1) * 10;
      final end = (start + 10).clamp(0, all.length);
      inventoryProducts.assignAll(
          start < all.length ? all.sublist(start, end) : []);
      inventoryMeta.value = PageMeta(
          total: all.length,
          page: page,
          lastPage: (all.length / 10).ceil().clamp(1, 9999));
      inventoryCurrentPage.value = page;
    } finally {
      isLoadingInventory.value = false;
    }
  }

  /// Crea el producto en el backend y devuelve el modelo creado (con su id),
  /// para poder subir después la imagen (que exige `product_id`).
  Future<ProductModel?> addProduct(ProductModel product) async {
    products.add(product);
    _calculateStoreMetrics();

    try {
      final payload = <String, dynamic>{
        'store': storeId.value.isEmpty ? null : storeId.value,
        'name': product.name,
        'description': product.description,
        'image_url': product.image.startsWith('http') ? product.image : null,
        'price': product.originalPrice,
        'discount': product.discountPercent,
        'stock': product.stock > 0 ? product.stock : product.quantity,
        'points_required': product.pointsRequired,
        'is_redeemable': product.isRedeemable,
        if (product.monetaryPrice > 0) 'monetary_price': product.monetaryPrice,
        if (product.category.isNotEmpty) 'category': product.category,
      }..removeWhere((_, v) => v == null);

      final created = await _repo.adminCreateProduct(payload);
      if (created != null) {
        final createdModel = ProductModel.fromJson(created);
        final idx = products.indexOf(product);
        if (idx != -1) {
          products[idx] = createdModel;
          _calculateStoreMetrics();
        }
        CustomSnackBar.showCustomSnackBar(
          title: 'Producto creado',
          message: 'El producto se guardó en el backend.',
        );
        return createdModel;
      }
    } on ApiException catch (e) {
      products.remove(product); // quita el optimista si falló
      _calculateStoreMetrics();
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'No se pudo persistir',
        message: e.message,
      );
    } catch (_) {
      products.remove(product);
      _calculateStoreMetrics();
    }
    return null;
  }

  Future<void> deleteProduct(ProductModel product) async {
    final index = products.indexOf(product);
    products.remove(product);
    _calculateStoreMetrics();
    try {
      await _repo.adminDeleteProduct(product.id);
      CustomSnackBar.showCustomSnackBar(
        title: 'Producto eliminado',
        message: 'El producto fue eliminado correctamente.',
      );
    } on ApiException catch (e) {
      if (index != -1) { products.insert(index, product); } else { products.add(product); }
      _calculateStoreMetrics();
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error al eliminar',
        message: e.message,
      );
    } catch (_) {
      if (index != -1) { products.insert(index, product); } else { products.add(product); }
      _calculateStoreMetrics();
    }
  }

  Future<ProductModel?> updateProduct(
      String productId, Map<String, dynamic> payload) async {
    try {
      final updated = await _repo.adminUpdateProduct(productId, payload);
      if (updated != null) {
        final updatedModel = ProductModel.fromJson(updated);
        final idx = products.indexWhere((p) => p.id == productId);
        if (idx != -1) {
          products[idx] = updatedModel;
          _calculateStoreMetrics();
        }
        CustomSnackBar.showCustomSnackBar(
          title: 'Producto actualizado',
          message: 'Los cambios se guardaron correctamente.',
        );
        return updatedModel;
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error al actualizar',
        message: e.message,
      );
    } catch (_) {}
    return null;
  }

  // ── Dashboard stats ──────────────────────────────────────────────────────

  // Prefer backend analytics; fall back to local redemptionCode list.
  int get pendingCount {
    final summary = analyticsSummary.value;
    if (summary['pending_redemption_codes'] != null) {
      return (summary['pending_redemption_codes'] as num).toInt();
    }
    return redemptionCodes
        .where((v) =>
            v.status == RedemptionCodeStatus.pending ||
            v.status == RedemptionCodeStatus.paid ||
            // Validado pero aún sin entregar: sigue pendiente de acción en el
            // mostrador (falta confirmar la entrega).
            v.status == RedemptionCodeStatus.inProgress)
        .length;
  }

  int get completedTodayCount {
    final summary = analyticsSummary.value;
    if (summary['completed_today'] != null) {
      return (summary['completed_today'] as num).toInt();
    }
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    return redemptionCodes.where((v) => v.isRedeemed && v.issuedAt.isAfter(dayStart)).length;
  }

  int get completedMonthCount {
    final summary = analyticsSummary.value;
    if (summary['completed_this_month'] != null) {
      return (summary['completed_this_month'] as num).toInt();
    }
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return redemptionCodes.where((v) => v.isRedeemed && v.issuedAt.isAfter(monthStart)).length;
  }

  int get expiredCount => redemptionCodes.where((v) => v.isExpired && !v.isRedeemed).length;

  int get activePrizesCount {
    final summary = analyticsSummary.value;
    if (summary['active_products'] != null) {
      return (summary['active_products'] as num).toInt();
    }
    return products.where((p) => p.quantity > 0).length;
  }

  int get availablePoints {
    final summary = analyticsSummary.value;
    if (summary['available_points'] != null) {
      return (summary['available_points'] as num).toInt();
    }
    return 0;
  }

  String get storeCardId {
    // Prefer the stable ID returned by GET /stores/<id>/
    if (currentStore.cardId.isNotEmpty) return currentStore.cardId;
    // Fallback: derive from store UUID until backend field is available
    final id = storeId.value.replaceAll('-', '').toUpperCase();
    final part = id.length >= 4 ? id.substring(0, 4) : id.padRight(4, '0');
    return 'TIENDA-$part-X';
  }

  int get accumulatedPoints {
    final summary = analyticsSummary.value;
    if (summary['total_points_accumulated'] != null) {
      return (summary['total_points_accumulated'] as num).toInt();
    }
    return redemptionCodes.fold<int>(0, (sum, v) => sum + v.pointsUsed);
  }

  List<RedemptionCodeModel> get recentCanjes {
    final sorted = [...redemptionCodes]
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return sorted.take(10).toList();
  }

  List<Map<String, dynamic>> get activityFeed {
    // Prefer real backend events from GET /stores/<id>/activity/
    if (remoteActivity.isNotEmpty) {
      return remoteActivity.map(_normalizeActivityEvent).toList();
    }
    // Fallback: derive activity locally while backend data is unavailable
    return _derivedActivityFeed();
  }

  Map<String, dynamic> _normalizeActivityEvent(Map<String, dynamic> event) {
    final type = (event['type'] ?? '').toString();
    final title = (event['title'] ?? '').toString();
    final description = (event['description'] ?? event['body'] ?? '').toString();
    final ts = event['timestamp'] ?? event['created_at'];
    final timeLabel = ts != null ? _relativeTime(DateTime.tryParse(ts.toString())) : '';

    String color;
    switch (type) {
      case 'redemption_code_redeemed':
      case 'redemption':
        color = 'green';
        break;
      case 'redemption_code_created':
      case 'product_added':
        color = 'orange';
        break;
      case 'low_stock':
        color = 'red';
        break;
      case 'system_update':
        color = 'grey';
        break;
      default:
        color = 'purple';
    }

    return {
      'title': title,
      'body': description,
      'time': timeLabel,
      'color': color,
      'action_label': (event['action_label'] ?? '').toString(),
      'action_route': (event['action_route'] ?? '').toString(),
    };
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
    return 'Hace ${diff.inDays} días';
  }

  List<Map<String, dynamic>> _derivedActivityFeed() {
    final items = <Map<String, dynamic>>[];

    final redeemed = redeemedRedemptionCodes;
    if (redeemed.length >= 10) {
      final milestone = (redeemed.length ~/ 10) * 10;
      items.add({
        'title': 'Nueva meta alcanzada',
        'body': 'Tienda superó los $milestone canjes totales.',
        'time': _relativeTime(redeemedRedemptionCodes.last.issuedAt),
        'color': 'purple',
        'action_label': '',
        'action_route': '',
      });
    }

    if (redemptionCodes.isNotEmpty) {
      final countByProduct = <String, int>{};
      for (final v in redemptionCodes) {
        countByProduct[v.productId] = (countByProduct[v.productId] ?? 0) + 1;
      }
      final topEntry =
          countByProduct.entries.reduce((a, b) => a.value > b.value ? a : b);
      final topRedemptionCode = redemptionCodes.firstWhere(
        (v) => v.productId == topEntry.key,
        orElse: () => redemptionCodes.first,
      );
      final name = productNameFor(topRedemptionCode);
      items.add({
        'title': 'Premio destacado',
        'body': "'$name' es el más canjeado esta semana.",
        'time': _relativeTime(topRedemptionCode.issuedAt),
        'color': 'orange',
        'action_label': '',
        'action_route': '',
      });
    }

    final lowStock =
        products.where((p) => p.quantity > 0 && p.quantity < 5).toList();
    if (lowStock.isNotEmpty) {
      final prod = lowStock.first;
      items.add({
        'title': 'Alerta de stock',
        'body': '${prod.name} (${prod.quantity} unidades restantes).',
        'time': 'Reciente',
        'color': 'red',
        'action_label': 'Gestionar stock',
        'action_route': '',
      });
    }

    return items;
  }

  // ─────────────────────────────────────────────────────────────────────────

  List<RedemptionCodeModel> get recentValidRedemptionCodes {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    return redemptionCodes
        .where((v) => v.createdAt.isAfter(cutoff) && !v.isRedeemed && !v.isExpired)
        .toList();
  }

  List<RedemptionCodeModel> get lastMonthValidRedemptionCodes {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return redemptionCodes
        .where((v) => v.createdAt.isAfter(cutoff) && !v.isRedeemed && !v.isExpired)
        .toList();
  }

  List<RedemptionCodeModel> get redeemedRedemptionCodes =>
      redemptionCodes.where((v) => v.isRedeemed).toList();

  List<RedemptionCodeModel> get expiredUnredeemedRedemptionCodes =>
      redemptionCodes.where((v) => v.isExpired && !v.isRedeemed).toList();

  List<RedemptionCodeModel> get favoriteRedemptionCodes =>
      redemptionCodes.where((v) => favoriteRedemptionCodeIds.contains(v.id)).toList();

  bool isFavorite(String redemptionCodeId) => favoriteRedemptionCodeIds.contains(redemptionCodeId);

  void toggleFavorite(String redemptionCodeId) {
    if (favoriteRedemptionCodeIds.contains(redemptionCodeId)) {
      favoriteRedemptionCodeIds.remove(redemptionCodeId);
    } else {
      favoriteRedemptionCodeIds.add(redemptionCodeId);
    }
  }

  // Usa datos embebidos del backend; solo cae a dummy si están vacíos.
  String customerNameFor(RedemptionCodeModel redemptionCode) {
    final name = redemptionCode.customerName;
    if (name != null && name.isNotEmpty) return name;
    final email = redemptionCode.customerEmail;
    if (email != null && email.isNotEmpty) return email;
    return DummyHelper.customerNameById(redemptionCode.customerUserId);
  }

  String customerEmailFor(RedemptionCodeModel redemptionCode) {
    final email = redemptionCode.customerEmail;
    if (email != null && email.isNotEmpty) return email;
    return DummyHelper.customerEmailById(redemptionCode.customerUserId);
  }

  String productNameFor(RedemptionCodeModel redemptionCode) {
    if (redemptionCode.productName != null && redemptionCode.productName!.isNotEmpty) {
      return redemptionCode.productName!;
    }
    return DummyHelper.productNameById(redemptionCode.productId);
  }

  double get redemptionsGrowthPercent {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final thisMonth = redemptionCodes
        .where((v) => v.isRedeemed && v.createdAt.isAfter(thisMonthStart))
        .length;
    final lastMonth = redemptionCodes
        .where((v) =>
            v.isRedeemed &&
            v.createdAt.isAfter(lastMonthStart) &&
            v.createdAt.isBefore(thisMonthStart))
        .length;
    if (lastMonth == 0) return thisMonth > 0 ? 100.0 : 0.0;
    return ((thisMonth - lastMonth) / lastMonth) * 100.0;
  }

  String get storeTier {
    final count = redemptionCodes.length;
    if (count >= 200) return 'Gold';
    if (count >= 50) return 'Silver';
    return 'Bronze';
  }

  // ── Monthly loyalty goal ──────────────────────────────────────────────────
  // Backend: GET /marketplace/stores/<id>/monthly-goal/
  // Expected fields: monthly_goal_current, monthly_goal_target,
  //                  monthly_goal_days_remaining, monthly_goal_prize

  int get monthlyGoalCurrentPts {
    final g = monthlyGoal.value;
    if (g['monthly_goal_current'] != null) {
      return (g['monthly_goal_current'] as num).toInt();
    }
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return redemptionCodes
        .where((v) => v.isRedeemed && v.issuedAt.isAfter(monthStart))
        .fold<int>(0, (sum, v) => sum + v.pointsUsed);
  }

  int get monthlyGoalTargetPts {
    final g = monthlyGoal.value;
    if (g['monthly_goal_target'] != null) {
      return (g['monthly_goal_target'] as num).toInt();
    }
    if (currentStore.monthlyGoalTarget > 0) return currentStore.monthlyGoalTarget;
    return 500000;
  }

  int get monthlyGoalDaysRemaining {
    final g = monthlyGoal.value;
    if (g['monthly_goal_days_remaining'] != null) {
      return (g['monthly_goal_days_remaining'] as num).toInt();
    }
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return lastDay.day - now.day;
  }

  String get monthlyGoalPrizeName {
    final g = monthlyGoal.value;
    if ((g['monthly_goal_prize'] ?? '').toString().isNotEmpty) {
      return g['monthly_goal_prize'].toString();
    }
    return currentStore.monthlyGoalPrize;
  }

  double get monthlyGoalPercent {
    final target = monthlyGoalTargetPts;
    if (target == 0) return 0;
    return (monthlyGoalCurrentPts / target).clamp(0.0, 1.0);
  }

  int get maxProductQuantity {
    if (products.isEmpty) return 1;
    return products.map((p) => p.quantity).reduce((a, b) => a > b ? a : b);
  }

  /// Descarga el inventario como CSV.
  /// GET /marketplace/admin/products/export/?store={id}&format=csv
  final RxBool isExportingCsv = false.obs;

  Future<void> exportInventoryCsv() async {
    if (isExportingCsv.value) return;
    isExportingCsv.value = true;
    try {
      final bytes = await _repo.exportProductsCsv(storeId.value);
      if (bytes.isEmpty) {
        CustomSnackBar.showCustomErrorSnackBar(
          title: 'Sin datos',
          message: 'El servidor devolvió un archivo vacío.',
        );
        return;
      }

      final filename = 'productos_tienda_${storeId.value}.csv';
      final file = await _resolveDownloadFile(filename);
      await file.writeAsBytes(bytes, flush: true);

      CustomSnackBar.showCustomSnackBar(
        title: 'CSV exportado',
        message: 'Guardado en ${file.path}',
        duration: const Duration(seconds: 4),
      );
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error al exportar',
        message: e.message,
      );
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error al exportar',
        message: 'No se pudo guardar el archivo.',
      );
    } finally {
      isExportingCsv.value = false;
    }
  }

  Future<File> _resolveDownloadFile(String filename) async {
    if (Platform.isAndroid) {
      // Standard public Downloads folder — works without extra permissions
      // on most Android versions when requestLegacyExternalStorage is set.
      final dir = Directory('/storage/emulated/0/Download');
      if (dir.existsSync()) {
        return File('${dir.path}/$filename');
      }
    }
    // Fallback: app-private temp dir (no extra permissions needed on any OS).
    return File('${Directory.systemTemp.path}/$filename');
  }

  /// Sube el banner de la tienda.
  /// POST /marketplace/stores/<id>/upload-banner/
  Future<bool> uploadStoreBanner(XFile file) async {
    try {
      final url = await _repo.uploadStoreBanner(storeId.value, file);
      if (url != null) {
        // Recarga la tienda para reflejar la nueva imagen
        await _loadFromBackend();
        CustomSnackBar.showCustomSnackBar(
            title: 'Portada actualizada', message: 'El banner se subió correctamente.');
        return true;
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
          title: 'Error', message: 'No se pudo subir el banner.');
    }
    return false;
  }

  /// Sube el logo de la tienda.
  /// POST /marketplace/stores/<id>/upload-logo/
  Future<bool> uploadStoreLogo(XFile file) async {
    try {
      final url = await _repo.uploadStoreLogo(storeId.value, file);
      if (url != null) {
        await _loadFromBackend();
        CustomSnackBar.showCustomSnackBar(
            title: 'Logo actualizado', message: 'El logo se subió correctamente.');
        return true;
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
          title: 'Error', message: 'No se pudo subir el logo.');
    }
    return false;
  }

  /// Convierte coordenadas a dirección legible.
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      return await _repo.reverseGeocode(lat, lng);
    } catch (_) {
      return null;
    }
  }

  /// Convierte una dirección a coordenadas GPS.
  Future<Map<String, double>?> geocode(String address) async {
    try {
      return await _repo.geocode(address);
    } catch (_) {
      return null;
    }
  }

  /// Sube una imagen al backend y devuelve la URL resultante.
  /// POST /marketplace/admin/products/upload-image/
  Future<String?> uploadProductImage(XFile file, {String? productId}) async {
    try {
      return await _repo.uploadProductImage(file, productId: productId);
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error al subir imagen',
        message: e.message,
      );
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: 'No se pudo subir la imagen.',
      );
    }
    return null;
  }

  /// Alterna el estado publicado/pausado de un producto.
  Future<void> toggleProductPublished(ProductModel product) async {
    final newState = !product.isPublished;
    final idx = products.indexWhere((p) => p.id == product.id);
    // Optimistic update
    if (idx != -1) {
      products[idx].isPublished = newState;
      products.refresh();
    }
    final invIdx = inventoryProducts.indexWhere((p) => p.id == product.id);
    if (invIdx != -1) {
      inventoryProducts[invIdx].isPublished = newState;
      inventoryProducts.refresh();
    }
    try {
      await _repo.adminUpdateProduct(
          product.id, {'is_published': newState});
    } on ApiException catch (e) {
      // Revert on failure
      if (idx != -1) { products[idx].isPublished = !newState; products.refresh(); }
      if (invIdx != -1) { inventoryProducts[invIdx].isPublished = !newState; inventoryProducts.refresh(); }
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error', message: e.message);
    } catch (_) {
      if (idx != -1) { products[idx].isPublished = !newState; products.refresh(); }
      if (invIdx != -1) { inventoryProducts[invIdx].isPublished = !newState; inventoryProducts.refresh(); }
    }
  }

  Future<void> previewRedemptionCodeCode(String code) async {
    if (code.trim().isEmpty) return;
    isPreviewingRedemptionCode.value = true;
    previewError.value = '';
    previewedRedemptionCode.value = null;
    try {
      final redemptionCode = await _repo.previewRedemptionCode(code.trim());
      if (redemptionCode != null) {
        previewedRedemptionCode.value = redemptionCode;
      } else {
        previewError.value = 'Código no encontrado.';
      }
    } on ApiException catch (e) {
      previewError.value = e.message;
    } catch (_) {
      previewError.value = 'No se pudo buscar el código.';
    } finally {
      isPreviewingRedemptionCode.value = false;
    }
  }

  void clearRedemptionCodePreview() {
    previewedRedemptionCode.value = null;
    previewError.value = '';
  }

  /// Paso 1 del mostrador (ST-CJ-02): validar. El código pasa a IN_PROGRESS
  /// pero NO se consumen puntos todavía; eso es la entrega. Se conserva el
  /// código a la vista, con su estado ya actualizado, para poder entregarlo.
  Future<bool> validateRedemptionCodeCode(String code, {String? pin}) async {
    try {
      final result = await _repo.validateRedemptionCode(code, pin: pin);
      if (result != null) {
        _applyRedemptionCodeResult(result);
        await _loadFromBackend();
        CustomSnackBar.showCustomSnackBar(
          title: 'Código validado',
          message:
              'Canje en proceso. Confirma la entrega para completarlo y consumir los puntos.',
        );
        return true;
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Código de canje inválido',
        message: e.message,
      );
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: 'No fue posible validar el código de canje.',
      );
    }
    return false;
  }

  /// Paso 2 del mostrador (ST-CJ-03): entregar. El código pasa a DELIVERED y el
  /// backend consume los puntos bloqueados. Falla con 400 si no se validó antes.
  Future<bool> deliverRedemptionCodeCode(String redemptionCodeId) async {
    try {
      final result = await _repo.deliverRedemptionCode(redemptionCodeId);
      if (result != null) {
        _applyRedemptionCodeResult(result);
        await _loadFromBackend();
        CustomSnackBar.showCustomSnackBar(
          title: 'Entrega confirmada',
          message: 'El canje se entregó y los puntos se consumieron.',
        );
        return true;
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'No se pudo entregar',
        message: e.message,
      );
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: 'No fue posible confirmar la entrega.',
      );
    }
    return false;
  }

  /// Refresca el código a la vista con el estado/id de la respuesta del backend,
  /// conservando los datos ricos del preview (producto, cliente…).
  void _applyRedemptionCodeResult(Map<String, dynamic> result) {
    final fresh = RedemptionCodeModel.fromJson(result);
    final current = previewedRedemptionCode.value;
    previewedRedemptionCode.value = current == null
        ? fresh
        : current.copyWith(
            id: fresh.id.isNotEmpty ? fresh.id : current.id,
            status: fresh.status,
            redeemedAt: fresh.redeemedAt,
          );
    previewError.value = '';
  }

  // ── Store Orders ─────────────────────────────────────────────────────────

  Future<void> loadStoreOrders({int page = 1, String? status}) async {
    if (isLoadingOrders.value) return;
    isLoadingOrders.value = true;
    storeOrdersStatusFilter.value = status ?? '';
    try {
      final result = await _repo.fetchStoreOrders(
        storeId: storeId.value,
        status: status,
        page: page,
      );
      final rawList = result['results'] ?? result['data'] ?? const [];
      storeOrders.assignAll(rawList is List
          ? rawList.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const []);
      final rawMeta = result['meta'];
      if (rawMeta is Map) {
        storeOrdersMeta.value = Map<String, dynamic>.from(rawMeta);
        storeOrdersPage.value = page;
      }
    } catch (_) {} finally {
      isLoadingOrders.value = false;
    }
  }

  // ── PIN ───────────────────────────────────────────────────────────────────

  String get pinMasked =>
      storePinData.value['pin_masked']?.toString() ?? '●●●●●●';

  bool get pinConfigured =>
      storePinData.value['pin_configured'] as bool? ?? false;

  Future<void> regeneratePin() async {
    if (isRegeneratingPin.value) return;
    isRegeneratingPin.value = true;
    try {
      final result = await _repo.regenerateStorePIN(storeId.value);
      if (result.isNotEmpty) {
        storePinData.value = result;
        regeneratedPin.value = result['pin']?.toString() ?? '';
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error', message: e.message);
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error', message: 'No se pudo regenerar el PIN.');
    } finally {
      isRegeneratingPin.value = false;
    }
  }

  void clearRegeneratedPin() => regeneratedPin.value = '';

  final RxBool isInitiatingPayment = false.obs;

  /// POST /marketplace/redemptionCodes/{code}/initiate-payment/
  /// Devuelve { client_secret, payment_intent_id, amount_eur, status } o lanza ApiException.
  Future<Map<String, dynamic>?> initiateRedemptionCodePayment(String code,
      {String? paymentMethodId}) async {
    if (isInitiatingPayment.value) return null;
    isInitiatingPayment.value = true;
    try {
      return await _repo.initiateRedemptionCodePayment(code,
          paymentMethodId: paymentMethodId);
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error al iniciar pago', message: e.message);
      return null;
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error', message: 'No se pudo iniciar el pago.');
      return null;
    } finally {
      isInitiatingPayment.value = false;
    }
  }

  Future<Map<String, dynamic>?> reportRedemptionCodeIncident(String redemptionCodeId,
      {required String reason, String notes = ''}) async {
    try {
      final result = await _repo.reportRedemptionCodeIncident(
          redemptionCodeId, reason: reason, notes: notes);
      final ticketId = result['ticket_id'];
      CustomSnackBar.showCustomSnackBar(
        title: 'Incidencia reportada',
        message: ticketId != null
            ? 'Ticket #$ticketId creado. El equipo ha sido notificado.'
            : 'El equipo ha sido notificado.',
      );
      return result.isNotEmpty ? result : null;
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error', message: 'No se pudo reportar la incidencia.');
    }
    return null;
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  final RxBool isSavingSettings = false.obs;

  /// Recarga la lista de usuarios desde el backend.
  Future<void> reloadStoreUsers() async {
    // Evitar llamadas con el ID dummy antes de que el backend cargue.
    if (storeId.value.isEmpty || storeId.value.startsWith('store_')) return;
    try {
      final users = await _repo.fetchStoreUsers(storeId.value);
      if (users.isNotEmpty) storeUsers.assignAll(users);
    } catch (_) {}
  }

  Future<void> loadRoleDefinitions() async {
    if (storeId.value.isEmpty || storeId.value.startsWith('store_')) return;
    try {
      final roles = await _repo.fetchStoreRolesPermissions(storeId.value);
      if (roles.isNotEmpty) roleDefinitions.assignAll(roles);
    } catch (_) {}
  }

  /// PATCH /marketplace/stores/<id>/ — persiste cambios de la tienda.
  Future<bool> saveStoreSettings(Map<String, dynamic> payload) async {
    if (isSavingSettings.value) return false;
    isSavingSettings.value = true;
    try {
      final updated = await _repo.updateStore(storeId.value, payload);
      if (updated != null) {
        currentStore = updated;
        storeId.value = updated.id;
        CustomSnackBar.showCustomSnackBar(
          title: 'Guardado',
          message: 'Los cambios se guardaron correctamente.',
        );
        return true;
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error al guardar',
        message: e.message,
      );
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: 'No se pudieron guardar los cambios.',
      );
    } finally {
      isSavingSettings.value = false;
    }
    return false;
  }

  /// Invita a un nuevo usuario a la tienda.
  Future<bool> inviteUser(String email, String role) async {
    try {
      await _repo.inviteStoreUser(storeId.value, email, role);
      await reloadStoreUsers();
      CustomSnackBar.showCustomSnackBar(
        title: 'Invitación enviada',
        message: 'Se envió la invitación a $email.',
      );
      return true;
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: e.message,
      );
    } catch (_) {}
    return false;
  }

  /// Elimina un usuario de la tienda.
  Future<void> removeUser(String userId) async {
    try {
      await _repo.removeStoreUser(storeId.value, userId);
      storeUsers.removeWhere((u) => u.id == userId);
      CustomSnackBar.showCustomSnackBar(
        title: 'Usuario eliminado',
        message: 'El usuario fue removido de la tienda.',
      );
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: e.message,
      );
    } catch (_) {}
  }

  /// Actualiza el rol de un usuario.
  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _repo.updateStoreUserRole(storeId.value, userId, role);
      await reloadStoreUsers();
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: e.message,
      );
    } catch (_) {}
  }

  /// Cambia el PIN de la tienda.
  Future<bool> changePin(String currentPin, String newPin) async {
    try {
      await _repo.changeStorePin(storeId.value, currentPin, newPin);
      CustomSnackBar.showCustomSnackBar(
        title: 'PIN actualizado',
        message: 'El PIN de la tienda fue cambiado correctamente.',
      );
      return true;
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: e.message,
      );
    } catch (_) {}
    return false;
  }

  /// Activa o desactiva el doble factor de autenticación.
  Future<void> toggleTwoFactor(bool enabled) async {
    try {
      await _repo.updateStoreSecurity(storeId.value, twoFactorEnabled: enabled);
      currentStore = StoreModel(
        id: currentStore.id,
        name: currentStore.name,
        description: currentStore.description,
        ownerId: currentStore.ownerId,
        ownerEmail: currentStore.ownerEmail,
        ownerName: currentStore.ownerName,
        adminUserIds: currentStore.adminUserIds,
        fiscalId: currentStore.fiscalId,
        address: currentStore.address,
        logoUrl: currentStore.logoUrl,
        billingEmail: currentStore.billingEmail,
        billingPhone: currentStore.billingPhone,
        pin: currentStore.pin,
        createdAt: currentStore.createdAt,
        banner: currentStore.banner,
        email: currentStore.email,
        website: currentStore.website,
        openingHours: currentStore.openingHours,
        isPublished: currentStore.isPublished,
        categories: currentStore.categories,
        rating: currentStore.rating,
        reviewCount: currentStore.reviewCount,
        cardId: currentStore.cardId,
        latitude: currentStore.latitude,
        longitude: currentStore.longitude,
        billingAddress: currentStore.billingAddress,
        twoFactorEnabled: enabled,
      );
      storeId.refresh();
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: e.message,
      );
    } catch (_) {}
  }
}
