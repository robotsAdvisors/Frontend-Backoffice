/// Configuracion centralizada de la API del backend Django (Letdem).
///
/// Cambiar [baseUrl] segun el entorno:
/// - Desarrollo local (web):     http://127.0.0.1:8000
/// - Emulador Android:           http://10.0.2.2:8000
/// - Dispositivo fisico LAN:     http://<IP-de-tu-PC>:8000
/// - Produccion:                 https://api.letdem.com
class ApiConfig {
  ApiConfig._();

  /// Base host del backend (sin /api/v1).
  static const String baseUrl = String.fromEnvironment(
    'LETDEM_API_BASE_URL',
    defaultValue: 'https://api.letdem.net',
  );

  /// Prefijo de la API REST.
  static const String apiPrefix = '/api/v1';

  /// URL completa base para las peticiones.
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  /// Convierte una URL de media relativa (`/media/x.jpg`) en absoluta usando el
  /// host del backend. Deja intactas las que ya son absolutas (`http...`).
  /// Necesario en web: `NetworkImage('/media/x')` resolvería contra el origen
  /// del navegador (localhost) en vez del backend → 404.
  static String absoluteMedia(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return url.startsWith('/') ? '$baseUrl$url' : '$baseUrl/$url';
  }

  // ---- Endpoints ----
  // Auth
  // NOTE: the backend (DRF) defines all `/auth/...` routes WITH a trailing
  // slash, and returns 405/404 without it. The `/users/me...` routes are
  // defined WITHOUT a trailing slash, so those stay as-is.
  static const String authLogin = '/auth/login/';
  static const String authSignup = '/auth/signup/';
  static const String authSocialLogin = '/auth/social-login/';
  static const String authSocialSignup = '/auth/social-signup/';
  static const String authVerifyEmail = '/auth/account-verification/validate/';
  static const String authResetPassword = '/auth/password-reset/';
  static const String authSetPassword = '/auth/set-password/';
  static const String authChangePassword = '/users/me/change-password';
  static const String tokenRefresh = '/auth/token/refresh/';

  // Profile
  static const String me = '/users/me';
  static const String mePreferences = '/users/me/preferences/';

  // Marketplace - catalogo publico
  static const String categories = '/marketplace/categories/';
  static const String stores = '/marketplace/stores/';
  static const String products = '/marketplace/products/';

  // Marketplace - autenticado
  static const String redemptionCodes = '/marketplace/redemption-codes/';
  // Canjes del COMERCIO (backoffice de tienda). La genérica de arriba está
  // scopeada al usuario: sirve para el historial del cliente, NO para la tienda.
  static const String storeRedemptionCodes = '/marketplace/stores/redemption-codes/';
  static const String redemptionCodesPending = '/marketplace/redemption-codes/pending/';
  static const String redemptionCodesCreateOnline = '/marketplace/redemption-codes/online/';
  // La validación de un código la hace la tienda, y cuelga de `stores/`.
  static const String redemptionCodesValidate  = '/marketplace/stores/redemption-codes/validation/';
  // Entrega (ST-CJ-03): segundo paso del mostrador. Aquí el backend consume
  // los puntos bloqueados y el código pasa a DELIVERED.
  static String redemptionCodeDelivery(String id)        => '/marketplace/stores/redemption-codes/$id/delivery/';
  static const String redemptionCodesPreview   = '/marketplace/redemption-codes/preview/';
  // La incidencia del mostrador cuelga de `stores/`: es la tienda quien la
  // registra sobre un canje suyo (DG-07), no el usuario sobre el propio.
  static String redemptionCodeIncident(String id)        => '/marketplace/stores/redemption-codes/$id/incident/';
  static String redemptionCodeInitiatePayment(String code) => '/marketplace/redemption-codes/$code/payment-intent/';
  static const String orders      = '/marketplace/orders/';
  static const String storeOrders = '/marketplace/stores/orders/';
  static const String purchaseWithRedeem = '/marketplace/purchases/with-redemption/';
  static const String purchaseWithoutRedeem = '/marketplace/purchases/without-redemption/';

  // Marketplace - admin
  static const String adminCategories    = '/marketplace/admin/categories/';
  static const String adminStores        = '/marketplace/admin/stores/';
  static const String adminProducts      = '/marketplace/admin/products/';
  static const String adminStats         = '/marketplace/admin/stats/';
  static const String adminInventoryStats = '/marketplace/admin/inventory/stats/';

  // Marketplace - backoffice dashboard (nuevos endpoints)
  static const String adminDashboardStats = '/marketplace/admin/dashboard/stats/';
  static const String adminAlerts         = '/marketplace/admin/alerts/';
  static const String adminAuditLog       = '/marketplace/admin/audit-log/';
  static const String adminSystemHealth   = '/marketplace/admin/system-health/';
  static const String adminDomainStats    = '/marketplace/admin/domain-stats/';

