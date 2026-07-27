import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/antifraud_report_model.dart';
import '../../routes/app_pages.dart';
import 'controllers/antifraude_controller.dart';

/// Etiqueta legible de un estado de moderación.
String antifraudStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'SUSPICIOUS':
      return 'Sospechosa';
    case 'UNDER_REVIEW':
      return 'En revisión';
    case 'OBSERVATION':
      return 'En observación';
    default:
      return status;
  }
}

/// Cola de contribuciones sospechosas (BG-06), cableada al backend
/// (`/admin/moderation/contributions/`). Filtra por estado y abre el detalle.
class AntifraudeScreen extends GetView<AntifraudeController> {
  const AntifraudeScreen({super.key});

  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión Antifraude'),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Umbrales',
            icon: const Icon(Icons.tune),
            onPressed: () => Get.toNamed(Routes.ANTIFRAUDE_SETTINGS),
          ),
        ],
      ),
      body: Column(
        children: [
          _filters(),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.queue.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator(color: _purple));
              }
              if (controller.queue.isEmpty) {
                return const Center(
                  child: Text('No hay contribuciones sospechosas.',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return RefreshIndicator(
                onRefresh: () => controller.loadQueue(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.queue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _row(controller.queue[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    const opts = [
      ['', 'Todas'],
      ['SUSPICIOUS', 'Sospechosas'],
      ['UNDER_REVIEW', 'En revisión'],
      ['OBSERVATION', 'En observación'],
    ];
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Obx(() {
        // Lectura SÍNCRONA de la observable para que Obx registre la dependencia
        // (dentro del itemBuilder se ejecuta más tarde y Obx no la detectaría).
        final current = controller.statusFilter.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: opts.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final selected = current == opts[i][0];
            return ChoiceChip(
              label: Text(opts[i][1]),
              selected: selected,
              selectedColor: _purple.withValues(alpha: 0.15),
              onSelected: (_) => controller.loadQueue(opts[i][0]),
            );
          },
        );
      }),
    );
  }

  Widget _row(AntifraudReportModel r) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: ListTile(
        onTap: () {
          controller.select(r);
          Get.toNamed(Routes.ANTIFRAUDE_DETAIL);
        },
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEDE9FE),
          child: Icon(r.isSpace ? Icons.local_parking : Icons.warning_amber,
              color: _purple),
        ),
        title: Text(r.user ?? 'Usuario desconocido',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            if (r.type != null && r.type!.isNotEmpty) r.type!,
            if (r.streetName.isNotEmpty) r.streetName,
            '${r.signals.length} señal(es)',
          ].join('  ·  '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _statusChip(r.status, antifraudStatusLabel(r.status)),
      ),
    );
  }

  Widget _statusChip(String status, String label) {
    Color c;
    switch (status.toUpperCase()) {
      case 'SUSPICIOUS':
        c = Colors.red;
        break;
      case 'UNDER_REVIEW':
        c = Colors.orange;
        break;
      case 'OBSERVATION':
        c = Colors.blueGrey;
        break;
      default:
        c = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
