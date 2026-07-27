import '../../../utils/api_config.dart';
import '../models/antifraud_report_model.dart';
import '../models/antifraud_rule_model.dart';
import '../services/http/api_client.dart';

/// Repositorio del backoffice antifraude del Super Admin (points_admin).
///
/// Cubre la cola de revisión de contribuciones sospechosas (BG-06) y el CRUD de
/// umbrales antifraude (BG-07), contra `/api/v1/admin/...`. Solo el Super Admin
/// (o el moderador designado en la cola) tiene acceso; el backend responde 403
/// en caso contrario.
class AntifraudRepository {
  AntifraudRepository._();
  static final AntifraudRepository instance = AntifraudRepository._();

  final _dio = ApiClient.instance.dio;

  // ---------- BG-06: cola de moderación ----------

  /// Cola de contribuciones sospechosas (plazas y alertas).
  /// GET /admin/moderation/contributions/?status=SUSPICIOUS|UNDER_REVIEW|OBSERVATION
  /// Sin `status` devuelve las tres. Envelope: {count, results:[...]}.
  Future<List<AntifraudReportModel>> fetchModerationQueue({String? status}) async {
    try {
      final response = await _dio.get(
        ApiConfig.moderationQueue,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return _toList(response.data)
          .whereType<Map>()
          .map((e) => AntifraudReportModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Decisión del moderador sobre una contribución.
  /// POST /admin/moderation/contributions/{kind}/{id}/  body: {decision, reason}
  /// `kind` = "space" | "event"; `decision` = "validate" | "reject" | "observe".
  /// Devuelve la fila actualizada.
  Future<AntifraudReportModel?> decideModeration({
    required String kind,
    required String id,
    required String decision,
    String reason = '',
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.moderationDecision(kind, id),
        data: {
          'decision': decision,
          if (reason.isNotEmpty) 'reason': reason,
        },
      );
      if (response.data is Map) {
        return AntifraudReportModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  // ---------- BG-07: umbrales antifraude ----------

  /// Lista de umbrales antifraude (sin paginación).
  /// GET /admin/antifraud-rules/
  Future<List<AntifraudRuleModel>> fetchAntifraudRules() async {
    try {
      final response = await _dio.get(ApiConfig.antifraudRules);
      return _toList(response.data)
          .whereType<Map>()
          .map((e) => AntifraudRuleModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Crea una regla antifraude.
  /// POST /admin/antifraud-rules/
  Future<AntifraudRuleModel?> createAntifraudRule(AntifraudRuleModel rule) async {
    try {
      final response = await _dio.post(
        ApiConfig.antifraudRules,
        data: rule.toJson(),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map) {
        return AntifraudRuleModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Edita un umbral antifraude (el backend audita el cambio).
  /// PATCH /admin/antifraud-rules/{id}/  body: campos editables
  Future<AntifraudRuleModel?> updateAntifraudRule(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch(
        ApiConfig.antifraudRuleDetail(id),
        data: payload,
      );
      if (response.statusCode == 200 && response.data is Map) {
        return AntifraudRuleModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (e) {
      throw toApiException(e);
    }
    return null;
  }

  /// Extrae la lista del envelope del backend: `{count, results:[...]}`,
  /// `{data:[...]}` o una lista plana (las reglas llegan sin envoltorio).
  static List<dynamic> _toList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['results'] is List) return List<dynamic>.from(data['results'] as List);
      if (data['data'] is List) return List<dynamic>.from(data['data'] as List);
    }
    return const [];
  }
}
