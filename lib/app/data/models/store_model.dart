import '../../../utils/api_config.dart';

class StoreModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String ownerEmail;
  final String ownerName;
  final List<String> adminUserIds;
  final String fiscalId;
  final String address;
  final String logoUrl;
  final String billingEmail;
  final String billingPhone;
  final String pin;
  final DateTime createdAt;
  // Nuevos campos del backend
  final String banner;
  final String email;
  final String website;
  final Map<String, dynamic> openingHours;
  final bool isPublished;
  final List<String> categories;
  final double rating;
  final int reviewCount;
  final String cardId;       // e.g. "STR-000042" — assigned by backend
  final double? latitude;    // GPS latitude
  final double? longitude;   // GPS longitude
  final String billingAddress;
  final bool twoFactorEnabled;
  final String subtitle;          // alias de description — retornado por StoreSerializer
  final int monthlyGoalTarget;    // de monthly_goal_target en StoreSerializer
  final String monthlyGoalPrize;  // de monthly_goal_prize en StoreSerializer
  final String kycStatus;         // kyc_status from backend: pending|in_review|approved|rejected|suspended|''

  StoreModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerEmail,
    this.ownerName = '',
    required this.adminUserIds,
    required this.fiscalId,
    required this.address,
    required this.logoUrl,
    required this.billingEmail,
    required this.billingPhone,
    required this.pin,
    required this.createdAt,
    this.banner = '',
    this.email = '',
    this.website = '',
    this.openingHours = const {},
    this.isPublished = true,
    this.categories = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.cardId = '',
    this.latitude,
    this.longitude,
    this.billingAddress = '',
    this.twoFactorEnabled = false,
    this.subtitle = '',
    this.monthlyGoalTarget = 500000,
    this.monthlyGoalPrize = '',
    this.kycStatus = '',
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    // Support both Django snake_case and legacy camelCase keys.
    final hours = json['opening_hours'] ?? json['openingHours'] ?? const {};
    // El backend puede mandar `categories` (lista) o `category` (objeto único
    // {name, display_name}). Se normaliza a una lista de nombres legibles.
    final catsRaw = json['categories'];
    final catObj = json['category'];
    final cats = catsRaw is List
        ? catsRaw
        : (catObj is Map
            ? [(catObj['display_name'] ?? catObj['name'] ?? '').toString()]
            : const []);
    // El backend usa `is_active`; se mantienen `is_published`/`isPublished` como
    // fallback para respuestas antiguas.
    final published = json['is_published'] ??
        json['isPublished'] ??
        json['is_active'] ??
        true;

    // owner can be a nested object {id, email} or a plain ID.
    final ownerRaw = json['owner'];
    final ownerId = ownerRaw is Map
        ? (ownerRaw['id']?.toString() ?? '')
        : (json['owner_id'] ?? json['ownerId'] ?? ownerRaw ?? '').toString();
    final ownerEmail = ownerRaw is Map
        ? (ownerRaw['email']?.toString() ?? '')
        : (json['owner_email'] ?? json['ownerEmail'] ?? '').toString();
    String ownerName = (json['owner_name'] ?? '').toString().trim();
    if (ownerName.isEmpty && ownerRaw is Map) {
      final fn = (ownerRaw['first_name'] ?? ownerRaw['firstName'] ?? '').toString().trim();
      final ln = (ownerRaw['last_name'] ?? ownerRaw['lastName'] ?? '').toString().trim();
      ownerName = [fn, ln].where((s) => s.isNotEmpty).join(' ');
      if (ownerName.isEmpty) {
        ownerName = (ownerRaw['name'] ?? ownerRaw['username'] ?? '').toString().trim();
      }
    }

    final adminRaw = json['admin_user_ids'] ?? json['adminUserIds'];

    return StoreModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      ownerId: ownerId,
      ownerEmail: ownerEmail.isNotEmpty ? ownerEmail : (json['email'] ?? '').toString(),
      ownerName: ownerName,
      adminUserIds: adminRaw is List
          ? List<String>.from(adminRaw.map((e) => e.toString()))
          : const [],
      // Backend v2 uses 'cif'; keep 'fiscal_id'/'fiscalId' as fallback.
      fiscalId: (json['cif'] ?? json['fiscal_id'] ?? json['fiscalId'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      logoUrl: ApiConfig.absoluteMedia(
          (json['logo'] ?? json['logo_url'] ?? json['image_url'])?.toString()),
      billingEmail: (json['billing_email'] ?? json['billingEmail'] ?? json['email'] ?? '').toString(),
      billingPhone: (json['phone_number'] ?? json['phoneNumber'] ?? json['phone'] ?? '').toString(),
      pin: (json['pin'] ?? '').toString(),
      createdAt: DateTime.tryParse(
              (json['created_at'] ?? json['createdAt'] ?? json['created'] ?? '')
                  .toString()) ??
          DateTime.now(),
      banner: ApiConfig.absoluteMedia(
          (json['banner'] ?? json['banner_url'] ?? json['banner_image'])?.toString()),
      email: (json['email'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      openingHours: hours is Map ? Map<String, dynamic>.from(hours) : const {},
      isPublished: published is bool
          ? published
          : published.toString().toLowerCase() == 'true',
      categories:
          List<String>.from(cats.map((e) => e.toString())).where((s) => s.isNotEmpty).toList(),
      rating: double.tryParse(
              (json['rating'] ?? json['average_rating'] ?? 0).toString()) ??
          0.0,
      reviewCount: json['review_count'] is int
          ? json['review_count'] as int
          : int.tryParse('${json['review_count'] ?? 0}') ?? 0,
      cardId: (json['card_id'] ?? '').toString(),
      latitude: _toDouble(json['latitude'] ?? json['lat']),
      longitude: _toDouble(json['longitude'] ?? json['lng']),
      billingAddress: (json['billing_address'] ?? json['billingAddress'] ?? '').toString(),
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? json['twoFactorEnabled'] as bool? ?? false,
      subtitle: (json['subtitle'] ?? json['description'] ?? '').toString(),
      monthlyGoalTarget: json['monthly_goal_target'] is num
          ? (json['monthly_goal_target'] as num).toInt()
          : int.tryParse('${json['monthly_goal_target'] ?? 500000}') ?? 500000,
      monthlyGoalPrize: (json['monthly_goal_prize'] ?? '').toString(),
      kycStatus: (json['kyc_status'] ?? json['kycStatus'] ?? '').toString(),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// Copia con banner/logo nuevos (para reflejar la subida al instante sin
  /// depender de que el GET de la tienda devuelva la imagen actualizada).
  StoreModel copyWith({String? banner, String? logoUrl}) => StoreModel(
        id: id,
        name: name,
        description: description,
        ownerId: ownerId,
        ownerEmail: ownerEmail,
        ownerName: ownerName,
        adminUserIds: adminUserIds,
        fiscalId: fiscalId,
        address: address,
        logoUrl: logoUrl ?? this.logoUrl,
        billingEmail: billingEmail,
        billingPhone: billingPhone,
        pin: pin,
        createdAt: createdAt,
        banner: banner ?? this.banner,
        email: email,
        website: website,
        openingHours: openingHours,
        isPublished: isPublished,
        categories: categories,
        rating: rating,
        reviewCount: reviewCount,
        cardId: cardId,
        latitude: latitude,
        longitude: longitude,
        billingAddress: billingAddress,
        twoFactorEnabled: twoFactorEnabled,
        subtitle: subtitle,
        monthlyGoalTarget: monthlyGoalTarget,
        monthlyGoalPrize: monthlyGoalPrize,
        kycStatus: kycStatus,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'ownerName': ownerName,
      'adminUserIds': adminUserIds,
      'fiscalId': fiscalId,
      'address': address,
      'logo': logoUrl,
      'billingEmail': billingEmail,
      'phoneNumber': billingPhone,
      'pin': pin,
      'createdAt': createdAt.toIso8601String(),
      'banner': banner,
      'email': email,
      'website': website,
      'openingHours': openingHours,
      'isPublished': isPublished,
      'categories': categories,
      'rating': rating,
      'review_count': reviewCount,
      'card_id': cardId,
      'cif': fiscalId,
      'latitude': latitude,
      'longitude': longitude,
      'billing_address': billingAddress,
      'two_factor_enabled': twoFactorEnabled,
    };
  }
}