import 'package:get/get.dart';

class WalletPointsController extends GetxController {
  var disponible = 0.0.obs;
  var pendiente = 0.0.obs;
  var bloqueado = 0.0.obs;
  var expirado = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // TODO: conectar con backend
    disponible.value = 120;
    pendiente.value = 30;
    bloqueado.value = 50;
    expirado.value = 10;
  }
}