  // Marketplace - analytics
  static const String analyticsRedemptionCodesDaily    = '/marketplace/analytics/redemption-codes/daily/';
  static const String analyticsSummary          = '/marketplace/analytics/summary/';
  static const String analyticsRedemptionCodesByStatus = '/marketplace/analytics/redemption-codes/by-status/';
  static const String analyticsTopRedeemed      = '/marketplace/analytics/products/top-redeemed/';

  // Marketplace - store detail, activity & management
  static String storeDetail(String id) => '/marketplace/stores/$id/';
  static String storeSettings(String id) => '/marketplace/stores/$id/settings/';
  static String storeActivity(String id) => '/marketplace/stores/$id/activity/';
  static String storeMonthlyGoal(String id)  => '/marketplace/stores/$id/monthly-goal/';
  static String storeBannerUpload(String id) => '/marketplace/stores/$id/banner/';
  static String storeLogoUpload(String id)   => '/marketplace/stores/$id/logo/';

  // Location / Geocoding
  static const String locationReverseGeocode = '/location/reverse-geocode/';
  static const String locationGeocode        = '/location/geocode/';
  static String storeReviews(String id)     => '/marketplace/stores/$id/reviews/';
  static String storeReviewStats(String id) => '/marketplace/stores/$id/reviews/stats/';
  static String reviewDetail(String id)     => '/marketplace/reviews/$id/';
  static String reviewReply(String id)      => '/marketplace/reviews/$id/reply/';
  static String reviewReport(String id)     => '/marketplace/reviews/$id/report/';
  static String reviewHide(String id)       => '/marketplace/reviews/$id/visibility/';
  static String storePIN(String id) => '/marketplace/stores/$id/pin/';
  static String storePINRegenerate(String id) => '/marketplace/stores/$id/pin/regenerate/';
  static String storeSecurityLog(String id) => '/marketplace/stores/$id/security-log/';

  // Auth — 2FA & Roles
  static const String twoFactorSetup = '/auth/2fa/setup/';
  static const String twoFactorVerify = '/auth/2fa/verify/';
  static const String twoFactorBackupMethod = '/auth/2fa/backup-method/';
  static const String authRoles = '/auth/roles/';

  // Backoffice — GDPR / RGPD  (/v1/admin/gdpr/...)
  static const String gdprRequests = '/admin/gdpr/requests/';
  static const String gdprStats    = '/admin/gdpr/requests/stats/';
  static const String gdprExport   = '/admin/gdpr/requests/export/';
  static const String gdprFormats  = '/admin/gdpr/formats/';
  static String gdprRequestDetail(String id) => '/admin/gdpr/requests/$id/';

  // Backoffice — Support Tickets
  // Cuelgan del urlconf del marketplace (`/marketplace/admin/…`), no del de
  // accounts (`/admin/…`), que es donde viven usuarios, KYC, GDPR y legal.
  static const String adminTickets          = '/marketplace/admin/tickets/';
  static const String adminTicketsCreate    = '/marketplace/admin/tickets/';
  static const String adminTicketCategories = '/marketplace/admin/ticket-categories/';
  static const String adminAgents           = '/marketplace/admin/agents/';
  // El detalle (GET/PATCH) YA existe: AdminTicketDetailView. Escalar, cerrar y
  // reasignar se hacen por ese PATCH (status / assigned_to), no por rutas de
  // acción dedicadas. `messages/` sigue SIN exponerse: enviar mensaje da 404
  // hasta que el backend lo implemente (la UI lo degrada a "no disponible").
  static String adminTicketDetail(String id)   => '/marketplace/admin/tickets/$id/';
  static String adminTicketMessages(String id) => '/marketplace/admin/tickets/$id/messages/';

  // Backoffice — Admin User Management
  static const String adminUsers = '/admin/users/';
  static String adminUserDetail(String id) => '/admin/users/$id/';
  static String adminUserAuditLog(String id) => '/admin/users/$id/audit-log/';
  static String adminUserSuspend(String id) => '/admin/users/$id/suspend/';
  static String adminUserRevealDoc(String id) => '/admin/users/$id/reveal-document/';
  static String adminUserAudit(String id) => '/admin/users/$id/audit/';
  static String adminUserSubscription(String id) => '/admin/users/$id/subscription/';
  static String adminUserBenefits(String id) => '/admin/users/$id/benefits/';
  static String adminUserTransactions(String id) => '/admin/users/$id/transactions/';
  static String adminUserKyc(String id) => '/admin/users/$id/kyc/';
  static String adminUserDeactivation(String id) => '/admin/users/$id/deactivation/';

