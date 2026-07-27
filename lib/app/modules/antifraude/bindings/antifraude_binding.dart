import 'package:get/get.dart';

import '../controllers/antifraude_controller.dart';

/// Se aplica a todas las rutas de antifraude para que la cola, el detalle y la
/// configuración compartan la misma instancia (fenix la recrea si se dispuso).
class AntifraudeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AntifraudeController>(() => AntifraudeController(), fenix: true);
  }
}
