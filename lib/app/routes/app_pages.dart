import 'package:get/get.dart';

import '../modules/base/bindings/base_binding.dart';
import '../modules/base/views/base_view.dart';
import '../modules/calendar/bindings/calendar_binding.dart';
import '../modules/calendar/views/calendar_view.dart';
import '../modules/cart/bindings/cart_binding.dart';
import '../modules/cart/views/cart_view.dart';
import '../modules/category/bindings/category_binding.dart';
import '../modules/category/views/category_view.dart';
import '../modules/customer_history/bindings/customer_history_binding.dart';
import '../modules/customer_history/views/customer_history_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/product_details/bindings/product_details_binding.dart';
import '../modules/product_details/views/product_details_view.dart';
import '../modules/products/bindings/products_binding.dart';
import '../modules/products/views/products_view.dart';
import '../modules/login/views/forgot_password_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/change_password_view.dart';
import '../modules/profile/views/preferences_view.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/stores/bindings/stores_binding.dart';
import '../modules/stores/views/stores_view.dart';
import '../modules/welcome/bindings/welcome_binding.dart';
import '../modules/welcome/views/welcome_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/admin/bindings/admin_binding.dart';
import '../modules/admin/views/add_product_view.dart';
import '../modules/admin/views/analytics_view.dart';
import '../modules/admin/views/admin_view.dart';
import '../modules/admin/views/reviews_view.dart';
import '../modules/admin/views/redemption_code_history_view.dart';
import '../modules/admin/views/admin_settings_view.dart';
import '../modules/admin/views/inventario_view.dart';
import '../modules/admin/views/premios_view.dart';
import '../modules/general_admin/bindings/general_admin_binding.dart';
import '../modules/general_admin/bindings/gdpr_binding.dart';
import '../modules/general_admin/bindings/support_binding.dart';
import '../modules/general_admin/views/general_admin_view.dart';
import '../modules/general_admin/views/gdpr_requests_view.dart';
import '../modules/general_admin/views/support_tickets_view.dart';
import '../modules/general_admin/views/user_detail_view.dart';
import '../modules/general_admin/views/store_config_view.dart';
import '../modules/general_admin/views/kybc_view.dart';
import '../modules/general_admin/views/sensitive_policies_view.dart';
import '../modules/general_admin/views/legal_consents_view.dart';
import '../modules/general_admin/views/stripe_disputes_view.dart';
import '../modules/admin/views/empleados_view.dart';
import '../modules/admin/views/seguridad_view.dart';
import '../modules/admin/views/incidencias_view.dart';
import '../modules/admin/views/confirmar_entrega_view.dart';
import '../modules/general_admin/views/comercios_view.dart';
import '../modules/general_admin/views/campaigns_view.dart';
import '../modules/antifraude/antifraude_screen.dart';
import '../modules/antifraude/antifraude_detail.dart';
import '../modules/antifraude/antifraude_settings.dart';
import '../modules/antifraude/bindings/antifraude_binding.dart';
import '../modules/withdrawals/bindings/withdrawals_binding.dart';
import '../modules/withdrawals/views/withdrawals_view.dart';
import '../modules/virtual_card/bindings/virtual_card_binding.dart';
import '../modules/virtual_card/views/virtual_card_view.dart';

// Import de la nueva vista
import '../modules/general_admin/views/publicaciones_page.dart';
import '../modules/general_admin/views/publicacion_detail_page.dart';

// Wallet de puntos
import '../modules/general_admin/views/wallet_points_view.dart';
import '../modules/general_admin/bindings/wallet_points_binding.dart';

// Historial de movimientos
import '../modules/general_admin/views/movimientos_view.dart';
import '../modules/general_admin/bindings/movimientos_binding.dart';