  // Backoffice — Antifraude (points_admin: /api/v1/admin/...)
  // BG-06: cola de contribuciones sospechosas + decisión del moderador.
  static const String moderationQueue = '/admin/moderation/contributions/';
  static String moderationDecision(String kind, String id) =>
      '/admin/moderation/contributions/$kind/$id/';
  // BG-07: umbrales antifraude (CRUD del Super Admin).
  static const String antifraudRules = '/admin/antifraud-rules/';
  static String antifraudRuleDetail(int id) => '/admin/antifraud-rules/$id/';

  // Backoffice — Admin Store Management
  static String adminStoreDetail(String id) => '/marketplace/admin/stores/$id/';

  // Backoffice — KYBC Compliance
  static const String adminKycStats   = '/admin/kyc/stats/';
  static const String adminKycQueue   = '/admin/kyc/queue/';
  static String adminUserComplianceAction(String id) => '/admin/users/$id/kyc/action/';
  static String adminUserComplianceHistory(String id) => '/admin/users/$id/compliance/history/';

  // Backoffice — Políticas Sensibles
  // OJO: sin contraparte en el backend (no hay ningún urlconf `policies/`).
  static const String adminPolicies      = '/admin/policies/';
  static const String adminPoliciesStats = '/admin/policies/stats/';
  static String adminPolicyDetail(String id) => '/admin/policies/$id/';

  // Backoffice — Legal & Consents
  static const String adminLegalConsents = '/admin/legal/consents/';
  static String adminLegalConsentDetail(String id) => '/admin/legal/consents/$id/';
  static const String adminLegalDocuments = '/admin/legal/documents/';
  static const String adminLegalStats = '/admin/legal/consents/stats/';
  static String adminLegalConsentAction(String id) => '/admin/legal/consents/$id/action/';
  // Product image upload
  static const String adminProductUploadImage =
      '/marketplace/admin/products/image/';
  static const String adminProductExport =
      '/marketplace/admin/products/export/';

  // Users: GET list + POST invite share the same URL
  static String storeUsers(String id) => '/marketplace/stores/$id/users/';
  static String storeUserDetail(String storeId, String userId) =>
      '/marketplace/stores/$storeId/users/$userId/';
  static String storeRolesPermissions(String id) => '/marketplace/stores/$id/roles/';
  static String storeChangePIN(String id) => '/marketplace/stores/$id/pin/change/';
  static String storeSecurity(String id) => '/marketplace/stores/$id/security/';

  // Withdrawals — viven en `credits/`, no en `wallet/` (que solo sirve la
  // tarjeta virtual).
  static const String withdrawals = '/credits/withdrawals/';
  static const String withdrawalsConfig = '/credits/withdrawals/config/';

  // Virtual Card
  static const String virtualCard = '/wallet/virtual-card/';

  // Backoffice — expedientes de disputa y reembolsos (BG-04/BG-05).
  // Cuelgan de `/admin/` (points_admin), no de `/admin/stripe/`, que no existe.
  // ⚠️ La respuesta separa el estado del EXPEDIENTE (`case`) del estado en
  // Stripe (`stripe`), en dos bloques; StripeDisputeModel aún los lee planos.
  static const String adminStripeDisputes      = '/admin/disputes/';
  static const String adminStripeDisputeStats  = '/admin/disputes/stats/';
  static String adminStripeDisputeDetail(String id) => '/admin/disputes/$id/';
  static String adminStripeDisputeAction(String id) => '/admin/disputes/$id/action/';
  static const String adminStripeRefunds       = '/admin/refunds/';

  // Backoffice — Campañas promocionales (superadmin / IsSuperAdmin).
  // OJO: cuelgan de `/admin/` (points_admin), NO de `/marketplace/admin/`
  // (que da 404). El listado es un array pelado (sin results/meta).
  static const String adminCampaigns = '/admin/campaigns/';
  static String adminCampaignDetail(String id)  => '/admin/campaigns/$id/';
  // Subida del banner (multipart, campo `image`). Necesita el id → primero se
  // crea la campaña y con el id devuelto se sube la imagen.
  static String adminCampaignImage(String id)   => '/admin/campaigns/$id/image/';
  // Analítica de rendimiento de la campaña (puntos, alcance, presupuesto).
  static String adminCampaignImpact(String id)  => '/admin/campaigns/$id/impact/';
  // Vista previa: mismo serializer que ve el usuario/tienda en el marketplace.
  static String adminCampaignPreview(String id) => '/admin/campaigns/$id/preview/';
}
