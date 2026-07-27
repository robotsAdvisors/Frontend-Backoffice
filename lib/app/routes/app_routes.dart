part of 'app_pages.dart';
// DO NOT EDIT. This is code generated via package:get_cli/get_cli.dart

abstract class Routes {
  Routes._();
  static const SPLASH = _Paths.SPLASH;
  static const BASE = _Paths.BASE;
  static const HOME = _Paths.HOME;
  static const CART = _Paths.CART;
  static const PRODUCT_DETAILS = _Paths.PRODUCT_DETAILS;
  static const WELCOME = _Paths.WELCOME;
  static const LOGIN = _Paths.LOGIN;
  static const ADMIN = _Paths.ADMIN;
  static const GENERAL_ADMIN = _Paths.GENERAL_ADMIN;
  static const CATEGORY = _Paths.CATEGORY;
  static const CALENDAR = _Paths.CALENDAR;
  static const PROFILE = _Paths.PROFILE;
  static const PRODUCTS = _Paths.PRODUCTS;
  static const REDEMPTION_CODE_HISTORY = _Paths.REDEMPTION_CODE_HISTORY;
  static const CUSTOMER_HISTORY = _Paths.CUSTOMER_HISTORY;
  static const STORES = _Paths.STORES;
  static const ADD_PRODUCT = _Paths.ADD_PRODUCT;
  static const ANALYTICS = _Paths.ANALYTICS;
  static const PREFERENCES = _Paths.PREFERENCES;
  static const CHANGE_PASSWORD = _Paths.CHANGE_PASSWORD;
  static const FORGOT_PASSWORD = _Paths.FORGOT_PASSWORD;
  static const WITHDRAWALS = _Paths.WITHDRAWALS;
  static const VIRTUAL_CARD = _Paths.VIRTUAL_CARD;
  static const ADMIN_SETTINGS = _Paths.ADMIN_SETTINGS;
  static const INVENTARIO = _Paths.INVENTARIO;
  static const PREMIOS = _Paths.PREMIOS;
  static const ADMIN_USER_DETAIL = _Paths.ADMIN_USER_DETAIL;
  static const GDPR_REQUESTS    = _Paths.GDPR_REQUESTS;
  static const REVIEWS          = _Paths.REVIEWS;
  static const SUPPORT_TICKETS  = _Paths.SUPPORT_TICKETS;
  static const STORE_CONFIG     = _Paths.STORE_CONFIG;
  static const KYBC             = _Paths.KYBC;
  static const SENSITIVE_POLICIES = _Paths.SENSITIVE_POLICIES;
  static const LEGAL_CONSENTS     = _Paths.LEGAL_CONSENTS;
  static const STRIPE_DISPUTES    = _Paths.STRIPE_DISPUTES;
  static const EMPLEADOS          = _Paths.EMPLEADOS;
  static const SEGURIDAD          = _Paths.SEGURIDAD;
  static const INCIDENCIAS        = _Paths.INCIDENCIAS;
  static const CONFIRMAR_ENTREGA  = _Paths.CONFIRMAR_ENTREGA;
  static const COMERCIOS          = _Paths.COMERCIOS;
  static const CAMPAIGNS          = _Paths.CAMPAIGNS;
  static const ANTIFRAUDE          = _Paths.ANTIFRAUDE;
  static const ANTIFRAUDE_DETAIL   = _Paths.ANTIFRAUDE_DETAIL;
  static const ANTIFRAUDE_SETTINGS = _Paths.ANTIFRAUDE_SETTINGS;

  // Nuevas rutas para publicaciones
  static const PUBLICACIONES      = _Paths.PUBLICACIONES;
  static const PUBLICACION_DETAIL = _Paths.PUBLICACION_DETAIL;

  // Nueva ruta para Wallet de puntos
  static const WALLET_POINTS      = _Paths.WALLET_POINTS;

  // Nueva ruta para Historial de movimientos
  static const MOVIMIENTOS        = _Paths.MOVIMIENTOS;

  // Nueva ruta para Configuración del programa de puntos
  static const CONFIGURACION_PUNTOS = _Paths.CONFIGURACION_PUNTOS;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH = '/splash';
  static const WELCOME = '/welcome';
  static const LOGIN = '/login';
  static const ADMIN = '/admin';
  static const GENERAL_ADMIN = '/general-admin';
  static const BASE = '/base';
  static const HOME = '/home';
  static const CART = '/cart';
  static const PRODUCT_DETAILS = '/product-details';
  static const CATEGORY = '/category';
  static const CALENDAR = '/calendar';
  static const PROFILE = '/profile';
  static const PRODUCTS = '/products';
  static const REDEMPTION_CODE_HISTORY = '/redemption-code-history';
  static const CUSTOMER_HISTORY = '/customer-history';
  static const STORES = '/stores';
  static const ADD_PRODUCT = '/add-product';
  static const ANALYTICS = '/analytics';
  static const PREFERENCES = '/preferences';
  static const CHANGE_PASSWORD = '/change-password';
  static const FORGOT_PASSWORD = '/forgot-password';
  static const WITHDRAWALS = '/withdrawals';
  static const VIRTUAL_CARD = '/virtual-card';
  static const ADMIN_SETTINGS = '/admin-settings';
  static const INVENTARIO = '/inventario';
  static const PREMIOS = '/premios';
  static const ADMIN_USER_DETAIL = '/admin/users/detail';
  static const GDPR_REQUESTS    = '/backoffice/gdpr';
  static const REVIEWS          = '/reviews';
  static const SUPPORT_TICKETS  = '/backoffice/support';
  static const STORE_CONFIG     = '/backoffice/store-config';
  static const KYBC             = '/backoffice/kybc';
  static const SENSITIVE_POLICIES = '/backoffice/politicas';
  static const LEGAL_CONSENTS     = '/backoffice/legal';
  static const STRIPE_DISPUTES    = '/backoffice/pagos';
  static const EMPLEADOS          = '/admin/empleados';
  static const SEGURIDAD          = '/admin/seguridad';
  static const INCIDENCIAS        = '/admin/incidencias';
  static const CONFIRMAR_ENTREGA  = '/admin/confirmar-entrega';
  static const COMERCIOS          = '/backoffice/comercios';
  static const CAMPAIGNS          = '/backoffice/campaigns';
  static const ANTIFRAUDE          = '/antifraude';
  static const ANTIFRAUDE_DETAIL   = '/antifraude/detail';
  static const ANTIFRAUDE_SETTINGS = '/antifraude/settings';

  // Nuevos paths para publicaciones
  static const PUBLICACIONES      = '/backoffice/publicaciones';
  static const PUBLICACION_DETAIL = '/backoffice/publicaciones/detail';

  // Nuevo path para Wallet de puntos
  static const WALLET_POINTS      = '/backoffice/wallet';

  // Nuevo path para Historial de movimientos
  static const MOVIMIENTOS        = '/backoffice/movimientos';

  // Nuevo path para Configuración del programa de puntos
  static const CONFIGURACION_PUNTOS = '/backoffice/configuracion-puntos';
}
