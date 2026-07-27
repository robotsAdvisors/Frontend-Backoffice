import 'package:get/get.dart';
import '../controllers/wallet_points_controller.dart';

class WalletPointsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletPointsController>(() => WalletPointsController());
  }
}
