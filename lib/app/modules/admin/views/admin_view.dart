import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/redemption_code_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/admin_controller.dart';

class AdminView extends StatefulWidget {
  const AdminView({Key? key}) : super(key: key);

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg = Color(0xFFF5F3FF);

  late final AdminController _ctrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          _sidebar(context),
          Expanded(child: _mainArea(context)),
        ],
      ),
    );
  }

  // ─── SIDEBAR ─────────────────────────────────────────────────────────────────

  Widget _sidebar(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _purple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // storeId.value observed so Obx rebuilds when store loads
                      Obx(() {
                        _ctrl.storeId.value;
                        return Text(
                          _ctrl.currentStore.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                      Obx(() {
                        _ctrl.storeId.value;
                        final sub = _ctrl.currentStore.subtitle;
                        return Text(
                          sub.isNotEmpty ? sub : 'Gestión de Tienda',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _navItem(icon: Icons.home_outlined, label: 'Inicio', selected: true),
          _navItem(
            icon: Icons.star_outline,
            label: 'Reseñas',
            onTap: () => Get.toNamed(Routes.REVIEWS),
          ),
          _navItem(
            icon: Icons.swap_horiz_rounded,
            label: 'Canjes',
            onTap: () => Get.toNamed(Routes.REDEMPTION_CODE_HISTORY),
          ),
          _navItem(
            icon: Icons.card_giftcard_outlined,
            label: 'Premios',
            onTap: () => Get.toNamed(Routes.PREMIOS),
          ),
          _navItem(
            icon: Icons.grid_view_rounded,
            label: 'Material',
            onTap: () => Get.toNamed(Routes.INVENTARIO),
          ),
          _navItem(
            icon: Icons.bar_chart_outlined,
            label: 'Estadísticas',
            onTap: () => Get.toNamed(Routes.ANALYTICS),
          ),
          const Spacer(),
          const Divider(height: 1),
          _navItem(
            icon: Icons.lock_outline,
            label: 'PIN',
            onTap: () => Get.toNamed(Routes.ADMIN_SETTINGS),
          ),
          _navItem(
            icon: Icons.shield_outlined,
            label: 'Seguridad',
            onTap: () => Get.toNamed(Routes.ADMIN_SETTINGS),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showValidateRedemptionCodeDialog(context),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Nuevo Canje',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1B4B),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          ListTile(
            dense: true,
            leading:
                const Icon(Icons.logout, size: 18, color: Colors.grey),
            title: const Text('Cerrar Sesión',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _purpleLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? _purple : Colors.grey.shade500),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? _purple : Colors.grey.shade700,
                )),
          ],
        ),
      ),
    );
  }

  // ─── MAIN AREA ───────────────────────────────────────────────────────────────

  Widget _mainArea(BuildContext context) {
    return Column(
      children: [
        _topBar(context),
        Expanded(
          child: Obx(() {
            if (_ctrl.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statsRow(),
                        const SizedBox(height: 20),
                        _recentCanjesPanel(context),
                        const SizedBox(height: 16),
                        _monthlyGoalBanner(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 260,
                    child: Column(
                      children: [
                        _storeVirtualCard(),
                        const SizedBox(height: 16),
                        _activityPanel(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────────────────

  Widget _topBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          const Text(
            'Resumen Operativo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar canje por ID o cliente...',
                  hintStyle:
                      TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search,
                      size: 18, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    Get.toNamed(Routes.REDEMPTION_CODE_HISTORY);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 20),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined,
                  size: 22, color: Color(0xFF374151)),
              Positioned(
                top: -2,
                right: -2,
                child: Obx(() => _ctrl.pendingCount > 0
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle),
                      )
                    : const SizedBox.shrink()),
              ),
            ],
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () => _showStoreDetailsSheet(context),
            child: const Icon(Icons.settings_outlined,
                size: 22, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 20),
          const Icon(Icons.help_outline,
              size: 22, color: Color(0xFF374151)),
          const SizedBox(width: 20),
          Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _purpleLight,
                    child: _ctrl.currentStore.logoUrl.startsWith('http')
                        ? ClipOval(
                            child: Image.network(
                              _ctrl.currentStore.logoUrl,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: _purple),
                            ),
                          )
                        : const Icon(Icons.person,
                            size: 16, color: _purple),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AuthService.isStoreAdmin
                            ? 'Admin LetDem'
                            : _ctrl.currentStore.name,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _ctrl.currentStore.name,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
        ],
      ),
    );
  }

  // ─── STATS ROW ────────────────────────────────────────────────────────────────

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: Obx(() => _statCard(
                bgColor: const Color(0xFF6B7280),
                icon: Icons.access_time_outlined,
                label: 'Pendientes',
                value: '${_ctrl.pendingCount}',
                sublabel: 'Canjes sin validar',
              )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() => _statCard(
                bgColor: const Color(0xFF14532D),
                icon: Icons.check_circle_outline,
                label: 'Completados',
                value: _fmtNum(_ctrl.completedTodayCount),
                sublabel: 'Órdenes finalizadas hoy',
              )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() => _statCard(
                bgColor: const Color(0xFF7F1D1D),
                icon: Icons.timer_off_outlined,
                label: 'Expirados',
                value: '${_ctrl.expiredCount}',
                sublabel: 'Canjes no retirados',
              )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() => _statCard(
                bgColor: const Color(0xFFFFF7ED),
                icon: Icons.view_list_outlined,
                label: 'Premios activos',
                value: '${_ctrl.activePrizesCount}',
                sublabel: 'Catálogo total activo',
                darkText: false,
              )),
        ),
      ],
    );
  }

  Widget _statCard({
    required Color bgColor,
    required IconData icon,
    required String label,
    required String value,
    required String sublabel,
    bool darkText = true,
  }) {
    final textColor = darkText ? Colors.white : const Color(0xFF92400E);
    final iconColor = darkText ? Colors.white70 : const Color(0xFFD97706);
    final badgeBg = darkText
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.orange.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1)),
          const SizedBox(height: 4),
          Text(sublabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  // ─── STORE VIRTUAL CARD ───────────────────────────────────────────────────────

  Widget _storeVirtualCard() {
    return Obx(() {
      final cardId = _ctrl.storeCardId;
      final pts = _ctrl.accumulatedPoints;
      final available = _ctrl.availablePoints;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF9F5FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('LETDEM TIENDA',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 0.8)),
                ),
                const Icon(Icons.bar_chart_rounded,
                    color: Colors.white38, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Flexible(
                  child: Text('Tarjeta actual de puntos: ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.white60)),
                ),
                Text('${_fmtNumLong(available)} Pts',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
            const SizedBox(height: 6),
            Text('ID: $cardId',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5)),
            const SizedBox(height: 16),
            const Text('FONDO ACUMULADO',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white60,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text('${_fmtNumLong(pts)} Pts',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ─── CANJES RECIENTES ─────────────────────────────────────────────────────────

  Widget _recentCanjesPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Canjes recientes',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827))),
                  SizedBox(height: 2),
                  Text('Últimas transacciones realizadas hoy',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showValidateRedemptionCodeDialog(context),
                icon: const Icon(Icons.qr_code_scanner,
                    size: 16, color: Colors.white),
                label: const Text('Validar canje',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _canjesTableHeader(),
          const Divider(height: 1),
          Obx(() {
            final recent = _ctrl.recentCanjes;
            if (recent.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No hay canjes recientes.',
                      style: TextStyle(color: Colors.grey)),
                ),
              );
            }
            return Column(
              children: recent.map((v) => _canjeRow(v)).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _canjesTableHeader() {
    const style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.3);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Usuario', style: style)),
          Expanded(flex: 2, child: Text('Premio', style: style)),
          Expanded(child: Text('Fecha/Hora', style: style)),
          SizedBox(width: 80, child: Text('Valor', style: style)),
          SizedBox(width: 110, child: Text('Estado', style: style)),
        ],
      ),
    );
  }

  Widget _canjeRow(RedemptionCodeModel v) {
    final customerName = _ctrl.customerNameFor(v);
    final initials = customerName
        .split(' ')
        .map((s) => s.isNotEmpty ? s[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    final productName = _ctrl.productNameFor(v);
    final timeStr = _fmtTime(v.issuedAt.toLocal());
    final dateStr = _fmtRelativeDate(v.issuedAt.toLocal());
    final pts = v.pointsUsed;
    final statusLabel = _statusLabel(v);
    final statusColor = _statusColor(v);
    final statusBg = _statusBg(v);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _purpleLight,
                      child: Text(
                          initials.isEmpty ? '?' : initials,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _purple)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(customerName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(productName,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(timeStr,
                        style: const TextStyle(fontSize: 13)),
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                child: Text('$pts\nPts',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _purple)),
              ),
              SizedBox(
                width: 110,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor),
                      textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  String _statusLabel(RedemptionCodeModel v) {
    if (v.isRedeemed) return 'COMPLETADO';
    if (v.isIncident) return 'INCIDENCIA';
    if (v.isExpired) return 'EXPIRADO';
    if (v.isInProgress) return 'EN PROCESO';
    return 'PENDIENTE';
  }

  Color _statusColor(RedemptionCodeModel v) {
    if (v.isRedeemed) return const Color(0xFF166534);
    if (v.isIncident) return const Color(0xFF991B1B);
    if (v.isExpired) return const Color(0xFF991B1B);
    if (v.isInProgress) return const Color(0xFF1D4ED8);
    return const Color(0xFF92400E);
  }

  Color _statusBg(RedemptionCodeModel v) {
    if (v.isRedeemed) return const Color(0xFFDCFCE7);
    if (v.isIncident) return const Color(0xFFFEE2E2);
    if (v.isExpired) return const Color(0xFFFEE2E2);
    if (v.isInProgress) return const Color(0xFFDBEAFE);
    return const Color(0xFFFEF3C7);
  }

  // ─── ACTIVITY PANEL ───────────────────────────────────────────────────────────

  Widget _activityPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Actividad de Tienda',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bolt,
                    size: 14, color: Color(0xFFD97706)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final feed = _ctrl.activityFeed;
            if (feed.isEmpty) {
              return const Text('Sin actividad reciente.',
                  style: TextStyle(fontSize: 12, color: Colors.grey));
            }
            return Column(
              children: feed.map(_activityItem).toList(),
            );
          }),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => Get.toNamed(Routes.REDEMPTION_CODE_HISTORY),
            child: const Center(
              child: Text(
                'Ver todo el historial',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _purple,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityItem(Map<String, dynamic> item) {
    final color = _dotColor(item['color'] as String? ?? 'purple');
    final actionLabel = (item['action_label'] as String? ?? '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 3),
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(item['body'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                if (actionLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => Get.toNamed(Routes.INVENTARIO),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _purple),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(item['time'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _purple)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _dotColor(String c) {
    switch (c) {
      case 'green':
        return Colors.green;
      case 'red':
        return const Color(0xFFDC2626);
      case 'orange':
        return Colors.orange;
      case 'grey':
        return Colors.grey;
      case 'red':
        return const Color(0xFFDC2626);
      default:
        return _purple;
    }
  }

  // ─── DIALOGS ──────────────────────────────────────────────────────────────────

  void _showValidateRedemptionCodeDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Validar canje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el código de canje:'),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: InputDecoration(
                hintText: 'Ej: VCH-123456',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;
              Navigator.of(ctx).pop();
              await _ctrl.validateRedemptionCodeCode(code);
            },
            child: const Text('Validar'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.signOut();
              Get.offAllNamed(Routes.LOGIN);
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _showStoreDetailsSheet(BuildContext context) {
    final store = _ctrl.currentStore;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: store.logoUrl.startsWith('http')
                      ? Image.network(store.logoUrl,
                          width: 80, height: 80, fit: BoxFit.cover)
                      : Container(
                          width: 80,
                          height: 80,
                          color: _purpleLight,
                          child: const Icon(Icons.store,
                              size: 40, color: _purple),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                  child: Text(store.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700))),
              const SizedBox(height: 8),
              Center(
                  child: Text(store.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey))),
              const SizedBox(height: 24),
              _sheetRow('ID fiscal', store.fiscalId),
              _sheetRow('Email facturación', store.billingEmail),
              _sheetRow('Teléfono', store.billingPhone),
              _sheetRow('Dirección', store.address),
              _sheetRow('Email dueño', store.ownerEmail),
              _sheetRow('ID tarjeta', _ctrl.storeCardId),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _sheetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
              width: 130,
              child: Text('$label:',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13, color: Colors.grey))),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────────

  String _fmtNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _fmtNumLong(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      final s = n.toString();
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return '$n';
  }

  String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final suffix = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }

  String _fmtRelativeDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) return 'Hoy';
    if (date == yesterday) return 'Ayer';
    return '${d.day}/${d.month}/${d.year}';
  }

  // ─── MONTHLY GOAL BANNER ──────────────────────────────────────────────────

  Widget _monthlyGoalBanner() {
    return Obx(() {
      final current = _ctrl.monthlyGoalCurrentPts;
      final target = _ctrl.monthlyGoalTargetPts;
      final days = _ctrl.monthlyGoalDaysRemaining;
      final prize = _ctrl.monthlyGoalPrizeName;
      final percent = _ctrl.monthlyGoalPercent;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_outlined, color: _purple, size: 20),
            const SizedBox(width: 10),
            Flexible(
              flex: 2,
              child: Text(
                'Meta Mensual de Fidelización',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(_purple),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              flex: 2,
              child: Text(
                '${(percent * 100).toStringAsFixed(0)}% · ${_fmtNumLong(current)}/${_fmtNumLong(target)} Pts',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              flex: 2,
              child: Text(
                '$days días',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            if (prize.isNotEmpty) ...[
              const SizedBox(width: 10),
              Flexible(
                flex: 2,
                child: Text(
                  prize,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: _purple, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
