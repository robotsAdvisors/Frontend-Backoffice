import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/store_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/general_admin_controller.dart';
import 'backoffice_sidebar.dart';

class GeneralAdminView extends GetView<GeneralAdminController> {
  const GeneralAdminView({super.key});

  static const Color _purple      = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg          = Color(0xFFF8F7FF);
  static const Color _dark        = Color(0xFF1E1B4B);
  static const Color _border      = Color(0xFFEEEEEE);
  static const Color _green       = Color(0xFF10B981);
  static const Color _amber       = Color(0xFFF59E0B);
  static const Color _red         = Color(0xFFEF4444);
  static const Color _blue        = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bg,
        body: Row(children: [
          BackofficeSidebar(current: 'dashboard'),
          Expanded(child: _body(context, desktop: true)),
          _alertasPanel(),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      drawer: Drawer(child: SafeArea(child: BackofficeSidebar(current: 'dashboard'))),
      body: _body(context, desktop: false),
    );
  }

  // ─── SIDEBAR ────────────────────────────────────────────────────────────────

  // ─── BODY ───────────────────────────────────────────────────────────────────

  Widget _body(BuildContext context, {required bool desktop}) {
    return Column(children: [
      _topBar(context, desktop: desktop),
      Expanded(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(desktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pageHeader(),
              const SizedBox(height: 20),
              _statCards(),
              const SizedBox(height: 20),
              _storesTable(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ]);
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────────────────

  Widget _topBar(BuildContext context, {required bool desktop}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(children: [
        if (!desktop)
          IconButton(
            icon: const Icon(Icons.menu, size: 20),
            onPressed: () => Scaffold.of(context).openDrawer(),
            padding: EdgeInsets.zero,
          ),
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(children: [
              SizedBox(width: 12),
              Icon(Icons.search, size: 17, color: Colors.grey),
              SizedBox(width: 8),
              Text('Buscar tiendas, comercios...',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Obx(() {
          final initials = controller.currentUserInitials.value.isNotEmpty
              ? controller.currentUserInitials.value
              : 'SA';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _purpleLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _purple.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: _purple,
                child: Text(initials,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              const Text('Super Admin',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _purple)),
            ]),
          );
        }),
      ]),
    );
  }

  // ─── PAGE HEADER ─────────────────────────────────────────────────────────────

  Widget _pageHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gestión global de tiendas',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _dark)),
        SizedBox(height: 4),
        Text('Gestiona tu red: CRM, KYBC y estados',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  // ─── STAT CARDS ──────────────────────────────────────────────────────────────

  Widget _statCards() {
    return Obx(() {
      final defs = [
        _StatDef(
          value: _fmt(controller.totalStores.value),
          label: 'Tiendas',
          icon: Icons.store_outlined,
          color: _purple,
        ),
        _StatDef(
          value: (controller.kybcStats.value?.pendingCount ?? 0).toString(),
          label: 'KYBC pendientes',
          icon: Icons.hourglass_empty_outlined,
          color: _amber,
        ),
        _StatDef(
          value: (controller.kybcStats.value?.inReviewCount ?? 0).toString(),
          label: 'En revisión',
          icon: Icons.rate_review_outlined,
          color: _blue,
        ),
      ];
      return LayoutBuilder(builder: (_, c) {
        if (c.maxWidth >= 500) {
          return Row(
            children: defs.asMap().entries.map((e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: e.key < defs.length - 1 ? 12 : 0),
                child: _statCard(e.value),
              ),
            )).toList(),
          );
        }
        return Wrap(
          spacing: 12, runSpacing: 12,
          children: defs.map((d) => SizedBox(
            width: (c.maxWidth - 12) / 2,
            child: _statCard(d),
          )).toList(),
        );
      });
    });
  }

  Widget _statCard(_StatDef def) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: def.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(def.icon, size: 20, color: def.color),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(def.value,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800, color: _dark, height: 1.1)),
            const SizedBox(height: 2),
            Text(def.label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ]),
    );
  }

  // ─── STORES TABLE ─────────────────────────────────────────────────────────────

  static const _hdrStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Colors.grey,
    letterSpacing: 0.5,
  );

  Widget _storesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(children: [
              const Text('Tiendas registradas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
              const Spacer(),
              Obx(() => controller.isLoading.value
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _purple))
                  : const SizedBox.shrink()),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: const Color(0xFFF9F9F9),
            child: const Row(children: [
              Expanded(flex: 4, child: Text('TIENDA',  style: _hdrStyle)),
              Expanded(flex: 2, child: Text('KYBC',    style: _hdrStyle)),
              Expanded(flex: 2, child: Text('ESTADO',  style: _hdrStyle)),
              SizedBox(width: 110, child: Text('ACCIÓN', style: _hdrStyle, textAlign: TextAlign.center)),
            ]),
          ),
          Obx(() {
            final stores = controller.stores;
            if (stores.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Sin tiendas registradas',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              );
            }
            return Column(
              children: stores.take(20).map((s) => _storeRow(s)).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _storeRow(StoreModel store) {
    final (kycLabel, kycColor, kycBg) = _kycBadge(store.kycStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(children: [
        // Tienda
        Expanded(
          flex: 4,
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: _purpleLight,
                borderRadius: BorderRadius.circular(8),
                image: store.logoUrl.startsWith('http')
                    ? DecorationImage(
                        image: NetworkImage(store.logoUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: store.logoUrl.startsWith('http')
                  ? null
                  : Center(
                      child: Text(
                        store.name.isNotEmpty ? store.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: _purple),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _dark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (store.address.isNotEmpty)
                    Text(store.address,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ]),
        ),
        // KYBC
        Expanded(flex: 2, child: _badge(kycLabel, kycColor, kycBg)),
        // Estado
        Expanded(
          flex: 2,
          child: _badge(
            store.isPublished ? 'Activo' : 'Inactivo',
            store.isPublished ? _green : Colors.grey,
            store.isPublished ? const Color(0xFFECFDF5) : const Color(0xFFF5F5F5),
          ),
        ),
        // Acción
        SizedBox(
          width: 110,
          child: Center(
            child: OutlinedButton(
              onPressed: () => Get.toNamed(
                Routes.STORE_CONFIG,
                arguments: {'storeId': store.id},
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                side: BorderSide(color: _purple.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Configurar',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: _purple)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _badge(String label, Color color, Color bg) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: color, letterSpacing: 0.3)),
      ),
    );
  }

  (String, Color, Color) _kycBadge(String status) {
    switch (status.toLowerCase()) {
      case 'approved':   return ('Aprobado',    _green,  const Color(0xFFECFDF5));
      case 'rejected':   return ('Rechazado',   _red,    const Color(0xFFFEF2F2));
      case 'in_review':  return ('En Revisión', _amber,  const Color(0xFFFFFBEB));
      case 'pending':    return ('Pendiente',   _purple, _purpleLight);
      case 'suspended':  return ('Suspendido',  _red,    const Color(0xFFFEF2F2));
      case 'notificado': return ('Notificado',  _blue,   const Color(0xFFEFF6FF));
      default:           return ('Sin KYC',     Colors.grey, const Color(0xFFF5F5F5));
    }
  }

  // ─── ALERTAS COMERCIO PANEL ──────────────────────────────────────────────────

  Widget _alertasPanel() {
    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text('Alertas comercio',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
          ),
          Container(height: 1, color: _border),
          Expanded(
            child: Obx(() {
              final kybcPending   = controller.kybcStats.value?.pendingCount ?? 0;
              final storesNoFiscal = controller.stores
                  .where((s) => s.fiscalId.isEmpty)
                  .length;
              return Column(children: [
                _alertItem(
                  icon: Icons.verified_user_outlined,
                  iconColor: _purple,
                  iconBg: _purpleLight,
                  title: 'KYBC pendiente',
                  badge: kybcPending > 0 ? kybcPending.toString() : null,
                  onTap: () => Get.toNamed(Routes.KYBC),
                ),
                _alertItem(
                  icon: Icons.receipt_long_outlined,
                  iconColor: _amber,
                  iconBg: const Color(0xFFFFFBEB),
                  title: 'Datos fiscales',
                  subtitle: storesNoFiscal > 0
                      ? '$storesNoFiscal sin completar'
                      : 'Al día',
                  actionLabel: storesNoFiscal > 0 ? 'Editar datos' : null,
                  onTap: () {},
                ),
                _alertItem(
                  icon: Icons.support_agent_outlined,
                  iconColor: _blue,
                  iconBg: const Color(0xFFEFF6FF),
                  title: 'Soporte',
                  badge: controller.supportPending.value > 0
                      ? controller.supportPending.value.toString()
                      : null,
                  subtitle: 'Tickets pendientes',
                  onTap: () => Get.toNamed(Routes.SUPPORT_TICKETS),
                ),
              ]);
            }),
          ),
        ],
      ),
    );
  }

  Widget _alertItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    String? badge,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: const BoxDecoration(
        color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(badge,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
            ]),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 41),
                child: Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 41),
                child: Text(actionLabel,
                    style: const TextStyle(
                        fontSize: 11, color: _purple, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final k = n / 1000;
      return '${k == k.truncateToDouble() ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return n.toString();
  }
}

// ─── DATA CLASSES ─────────────────────────────────────────────────────────────

class _StatDef {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatDef({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}
