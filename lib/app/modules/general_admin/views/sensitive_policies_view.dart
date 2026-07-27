import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/sensitive_policy_model.dart';
import '../controllers/general_admin_controller.dart';
import 'backoffice_sidebar.dart';

class SensitivePoliciesView extends GetView<GeneralAdminController> {
  const SensitivePoliciesView({super.key});

  static const Color _purple      = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg          = Color(0xFFF8F7FF);
  static const Color _dark        = Color(0xFF1E1B4B);
  static const Color _border      = Color(0xFFEEEEEE);
  static const Color _green       = Color(0xFF10B981);
  static const Color _amber       = Color(0xFFF59E0B);
  static const Color _blue        = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    controller.loadSensitivePolicies();
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bg,
        body: Row(children: [
          BackofficeSidebar(current: 'politicas'),
          Expanded(child: _body(context, desktop: true)),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      drawer: Drawer(child: SafeArea(child: BackofficeSidebar(current: 'politicas'))),
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
              _pageHeader(context),
              const SizedBox(height: 20),
              _statCards(),
              const SizedBox(height: 20),
              _policiesTable(context),
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
              Text('Buscar políticas, resoluciones...',
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

  Widget _pageHeader(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Políticas sensibles',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _dark)),
          SizedBox(height: 4),
          Text('Administra, centraliza, RGPD, geolocalización y auditoría',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
      ),
      const SizedBox(width: 16),
      ElevatedButton.icon(
        icon: const Icon(Icons.add, size: 15, color: Colors.white),
        label: const Text('Nueva Política',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        onPressed: () => _showPolicyDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _purple,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ]);
  }

  // ─── STAT CARDS ──────────────────────────────────────────────────────────────

  Widget _statCards() {
    return Obx(() {
      final defs = [
        _StatDef(
          value: controller.policiesActive.value.toString(),
          label: 'Documentos activos',
          icon: Icons.description_outlined,
          color: _purple,
        ),
        _StatDef(
          value: controller.policiesPending.value.toString(),
          label: 'Pendientes',
          icon: Icons.pending_actions_outlined,
          color: _amber,
        ),
        _StatDef(
          value: _fmtPct(controller.policiesCoverage.value),
          label: 'Cobertura',
          icon: Icons.shield_outlined,
          color: _green,
        ),
      ];
      return LayoutBuilder(builder: (_, c) {
        if (c.maxWidth >= 480) {
          return Row(
            children: defs.asMap().entries.map((e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: e.key < defs.length - 1 ? 12 : 0),
                child: _statCard(e.value),
              ),
            )).toList(),
          );
        }
        return Column(
          children: defs.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 10), child: _statCard(d))).toList(),
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
                    fontSize: 26, fontWeight: FontWeight.w800, color: _dark, height: 1.1)),
            const SizedBox(height: 2),
            Text(def.label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ]),
    );
  }

  // ─── POLICIES TABLE ──────────────────────────────────────────────────────────

  static const _hdr = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.5);

  Widget _policiesTable(BuildContext context) {
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
              const Text('Políticas registradas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
              const Spacer(),
              Obx(() => controller.isLoadingPolicies.value
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _purple))
                  : const SizedBox.shrink()),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: const Color(0xFFF9F9F9),
            child: const Row(children: [
              Expanded(flex: 4, child: Text('POLÍTICA',  style: _hdr)),
              Expanded(flex: 2, child: Text('CATEGORÍA', style: _hdr)),
              Expanded(flex: 2, child: Text('PLAZO',     style: _hdr)),
              Expanded(flex: 2, child: Text('RUTA',      style: _hdr)),
              SizedBox(width: 110,  child: Text('ACCIÓN', style: _hdr, textAlign: TextAlign.center)),
            ]),
          ),
          Obx(() {
            final policies = controller.sensitivePolicies;
            if (policies.isEmpty && !controller.isLoadingPolicies.value) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Sin políticas registradas',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              );
            }
            return Column(
              children: policies.map((p) => _policyRow(context, p)).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _policyRow(BuildContext context, SensitivePolicyModel policy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(children: [
        // Política
        Expanded(
          flex: 4,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(policy.name,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _dark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (policy.description.isNotEmpty)
              Text(policy.description,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ]),
        ),
        // Categoría
        Expanded(
          flex: 2,
          child: _catBadge(policy.category),
        ),
        // Plazo
        Expanded(
          flex: 2,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.schedule_outlined, size: 13, color: Colors.grey),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                policy.plazo.isNotEmpty ? policy.plazo
                    : (policy.plazoInDays > 0 ? '${policy.plazoInDays} dias' : '—'),
                style: const TextStyle(fontSize: 12, color: _dark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
        // Ruta
        Expanded(flex: 2, child: _rutaBadge(policy.ruta)),
        // Acción
        SizedBox(
          width: 110,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (policy.isEditable)
              TextButton(
                onPressed: () => _showPolicyDialog(context, policy: policy),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Editar',
                    style: TextStyle(fontSize: 12, color: _purple, fontWeight: FontWeight.w600)),
              )
            else
              TextButton(
                onPressed: () => _showPolicyDetail(context, policy),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Ver',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600)),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _catBadge(String cat) {
    final (label, color, bg) = switch (cat.toLowerCase()) {
      'retencion' || 'retención' => ('Retención', _purple, _purpleLight),
      'gdpr' || 'rgpd'          => ('GDPR', _blue, const Color(0xFFEFF6FF)),
      'geolocalizacion'         => ('Geoloc.', _green, const Color(0xFFECFDF5)),
      'auditoria' || 'auditoría'=> ('Auditoría', _amber, const Color(0xFFFFFBEB)),
      _                         => (cat.isEmpty ? '—' : cat, Colors.grey, const Color(0xFFF5F5F5)),
    };
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }

  Widget _rutaBadge(String ruta) {
    final (color, bg) = switch (ruta.toLowerCase()) {
      'backoffice' => (_blue,   const Color(0xFFEFF6FF)),
      'usuario'    => (_green,  const Color(0xFFECFDF5)),
      'informe'    => (_amber,  const Color(0xFFFFFBEB)),
      'global'     => (_purple, _purpleLight),
      _            => (Colors.grey, const Color(0xFFF5F5F5)),
    };
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(ruta.isEmpty ? '—' : ruta,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }

  // ─── DIALOGS ─────────────────────────────────────────────────────────────────

  void _showPolicyDetail(BuildContext context, SensitivePolicyModel policy) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(policy.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (policy.description.isNotEmpty) ...[
            Text(policy.description,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
          ],
          _detailRow('Plazo', policy.plazo.isNotEmpty ? policy.plazo : '—'),
          _detailRow('Ruta', policy.ruta.isNotEmpty ? policy.ruta : '—'),
          _detailRow('Categoría', policy.category.isNotEmpty ? policy.category : '—'),
          _detailRow('Estado', policy.status),
        ]),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar', style: TextStyle(color: _purple)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _dark))),
      ]),
    );
  }

  void _showPolicyDialog(BuildContext context, {SensitivePolicyModel? policy}) {
    final nameCtrl  = TextEditingController(text: policy?.name ?? '');
    final descCtrl  = TextEditingController(text: policy?.description ?? '');
    final plazoCtrl = TextEditingController(
        text: policy != null
            ? (policy.plazoInDays > 0 ? policy.plazoInDays.toString() : '')
            : '');
    String selectedRuta   = policy?.ruta ?? 'Usuario';
    String selectedCat    = policy?.category ?? 'retencion';
    String selectedStatus = policy?.status ?? 'active';

    final rutas      = ['Usuario', 'Backoffice', 'Informe', 'Global'];
    final cats       = ['retencion', 'gdpr', 'geolocalizacion', 'auditoria'];
    final statuses   = ['active', 'pending', 'inactive'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(policy == null ? 'Nueva Política' : 'Editar Política',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _dialogField('Nombre', nameCtrl, hint: 'Ej: Retención de datos de usuarios'),
                const SizedBox(height: 12),
                _dialogField('Descripción', descCtrl, hint: 'Descripción breve', maxLines: 2),
                const SizedBox(height: 12),
                _dialogField('Plazo (días)', plazoCtrl, hint: '30', isNumber: true),
                const SizedBox(height: 12),
                _dialogDropdown('Ruta', rutas, selectedRuta,
                    (v) => setState(() => selectedRuta = v!)),
                const SizedBox(height: 12),
                _dialogDropdown('Categoría', cats, selectedCat,
                    (v) => setState(() => selectedCat = v!)),
                const SizedBox(height: 12),
                _dialogDropdown('Estado', statuses, selectedStatus,
                    (v) => setState(() => selectedStatus = v!)),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final payload = {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'retention_days': int.tryParse(plazoCtrl.text.trim()) ?? 0,
                  'plazo': plazoCtrl.text.trim().isNotEmpty
                      ? '${plazoCtrl.text.trim()} dias'
                      : '',
                  'ruta': selectedRuta,
                  'category': selectedCat,
                  'status': selectedStatus,
                };
                Get.back();
                if (policy == null) {
                  controller.createSensitivePolicyCtrl(payload);
                } else {
                  controller.updateSensitivePolicyCtrl(policy.id, payload);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(policy == null ? 'Crear' : 'Guardar',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      }),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl,
      {String hint = '', int maxLines = 1, bool isNumber = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _dark)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _purple),
          ),
        ),
      ),
    ]);
  }

  Widget _dialogDropdown(String label, List<String> options, String value,
      void Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _dark)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: _dark),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
        ),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      ),
    ]);
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  static String _fmtPct(double v) {
    if (v == 0.0) return '—';
    if (v == v.roundToDouble()) return '${v.toInt()}%';
    return '${v.toStringAsFixed(1)}%';
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
