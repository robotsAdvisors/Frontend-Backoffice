import '../../../utils/api_config.dart';

/// Presupuesto de una campaña (aparece en el CRUD y en /impact/).
class CampaignBudget {
  final int? maxPointsGlobal; // null = sin tope
  final int consumedPoints;
  final bool exhausted;

  const CampaignBudget({
    this.maxPointsGlobal,
    this.consumedPoints = 0,
    this.exhausted = false,
  });

  factory CampaignBudget.fromJson(Map<String, dynamic> json) => CampaignBudget(
        maxPointsGlobal: json['max_points_global'] == null
            ? null
            : int.tryParse('${json['max_points_global']}'),
        consumedPoints: int.tryParse('${json['consumed_points'] ?? 0}') ?? 0,
        exhausted: json['exhausted'] == true,
      );
}

/// Campaña promocional del superadmin (points_admin, /admin/campaigns/).
///
/// El backend manda los **multiplicadores como strings** (p. ej. "2.00"), así
/// que se conservan tal cual para no perder precisión al formatearlos.
class CampaignModel {
  final String id;
  final String slug; // identificador estable; llega también en el cart-quote
  final String storeId;
  final String name;
  final String product; // nombre o id del producto asociado
  final String affects; // EARNING | REDEMPTION
  final String earningMultiplier; // string, p. ej. "2.00"
  final String redemptionMultiplier;
  final double discountPercent;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? bannerImage; // URL devuelta por POST /admin/campaigns/{id}/image/
  final CampaignBudget? budget;
  final bool isActive;

  CampaignModel({
    required this.id,
    this.slug = '',
    this.storeId = '',
    required this.name,
    this.product = '',
    this.affects = '',
    this.earningMultiplier = '',
    this.redemptionMultiplier = '',
    this.discountPercent = 0,
    this.startDate,
    this.endDate,
    this.bannerImage,
    this.budget,
    this.isActive = true,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    final productRaw = json['product'];
    final budgetRaw = json['budget'];
    return CampaignModel(
      id: (json['id'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      storeId: (json['store'] ?? json['store_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      product: productRaw is Map
          ? (productRaw['name'] ?? productRaw['id'] ?? '').toString()
          : (productRaw ?? '').toString(),
      affects: (json['affects'] ?? '').toString(),
      // Multiplicadores: strings en el backend. Se dejan como vinieron.
      earningMultiplier: (json['earning_multiplier'] ?? '').toString(),
      redemptionMultiplier: (json['redemption_multiplier'] ?? '').toString(),
      discountPercent: _toDouble(json['discount'] ?? json['discount_percent']),
      startDate: DateTime.tryParse((json['starts_at'] ??
              json['start_date'] ??
              json['valid_from'] ??
              '')
          .toString()),
      endDate: DateTime.tryParse(
          (json['ends_at'] ?? json['end_date'] ?? json['valid_until'] ?? '')
              .toString()),
      bannerImage: ApiConfig.absoluteMedia(
          (json['banner_image'] ?? json['banner'] ?? json['image_url'])
              ?.toString()),
      budget: budgetRaw is Map
          ? CampaignBudget.fromJson(Map<String, dynamic>.from(budgetRaw))
          : null,
      isActive: json['is_active'] as bool? ?? json['active'] as bool? ?? true,
    );
  }

  CampaignModel copyWith({String? bannerImage, bool? isActive}) => CampaignModel(
        id: id,
        slug: slug,
        storeId: storeId,
        name: name,
        product: product,
        affects: affects,
        earningMultiplier: earningMultiplier,
        redemptionMultiplier: redemptionMultiplier,
        discountPercent: discountPercent,
        startDate: startDate,
        endDate: endDate,
        bannerImage: bannerImage ?? this.bannerImage,
        budget: budget,
        isActive: isActive ?? this.isActive,
      );

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
