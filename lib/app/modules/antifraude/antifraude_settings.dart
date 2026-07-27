import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/antifraud_rule_model.dart';
import 'controllers/antifraude_controller.dart';

/// Etiqueta legible de una señal antifraude.
String antifraudSignalLabel(String signal) {
  switch (signal.toUpperCase()) {
    case 'ZONE_REPEAT':
      return 'Repetición de zona';
    case 'DAILY_VOLUME':
      return 'Volumen diario';
    case 'CROSS_USER_DUPLICATE':
      return 'Duplicado entre usuarios';
    case 'REJECTION_RATIO':
      return 'Ratio de rechazos';
    default:
      return signal;
  }
}

/// Configuración antifraude (BG-07): lista y edición de umbrales, cableada al
/// backend (`/admin/antifraud-rules/`).
class AntifraudeSettings extends GetView<AntifraudeController> {
  const AntifraudeSettings({super.key});

  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.rules.isEmpty) controller.loadRules();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Antifraude'),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoadingRules.value && controller.rules.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: _purple));
        }
        if (controller.rules.isEmpty) {
          return const Center(
            child: Text('No hay umbrales configurados.',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadRules,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ruleCard(context, controller.rules[i]),
          ),
        );
      }),
    );
  }

  Widget _ruleCard(BuildContext context, AntifraudRuleModel rule) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: ListTile(
        onTap: () => _editDialog(context, rule),
        title: Text(antifraudSignalLabel(rule.signal),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          'Umbral: ${rule.threshold}  ·  Ventana: ${rule.timeWindowMinutes} min  ·  '
          'Precisión: ${rule.geohashPrecision}  ·  Al superar: ${rule.onBreach}',
        ),
        trailing: Icon(
          rule.isActive ? Icons.check_circle : Icons.pause_circle_outline,
          color: rule.isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  void _editDialog(BuildContext context, AntifraudRuleModel rule) {
    final thresholdCtrl =
        TextEditingController(text: rule.threshold.toString());
    final windowCtrl =
        TextEditingController(text: rule.timeWindowMinutes.toString());
    final precisionCtrl =
        TextEditingController(text: rule.geohashPrecision.toString());
    final rx = RxString(rule.onBreach);
    final active = RxBool(rule.isActive);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(antifraudSignalLabel(rule.signal)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: thresholdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Umbral'),
              ),
              TextField(
                controller: windowCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Ventana (minutos)'),
              ),
              TextField(
                controller: precisionCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Precisión geohash'),
              ),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                    initialValue:
                        ['SUSPICIOUS', 'UNDER_REVIEW', 'BLOCK'].contains(rx.value)
                            ? rx.value
                            : 'SUSPICIOUS',
                    decoration:
                        const InputDecoration(labelText: 'Acción al superar'),
                    items: const [
                      DropdownMenuItem(
                          value: 'SUSPICIOUS', child: Text('Marcar sospechosa')),
                      DropdownMenuItem(
                          value: 'UNDER_REVIEW', child: Text('Enviar a revisión')),
                      DropdownMenuItem(
                          value: 'BLOCK', child: Text('Bloquear (rechazo auto)')),
                    ],
                    onChanged: (v) => rx.value = v ?? rx.value,
                  )),
              Obx(() => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activa'),
                    value: active.value,
                    onChanged: (v) => active.value = v,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          Obx(() => ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _purple, foregroundColor: Colors.white),
                onPressed: controller.isSavingRule.value
                    ? null
                    : () async {
                        final payload = <String, dynamic>{
                          'threshold':
                              int.tryParse(thresholdCtrl.text.trim()) ??
                                  rule.threshold,
                          'time_window_minutes':
                              int.tryParse(windowCtrl.text.trim()) ??
                                  rule.timeWindowMinutes,
                          'geohash_precision':
                              int.tryParse(precisionCtrl.text.trim()) ??
                                  rule.geohashPrecision,
                          'on_breach': rx.value,
                          'is_active': active.value,
                        };
                        final ok = await controller.saveRule(rule, payload);
                        if (ok) Get.back();
                      },
                child: controller.isSavingRule.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar'),
              )),
        ],
      ),
    );
  }
}
