import 'package:get/get.dart';
import 'controllers/general_admin_controller.dart';

class GeneralAdminBinding extends Bindings {
  @override
  void dependencies() {
    // Inyecta el controlador cuando se accede a la ruta /general-admin
    Get.lazyPut<GeneralAdminController>(() => GeneralAdminController());
  }
}
