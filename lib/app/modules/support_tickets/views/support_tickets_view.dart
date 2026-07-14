import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/support_controller.dart';

class SupportTicketsView extends GetView<SupportController> {
  const SupportTicketsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tickets de Soporte')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crear nuevo ticket',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Asunto',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => controller.subject.value = val,
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (val) => controller.description.value = val,
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Campo a modificar',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => controller.campo.value = val,
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Valor actual',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => controller.valorActual.value = val,
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Valor solicitado',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => controller.valorSolicitado.value = val,
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Justificación',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (val) => controller.justificacion.value = val,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Enviar Ticket'),
                onPressed: controller.submitTicket,
              ),
            ),

            const SizedBox(height: 30),
            const Text('Tickets enviados:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            Expanded(
              child: Obx(() {
                if (controller.tickets.isEmpty) {
                  return const Center(
                    child: Text('No hay tickets todavía',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  itemCount: controller.tickets.length,
                  itemBuilder: (_, i) {
                    final t = controller.tickets[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.confirmation_number),
                        title: Text(t['subject'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Descripción: ${t['description']}'),
                            Text('Campo: ${t['campo']}'),
                            Text('Actual: ${t['valorActual']} → Solicitado: ${t['valorSolicitado']}'),
                            Text('Estado: ${t['status']}'),
                            if (t['motivo'] != null)
                              Text('Motivo: ${t['motivo']}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'aprobar') {
                              controller.approveTicket(t['id'], 'SuperAdmin');
                            } else if (action == 'rechazar') {
                              controller.rejectTicket(t['id'], 'SuperAdmin', 'Datos incorrectos');
                            } else if (action == 'info') {
                              controller.requestInfo(t['id'], 'SuperAdmin', 'Falta documentación');
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'aprobar',
                              child: Text('Aprobar'),
                            ),
                            const PopupMenuItem(
                              value: 'rechazar',
                              child: Text('Rechazar'),
                            ),
                            const PopupMenuItem(
                              value: 'info',
                              child: Text('Pedir información'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
