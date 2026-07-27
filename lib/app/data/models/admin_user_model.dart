class AdminUserModel {
  final String id;            // e.g. "L_UA-000034-A"
  final String firstName;
  final String lastName;
  final String name;          // firstName + lastName combinados
  final String emailMasked;   // "p*****@market.com"
  final String emailFull;
  final String documentType;  // "DNI" | "PASAPORTE"
  final String documentMasked; // "****492-G"
  final bool isActive;
  final bool isSuspended;
  final bool isStaff;
  final String country;
  final String language;
  final DateTime registeredAt;
  final DateTime? lastAccessAt;
  final DateTime? lastPurchaseAt;
  // Compliance
  final int consentPercent;
  final bool kycEnabled;
  final bool authEnabled;
  final bool hasBillingInfo;
  // Marketplace activity
  final int totalPoints;
  final int totalRedemptions;
  final int openDisputes;
  // Subscription & Benefits
  final String subscriptionPlan;
  final String subscriptionStatus;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionRenewalDate;
  final List<String> benefits;
  // Transactions
  final List<Map<String, dynamic>> transactions;
  // KYC & Deactivation
  final String kycStatus;
  final DateTime? kycSubmittedAt;
  final DateTime? kycApprovedAt;
  final String? kycRejectionReason;
  final String? deactivationStatus;
  final DateTime? deactivationDate;
  // Presentes SOLO en el detalle (GET /admin/users/{id}/), no en el listado.
  final List<StoreMembership> storeMemberships;
  final List<UserConsent> consents;
  final List<UserGdprRequest> gdprRequests;
  final List<UserAuditEntry> recentAudit;

  AdminUserModel({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    required this.name,
    required this.emailMasked,
    required this.emailFull,
    this.documentType = 'DNI',
    this.documentMasked = '',
    this.isActive = true,
    this.isSuspended = false,
    this.isStaff = false,
    this.country = '',
    this.language = '',
    required this.registeredAt,
    this.lastAccessAt,
    this.lastPurchaseAt,
    this.consentPercent = 0,
    this.kycEnabled = false,
    this.authEnabled = false,
    this.hasBillingInfo = false,
    this.totalPoints = 0,
    this.totalRedemptions = 0,
    this.openDisputes = 0,
    this.subscriptionPlan = 'Free',
    this.subscriptionStatus = 'active',
    this.subscriptionStartDate,
    this.subscriptionRenewalDate,
    this.benefits = const [],
    this.transactions = const [],
    this.kycStatus = 'pending',
    this.kycSubmittedAt,
    this.kycApprovedAt,
    this.kycRejectionReason,
    this.deactivationStatus,
    this.deactivationDate,
    this.storeMemberships = const [],
    this.consents = const [],
    this.gdprRequests = const [],
    this.recentAudit = const [],
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final compliance = json['compliance'] ?? json['cumplimiento'] ?? const {};
    final activity   = json['marketplace_activity'] ?? json['activity'] ?? const {};
    final subscription = json['subscription'] ?? const {};
    final benefits = json['benefits'] ?? const {};
    final kyc = json['kyc'] ?? const {};

    final fn = (json['first_name'] ?? '').toString().trim();
    final ln = (json['last_name']  ?? '').toString().trim();
    final fullName = (json['full_name'] ?? json['name'] ?? '').toString().trim();
    final name = fullName.isNotEmpty ? fullName : [fn, ln].where((s) => s.isNotEmpty).join(' ');

    // Parse benefits
    final benefitsRaw = benefits is Map ? benefits['benefits'] ?? [] : [];
    final benefitsList = (benefitsRaw is List)
        ? benefitsRaw.whereType<String>().toList()
        : <String>[];

    // Parse transactions
    final transactionsRaw = json['transactions'] ?? [];
    final transactionsList = (transactionsRaw is List)
        ? transactionsRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    // Listas anidadas del detalle. `_maps` normaliza cualquier lista de objetos.
    List<Map<String, dynamic>> maps(dynamic raw) => raw is List
        ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const <Map<String, dynamic>>[];

    return AdminUserModel(
      id:             (json['user_id'] ?? json['id'] ?? '').toString(),
      firstName:      fn,
      lastName:       ln,
      name:           name,
      emailMasked:    (json['email_masked'] ?? json['email'] ?? '').toString(),
      emailFull:      (json['email_full'] ?? json['email'] ?? '').toString(),
      documentType:   (json['document_type'] ?? 'DNI').toString(),
      documentMasked: (json['document_masked'] ?? '').toString(),
      isActive:       json['is_active'] as bool? ?? true,
      isSuspended:    json['is_suspended'] as bool? ?? false,
      isStaff:        json['is_staff'] as bool? ?? false,
      country:        (json['country'] ?? '').toString(),
      language:       (json['language'] ?? '').toString(),
      registeredAt:   DateTime.tryParse((json['registered_at'] ?? json['date_joined'] ?? '').toString()) ?? DateTime.now(),
      lastAccessAt:   DateTime.tryParse((json['last_access'] ?? json['last_login'] ?? json['last_active_at'] ?? '').toString()),
      lastPurchaseAt: DateTime.tryParse((json['last_purchase'] ?? '').toString()),
      consentPercent: _toInt(compliance is Map ? (compliance['consent_percent'] ?? json['consent_percent']) : 0),
      kycEnabled:     _toBool(compliance is Map ? (compliance['kyc_enabled'] ?? json['kyc_enabled']) : false),
      authEnabled:    _toBool(compliance is Map ? (compliance['auth_enabled'] ?? json['auth_enabled'] ?? json['two_factor_enabled']) : json['two_factor_enabled']),
      hasBillingInfo: _toBool(compliance is Map ? (compliance['has_billing'] ?? json['has_billing']) : false),
      totalPoints:    _toInt(activity is Map ? (activity['total_points'] ?? json['total_points']) : 0),
      totalRedemptions: _toInt(activity is Map ? (activity['total_redemptions'] ?? json['total_redemptions']) : 0),
      openDisputes:   _toInt(activity is Map ? (activity['open_disputes'] ?? json['open_disputes']) : 0),
      subscriptionPlan: (subscription is Map ? (subscription['plan'] ?? 'Free') : 'Free').toString(),
      subscriptionStatus: (subscription is Map ? (subscription['status'] ?? 'active') : 'active').toString(),
      subscriptionStartDate: subscription is Map
          ? DateTime.tryParse((subscription['subscribed_at'] ?? '').toString())
          : null,
      subscriptionRenewalDate: subscription is Map
          ? DateTime.tryParse((subscription['renewal_date'] ?? '').toString())
          : null,
      benefits: benefitsList,
      transactions: transactionsList,
      kycStatus: (kyc is Map ? (kyc['status'] ?? 'pending') : 'pending').toString(),
      kycSubmittedAt: kyc is Map ? DateTime.tryParse((kyc['submitted_at'] ?? '').toString()) : null,
      kycApprovedAt: kyc is Map ? DateTime.tryParse((kyc['approved_at'] ?? '').toString()) : null,
      kycRejectionReason: kyc is Map ? (kyc['rejection_reason'] ?? '').toString() : null,
      deactivationStatus: json['is_deleted'] == true
          ? 'deleted'
          : ((json['deactivation_status'] ?? '').toString().isEmpty
              ? null
              : (json['deactivation_status'] ?? '').toString()),
      deactivationDate: DateTime.tryParse(
          (json['deleted_at'] ?? json['deactivation_date'] ?? '').toString()),
      storeMemberships:
          maps(json['store_memberships']).map(StoreMembership.fromJson).toList(),
      consents: maps(json['consents']).map(UserConsent.fromJson).toList(),
      gdprRequests:
          maps(json['gdpr_requests']).map(UserGdprRequest.fromJson).toList(),
      recentAudit:
          maps(json['recent_audit']).map(UserAuditEntry.fromJson).toList(),
    );
  }

  static int  _toInt(dynamic v)  => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
  static bool _toBool(dynamic v) => v is bool ? v : (v?.toString().toLowerCase() == 'true');

  String get statusLabel => isSuspended ? 'Cuenta Suspendida' : (isActive ? 'Cuenta Activa' : 'Inactiva');
}

/// Pertenencia de un usuario a una tienda (rol y estado).
/// OJO: el backend serializa con doble guion bajo (`store__id`, `store__name`),
/// artefacto del ORM de Django; se mapea LITERALMENTE esas claves.
class StoreMembership {
  final String storeId;
  final String storeName;
  final String role; // OWNER | ADMIN | MEMBER
  final bool isActive;
  final DateTime? created;

  const StoreMembership({
    required this.storeId,
    required this.storeName,
    this.role = '',
    this.isActive = true,
    this.created,
  });

  factory StoreMembership.fromJson(Map<String, dynamic> json) => StoreMembership(
        storeId: (json['store__id'] ?? '').toString(),
        storeName: (json['store__name'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
        isActive: json['is_active'] as bool? ?? true,
        created: DateTime.tryParse((json['created'] ?? '').toString()),
      );
}

/// Consentimiento legal aceptado/retirado por el usuario.
class UserConsent {
  final String documentType;
  final String version;
  final DateTime? acceptedAt;
  final DateTime? withdrawnAt;

  const UserConsent({
    this.documentType = '',
    this.version = '',
    this.acceptedAt,
    this.withdrawnAt,
  });

  factory UserConsent.fromJson(Map<String, dynamic> json) => UserConsent(
        documentType: (json['document_type'] ?? '').toString(),
        version: (json['version'] ?? '').toString(),
        acceptedAt: DateTime.tryParse((json['accepted_at'] ?? '').toString()),
        withdrawnAt: DateTime.tryParse((json['withdrawn_at'] ?? '').toString()),
      );
}

/// Solicitud RGPD del usuario (acceso, borrado, etc.).
class UserGdprRequest {
  final String type;
  final String status;
  final DateTime? created;

  const UserGdprRequest({this.type = '', this.status = '', this.created});

  factory UserGdprRequest.fromJson(Map<String, dynamic> json) => UserGdprRequest(
        type: (json['type'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        created: DateTime.tryParse((json['created'] ?? '').toString()),
      );
}

/// Entrada reciente del registro de auditoría del usuario.
class UserAuditEntry {
  final String action;
  final String description;
  final DateTime? created;

  const UserAuditEntry({this.action = '', this.description = '', this.created});

  factory UserAuditEntry.fromJson(Map<String, dynamic> json) => UserAuditEntry(
        action: (json['action'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        created: DateTime.tryParse((json['created'] ?? '').toString()),
      );
}
