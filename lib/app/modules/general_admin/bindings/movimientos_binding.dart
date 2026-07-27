import 'package:get/get.dart';
import '../controllers/movimientos_controller.dart';

class MovimientosBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MovimientosController>(() => MovimientosController());
  }
}
