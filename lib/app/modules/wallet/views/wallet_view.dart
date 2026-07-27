import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/wallet_controller.dart';

class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet de puntos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _saldoCard('Disponible', controller.disponible.value, Colors.green),
                _saldoCard('Pendiente', controller.pendiente.value, Colors.orange),
                _saldoCard('Bloqueado', controller.bloqueado.value, Colors.blue),
                _saldoCard('Expirado', controller.expirado.value, Colors.red),
              ],
            )),
      ),
    );
  }

  Widget _saldoCard(String titulo, int puntos, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(titulo,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 12),
            Text('$puntos pts',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
