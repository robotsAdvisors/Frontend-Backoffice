import 'dart:math';

import 'package:get/get.dart';

import '../../../../utils/dummy_helper.dart';
import '../../../components/custom_snackbar.dart';
import '../../../data/models/admin_user_model.dart';
import '../../../data/models/audit_log_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/kybc_stats_model.dart';
import '../../../data/models/sensitive_policy_model.dart';
import '../../../data/models/stripe_dispute_model.dart';
import '../../../data/models/data_subject_request_model.dart';
import '../../../data/models/legal_consent_model.dart';
import '../../../data/models/legal_stats_response.dart';
import '../../../data/models/legal_version_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/paginated.dart';
import '../../../data/models/store_model.dart';
import '../../../data/models/store_user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/marketplace_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/http/api_client.dart';

class GeneralAdminController extends GetxController {
  final RxList<StoreModel> stores = <StoreModel>[].obs;
  final RxList<StoreUserModel> storeUsers = <StoreUserModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;

  // Métricas globales
  final RxInt totalStores = 0.obs;
  final RxInt totalStoreUsers = 0.obs;
  final RxInt totalCategories = 0.obs;
  final RxInt totalProducts = 0.obs;
  final RxInt totalRedemptions = 0.obs;
  final RxInt totalPointsPts = 0.obs;
  final RxMap<String, int> storeRevenue = <String, int>{}.obs;

  // Crecimiento
  final RxDouble storesGrowthPercent = 0.0.obs;
  final RxDouble usersGrowthPercent = 0.0.obs;

  // Permisos del sistema
  final RxInt superAdminCount = 0.obs;
  final RxInt supportTeamCount = 0.obs;
  final RxInt securityCompliance = 0.obs;

  // Network Growth chart
  final RxMap<String, List<int>> networkGrowth = <String, List<int>>{}.obs;
  final RxInt selectedGrowthTab = 1.obs;

  // Usuario logueado
  final RxString currentUserName = ''.obs;
  final RxString currentUserInitials = ''.obs;

  // Backoffice — gestión de usuarios
  final RxList<AdminUserModel> adminUsers = <AdminUserModel>[].obs;
  final Rx<AdminUserModel?> selectedUser = Rx<AdminUserModel?>(null);
  final RxList<AuditLogModel> auditLog = <AuditLogModel>[].obs;
  final RxBool isLoadingUser = false.obs;
  final RxBool isSuspending = false.obs;
  final RxString revealedDocument = ''.obs;

  // User detail sections
  final RxMap<String, dynamic> userSubscription = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> userBenefits = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> userTransactions = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> userKyc = <String, dynamic>{}.obs;

  // Legal & Consents Management
  final RxList<LegalConsentModel> legalConsents = <LegalConsentModel>[].obs;
  final Rx<LegalStatsResponse?> legalStats = Rx<LegalStatsResponse?>(null);
  final RxList<LegalVersionModel> legalVersions = <LegalVersionModel>[].obs;
  final RxList<DataSubjectRequestModel> dataSubjectRequests = <DataSubjectRequestModel>[].obs;
  final RxBool isLoadingLegal = false.obs;

  // Store Configuration (backoffice)
  final Rx<StoreModel?> selectedStore = Rx<StoreModel?>(null);
  final RxList<StoreUserModel> selectedStoreUsers = <StoreUserModel>[].obs;
  final RxString selectedStorePinMasked = ''.obs;
  final RxBool isLoadingStore = false.obs;
  final RxBool isSavingStore = false.obs;
  final RxString storeQuery = ''.obs;

  void searchStores(String query) => storeQuery.value = query.toLowerCase();

  // KYBC Compliance
  final Rx<KybcStatsModel?> kybcStats = Rx<KybcStatsModel?>(null);
  final RxList<AdminUserModel> kycQueue = <AdminUserModel>[].obs;
  final Rx<AdminUserModel?> selectedKycUser = Rx<AdminUserModel?>(null);
  final RxList<Map<String, dynamic>> complianceHistory = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingKybc = false.obs;
  final RxBool isExecutingAction = false.obs;
  final RxInt kycQueueTab = 0.obs; // 0=pending, 1=in_review

  // Políticas Sensibles
  final RxList<SensitivePolicyModel> sensitivePolicies = <SensitivePolicyModel>[].obs;
  final RxInt policiesActive  = 0.obs;
  final RxInt policiesPending = 0.obs;
  final RxDouble policiesCoverage = 0.0.obs;
  final RxBool isLoadingPolicies = false.obs;

  // Stripe Disputes & Refunds
  final RxList<StripeDisputeModel> stripeDisputes = <StripeDisputeModel>[].obs;
  final Rx<StripeDisputeStats?> stripeDisputeStats = Rx<StripeDisputeStats?>(null);
  final RxBool isLoadingDisputes = false.obs;

  final RxBool isLoading = false.obs;

