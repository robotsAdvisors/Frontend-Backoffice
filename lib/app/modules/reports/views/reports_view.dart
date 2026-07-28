import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reports_controller.dart';

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes Ejecutivos')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMetricCard('Puntos emitidos', controller.pointsIssued.value),
            _buildMetricCard('Puntos consumidos', controller.pointsConsumed.value),
            _buildMetricCard('Puntos liberados', controller.pointsReleased.value),
            _buildMetricCard('Puntos caducados', controller.pointsExpired.value),
            _buildMetricCard('Incidencias abiertas', controller.incidentsOpen.value),
          ],
        );
      }),
    );
  }

  Widget _buildMetricCard(String title, int value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        trailing: Text(value.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
