import 'package:get/get.dart';

class ReportsController extends GetxController {
  final isLoading = false.obs;
  final pointsIssued = 0.obs;
  final pointsConsumed = 0.obs;
  final pointsReleased = 0.obs;
  final pointsExpired = 0.obs;
  final incidentsOpen = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadReports();
  }

  Future<void> loadReports() async {
    isLoading.value = true;
    try {
      // Aquí llamás al backend de tu amiga para traer métricas
      // Ejemplo:
      // final stats = await ReportsRepository.instance.fetchStats();
      // pointsIssued.value = stats.pointsIssued;
      // pointsConsumed.value = stats.pointsConsumed;
      // ...
    } catch (_) {
      // Manejo de error
    } finally {
      isLoading.value = false;
    }
  }
}
