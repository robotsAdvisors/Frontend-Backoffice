import 'package:get/get.dart';

class Movimiento {
  final String fecha;     // ya formateada desde backend
  final int cantidad;
  final String estado;    // pendiente, validado, bloqueado, consumido, liberado, rechazado, expirado, ajustado
  final String motivo;

  Movimiento({
    required this.fecha,
    required this.cantidad,
    required this.estado,
    required this.motivo,
  });
}

class MovimientosController extends GetxController {
  var movimientos = <Movimiento>[].obs;

  @override
  void onInit() {
    super.onInit();
    // TODO: reemplazar con fetch real desde backend
    movimientos.assignAll([
      Movimiento(
          fecha: '2026-07-22',
          cantidad: 50,
          estado: 'validado',
          motivo: 'Registro completo'),
      Movimiento(
          fecha: '2026-07-21',
          cantidad: 25,
          estado: 'pendiente',
          motivo: 'Perfil básico'),
      Movimiento(
          fecha: '2026-07-20',
          cantidad: -100,
          estado: 'consumido',
          motivo: 'Canje confirmado'),
      Movimiento(
          fecha: '2026-07-19',
          cantidad: 30,
          estado: 'bloqueado',
          motivo: 'Canje generado'),
    ]);
  }
}
