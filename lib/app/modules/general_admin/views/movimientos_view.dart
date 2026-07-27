import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/movimientos_controller.dart';

class MovimientosView extends GetView<MovimientosController> {
  const MovimientosView({super.key});

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'validado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'bloqueado':
        return Colors.blueGrey;
      case 'consumido':
        return Colors.red;
      case 'liberado':
        return Colors.blue;
      case 'rechazado':
        return Colors.black;
      case 'expirado':
        return Colors.purple;
      case 'ajustado':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de movimientos')),
      body: Obx(() => ListView.builder(
            itemCount: controller.movimientos.length,
            itemBuilder: (context, index) {
              final m = controller.movimientos[index];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.stars, color: _estadoColor(m.estado)),
                  title: Text('${m.motivo} (${m.estado})'),
                  subtitle: Text(m.fecha), // ya formateada desde el controller
                  trailing: Text(
                    m.cantidad.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _estadoColor(m.estado),
                    ),
                  ),
                ),
              );
            },
          )),
    );
  }
}
