import 'package:get/get.dart';
import '../controllers/configuracion_puntos_controller.dart';

class ConfiguracionPuntosBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConfiguracionPuntosController>(
      () => ConfiguracionPuntosController(),
    );
  }
}
