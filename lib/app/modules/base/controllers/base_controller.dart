import 'package:get/get.dart';

import '../../../../utils/app_config.dart';
import '../../../../utils/dummy_helper.dart';
import '../../cart/controllers/cart_controller.dart';

class BaseController extends GetxController {

  int currentIndex = 0;
  int cartItemsCount = 0;
  final RxInt userPoints = 0.obs;

  @override
  void onInit() {
    getCartItemsCount();
    super.onInit();
  }

  /// change the selected screen index
  changeScreen(int selectedIndex) {
    currentIndex = selectedIndex;
    update();
  }

  /// calculate the number of products in the cart
  // El contador del carrito se deriva de [DummyHelper] (carrito en memoria, aún
  // sin backend). En builds reales queda en 0 hasta que exista un carrito real.
  getCartItemsCount() {
    cartItemsCount = AppConfig.useDummyData
        ? DummyHelper.products.fold<int>(0, (p, c) => p + c.quantity)
        : 0;
    update(['CartBadge']);
  }

  /// when the user press on add + icon
  onIncreasePressed(String productId) {
    // El carrito demo no está cableado al backend: no-op en builds reales para
    // no mutar productos ficticios ni romper con IDs reales (firstWhere sin match).
    if (!AppConfig.useDummyData) return;
    DummyHelper.products.firstWhere((p) => p.id == productId).quantity++;
    getCartItemsCount();
    update(['ProductQuantity']);
  }

  /// when the user press on remove - icon
  onDecreasePressed(String productId) {
    if (!AppConfig.useDummyData) return;
    var product = DummyHelper.products.firstWhere((p) => p.id == productId);
    if (product.quantity > 0) {
      product.quantity--;
      getCartItemsCount();
      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().getCartProducts();
      }
      update(['ProductQuantity']);
    }
  }

}
