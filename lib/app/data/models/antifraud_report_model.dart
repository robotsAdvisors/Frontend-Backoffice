/// Una señal antifraude interna que disparó la sospecha (BG-06).
///
/// Es información SOLO para el moderador: el usuario final nunca la ve
/// (PT-CM-04). Llega dentro de `signals` en cada fila de la cola.
class AntifraudSignal {
  final String signal; // ZONE_REPEAT | DAILY_VOLUME | CROSS_USER_DUPLICATE | REJECTION_RATIO
  final String action; // SUSPICIOUS | UNDER_REVIEW | BLOCK (acción de la regla)
  final String detail; // texto legible, p. ej. "5 contribuciones en la misma zona en 1440 min"

  const AntifraudSignal({
    this.signal = '',
    this.action = '',
    this.detail = '',
  });

  factory AntifraudSignal.fromJson(Map<String, dynamic> json) => AntifraudSignal(
        signal: (json['signal'] ?? '').toString(),
        action: (json['action'] ?? '').toString(),
        detail: (json['detail'] ?? '').toString(),
      );
}

/// Una contribución sospechosa en la cola de revisión antifraude (BG-06).
///
/// Fila de `GET /api/v1/admin/moderation/contributions/`. Puede ser una plaza
/// (`kind == "space"`) o una alerta vial (`kind == "event"`). La decisión del
/// moderador se envía a
/// `POST /api/v1/admin/moderation/contributions/{kind}/{id}/`.
class AntifraudReportModel {
  final String id; // pk: UUID (hex) para space, entero-como-string para event
  final String kind; // "space" | "event"
  final String? user; // email del autor, puede venir null
  final String? type; // tipo de la contribución (WHITE/BLUE/... o tipo de evento)
  final String zone; // geohash aproximado de la zona
  final String streetName;
  final DateTime? created;
  final String status; // SUSPICIOUS | UNDER_REVIEW | OBSERVATION
  final List<AntifraudSignal> signals;

  AntifraudReportModel({
    this.id = '',
    this.kind = '',
    this.user,
    this.type,
    this.zone = '',
    this.streetName = '',
    this.created,
    this.status = '',
    this.signals = const [],
  });

  bool get isSpace => kind == 'space';
  bool get isEvent => kind == 'event';

  factory AntifraudReportModel.fromJson(Map<String, dynamic> json) {
    final rawSignals = json['signals'];
    return AntifraudReportModel(
      id: (json['id'] ?? '').toString(),
      kind: (json['kind'] ?? '').toString(),
      user: (json['user'] ?? '').toString().isEmpty
          ? null
          : (json['user']).toString(),
      type: (json['type'] ?? '').toString().isEmpty
          ? null
          : (json['type']).toString(),
      zone: (json['zone'] ?? '').toString(),
      streetName: (json['street_name'] ?? '').toString(),
      created: DateTime.tryParse((json['created'] ?? '').toString()),
      status: (json['status'] ?? '').toString(),
      signals: rawSignals is List
          ? rawSignals
              .whereType<Map>()
              .map((e) => AntifraudSignal.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
