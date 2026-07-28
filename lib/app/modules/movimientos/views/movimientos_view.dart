import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/movimientos_controller.dart';

class MovimientosView extends GetView<MovimientosController> {
  const MovimientosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Movimientos')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.movimientos.isEmpty) {
                return const Center(child: Text('No hay movimientos'));
              }
              return ListView.builder(
                itemCount: controller.movimientos.length,
                itemBuilder: (context, index) {
                  final m = controller.movimientos[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text('${m.motivo} (${m.estado})'),
                      subtitle: Text('Fecha: ${m.fecha}'),
                      trailing: Text('${m.cantidad} pts',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Obx(() => Wrap(
            spacing: 8,
            children: controller.filtros.map((f) {
              final selected = controller.filtroActual.value == f;
              return ChoiceChip(
                label: Text(f),
                selected: selected,
                onSelected: (_) => controller.cambiarFiltro(f),
              );
            }).toList(),
          )),
    );
  }
}
