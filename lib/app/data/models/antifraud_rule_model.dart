/// Un umbral antifraude editable por el Super Admin (BG-07).
///
/// CRUD en `/api/v1/admin/antifraud-rules/` (lista, sin paginación) y
/// `/api/v1/admin/antifraud-rules/{id}/` (ver/editar). Cada `signal` es único.
class AntifraudRuleModel {
  final int id;
  final String signal; // ZONE_REPEAT | DAILY_VOLUME | CROSS_USER_DUPLICATE | REJECTION_RATIO
  final bool isActive;
  final int threshold; // nº de contribuciones (o % de rechazos en REJECTION_RATIO)
  final int timeWindowMinutes; // ventana; 1440 = 24 h
  final int geohashPrecision; // 6 ≈ 1,2 km, 7 ≈ 150 m (solo señales de zona)
  final String onBreach; // SUSPICIOUS | UNDER_REVIEW | BLOCK (acción al superar el umbral)
  final DateTime? modified;

  const AntifraudRuleModel({
    this.id = 0,
    this.signal = '',
    this.isActive = true,
    this.threshold = 0,
    this.timeWindowMinutes = 1440,
    this.geohashPrecision = 7,
    this.onBreach = 'SUSPICIOUS',
    this.modified,
  });

  factory AntifraudRuleModel.fromJson(Map<String, dynamic> json) =>
      AntifraudRuleModel(
        id: int.tryParse('${json['id'] ?? 0}') ?? 0,
        signal: (json['signal'] ?? '').toString(),
        isActive: json['is_active'] as bool? ?? true,
        threshold: int.tryParse('${json['threshold'] ?? 0}') ?? 0,
        timeWindowMinutes:
            int.tryParse('${json['time_window_minutes'] ?? 1440}') ?? 1440,
        geohashPrecision:
            int.tryParse('${json['geohash_precision'] ?? 7}') ?? 7,
        onBreach: (json['on_breach'] ?? 'SUSPICIOUS').toString(),
        modified: DateTime.tryParse((json['modified'] ?? '').toString()),
      );

  /// Cuerpo para crear (POST) o editar (PATCH) la regla. Solo los campos
  /// editables; `id` y `modified` los gestiona el backend.
  Map<String, dynamic> toJson() => {
        'signal': signal,
        'is_active': isActive,
        'threshold': threshold,
        'time_window_minutes': timeWindowMinutes,
        'geohash_precision': geohashPrecision,
        'on_breach': onBreach,
      };

  AntifraudRuleModel copyWith({
    bool? isActive,
    int? threshold,
    int? timeWindowMinutes,
    int? geohashPrecision,
    String? onBreach,
  }) =>
      AntifraudRuleModel(
        id: id,
        signal: signal,
        isActive: isActive ?? this.isActive,
        threshold: threshold ?? this.threshold,
        timeWindowMinutes: timeWindowMinutes ?? this.timeWindowMinutes,
        geohashPrecision: geohashPrecision ?? this.geohashPrecision,
        onBreach: onBreach ?? this.onBreach,
        modified: modified,
      );
}
