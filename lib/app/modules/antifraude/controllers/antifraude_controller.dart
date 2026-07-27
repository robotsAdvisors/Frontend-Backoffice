import 'package:get/get.dart';

import '../../../components/custom_snackbar.dart';
import '../../../data/models/antifraud_report_model.dart';
import '../../../data/models/antifraud_rule_model.dart';
import '../../../data/repositories/antifraud_repository.dart';
import '../../../data/services/http/api_client.dart';

/// Controlador del backoffice antifraude (BG-06 cola de moderación, BG-07 reglas).
/// Usa [AntifraudRepository] (vía ApiClient: auth + contrato de error).
class AntifraudeController extends GetxController {
  final _repo = AntifraudRepository.instance;

  // ── Cola de moderación (BG-06) ──────────────────────────────────────────────
  final RxList<AntifraudReportModel> queue = <AntifraudReportModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString statusFilter = ''.obs; // '' | SUSPICIOUS | UNDER_REVIEW | OBSERVATION
  final Rx<AntifraudReportModel?> selected = Rx<AntifraudReportModel?>(null);
  final RxBool isDeciding = false.obs;

  // ── Reglas / umbrales (BG-07) ───────────────────────────────────────────────
  final RxList<AntifraudRuleModel> rules = <AntifraudRuleModel>[].obs;
  final RxBool isLoadingRules = false.obs;
  final RxBool isSavingRule = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadQueue();
  }

  /// Aplica un filtro de estado y recarga la cola. `status` vacío = las tres.
  Future<void> loadQueue([String? status]) async {
    if (status != null) statusFilter.value = status;
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final list = await _repo.fetchModerationQueue(
        status: statusFilter.value.isEmpty ? null : statusFilter.value,
      );
      queue.assignAll(list);
    } on ApiException catch (e) {
      if (!e.isUnavailable && e.statusCode != 403) {
        CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
      }
    } catch (_) {
      // silencio: cola vacía
    } finally {
      isLoading.value = false;
    }
  }

  void select(AntifraudReportModel report) => selected.value = report;

  /// Decisión del moderador: 'validate' | 'reject' | 'observe'.
  Future<bool> decide(String decision, {String reason = ''}) async {
    final r = selected.value;
    if (r == null || isDeciding.value) return false;
    isDeciding.value = true;
    try {
      final updated = await _repo.decideModeration(
        kind: r.kind,
        id: r.id,
        decision: decision,
        reason: reason,
      );
      if (updated != null) {
        selected.value = updated;
        final i = queue.indexWhere((x) => x.id == r.id && x.kind == r.kind);
        if (i != -1) queue[i] = updated;
      }
      CustomSnackBar.showCustomSnackBar(
          title: 'Decisión registrada', message: _decisionMsg(decision));
      return true;
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
          title: 'Error', message: 'No se pudo registrar la decisión.');
    } finally {
      isDeciding.value = false;
    }
    return false;
  }

  String _decisionMsg(String d) {
    switch (d) {
      case 'validate':
        return 'Contribución validada (puntos consolidados).';
      case 'reject':
        return 'Contribución rechazada (bloqueada).';
      case 'observe':
        return 'Mantenida en observación.';
      default:
        return 'Hecho.';
    }
  }

  // ── Reglas / umbrales ───────────────────────────────────────────────────────

  Future<void> loadRules() async {
    if (isLoadingRules.value) return;
    isLoadingRules.value = true;
    try {
      rules.assignAll(await _repo.fetchAntifraudRules());
    } on ApiException catch (e) {
      if (!e.isUnavailable && e.statusCode != 403) {
        CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
      }
    } catch (_) {
      // silencio
    } finally {
      isLoadingRules.value = false;
    }
  }

  /// Edita un umbral (PATCH). [payload] = campos editables.
  Future<bool> saveRule(AntifraudRuleModel rule, Map<String, dynamic> payload) async {
    if (isSavingRule.value) return false;
    isSavingRule.value = true;
    try {
      final updated = await _repo.updateAntifraudRule(rule.id, payload);
      if (updated != null) {
        final i = rules.indexWhere((r) => r.id == rule.id);
        if (i != -1) rules[i] = updated;
        CustomSnackBar.showCustomSnackBar(
            title: 'Guardado', message: 'Umbral actualizado.');
        return true;
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
          title: 'Error', message: 'No se pudo guardar el umbral.');
    } finally {
      isSavingRule.value = false;
    }
    return false;
  }
}
