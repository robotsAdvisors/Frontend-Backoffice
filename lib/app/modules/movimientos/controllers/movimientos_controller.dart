import 'package:get/get.dart';

class Movimiento {
  final String motivo;
  final String estado;
  final String fecha;
  final int cantidad;

  Movimiento({
    required this.motivo,
    required this.estado,
    required this.fecha,
    required this.cantidad,
  });
}

class MovimientosController extends GetxController {
  final isLoading = false.obs;
  final movimientos = <Movimiento>[].obs;
  final filtros = ['Todos', 'Ganados', 'Consumidos', 'Pendientes', 'Bloqueados', 'Expirados'].obs;
  final filtroActual = 'Todos'.obs;

  @override
  void onInit() {
    super.onInit();
    cargarMovimientos();
  }

  Future<void> cargarMovimientos() async {
    isLoading.value = true;
    try {
      // Aquí llamás al backend de tu amiga para traer movimientos
      // Ejemplo de datos mock:
      movimientos.assignAll([
        Movimiento(motivo: 'Registro completo', estado: 'Validado', fecha: '2026-07-20', cantidad: 50),
        Movimiento(motivo: 'Compra marketplace', estado: 'Pendiente', fecha: '2026-07-21', cantidad: 100),
        Movimiento(motivo: 'Canje Alexa', estado: 'Bloqueado', fecha: '2026-07-22', cantidad: 200),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  void cambiarFiltro(String filtro) {
    filtroActual.value = filtro;
    // Aquí podés aplicar lógica de filtrado sobre la lista
  }
}
