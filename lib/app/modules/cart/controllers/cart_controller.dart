import 'package:get/get.dart';

import '../../../../utils/app_config.dart';
import '../../../../utils/dummy_helper.dart';
import '../../../components/custom_snackbar.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/marketplace_repository.dart';
import '../../../data/services/http/api_client.dart';
import '../../base/controllers/base_controller.dart';

class CartController extends GetxController {

  /// Productos visibles en el carrito.
  RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isProcessing = false.obs;

  @override
  void onInit() {
    getCartProducts();
    super.onInit();
  }

  /// Compra los productos del carrito. Si el carrito tiene un solo producto se
  /// dispara directamente la compra contra el backend Letdem
  /// (POST /marketplace/purchase/without-redeem/). Si hay varios se hace una
  /// secuencia de llamadas, una por producto, ya que el endpoint actual del
  /// backend acepta `product_id` + `quantity`.
  Future<void> onPurchaseNowPressed({bool useRedeem = false}) async {
    if (products.isEmpty) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Carrito vacio',
        message: 'No hay productos para comprar',
      );
      return;
    }

    isProcessing.value = true;
    try {
      for (final product in products) {
        if (useRedeem) {
          await MarketplaceRepository.instance.purchaseWithRedeem(
            productId: product.id,
            quantity: product.quantity,
          );
        } else {
          await MarketplaceRepository.instance.purchaseWithoutRedeem(
            productId: product.id,
            quantity: product.quantity,
          );
        }
      }

      clearCart();
      Get.back();
      CustomSnackBar.showCustomSnackBar(
        title: 'Compra realizada',
        message: 'Tu pedido se ha registrado correctamente',
      );
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: e.message,
      );
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    } finally {
      isProcessing.value = false;
    }
  }

  /// get the cart products from the product list
  // NOTA: el carrito aún se apoya en [DummyHelper] como estado en memoria y no
  // está cableado al backend. En builds reales arranca vacío (no muestra los
  // productos de demostración) hasta que exista un carrito real.
  getCartProducts() {
    products.assignAll(
      AppConfig.useDummyData
          ? DummyHelper.products.where((p) => p.quantity > 0).toList()
          : <ProductModel>[],
    );
    update();
  }

  /// clear products in cart and reset cart items count
  clearCart() {
    if (AppConfig.useDummyData) {
      for (final p in DummyHelper.products) {
        p.quantity = 0;
      }
    }
    products.clear();
    Get.find<BaseController>().getCartItemsCount();
  }
}