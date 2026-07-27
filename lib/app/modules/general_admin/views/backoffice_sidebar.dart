import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/general_admin_controller.dart';

/// Sidebar única y consistente para TODO el backoffice del superadmin.
/// Uso: `const BackofficeSidebar(current: 'tiendas')`.
class BackofficeSidebar extends StatelessWidget {
  const BackofficeSidebar({super.key, required this.current});

  /// Clave del ítem activo: dashboard | tiendas | usuarios | campanias |
  /// moderacion | publicaciones | kybc | legal | gdpr | politicas | pagos | tickets | wallet | configuracion_puntos.
  final String current;

  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _ink = Color(0xFF1E1B4B);
  static const Color _border = Color(0xFFE5E7EB);

  static const List<_Nav> _items = [
    _Nav('dashboard', Icons.dashboard_outlined, 'Dashboard', Routes.GENERAL_ADMIN),
    _Nav('tiendas', Icons.store_outlined, 'Tiendas', Routes.COMERCIOS),
    _Nav('usuarios', Icons.people_outline, 'Usuarios', Routes.ADMIN_USER_DETAIL),
    _Nav('campanias', Icons.campaign_outlined, 'Campañas', Routes.CAMPAIGNS),
    _Nav('moderacion', Icons.flag_outlined, 'Moderación', Routes.ANTIFRAUDE),
    _Nav('publicaciones', Icons.local_parking, 'Publicaciones de aparcamiento', Routes.PUBLICACIONES),
    _Nav('kybc', Icons.verified_user_outlined, 'KYBC', Routes.KYBC),
    _Nav('legal', Icons.gavel_outlined, 'Legal', Routes.LEGAL_CONSENTS),
    _Nav('gdpr', Icons.privacy_tip_outlined, 'GDPR', Routes.GDPR_REQUESTS),
    _Nav('politicas', Icons.policy_outlined, 'Políticas', Routes.SENSITIVE_POLICIES),
    _Nav('pagos', Icons.payments_outlined, 'Pagos', Routes.STRIPE_DISPUTES),
    _Nav('tickets', Icons.support_agent_outlined, 'Tickets', Routes.SUPPORT_TICKETS),
    _Nav('wallet', Icons.account_balance_wallet_outlined, 'Wallet de puntos', Routes.WALLET_POINTS),
    _Nav('configuracion_puntos', Icons.settings_outlined, 'Configuración de puntos', Routes.CONFIGURACION_PUNTOS),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 4),
            child: Row(children: [
              Icon(Icons.rocket_launch_outlined, size: 18, color: _purple),
              SizedBox(width: 8),
              Text('Backoffice',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 46, bottom: 12),
            child: Text('Gestión Global',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          _userRow(),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _items.map(_navItem).toList(),
            ),
          ),
          const Divider(height: 1, color: _border),
          ListTile(
            dense: true,
            leading: const Icon(Icons.logout, size: 16, color: Colors.grey),
            title: const Text('Logout',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            onTap: () async {
              await AuthService.signOut();
              Get.offAllNamed(Routes.LOGIN);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _userRow() {
    Widget row(String name, String initials) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(children: [
            CircleAvatar(
                radius: 16,
                backgroundColor: _purpleLight,
                child: Text(initials,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _purple))),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  const Text('Admin',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ])),
          ]),
        );

    if (!Get.isRegistered<GeneralAdminController>()) {
      return row('Super Admin', 'SA');
    }
    final c = Get.find<GeneralAdminController>();
    return Obx(() => row(
          c.currentUserName.value.isEmpty ? 'Super Admin' : c.currentUserName.value,
          c.currentUserInitials.value.isEmpty ? 'SA' : c.currentUserInitials.value,
        ));
  }

  Widget _navItem(_Nav it) {
    final selected = it.key == current;
    return GestureDetector(
      onTap: selected ? null : () => Get.toNamed(it.route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
            color: selected ? _purpleLight : Colors.transparent,
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(it.icon, size: 17, color: selected ? _purple : Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(it.label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? _purple : Colors.grey.shade700)),
        ]),
      ),
    );
  }
}

class _Nav {
  final String key;
  final IconData icon;
  final String label;
  final String route;
  const _Nav(this.key, this.icon, this.label, this.route);
}
