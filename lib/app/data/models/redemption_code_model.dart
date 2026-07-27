enum RedemptionCodeStatus {
  pending,
  paid,
  // El mostrador validó el código; el usuario está delante (ST-CJ-02).
  inProgress,
  // Entregado: aquí se consumen los puntos (ST-CJ-03). Sustituye a `redeemed`,
  // que el backend deja como alias deprecado.
  delivered,
  // El mostrador no pudo entregar: sin stock, discrepancia… (DG-07).
  incident,
  redeemed,
  expired,
  cancelled,
  rejected,
}

class RedemptionCodeModel {
  final String id;
  final String campaignId;
  final String storeId;
  final String customerUserId;
  final String productId;
  final String code;
  final DateTime issuedAt;
  final DateTime? redeemedAt;
  final DateTime? expiresAt;
  final double discountPercent;
  final RedemptionCodeStatus status;
  final int pointsUsed;
  final String redeemType; // 'ONLINE' | 'IN_STORE'
  final String? qrCode;
  final String? productName;
  final String? productSku;
  final String? productImageUrl;
  final String? storeName;
  final String? customerName;
  final String? customerEmail;
  final String? customerAlias;   // @JuanPuntos77
  final String? customerBadge;   // tier label: 'Nivel de Calidad', 'Gold', etc.
  final String? paymentMethod;   // 'stripe' | 'card' | null
  final double? paymentAmountEur;
  final bool paymentVerified;
  final int? daysLeft;           // calculado por backend en preview

  RedemptionCodeModel({
    required this.id,
    required this.campaignId,
    required this.storeId,
    required this.customerUserId,
    required this.productId,
    required this.code,
    required this.issuedAt,
    this.redeemedAt,
    this.expiresAt,
    this.discountPercent = 0,
    this.status = RedemptionCodeStatus.pending,
    this.pointsUsed = 0,
    this.redeemType = 'ONLINE',
    this.qrCode,
    this.productName,
    this.productSku,
    this.productImageUrl,
    this.storeName,
    this.customerName,
    this.customerEmail,
    this.customerAlias,
    this.customerBadge,
    this.paymentMethod,
    this.paymentAmountEur,
    this.paymentVerified = false,
    this.daysLeft,
  });

  // Compatibility alias for old UI fields.
  DateTime get createdAt => issuedAt;

  /// Refresca estado/id tras validar o entregar sin perder los datos ricos que
  /// trajo el preview (nombre de producto, cliente…), que las respuestas de
  /// validation/ y delivery/ no reenvían completos.
  RedemptionCodeModel copyWith({
    String? id,
    RedemptionCodeStatus? status,
    DateTime? redeemedAt,
  }) {
    return RedemptionCodeModel(
      id: id ?? this.id,
      campaignId: campaignId,
      storeId: storeId,
      customerUserId: customerUserId,
      productId: productId,
      code: code,
      issuedAt: issuedAt,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      expiresAt: expiresAt,
      discountPercent: discountPercent,
      status: status ?? this.status,
      pointsUsed: pointsUsed,
      redeemType: redeemType,
      qrCode: qrCode,
      productName: productName,
      productSku: productSku,
      productImageUrl: productImageUrl,
      storeName: storeName,
      customerName: customerName,
      customerEmail: customerEmail,
      customerAlias: customerAlias,
      customerBadge: customerBadge,
      paymentMethod: paymentMethod,
      paymentAmountEur: paymentAmountEur,
      paymentVerified: paymentVerified,
      daysLeft: daysLeft,
    );
  }

  /// Entregado y puntos consumidos. El backend nuevo manda `DELIVERED`;
  /// `redeemed` se mantiene como alias deprecado durante una release.
  bool get isDelivered =>
      status == RedemptionCodeStatus.delivered ||
      status == RedemptionCodeStatus.redeemed;

  /// Alias histórico usado por la UI antigua (conteos, labels). Ahora reconoce
  /// también `DELIVERED`, que es la entrega real del flujo nuevo.
  bool get isRedeemed => isDelivered;