// Configuración del programa de puntos
import '../modules/general_admin/views/configuracion_puntos_view.dart';
import '../modules/general_admin/bindings/configuracion_puntos_binding.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(name: _Paths.SPLASH, page: () => const SplashView(), binding: SplashBinding()),
    GetPage(name: _Paths.WELCOME, page: () => const WelcomeView(), binding: WelcomeBinding()),
    GetPage(name: _Paths.LOGIN, page: () => const LoginView(), binding: LoginBinding()),
    GetPage(name: _Paths.ADMIN, page: () => const AdminView(), binding: AdminBinding()),
    GetPage(name: _Paths.REVIEWS, page: () => const ReviewsView(), binding: AdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.REDEMPTION_CODE_HISTORY, page: () => const RedemptionCodeHistoryView(), binding: AdminBinding()),
    GetPage(name: _Paths.ADD_PRODUCT, page: () => const AddProductView(), binding: AdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.ANALYTICS, page: () => const AnalyticsView(), binding: AdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.ADMIN_SETTINGS, page: () => const AdminSettingsView(), binding: AdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.INVENTARIO, page: () => const InventarioView(), binding: AdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.PREMIOS, page: () => const PremiosView(), binding: AdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.GENERAL_ADMIN, page: () => const GeneralAdminView(), binding: GeneralAdminBinding()),
    GetPage(name: _Paths.ADMIN_USER_DETAIL, page: () => const UserDetailView(), binding: GeneralAdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.GDPR_REQUESTS, page: () => const GdprRequestsView(), binding: GdprBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.SUPPORT_TICKETS, page: () => const SupportTicketsView(), binding: SupportBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.STORE_CONFIG, page: () => const StoreConfigView(), binding: GeneralAdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.KYBC, page: () => const KybcView(), binding: GeneralAdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.SENSITIVE_POLICIES, page: () => const SensitivePoliciesView(), binding: GeneralAdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.LEGAL_CONSENTS, page: () => const LegalConsentsView(), binding: GeneralAdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.STRIPE_DISPUTES, page: () => const StripeDisputesView(), binding: GeneralAdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.EMPLEADOS, page: () => const EmpleadosView(), binding: AdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.SEGURIDAD, page: () => const SeguridadView(), binding: AdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.INCIDENCIAS, page: () => const IncidenciasView(), binding: AdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.CONFIRMAR_ENTREGA, page: () => const ConfirmarEntregaView(), binding: AdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.COMERCIOS, page: () => const ComerciosView(), binding: GeneralAdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),
    GetPage(name: _Paths.CAMPAIGNS, page: () => const CampaignsView(), binding: GeneralAdminBinding(),
      transition: Transition.rightToLeft, transitionDuration: const Duration(milliseconds: 250)),

       // Antifraude
    GetPage(
      name: _Paths.ANTIFRAUDE,
      page: () => const AntifraudeScreen(),
      binding: AntifraudeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: _Paths.ANTIFRAUDE_DETAIL,
      page: () => const AntifraudeDetail(),
      binding: AntifraudeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: _Paths.ANTIFRAUDE_SETTINGS,
      page: () => const AntifraudeSettings(),
      binding: AntifraudeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    // Nueva ruta: Publicaciones de aparcamiento
    GetPage(
      name: _Paths.PUBLICACIONES,
      page: () => const PublicacionesPage(),
      binding: GeneralAdminBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: _Paths.PUBLICACION_DETAIL,
      page: () => const PublicacionDetailPage(id: 'demo'),
      binding: GeneralAdminBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    // Nueva ruta: Wallet de puntos
    GetPage(
      name: _Paths.WALLET_POINTS,
      page: () => const WalletPointsView(),
      binding: WalletPointsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    // Nueva ruta: Historial de movimientos
    GetPage(
      name: _Paths.MOVIMIENTOS,
      page: () => const MovimientosView(),
      binding: MovimientosBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    // Nueva ruta: Configuración del programa de puntos
    GetPage(
      name: _Paths.CONFIGURACION_PUNTOS,
      page: () => const ConfiguracionPuntosView(),
      binding: ConfiguracionPuntosBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
  ];
}
