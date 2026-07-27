import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/gdpr_request_model.dart';
import '../controllers/gdpr_controller.dart';
import 'backoffice_sidebar.dart';

class GdprRequestsView extends StatelessWidget {
  const GdprRequestsView({super.key});

  static const Color _purple      = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg          = Color(0xFFF8F7FF);

  @override
  Widget build(BuildContext context) {
    final ctrl     = Get.find<GdprController>();

    return Scaffold(
      backgroundColor: _bg,
      body: Row(children: [
        BackofficeSidebar(current: 'gdpr'),
        Expanded(child: _mainArea(context, ctrl)),
      ]),
    );
  }

  // ─── SIDEBAR ─────────────────────────────────────────────────────────────

  // ─── MAIN AREA ────────────────────────────────────────────────────────────

  Widget _mainArea(BuildContext context, GdprController ctrl) {
    return Column(children: [
      _topBar(ctrl),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pageHeader(context, ctrl),
              const SizedBox(height: 20),
              _statCards(ctrl),
              const SizedBox(height: 20),
              _filterBar(ctrl),
              const SizedBox(height: 12),
              _table(context, ctrl),
            ],
          ),
        ),
      ),
    ]);
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────────────

  Widget _topBar(GdprController ctrl) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar solicitudes GDPR...',
                hintStyle:
                    TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon:
                    Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                filled: true, fillColor: const Color(0xFFF5F5F5), isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => ctrl.loadRequests(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.notifications_outlined,
            size: 22, color: Color(0xFF374151)),
        const SizedBox(width: 16),
        const Icon(Icons.help_outline, size: 22, color: Color(0xFF374151)),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _purpleLight, borderRadius: BorderRadius.circular(20)),
          child: const Row(children: [
            Icon(Icons.admin_panel_settings, size: 14, color: _purple),
            SizedBox(width: 6),
            Text('Super Admin',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _purple)),
          ]),
        ),
      ]),
    );
  }

  // ─── PAGE HEADER ─────────────────────────────────────────────────────────

  Widget _pageHeader(BuildContext context, GdprController ctrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Solicitudes GDPR / RGPD',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: Color(0xFF111827))),
            const SizedBox(height: 4),
            const Text(
              'Gestión de privacidad, derechos de acceso y borrado de datos.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ]),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () => _showFormatsDialog(context, ctrl),
          icon: const Icon(Icons.description_outlined, size: 16),
          label: const Text('Ver Formatos Directiva',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _purple, side: const BorderSide(color: _purple),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 8),
        Obx(() => ElevatedButton.icon(
          onPressed: ctrl.isExporting.value ? null : ctrl.exportReport,
          icon: ctrl.isExporting.value
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.download_outlined, size: 16, color: Colors.white),
          label: const Text('Exportar Reporte',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1B4B), elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        )),
      ],
    );
  }

  // ─── STAT CARDS ──────────────────────────────────────────────────────────

  Widget _statCards(GdprController ctrl) {
    return Obx(() {
      final s = ctrl.stats.value;
      return Row(children: [
        Expanded(child: _statCard(
          label: 'PENDIENTES HOY',
          value: '${s.pendingToday}',
          sub: s.pendingChangePct != 0
              ? '${s.pendingChangePct >= 0 ? '+' : ''}${s.pendingChangePct.toStringAsFixed(0)}% vs ayer'
              : 'Sin cambio',
          subColor: s.pendingChangePct < 0 ? Colors.green : Colors.orange,
          icon: Icons.hourglass_empty_outlined,
          iconColor: Colors.grey.shade600,
          iconBg: const Color(0xFFF3F4F6),
        )),
        const SizedBox(width: 12),
        Expanded(child: _statCard(
          label: 'FUERA DE PLAZO',
          value: '${s.overdue}',
          sub: s.overdue > 0 ? 'Crítico' : 'Todo en plazo',
          subColor: s.overdue > 0 ? const Color(0xFFDC2626) : Colors.green,
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBg: const Color(0xFFFEE2E2),
          badge: s.overdue > 0 ? 'Crítico' : null,
          badgeColor: const Color(0xFFDC2626),
        )),
        const SizedBox(width: 12),
        Expanded(child: _statCard(
          label: 'PRÓXIMOS VENCIMIENTOS',
          value: '${s.upcoming3Days}',
          sub: 'Próx. 3 días',
          subColor: const Color(0xFFD97706),
          icon: Icons.schedule_outlined,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFFFF7ED),
        )),
        const SizedBox(width: 12),
        Expanded(child: _statCard(
          label: 'RESUELTAS',
          value: '${s.resolvedYear}',
          sub: 'Último 1 año',
          subColor: const Color(0xFF059669),
          icon: Icons.check_circle_outline,
          iconColor: const Color(0xFF059669),
          iconBg: const Color(0xFFD1FAE5),
        )),
      ]);
    });
  }

  Widget _statCard({
    required String label,
    required String value,
    required String sub,
    required Color subColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const Spacer(),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (badgeColor ?? Colors.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badge,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: badgeColor ?? Colors.red)),
            ),
        ]),
        const SizedBox(height: 12),
        Text(value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                color: Color(0xFF111827), height: 1)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey,
            fontWeight: FontWeight.w600, letterSpacing: 0.4)),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(fontSize: 12, color: subColor,
            fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ─── FILTER BAR ──────────────────────────────────────────────────────────

  Widget _filterBar(GdprController ctrl) {
    return Obx(() {
      final total = ctrl.meta.value.total;
      final shown = ctrl.requests.length;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(children: [
          // Tab filters
          _filterTab(ctrl, 'all',      'Todas'),
          _filterTab(ctrl, 'overdue',  'Vencidas'),
          _filterTab(ctrl, 'due_1day', 'Pró. 1 día'),
          _filterTab(ctrl, 'due_3days','Pró. 3 días'),
          _filterTab(ctrl, 'resolved', 'Resueltas'),
          const SizedBox(width: 16),
          const VerticalDivider(width: 1),
          const SizedBox(width: 16),
          // Type dropdown
          _typeDropdown(ctrl),
          const Spacer(),
          Text('Mostrando $shown de $total',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      );
    });
  }

  Widget _filterTab(GdprController ctrl, String key, String label) {
    return Obx(() {
      final selected = ctrl.activeFilter.value == key;
      return GestureDetector(
        onTap: () => ctrl.setFilter(key),
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _purple : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? _purple : const Color(0xFFE5E7EB)),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700)),
        ),
      );
    });
  }

  Widget _typeDropdown(GdprController ctrl) {
    const typeOptions = {
      'all':           'Tipo: Todos',
      'erasure':       'Derecho al olvido',
      'portability':   'Portabilidad',
      'access':        'Acceso a Datos',
      'rectification': 'Rectificación',
      'objection':     'Oposición',
      'restriction':   'Limitación',
    };
    return Obx(() => DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: ctrl.activeType.value,
        isDense: true,
        style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        items: typeOptions.entries.map((e) =>
            DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (v) { if (v != null) ctrl.setType(v); },
        icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
      ),
    ));
  }

  // ─── TABLE ────────────────────────────────────────────────────────────────

  Widget _table(BuildContext context, GdprController ctrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: [
        _tableHeader(),
        const Divider(height: 1),
        Obx(() {
          if (ctrl.isLoading.value) {
            return const Padding(padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()));
          }
          if (ctrl.requests.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('Sin solicitudes registradas.',
                  style: TextStyle(color: Colors.grey))),
            );
          }
          return Column(children:
              ctrl.requests.map((r) => _tableRow(context, ctrl, r)).toList());
        }),
        const Divider(height: 1),
        _paginationRow(ctrl),
      ]),
    );
  }

  Widget _tableHeader() {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
        color: Colors.grey, letterSpacing: 0.5);
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: const Row(children: [
        Expanded(flex: 3, child: Text('USUARIO', style: style)),
        Expanded(flex: 3, child: Text('TIPO DE SOLICITUD', style: style)),
        Expanded(flex: 2, child: Text('ESTADO', style: style)),
        Expanded(flex: 2, child: Text('FECHA ALTA', style: style)),
        SizedBox(width: 120, child: Text('PLAZO/LÍMITE', style: style)),
      ]),
    );
  }

  Widget _tableRow(BuildContext context, GdprController ctrl, GdprRequestModel r) {
    final initials = r.userName.split(' ').where((w) => w.isNotEmpty)
        .take(2).map((w) => w[0].toUpperCase()).join();

    return Column(children: [
      InkWell(
        onTap: () => _showRequestSheet(context, ctrl, r),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            // Usuario
            Expanded(flex: 3, child: Row(children: [
              CircleAvatar(radius: 18, backgroundColor: _purpleLight,
                  child: Text(initials.isEmpty ? '?' : initials,
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700, color: _purple))),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.userName, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Text(r.userEmail, style: const TextStyle(
                    fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis),
              ])),
            ])),
            // Tipo
            Expanded(flex: 3, child: Row(children: [
              Container(width: 4, height: 28,
                  decoration: BoxDecoration(
                    color: _typeColor(r.requestType),
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(r.typeLabel,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
            ])),
            // Estado
            Expanded(flex: 2, child: _statusBadge(r.status, r.statusLabel)),
            // Fecha Alta
            Expanded(flex: 2, child: Text(_fmtDate(r.createdAt),
                style: const TextStyle(fontSize: 13))),
            // Plazo
            SizedBox(width: 120, child: _deadlineBadge(r)),
          ]),
        ),
      ),
      const Divider(height: 1),
    ]);
  }

  Widget _statusBadge(String status, String label) {
    final Color bg;
    final Color fg;
    switch (status) {
      case 'received':       bg = const Color(0xFFEFF6FF); fg = const Color(0xFF1D4ED8); break;
      case 'pending_assign': bg = const Color(0xFFFFF7ED); fg = const Color(0xFFD97706); break;
      case 'in_process':     bg = _purpleLight;             fg = _purple;                break;
      case 'resolved':       bg = const Color(0xFFD1FAE5); fg = const Color(0xFF059669); break;
      case 'overdue':        bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626); break;
      default:               bg = const Color(0xFFF3F4F6); fg = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
          overflow: TextOverflow.ellipsis),
    );
  }

  Widget _deadlineBadge(GdprRequestModel r) {
    if (r.isResolved) {
      return const Text('—', style: TextStyle(color: Colors.grey));
    }
    final days = r.daysLeft;
    if (days == null) return const Text('—', style: TextStyle(color: Colors.grey));

    if (days < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8)),
        child: Text('${days.abs()} días vencido',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626))));
    }
    if (days == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8)),
        child: const Text('VENCE HOY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626))));
    }
    if (days <= 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(8)),
        child: Text('$days días',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Color(0xFFD97706))));
    }
    return Text('$days días',
        style: const TextStyle(fontSize: 12, color: Colors.grey));
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'erasure':       return const Color(0xFFDC2626);
      case 'portability':   return const Color(0xFF2563EB);
      case 'access':        return const Color(0xFF059669);
      case 'rectification': return const Color(0xFFD97706);
      case 'objection':     return _purple;
      default:              return Colors.grey;
    }
  }

  // ─── PAGINATION ───────────────────────────────────────────────────────────

  Widget _paginationRow(GdprController ctrl) {
    return Obx(() {
      final meta  = ctrl.meta.value;
      final page  = ctrl.currentPage.value;
      final total = meta.lastPage;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Text('Página $page de $total',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          _pgBtn(Icons.chevron_left,
              page > 1 ? () => ctrl.loadRequests(page: page - 1) : null),
          const SizedBox(width: 8),
          _pgBtn(Icons.chevron_right,
              page < total ? () => ctrl.loadRequests(page: page + 1) : null),
        ]),
      );
    });
  }

  Widget _pgBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 32, height: 32,
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18,
            color: onTap != null ? Colors.black87 : Colors.grey.shade300)),
    );
  }

  // ─── FORMATS DIALOG ──────────────────────────────────────────────────────

  void _showFormatsDialog(BuildContext context, GdprController ctrl) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.description_outlined, color: _purple, size: 20),
          SizedBox(width: 8),
          Text('Formatos Directiva RGPD',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: SizedBox(
          width: 520,
          child: Obx(() {
            if (ctrl.formats.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: ctrl.formats.map((f) => _formatRow(f)).toList(),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _formatRow(GdprFormat f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _purpleLight, borderRadius: BorderRadius.circular(8)),
            child: Text(f.article,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: _purple)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(f.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Plazo', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('${f.deadlineDays} días',
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: _purple)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── REQUEST DETAIL SHEET ─────────────────────────────────────────────────

  void _showRequestSheet(
      BuildContext context, GdprController ctrl, GdprRequestModel r) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
        color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(r.typeLabel,
                  style: const TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              _statusBadge(r.status, r.statusLabel),
            ]),
            const SizedBox(height: 4),
            Text('${r.userName}  ·  ${r.userEmail}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _sheetInfo('Fecha Alta', _fmtDate(r.createdAt))),
              Expanded(child: _sheetInfo('Plazo',
                  r.deadline != null ? _fmtDate(r.deadline!) : '—')),
              Expanded(child: _sheetInfo('Asignado a', r.assignedTo ?? 'Sin asignar')),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _actionBtn(
                label: 'Marcar en proceso',
                icon: Icons.play_arrow_outlined,
                color: _purple,
                onTap: r.status != 'in_process'
                    ? () { Get.back(); ctrl.updateStatus(r.id, 'in_process'); }
                    : null,
              )),
              const SizedBox(width: 12),
              Expanded(child: _actionBtn(
                label: 'Marcar resuelto',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF059669),
                onTap: r.status != 'resolved'
                    ? () { Get.back(); ctrl.updateStatus(r.id, 'resolved'); }
                    : null,
              )),
            ]),
            const SizedBox(height: 12),
            _assignRow(context, ctrl, r),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _assignRow(BuildContext context, GdprController ctrl, GdprRequestModel r) {
    final emailCtrl = TextEditingController(text: r.assignedTo ?? '');
    return Row(children: [
      Expanded(
        child: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Email del staff asignado',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: const Icon(Icons.person_outline, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ),
      const SizedBox(width: 10),
      ElevatedButton(
        onPressed: () {
          final email = emailCtrl.text.trim();
          if (email.isEmpty || !email.contains('@')) return;
          Get.back();
          ctrl.assignRequest(r.id, email);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1B4B), elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Asignar',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    ]);
  }

  Widget _sheetInfo(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _actionBtn({
    required String label, required IconData icon,
    required Color color, VoidCallback? onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: onTap != null ? color : Colors.grey.shade300,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  static String _fmtDate(DateTime d) {
    const meses = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                   'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${meses[d.month]} ${d.year}';
  }
}