  // Panel de Control Ejecutivo — métricas ejecutivas
  final RxInt activeIncidents = 0.obs;
  final RxInt totalReports = 0.obs;
  final RxInt openDisputes = 0.obs;
  final RxInt supportTicketsTotal = 0.obs;
  final RxInt kycVerifications = 0.obs;
  final RxDouble incidentsDelta = 0.0.obs;
  final RxDouble reportsDelta = 0.0.obs;
  final RxDouble disputesDelta = 0.0.obs;
  final RxDouble ticketsDelta = 0.0.obs;
  final RxDouble verificationsDelta = 0.0.obs;

  // Dominios Operacionales
  final RxInt supportPending = 0.obs;
  final RxInt supportResolvingToday = 0.obs;
  final RxInt complianceInReview = 0.obs;
  final RxInt complianceExpired = 0.obs;
  final RxInt paymentsActiveCollect = 0.obs;
  final RxDouble paymentsVolume = 0.0.obs;
  final RxInt moderationAlerts = 0.obs;
  final RxInt moderationPrevState = 0.obs;

  // Salud del Sistema
  final RxDouble dbHealthPct = 0.0.obs;
  final RxInt microservicesErrors = 0.obs;
  final RxInt latencyMediaMs = 0.obs;

  // Alertas Críticas y Auditoría Global
  final RxList<Map<String, dynamic>> criticalAlerts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> globalAuditEntries = <Map<String, dynamic>>[].obs;

  final _repo = MarketplaceRepository.instance;

  @override
  void onInit() {
    super.onInit();
    stores.assignAll(DummyHelper.stores);
    storeUsers.assignAll(DummyHelper.storeUsers);
    _initUserProfile();
    _calculateMetrics();
    _loadFromBackend();
  }

  void _initUserProfile() {
    final email = AuthService.currentUserEmail ?? '';
    if (email.isNotEmpty) {
      currentUserName.value = email.split('@').first;
      currentUserInitials.value = email[0].toUpperCase();
    }
  }

  Future<void> _loadFromBackend() async {
    isLoading.value = true;

    await Future.wait<void>([
      _repo.fetchStores().then((s) { if (s.isNotEmpty) stores.assignAll(s); }).catchError((_) {}),
      _repo.fetchCategories().then((c) { if (c.isNotEmpty) categories.assignAll(c); }).catchError((_) {}),
      _repo.fetchDashboardStats().then((s) { if (s != null) _applyStats(s); }).catchError((_) {}),
      _repo.fetchAdminAlerts().then((a) { if (a.isNotEmpty) criticalAlerts.assignAll(a); }).catchError((_) {}),
      _repo.fetchGlobalAuditLog().then((e) { if (e.isNotEmpty) globalAuditEntries.assignAll(e); }).catchError((_) {}),
      _repo.fetchSystemHealth().then((h) { if (h != null) _applySystemHealth(h); }).catchError((_) {}),
      _repo.fetchDomainStats().then((d) { if (d != null) _applyDomainStats(d); }).catchError((_) {}),
      _repo.fetchOrders(pageSize: 1).then((p) => _applyOrderStats(p.stats)).catchError((_) {}),
      AuthRepository.instance.fetchMe().then((me) { if (me != null) _applyUserProfile(me); }).catchError((_) {}),
      _repo.fetchKycStats().then((s) { kybcStats.value = s; }).catchError((_) {}),
    ]);

    _calculateMetrics();
    isLoading.value = false;
  }

  void _applyOrderStats(OrdersStats s) {
    if (totalRedemptions.value == 0 && s.totalOrders > 0) {
      totalRedemptions.value = s.totalOrders;
    }
    if (totalPointsPts.value == 0 && s.totalPointsUsed > 0) {
      totalPointsPts.value = s.totalPointsUsed;
    }
  }

  void _applyUserProfile(Map<String, dynamic> me) {
    final fn = (me['first_name'] ?? me['firstName'] ?? '').toString().trim();
    final ln = (me['last_name'] ?? me['lastName'] ?? '').toString().trim();
    final full = (me['full_name'] ?? me['name'] ?? '').toString().trim();
    final name = full.isNotEmpty ? full : [fn, ln].where((s) => s.isNotEmpty).join(' ');
    if (name.isNotEmpty) {
      currentUserName.value = name;
      currentUserInitials.value = name
          .split(' ')
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join();
    }
  }

