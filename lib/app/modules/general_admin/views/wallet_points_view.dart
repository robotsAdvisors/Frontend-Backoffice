import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/wallet_points_controller.dart';

class WalletPointsView extends GetView<WalletPointsController> {
  const WalletPointsView({super.key});

  Widget _saldoCard(String titulo, double valor, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.stars, color: color),
        title: Text(titulo),
        trailing: Text(
          valor.toStringAsFixed(0),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet de puntos')),
      body: Obx(() => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _saldoCard('Disponible', controller.disponible.value, Colors.green),
                _saldoCard('Pendiente', controller.pendiente.value, Colors.orange),
                _saldoCard('Bloqueado', controller.bloqueado.value, Colors.blueGrey),
                _saldoCard('Expirado', controller.expirado.value, Colors.red),
              ],
            ),
          )),
    );
  }
}
