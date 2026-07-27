import 'package:flutter/material.dart';

class PublicacionDetailPage extends StatelessWidget {
  final String id; // referencia de la publicación

  const PublicacionDetailPage({super.key, required this.id});

  /// Chip de estado con color e ícono
  Widget estadoChip(String estado) {
    Color color;
    IconData icon;

    switch (estado) {
      case 'Activa':
        color = Colors.green;
        icon = Icons.play_circle_fill;
        break;
      case 'Bloqueada':
        color = Colors.orange;
        icon = Icons.block;
        break;
      case 'Liberada':
        color = Colors.indigo;
        icon = Icons.lock_open;
        break;
      case 'Validada':
        color = Colors.blue;
        icon = Icons.verified;
        break;
      case 'Disputada':
        color = Colors.red;
        icon = Icons.report_problem;
        break;
      case 'Expirada':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case 'Reembolsada':
        color = Colors.red;
        icon = Icons.reply_all;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(estado),
      backgroundColor: color.withOpacity(0.8),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo para trazabilidad
    final List<Map<String, String>> timeline = [
      {'estado': 'Activa', 'tipo': 'Funcional', 'fecha': '2026-07-20 10:00'},
      {'estado': 'Bloqueada', 'tipo': 'Funcional', 'fecha': '2026-07-21 12:30'},
      {'estado': 'Liberada', 'tipo': 'Funcional', 'fecha': '2026-07-22 09:15'},
      {'estado': 'Validada', 'tipo': 'Económico', 'fecha': '2026-07-22 14:00'},
      {'estado': 'Disputada', 'tipo': 'Económico', 'fecha': '2026-07-23 11:45'},
    ];

    final funcionales = timeline.where((e) => e['tipo'] == 'Funcional').toList();
    final economicos = timeline.where((e) => e['tipo'] == 'Económico').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de publicación'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Validar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.search),
                  label: const Text('Revisar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.reply_all_outlined),
                  label: const Text('Reembolsar'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filtros superiores
            Row(
              children: [
                DropdownButton<String>(
                  value: 'Todas',
                  items: ['Todas', 'Activas', 'Pendientes de resultado', 'Disputadas', 'Expiradas']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {},
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por informador, solicitante o Stripe',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Timeline de trazabilidad separado
            Expanded(
              child: ListView(
                children: [
                  const Text('Estados Funcionales',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ...funcionales.map((item) => ListTile(
                        leading: const Icon(Icons.settings, color: Colors.blue),
                        title: Text(item['estado']!),
                        subtitle: Text(item['fecha']!),
                        trailing: estadoChip(item['estado']!),
                      )),
                  const SizedBox(height: 20),
                  const Text('Estados Económicos',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ...economicos.map((item) => ListTile(
                        leading: const Icon(Icons.attach_money, color: Colors.green),
                        title: Text(item['estado']!),
                        subtitle: Text(item['fecha']!),
                        trailing: estadoChip(item['estado']!),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
