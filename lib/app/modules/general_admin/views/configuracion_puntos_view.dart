import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/configuracion_puntos_controller.dart';
import '../widgets/configuracion_puntos_widgets.dart';

class ConfiguracionPuntosView extends StatelessWidget {
  const ConfiguracionPuntosView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ConfiguracionPuntosController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Configuración del programa de puntos")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Obx(() => CampoNumero(
              label: "Límite máximo de puntos por pedido",
              valorInicial: controller.limitePorPedido.value,
              onChanged: controller.setLimitePorPedido,
            )),
            Obx(() => CampoNumero(
              label: "Caducidad (meses)",
              valorInicial: controller.caducidadMeses.value,
              onChanged: controller.setCaducidadMeses,
            )),
            Obx(() => CampoNumero(
              label: "Máximo de puntos por campaña",
              valorInicial: controller.maximoPorCampania.value,
              onChanged: controller.setMaximoPorCampania,
            )),
            Obx(() => CampoNumero(
              label: "Puntos por registro",
              valorInicial: controller.puntosRegistro.value,
              onChanged: controller.setPuntosRegistro,
            )),
            Obx(() => CampoNumero(
              label: "Puntos por compra (EUR)",
              valorInicial: controller.puntosCompra.value,
              onChanged: controller.setPuntosCompra,
            )),
            Obx(() => CampoNumero(
              label: "Puntos por referido",
              valorInicial: controller.puntosReferido.value,
              onChanged: controller.setPuntosReferido,
            )),
            Obx(() => CampoSwitch(
              label: "Validar duplicados",
              valorInicial: controller.validarDuplicados.value,
              onChanged: controller.toggleValidarDuplicados,
            )),
            Obx(() => CampoSwitch(
              label: "Validar referidos",
              valorInicial: controller.validarReferidos.value,
              onChanged: controller.toggleValidarReferidos,
            )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.guardarConfiguracion,
              child: const Text("Guardar configuración"),
            ),
          ],
        ),
      ),
    );
  }
}