  void _applyStats(Map<String, dynamic> stats) {
    totalStores.value = _parseInt(stats['total_stores'] ?? stats['stores']) ?? totalStores.value;
    totalCategories.value = _parseInt(stats['total_categories'] ?? stats['categories']) ?? totalCategories.value;
    totalProducts.value = _parseInt(stats['total_products'] ?? stats['products']) ?? totalProducts.value;
    totalRedemptions.value = _parseInt(stats['total_redemptions'] ?? stats['redemptions']) ?? totalRedemptions.value;
    totalPointsPts.value = _parseInt(stats['total_points'] ?? stats['points_value']) ?? totalPointsPts.value;

    final usersRaw = stats['total_users'] ?? stats['active_users'] ?? stats['users'];
    if (usersRaw != null) totalStoreUsers.value = _parseInt(usersRaw) ?? totalStoreUsers.value;

    // Crecimiento
    final sg = _parseDouble(stats['stores_growth_percent'] ?? stats['stores_growth']);
    if (sg != null) storesGrowthPercent.value = sg;
    final ug = _parseDouble(stats['users_growth_percent'] ?? stats['users_growth']);
    if (ug != null) usersGrowthPercent.value = ug;

    // Permisos
    final sa = _parseInt(stats['super_admin_count'] ?? stats['superadmin_count']);
    if (sa != null) superAdminCount.value = sa;
    final st = _parseInt(stats['support_team_count'] ?? stats['support_count']);
    if (st != null) supportTeamCount.value = st;
    final sc = _parseInt(stats['security_compliance'] ?? stats['compliance']);
    if (sc != null) securityCompliance.value = sc;

    // Revenue por tienda
    final storeStats = stats['stores_stats'] ?? stats['store_stats'] ?? stats['stores_revenue'];
    if (storeStats is List) {
      for (final item in storeStats) {
        if (item is Map) {
          final id = (item['store_id'] ?? item['id'] ?? '').toString();
          final rev = _parseInt(item['revenue'] ?? item['total_revenue'] ?? item['total_points']);
          if (id.isNotEmpty && rev != null) storeRevenue[id] = rev;
        }
      }
    } else if (storeStats is Map) {
      storeStats.forEach((k, v) {
        final rev = _parseInt(v);
        if (rev != null) storeRevenue[k.toString()] = rev;
      });
    }

    // Network growth chart
    final growth = stats['network_growth'];
    if (growth is Map) {
      for (final key in ['7d', '30d', '6m']) {
        final raw = growth[key];
        if (raw is List) {
          networkGrowth[key] = raw.map((v) => _parseInt(v) ?? 0).toList();
        }
      }
    }

    // Métricas ejecutivas
    final ai = _parseInt(stats['active_incidents'] ?? stats['incidents_active'] ?? stats['incidents']);
    if (ai != null) activeIncidents.value = ai;
    final ig = _parseDouble(stats['incidents_growth_pct'] ?? stats['incidents_growth']);
    if (ig != null) incidentsDelta.value = ig;

    final tr = _parseInt(stats['total_reports'] ?? stats['reports']);
    if (tr != null) totalReports.value = tr;
    final rg = _parseDouble(stats['reports_growth_pct'] ?? stats['reports_growth']);
    if (rg != null) reportsDelta.value = rg;

    final od = _parseInt(stats['open_disputes'] ?? stats['disputes_open'] ?? stats['disputes']);
    if (od != null) openDisputes.value = od;
    final dg = _parseDouble(stats['disputes_growth_pct'] ?? stats['disputes_growth']);
    if (dg != null) disputesDelta.value = dg;

    final stc = _parseInt(stats['support_tickets_count'] ?? stats['tickets_total'] ?? stats['tickets']);
    if (stc != null) supportTicketsTotal.value = stc;
    final tg = _parseDouble(stats['tickets_growth_pct'] ?? stats['tickets_growth']);
    if (tg != null) ticketsDelta.value = tg;

    final kv = _parseInt(stats['kyc_verifications'] ?? stats['verifications']);
    if (kv != null) kycVerifications.value = kv;
    final vg = _parseDouble(stats['verifications_growth_pct'] ?? stats['verifications_growth']);
    if (vg != null) verificationsDelta.value = vg;

    // Dominios Operacionales (fallback si vienen embebidos en el stats principal)
    final domainRaw = stats['domain_stats'] ?? stats['domains'] ?? const {};
    if (domainRaw is Map) _applyDomainStats(Map<String, dynamic>.from(domainRaw));

    // Salud del Sistema (fallback si viene embebida en el stats principal)
    final healthRaw = stats['system_health'] ?? stats['health'] ?? const {};
    if (healthRaw is Map && healthRaw.isNotEmpty) {
      _applySystemHealth(Map<String, dynamic>.from(healthRaw));
    }

    // Alertas Críticas (fallback si vienen embebidas en el stats principal)
    final alertsRaw = stats['critical_alerts'] ?? stats['alerts'];
    if (alertsRaw is List && criticalAlerts.isEmpty) {
      criticalAlerts.value = alertsRaw
          .whereType<Map>()
          .map((a) => Map<String, dynamic>.from(a))
          .toList();
    }

    // Auditoría Global (fallback si viene embebida en el stats principal)
    final auditRaw = stats['global_audit'] ?? stats['audit_log'];
    if (auditRaw is List && globalAuditEntries.isEmpty) {
      globalAuditEntries.value = auditRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }

  void _applySystemHealth(Map<String, dynamic> h) {
    final dbh = _parseDouble(h['db_health_pct'] ?? h['db_health']);
    if (dbh != null) dbHealthPct.value = dbh;
    final me = _parseInt(h['microservices_errors'] ?? h['errors']);
    if (me != null) microservicesErrors.value = me;
    final lm = _parseInt(h['latency_ms'] ?? h['latency']);
    if (lm != null) latencyMediaMs.value = lm;
  }

  void _applyDomainStats(Map<String, dynamic> d) {
    final sup = d['support'];
    if (sup is Map) {
      final sp = _parseInt(sup['pending']); if (sp != null) supportPending.value = sp;
      final sr = _parseInt(sup['resolving_today']); if (sr != null) supportResolvingToday.value = sr;
    }
    final comp = d['compliance'];
    if (comp is Map) {
      final ci = _parseInt(comp['in_review']); if (ci != null) complianceInReview.value = ci;
      final ce = _parseInt(comp['expired']); if (ce != null) complianceExpired.value = ce;
    }
    final pay = d['payments'];
    if (pay is Map) {
      final pa = _parseInt(pay['active_collect']); if (pa != null) paymentsActiveCollect.value = pa;
      final pv = _parseDouble(pay['volume']); if (pv != null) paymentsVolume.value = pv;
    }
    final mod = d['moderation'];
    if (mod is Map) {
      final ma = _parseInt(mod['alerts']); if (ma != null) moderationAlerts.value = ma;
      final mp = _parseInt(mod['prev_state']); if (mp != null) moderationPrevState.value = mp;
    }
  }

  /// Devuelve los datos del gráfico normalizados a [0.0, 1.0] según el tab seleccionado.
  List<double> get currentGrowthData {
    final keys = ['7d', '30d', '6m'];
    final key = keys[selectedGrowthTab.value.clamp(0, 2)];
    final raw = networkGrowth[key] ?? [];
    if (raw.isEmpty) return [];
    final maxVal = raw.reduce(max);
    if (maxVal == 0) return List.filled(raw.length, 0.0);
    return raw.map((v) => v / maxVal).toList();
  }

  List<String> get currentGrowthLabels {
    switch (selectedGrowthTab.value) {
      case 0: return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 1: return ['W1', 'W2', 'W3', 'W4'];
      case 2: return ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
      default: return [];
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  void _calculateMetrics() {
    if (totalStores.value == 0) totalStores.value = stores.length;
    if (totalStoreUsers.value == 0) totalStoreUsers.value = storeUsers.length;
    if (totalCategories.value == 0) totalCategories.value = categories.length;
  }

  Future<void> addStore(StoreModel store) async {
    stores.add(store);
    _calculateMetrics();

    try {
      final payload = <String, dynamic>{
        'name': store.name,
        'address': store.address,
        'logo':
            store.logoUrl.startsWith('http') ? store.logoUrl : null,
        'phoneNumber': store.billingPhone.isEmpty ? null : store.billingPhone,
        if (store.email.isNotEmpty) 'email': store.email,
        if (store.website.isNotEmpty) 'website': store.website,
        if (store.banner.isNotEmpty) 'banner': store.banner,
        if (store.openingHours.isNotEmpty) 'openingHours': store.openingHours,
        if (store.categories.isNotEmpty) 'categories': store.categories,
      }..removeWhere((_, v) => v == null);

      final created = await _repo.adminCreateStore(payload);
      if (created != null) {
        final idx = stores.indexOf(store);
        if (idx != -1) {
          stores[idx] = created;
          _calculateMetrics();
        }
        CustomSnackBar.showCustomSnackBar(
          title: 'Tienda creada',
          message: 'La tienda se guardo en el backend.',
        );
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'No se pudo persistir',
        message: e.message,
      );
    } catch (_) {
      // Sin conexion: queda solo local.
    }
  }

  Future<void> addCategory({
    required String name,
    String? displayName,
    String? icon,
  }) async {
    try {
      final created = await _repo.adminCreateCategory(<String, dynamic>{
        'name': name,
        if (displayName != null) 'display_name': displayName,
        if (icon != null) 'icon': icon,
      });
      if (created != null) {
        categories.add(CategoryModel.fromJson(created));
        CustomSnackBar.showCustomSnackBar(
          title: 'Categoria creada',
          message: 'La categoria se guardo en el backend.',
        );
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'No se pudo crear',
        message: e.message,
      );
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: 'No fue posible crear la categoria.',
      );
    }
  }

  /// El backend aun no expone alta/baja de usuarios de tienda;
  /// se mantienen en memoria.
  void addStoreUser(StoreUserModel user) {
    storeUsers.add(user);
    _calculateMetrics();
  }

  void removeStore(String storeId) {
    stores.removeWhere((store) => store.id == storeId);
    storeUsers.removeWhere((user) => user.storeId == storeId);
    _calculateMetrics();
  }

  void removeStoreUser(String userId) {
    storeUsers.removeWhere((user) => user.id == userId);
    _calculateMetrics();
  }

  // ── Backoffice user management ────────────────────────────────────────────

  Future<void> loadAdminUsers({String? search}) async {
    try {
      final users = await _repo.fetchAdminUsers(search: search);
      adminUsers.assignAll(users);
    } catch (_) {}
  }

  Future<void> selectUser(String userId) async {
    isLoadingUser.value = true;
    revealedDocument.value = '';
    userSubscription.clear();
    userBenefits.clear();
    userTransactions.clear();
    userKyc.clear();
    try {
      final results = await Future.wait([
        _repo.fetchAdminUserDetail(userId),
        _repo.fetchAuditLog(userId),
        _repo.fetchUserSubscription(userId),
        _repo.fetchUserBenefits(userId),
        _repo.fetchUserTransactions(userId),
        _repo.fetchUserKyc(userId),
      ]);
      final user = results[0] as AdminUserModel?;
      final log  = results[1] as List<AuditLogModel>;
      final sub  = results[2] as Map<String, dynamic>?;
      final ben  = results[3] as Map<String, dynamic>?;
      final txn  = results[4] as List<Map<String, dynamic>>;
      final kyc  = results[5] as Map<String, dynamic>?;

      if (user != null) {
        // Merge the fetched data into the user model
        final mergedUser = AdminUserModel(
          id: user.id,
          firstName: user.firstName,
          lastName: user.lastName,
          name: user.name,
          emailMasked: user.emailMasked,
          emailFull: user.emailFull,
          documentType: user.documentType,
          documentMasked: user.documentMasked,
          isActive: user.isActive,
          isSuspended: user.isSuspended,
          isStaff: user.isStaff,
          country: user.country,
          language: user.language,
          registeredAt: user.registeredAt,
          lastAccessAt: user.lastAccessAt,
          lastPurchaseAt: user.lastPurchaseAt,
          consentPercent: user.consentPercent,
          kycEnabled: user.kycEnabled,
          authEnabled: user.authEnabled,
          hasBillingInfo: user.hasBillingInfo,
          totalPoints: user.totalPoints,
          totalRedemptions: user.totalRedemptions,
          openDisputes: user.openDisputes,
          subscriptionPlan: sub?['plan'] ?? user.subscriptionPlan,
          subscriptionStatus: sub?['status'] ?? user.subscriptionStatus,
          subscriptionStartDate: sub != null
              ? DateTime.tryParse((sub['subscribed_at'] ?? '').toString())
              : user.subscriptionStartDate,
          subscriptionRenewalDate: sub != null
              ? DateTime.tryParse((sub['renewal_date'] ?? '').toString())
              : user.subscriptionRenewalDate,
          benefits: ben?['benefits'] is List ? List<String>.from((ben!['benefits'] as List).whereType<String>()) : user.benefits,
          transactions: txn,
          kycStatus: kyc?['status'] ?? user.kycStatus,
          kycSubmittedAt: kyc != null ? DateTime.tryParse((kyc['submitted_at'] ?? '').toString()) : user.kycSubmittedAt,
          kycApprovedAt: kyc != null ? DateTime.tryParse((kyc['approved_at'] ?? '').toString()) : user.kycApprovedAt,
          kycRejectionReason: kyc?['rejection_reason'] ?? user.kycRejectionReason,
          deactivationStatus: user.deactivationStatus,
          deactivationDate: user.deactivationDate,
        );
        selectedUser.value = mergedUser;
      }
      auditLog.assignAll(log);
      if (sub != null) userSubscription.addAll(sub);
      if (ben != null) userBenefits.addAll(ben);
      userTransactions.assignAll(txn);
      if (kyc != null) userKyc.addAll(kyc);
    } catch (_) {} finally {
      isLoadingUser.value = false;
    }
  }

  Future<void> suspendSelectedUser(String reason) async {
    final user = selectedUser.value;
    if (user == null || isSuspending.value) return;
    isSuspending.value = true;
    try {
      final ok = await _repo.suspendUser(user.id, reason: reason);
      if (ok) {
        await selectUser(user.id);
        CustomSnackBar.showCustomSnackBar(
          title: 'Cuenta suspendida',
          message: 'La cuenta fue suspendida correctamente.',
        );
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error', message: 'No se pudo suspender la cuenta.');
    } finally {
      isSuspending.value = false;
    }
  }

  Future<void> revealDocument(String reason) async {
    final user = selectedUser.value;
    if (user == null) return;
    try {
      final result = await _repo.revealUserDocument(user.id, reason: reason);
      final doc = result['document_number']?.toString() ?? '';
      if (doc.isNotEmpty) {
        revealedDocument.value = doc;
        await selectUser(user.id);
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {}
  }

  Future<void> editSelectedUser(Map<String, dynamic> payload) async {
    final user = selectedUser.value;
    if (user == null) return;
    try {
      final updated = await _repo.editAdminUser(user.id, payload);
      if (updated != null) {
        selectedUser.value = updated;
        CustomSnackBar.showCustomSnackBar(
          title: 'Perfil actualizado',
          message: 'Los cambios se guardaron correctamente.',
        );
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error', message: 'No se pudo actualizar el perfil.');
    }
  }

  Future<void> markAsAudited(String userId, String notes) async {
    try {
      final ok = await _repo.auditUser(userId, notes: notes);
      if (ok) {
        await selectUser(userId); // refresca audit log
        CustomSnackBar.showCustomSnackBar(
          title: 'Auditado',
          message: 'El usuario fue marcado como revisado.',
        );
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {}
  }

  Future<void> restartUserKyc(String userId, {String? reason}) async {
    try {
      final result = await _repo.updateUserKyc(userId, action: 'restart', reason: reason);
      if (result != null) {
        await selectUser(userId);
        CustomSnackBar.showCustomSnackBar(
          title: 'KYC Reiniciado',
          message: 'El proceso de KYC fue reiniciado correctamente.',
        );
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {}
  }

  Future<void> approveUserKyc(String userId, {String? reason}) async {
    try {
      final result = await _repo.updateUserKyc(userId, action: 'approve', reason: reason);
      if (result != null) {
        await selectUser(userId);
        CustomSnackBar.showCustomSnackBar(
          title: 'KYC Aprobado',
          message: 'El KYC del usuario fue aprobado.',
        );
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {}
  }

  Future<void> rejectUserKyc(String userId, {required String reason}) async {
    try {
      final result = await _repo.updateUserKyc(userId, action: 'reject', reason: reason);
      if (result != null) {
        await selectUser(userId);
        CustomSnackBar.showCustomSnackBar(
          title: 'KYC Rechazado',
          message: 'El KYC del usuario fue rechazado.',
        );
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {}
  }

  Future<void> deactivateUser(String userId, {required String reason}) async {
    try {
      final ok = await _repo.updateUserDeactivation(userId, action: 'soft_delete', reason: reason);
      if (ok) {
        await selectUser(userId);
        CustomSnackBar.showCustomSnackBar(
          title: 'Cuenta Desactivada',
          message: 'La cuenta del usuario fue desactivada.',
        );
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {}
  }

  Future<void> restoreUser(String userId, {String? reason}) async {
    try {
      final ok = await _repo.updateUserDeactivation(userId, action: 'restore', reason: reason);
      if (ok) {
        await selectUser(userId);
        CustomSnackBar.showCustomSnackBar(
          title: 'Cuenta Restaurada',
          message: 'La cuenta del usuario fue restaurada.',
        );
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {}
  }

  void dismissAlert(String id) =>
      criticalAlerts.removeWhere((a) => a['id']?.toString() == id);

  Future<void> refreshAuditLog() => _loadFromBackend();

  // ──────────── LEGAL CONSENTS & RGPD ────────────
  Future<void> loadLegalConsents({String? status, int page = 1}) async {
    try {
      isLoadingLegal.value = true;
      final results = await Future.wait([
        _repo.fetchLegalConsents(status: status, page: page, pageSize: 50),
        _repo.fetchLegalStats(),
        _repo.fetchLegalVersions(page: 1, pageSize: 50),
        _repo.fetchDataSubjectRequests(status: 'pending', page: 1, pageSize: 50),
      ]);

      final consents = results[0] as Paginated<LegalConsentModel>;
      final stats = results[1] as LegalStatsResponse;
      final versions = results[2] as Paginated<LegalVersionModel>;
      final requests = results[3] as Paginated<DataSubjectRequestModel>;

      legalConsents.assignAll(consents.data);
      legalStats.value = stats;
      legalVersions.assignAll(versions.data);
      dataSubjectRequests.assignAll(requests.data);
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    } finally {
      isLoadingLegal.value = false;
    }
  }

  Future<void> updateLegalConsent(String consentId, {required String action, String? reason}) async {
    try {
      await _repo.updateLegalConsent(consentId, action: action, reason: reason);
      CustomSnackBar.showCustomSnackBar(title: 'Legal', message: 'Consentimiento actualizado');
      await loadLegalConsents();
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    }
  }

  Future<void> updateDataSubjectRequest(String requestId, {required String action, String? reason}) async {
    try {
      await _repo.updateDataSubjectRequest(requestId, action: action, reason: reason);
      CustomSnackBar.showCustomSnackBar(title: 'RGPD', message: 'Solicitud actualizada');
      await loadLegalConsents();
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    }
  }

  Future<void> activateLegalDocument(String documentId) async {
    try {
      await _repo.updateLegalDocument(documentId, isActive: true);
      CustomSnackBar.showCustomSnackBar(title: 'Legal', message: 'Documento activado');
      await loadLegalConsents();
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    }
  }

  Future<void> createLegalDocument({
    required String documentType,
    required String version,
    required String title,
    required String summary,
    bool activateImmediately = false,
  }) async {
    try {
      await _repo.createLegalDocument(
        documentType: documentType,
        version: version,
        title: title,
        summary: summary,
        activateImmediately: activateImmediately,
      );
      CustomSnackBar.showCustomSnackBar(title: 'Legal', message: 'Documento creado');
      await loadLegalConsents();
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    }
  }

  // ──────────── STORE CONFIGURATION ────────────

  Future<void> loadStoreDetail(String storeId,
      {StoreModel? knownStore}) async {
    isLoadingStore.value = true;
    // Show the known store immediately while fetching fresh data
    if (knownStore != null) selectedStore.value = knownStore;
    selectedStoreUsers.clear();
    selectedStorePinMasked.value = '';
    try {
      final results = await Future.wait([
        _repo.adminGetStoreDetail(storeId)
            .catchError((_) => null as StoreModel?),
        _repo.fetchStoreUsers(storeId)
            .catchError((_) => <StoreUserModel>[]),
        _repo.fetchStorePIN(storeId).catchError((_) => <String, dynamic>{}),
      ]);
      final store = results[0] as StoreModel?;
      final users = results[1] as List<StoreUserModel>;
      final pinInfo = results[2] as Map<String, dynamic>;
      if (store != null) selectedStore.value = store;
      // Fallback: filter from the global storeUsers list if API returned nothing
      final effectiveUsers = users.isNotEmpty
          ? users
          : storeUsers.where((u) => u.storeId == storeId).toList();
      selectedStoreUsers.assignAll(effectiveUsers);
      selectedStorePinMasked.value =
          (pinInfo['pin_masked'] ?? pinInfo['pin'] ?? '****').toString();
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    } finally {
      isLoadingStore.value = false;
    }
  }

  Future<void> saveStoreChanges(String storeId, Map<String, dynamic> payload) async {
    isSavingStore.value = true;
    try {
      final updated = await _repo.adminUpdateStore(storeId, payload);
      if (updated != null) {
        selectedStore.value = updated;
        final idx = stores.indexWhere((s) => s.id == storeId);
        if (idx != -1) stores[idx] = updated;
        CustomSnackBar.showCustomSnackBar(
          title: 'Guardado', message: 'Configuración actualizada correctamente.');
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    } finally {
      isSavingStore.value = false;
    }
  }

  Future<void> inviteUserToSelectedStore(
      String storeId, String email, String role) async {
    try {
      await _repo.inviteStoreUser(storeId, email, role);
      CustomSnackBar.showCustomSnackBar(
          title: 'Invitación enviada', message: '$email fue invitado como $role.');
      await loadStoreDetail(storeId);
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    }
  }

  Future<void> removeUserFromSelectedStore(
      String storeId, String userId) async {
    try {
      await _repo.removeStoreUser(storeId, userId);
      selectedStoreUsers.removeWhere((u) => u.id == userId);
      CustomSnackBar.showCustomSnackBar(
          title: 'Usuario eliminado', message: 'El usuario fue removido de la tienda.');
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {}
  }

  Future<void> changeUserRoleInStore(
      String storeId, String userId, String role) async {
    try {
      await _repo.updateStoreUserRole(storeId, userId, role);
      await loadStoreDetail(storeId);
      CustomSnackBar.showCustomSnackBar(title: 'Rol actualizado', message: 'El rol fue cambiado.');
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {}
  }

  Future<void> regenerateSelectedStorePIN(String storeId) async {
    try {
      final result = await _repo.regenerateStorePIN(storeId);
      final pin = result['pin']?.toString() ?? '';
      final masked = result['pin_masked']?.toString() ?? '****';
      selectedStorePinMasked.value = masked;
      if (pin.isNotEmpty) {
        CustomSnackBar.showCustomSnackBar(
            title: 'PIN regenerado', message: 'Nuevo PIN: $pin (guárdalo, no se mostrará de nuevo).');
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {}
  }

  Future<void> toggleStore2FA(String storeId, {required bool enabled}) async {
    try {
      await _repo.updateStoreSecurity(storeId, twoFactorEnabled: enabled);
      if (selectedStore.value != null) {
        selectedStore.refresh();
      }
      CustomSnackBar.showCustomSnackBar(
          title: '2FA ${enabled ? "activado" : "desactivado"}',
          message: 'El doble factor de autenticación fue ${enabled ? "activado" : "desactivado"}.');
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (_) {}
  }

  Future<String?> uploadSelectedStoreBanner(String storeId, dynamic file) async {
    try {
      return await _repo.uploadStoreBanner(storeId, file);
    } catch (_) { return null; }
  }

  Future<String?> uploadSelectedStoreLogo(String storeId, dynamic file) async {
    try {
      return await _repo.uploadStoreLogo(storeId, file);
    } catch (_) { return null; }
  }

  // ──────────── KYBC COMPLIANCE ────────────

  Future<void> loadKybcData({String? status}) async {
    isLoadingKybc.value = true;
    try {
      final tab = kycQueueTab.value == 0 ? 'pending' : 'in_review';
      final results = await Future.wait([
        _repo.fetchKycStats(),
        _repo.fetchKycQueue(status: status ?? tab, page: 1, pageSize: 30),
      ]);
      kybcStats.value = results[0] as KybcStatsModel;
      kycQueue.assignAll((results[1] as Paginated<AdminUserModel>).data);
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    } finally {
      isLoadingKybc.value = false;
    }
  }

  Future<void> loadKycQueueTab(int tabIndex) async {
    kycQueueTab.value = tabIndex;
    final status = tabIndex == 0 ? 'pending' : 'in_review';
    try {
      final page = await _repo.fetchKycQueue(status: status, page: 1, pageSize: 30);
      kycQueue.assignAll(page.data);
    } catch (_) {}
  }

  Future<void> selectKycUser(AdminUserModel user) async {
    selectedKycUser.value = user;
    complianceHistory.clear();
    try {
      final results = await Future.wait([
        _repo.fetchUserKyc(user.id),
        _repo.fetchComplianceHistory(user.id),
      ]);
      final kyc = results[0] as Map<String, dynamic>?;
      final history = results[1] as List<Map<String, dynamic>>;
      if (kyc != null) userKyc.assignAll(kyc);
      complianceHistory.assignAll(history);
    } catch (_) {}
  }

  Future<void> executeComplianceAction(
      String userId, {
      required String action,
      String? reason,
      String? notes,
      }) async {
    if (isExecutingAction.value) return;
    isExecutingAction.value = true;
    try {
      await _repo.executeComplianceAction(userId,
          action: action, reason: reason, notes: notes);
      CustomSnackBar.showCustomSnackBar(
          title: 'Acción ejecutada',
          message: 'La acción de cumplimiento fue registrada.');
      await loadKybcData();
      if (selectedKycUser.value?.id == userId) {
        final updated = kycQueue.firstWhereOrNull((u) => u.id == userId);
        if (updated != null) await selectKycUser(updated);
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    } finally {
      isExecutingAction.value = false;
    }
  }

  // ──────────── POLÍTICAS SENSIBLES ────────────

  Future<void> loadSensitivePolicies() async {
    isLoadingPolicies.value = true;
    try {
      final results = await Future.wait([
        _repo.fetchSensitivePolicies(),
        _repo.fetchSensitivePoliciesStats(),
      ]);
      final policies = results[0] as List<SensitivePolicyModel>;
      final stats    = results[1] as Map<String, dynamic>;
      sensitivePolicies.assignAll(policies);
      policiesActive.value =
          _parseInt(stats['active_count'] ?? stats['active'] ?? stats['documentos_activos']) ??
          policies.where((p) => p.status == 'active').length;
      policiesPending.value =
          _parseInt(stats['pending_count'] ?? stats['pending'] ?? stats['pendientes']) ??
          policies.where((p) => p.status == 'pending').length;
      final cov = _parseDouble(stats['coverage_pct'] ?? stats['coverage'] ?? stats['cobertura']);
      policiesCoverage.value = cov ?? 100.0;
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    } finally {
      isLoadingPolicies.value = false;
    }
  }

  Future<void> updateSensitivePolicyCtrl(
      String id, Map<String, dynamic> payload) async {
    try {
      final updated = await _repo.updateSensitivePolicy(id, payload);
      if (updated != null) {
        final idx = sensitivePolicies.indexWhere((p) => p.id == id);
        if (idx != -1) sensitivePolicies[idx] = updated;
        CustomSnackBar.showCustomSnackBar(
            title: 'Política actualizada',
            message: 'Los cambios se guardaron correctamente.');
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    }
  }

  Future<void> createSensitivePolicyCtrl(Map<String, dynamic> payload) async {
    try {
      final created = await _repo.createSensitivePolicy(payload);
      if (created != null) {
        sensitivePolicies.insert(0, created);
        policiesActive.value++;
        CustomSnackBar.showCustomSnackBar(
            title: 'Política creada', message: 'La política fue creada correctamente.');
      }
    } on ApiException catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
    }
  }

// ──────────── STRIPE DISPUTES & REFUNDS ────────────

Future<void> loadStripeDisputes({String? status}) async {
  isLoadingDisputes.value = true;
  try {
    final results = await Future.wait([
      _repo.fetchStripeDisputes(status: status),
      _repo.fetchStripeDisputeStats(),
    ]);
    stripeDisputes.assignAll(results[0] as List<StripeDisputeModel>);
    stripeDisputeStats.value = results[1] as StripeDisputeStats;
  } catch (e) {
    CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error', message: e.toString());
  } finally {
    isLoadingDisputes.value = false;
  }
}

Future<void> performDisputeAction(String id,
    {required String action, String? notes}) async {
  try {
    await _repo.performStripeDisputeAction(id, action: action, notes: notes);
    CustomSnackBar.showCustomSnackBar(
        title: 'Disputa', message: 'Acción ejecutada correctamente.');
    await loadStripeDisputes();
  } on ApiException catch (e) {
    CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.message);
  } catch (e) {
    CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: e.toString());
  }
}

// ── Campañas Promocionales ────────────────────────────────────────────

final RxList<Map<String, dynamic>> campaigns = <Map<String, dynamic>>[].obs;

/// Crea una nueva campaña y la agrega a la lista.
/// Podés extender esto para persistir en backend.
Future<void> createCampaign(Map<String, dynamic> payload) async {
  campaigns.add(payload);
  CustomSnackBar.showCustomSnackBar(
    title: 'Campaña creada',
    message: 'La campaña se agregó correctamente.',
  );
}

/// Elimina una campaña por nombre.
/// Podés extender esto para borrar en backend.
Future<void> deleteCampaignByName(String name) async {
  campaigns.removeWhere((c) => c['name'] == name);
  CustomSnackBar.showCustomSnackBar(
    title: 'Campaña eliminada',
    message: 'La campaña fue eliminada correctamente.',
  );
}
}