  /// El mostrador ya validó el código y el canje está en curso (IN_PROGRESS):
  /// es el estado desde el que se habilita el botón de entregar.
  bool get isInProgress => status == RedemptionCodeStatus.inProgress;

  bool get isIncident => status == RedemptionCodeStatus.incident;

  bool get isExpired {
    if (status == RedemptionCodeStatus.expired) {
      return true;
    }
    return expiresAt != null && expiresAt!.isBefore(DateTime.now());
  }

  factory RedemptionCodeModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final store = json['store'];
    final product = json['product'];
    final customerId = user is Map
        ? (user['id']?.toString() ?? '')
        : (user?.toString() ?? '');
    final storeId = store is Map
        ? (store['id']?.toString() ?? '')
        : (store?.toString() ?? '');
    final productId = product is Map
        ? (product['id']?.toString() ?? '')
        : (product?.toString() ?? '');

    return RedemptionCodeModel(
      id: json['id']?.toString() ?? '',
      campaignId: (json['campaign_id'] ?? '').toString(),
      storeId: storeId,
      customerUserId: customerId,
      productId: productId,
      code: (json['code'] ?? '').toString(),
      issuedAt:
          _parseDate(json['issued_at'] ?? json['created_at']) ?? DateTime.now(),
      redeemedAt: _parseDate(json['redeemed_at']),
      expiresAt: _parseDate(json['expires_at']),
      discountPercent:
          _toDouble(json['discount_percentage'] ?? json['discount_percent']),
      status: _parseStatus(json['status']),
      pointsUsed: json['points_used'] is int
          ? json['points_used'] as int
          : int.tryParse('${json['points_used']}') ?? 0,
      redeemType: (json['redeem_type'] ?? 'ONLINE').toString(),
      qrCode: json['qr_code']?.toString(),
      productName: product is Map ? product['name']?.toString() : null,
      productSku: product is Map ? product['sku']?.toString() : null,
      productImageUrl: product is Map
          ? (product['image'] ?? product['image_url'] ?? product['thumbnail'])?.toString()
          : null,
      storeName: store is Map ? store['name']?.toString() : null,
      customerName: user is Map
          ? (user['name'] ?? user['full_name'] ?? user['username'] ?? user['email'] ?? '').toString()
          : null,
      customerEmail: user is Map ? user['email']?.toString() : null,
      customerAlias: user is Map
          ? (user['alias'] ?? user['username'])?.toString()
          : null,
      customerBadge: user is Map
          ? (user['badge'] ?? user['tier'] ?? user['loyalty_badge'] ?? user['loyalty_level'])?.toString()
          : null,
      paymentMethod: json['payment_method']?.toString(),
      paymentAmountEur: _toDouble(json['payment_amount_eur'] ?? json['payment_amount']),
      paymentVerified: json['payment_verified'] as bool? ?? false,
      daysLeft: json['days_left'] is int
          ? json['days_left'] as int
          : int.tryParse('${json['days_left'] ?? ''}'),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static RedemptionCodeStatus _parseStatus(dynamic v) {
    switch ((v ?? '').toString().toUpperCase()) {
      case 'PAID':
        return RedemptionCodeStatus.paid;
      case 'IN_PROGRESS':
        return RedemptionCodeStatus.inProgress;
      case 'DELIVERED':
        return RedemptionCodeStatus.delivered;
      case 'INCIDENT':
        return RedemptionCodeStatus.incident;
      case 'REDEEMED':
        return RedemptionCodeStatus.redeemed;
      case 'EXPIRED':
        return RedemptionCodeStatus.expired;
      case 'CANCELLED':
        return RedemptionCodeStatus.cancelled;
      case 'REJECTED':
        return RedemptionCodeStatus.rejected;
      case 'PENDING':
      default:
        return RedemptionCodeStatus.pending;
    }
  }
}
