import 'package:get/get.dart';

class SupportController extends GetxController {
  // Campos del ticket
  final subject = ''.obs;
  final description = ''.obs;
  final storeId = ''.obs;
  final campo = ''.obs;
  final valorActual = ''.obs;
  final valorSolicitado = ''.obs;
  final justificacion = ''.obs;

  // Lista de tickets
  final tickets = <Map<String, dynamic>>[].obs;

  void submitTicket() {
    if (subject.value.isEmpty || description.value.isEmpty) {
      Get.snackbar('Error', 'Completa todos los campos');
      return;
    }
    tickets.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'subject': subject.value,
      'description': description.value,
      'storeId': storeId.value,
      'campo': campo.value,
      'valorActual': valorActual.value,
      'valorSolicitado': valorSolicitado.value,
      'justificacion': justificacion.value,
      'status': 'pendiente',
      'createdAt': DateTime.now().toIso8601String(),
      'resolvedBy': null,
      'resolvedAt': null,
      'motivo': null,
    });
    subject.value = '';
    description.value = '';
    campo.value = '';
    valorActual.value = '';
    valorSolicitado.value = '';
    justificacion.value = '';
    Get.snackbar('Éxito', 'Ticket enviado correctamente');
  }

  void approveTicket(String id, String admin) {
    _updateTicket(id, 'aprobado', admin, 'Aprobado por Super Admin');
  }

  void rejectTicket(String id, String admin, String motivo) {
    _updateTicket(id, 'rechazado', admin, motivo);
  }

  void requestInfo(String id, String admin, String motivo) {
    _updateTicket(id, 'esperando información', admin, motivo);
  }

  void _updateTicket(String id, String status, String admin, String motivo) {
    final index = tickets.indexWhere((t) => t['id'] == id);
    if (index != -1) {
      tickets[index]['status'] = status;
      tickets[index]['resolvedBy'] = admin;
      tickets[index]['resolvedAt'] = DateTime.now().toIso8601String();
      tickets[index]['motivo'] = motivo;
      tickets.refresh();
      Get.snackbar('Ticket actualizado', 'Estado: $status');
    }
  }
}
