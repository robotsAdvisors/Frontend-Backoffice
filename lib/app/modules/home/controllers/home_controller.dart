import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../../config/theme/my_theme.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/app_config.dart';
import '../../../../utils/dummy_helper.dart';
import '../../../data/local/my_shared_pref.dart';
import '../../base/controllers/base_controller.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/marketplace_repository.dart';

class HomeController extends GetxController {

  // to hold categories & products
  RxList<CategoryModel> categories = <CategoryModel>[].obs;
  RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// Estadísticas del cliente (puntos, gasto, ahorro…). Se carga aparte
  /// porque requiere autenticación y puede fallar silenciosamente.
  final Rxn<OrdersStats> ordersStats = Rxn<OrdersStats>();
  final RxInt selectedCategoryId = (-1).obs;

  // for app theme
  var isLightTheme = MySharedPref.getThemeIsLight();

  // customer profile image in base64 (reactive)
  final RxString profileImageBase64 = (MySharedPref.getCustomerProfileImage() ?? '').obs;

  /// refresh profile image from SharedPrefs (call after returning from settings)
  void refreshProfileImage() {
    profileImageBase64.value = MySharedPref.getCustomerProfileImage() ?? '';
  }

  Uint8List? get profileImageBytes {
    if (profileImageBase64.value.isEmpty) {
      return null;
    }
    try {
      return base64Decode(profileImageBase64.value);
    } catch (_) {
      return null;
    }
  }

  // for home screen cards
  var cards = [Constants.card1, Constants.card2, Constants.card3];

  @override
  void onInit() {
    loadCatalog();
    loadOrdersStats();
    super.onInit();
  }

  /// Carga categorias y productos desde el backend Letdem.
  /// Si el backend falla, hace fallback a [DummyHelper] para no dejar la UI vacia.
  Future<void> loadCatalog() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final results = await Future.wait([
        MarketplaceRepository.instance.fetchCategories(),
        MarketplaceRepository.instance.fetchProducts(),
      ]);
      final remoteCategories = results[0] as List<CategoryModel>;
      final remoteProducts = results[1] as List<ProductModel>;
      // Con datos demo desactivados se respeta lo que devuelva el backend,
      // aunque venga vacío; solo se rellena con dummy en builds de demo.
      categories.assignAll(remoteCategories.isEmpty && AppConfig.useDummyData
          ? DummyHelper.categories
          : remoteCategories);
      products.assignAll(remoteProducts.isEmpty && AppConfig.useDummyData
          ? DummyHelper.products
          : remoteProducts);
    } catch (e) {
      errorMessage.value = e.toString();
      // Fallback a datos locales solo en builds de demo; en real, UI vacía + error.
      if (AppConfig.useDummyData) {
        categories.assignAll(DummyHelper.categories);
        products.assignAll(DummyHelper.products);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Carga las estadísticas del cliente (puntos actuales, gasto total…)
  /// desde el envelope `meta.stats` de `GET /marketplace/orders/`.
  /// Falla en silencio si el usuario no está autenticado.
  Future<void> loadOrdersStats() async {
    try {
      final page = await MarketplaceRepository.instance
          .fetchOrders(page: 1, pageSize: 1);
      ordersStats.value = page.stats;
      if (Get.isRegistered<BaseController>()) {
        Get.find<BaseController>().userPoints.value =
            page.stats.currentPoints;
      }
    } catch (_) {
      // Sin sesión o sin red: dejamos el card oculto.
    }
  }

  /// when the user press on change theme icon
  onChangeThemePressed() {
    MyTheme.changeTheme();
    isLightTheme = MySharedPref.getThemeIsLight();
    update(['Theme']);
  }
  
}
