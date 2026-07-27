import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/redemption_code_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/admin_controller.dart';

class IncidenciasView extends StatefulWidget {
  const IncidenciasView({super.key});

  @override
  State<IncidenciasView> createState() => _IncidenciasViewState();
}

class _IncidenciasViewState extends State<IncidenciasView> {
  static const Color _purple      = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg          = Color(0xFFF8F7FF);
  static const Color _dark        = Color(0xFF1E1B4B);
  static const Color _border      = Color(0xFFEEEEEE);
  static const Color _green       = Color(0xFF10B981);
  static const Color _red         = Color(0xFFEF4444);
  static const Color _amber       = Color(0xFFF59E0B);
  static const Color _blue        = Color(0xFF3B82F6);

  late final AdminController _ctrl;

  final _codeCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();

  // ⚠️ HARDCODED: backend should expose GET /marketplace/redemption-codes/incident-reasons/
  static const List<String> _reasons = [
    'Error en validación',
    'Código de canje no reconocido',
    'Doble cobro o redención',
    'Producto no disponible',
    'Problema técnico del sistema',
    'Otro',
  ];

  String _selectedReason = _reasons.first;
  bool _isSubmitting = false;

  // Session-only list; backend needs GET /marketplace/stores/{id}/incidents/
  final List<Map<String, dynamic>> _sessionIncidents = [];

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _notesCtrl.dispose();
    _ctrl.clearRedemptionCodePreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bg,
        body: Row(children: [
          _sidebar(context),
          Expanded(child: _body()),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      drawer: Drawer(child: SafeArea(child: _sidebar(context))),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _dark),
        title: const Text('Incidencias',
            style: TextStyle(color: _dark, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: _body(),
    );
  }

  // ─── SIDEBAR ──────────────────────────────────────────────────────────────

  Widget _sidebar(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: _purple, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.shield_outlined, size: 17, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('LetDem',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _dark)),
              Text('Admin Tienda',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
          ]),
        ),
        Container(height: 1, color: _border),
        const SizedBox(height: 8),
        _navItem(icon: Icons.grid_view_outlined,     label: 'Inicio',
            onTap: () => Get.offAllNamed(Routes.ADMIN)),
        _navItem(icon: Icons.receipt_long_outlined,   label: 'Canjes', selected: true),
        _navItem(icon: Icons.inventory_2_outlined,    label: 'Productos',
            onTap: () => Get.toNamed(Routes.INVENTARIO)),
        _navItem(icon: Icons.history_outlined,        label: 'Historial'),
        _navItem(icon: Icons.security_outlined,       label: 'Seguridad',
            onTap: () => Get.toNamed(Routes.SEGURIDAD)),
        _navItem(icon: Icons.settings_outlined,       label: 'Configuraciones',
            onTap: () => Get.toNamed(Routes.ADMIN_SETTINGS)),
        const Spacer(),
        Container(height: 1, color: _border),
        ListTile(
          dense: true,
          leading: const Icon(Icons.logout, size: 18, color: Colors.grey),
          title: const Text('Cerrar Sesión',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          onTap: () async {
            await AuthService.signOut();
            Get.offAllNamed(Routes.LOGIN);
          },
        ),
        const SizedBox(height: 8),
      ]),
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
        margin: const EdgeInsets.fromLTRB(12, 2, 12, 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _purpleLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 17, color: selected ? _purple : Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? _purple : Colors.grey.shade700,
          )),
        ]),
      ),
    );
  }

  // ─── BODY ─────────────────────────────────────────────────────────────────

  Widget _body() {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _header(),
            const SizedBox(height: 24),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: _formCard()),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: _criteriaCard()),
            ]),
            const SizedBox(height: 20),
            _recentIncidentsList(),
            const SizedBox(height: 20),
          ]),
        ),
      ),
      _bottomBar(),
    ]);
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _header() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Incidencias de canje',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _dark)),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
              color: _purpleLight, borderRadius: BorderRadius.circular(20)),
          child: const Text('ADMIN TIENDA',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _purple)),
        ),
      ]),
      const SizedBox(height: 4),
      const Text(
          'Revisa y gestiona problemas en canjes. Abre un ticket de soporte para el equipo de LetDem.',
          style: TextStyle(fontSize: 13, color: Colors.grey)),
    ]);
  }

  // ─── FORM CARD ────────────────────────────────────────────────────────────

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: _purpleLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.report_problem_outlined, size: 20, color: _purple),
          ),
          const SizedBox(width: 12),
          const Text('Nuevo ticket de canje',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        ]),
        const SizedBox(height: 20),

        // ── RedemptionCode lookup ─────────────────────────────────────────────────
        const Text('Código del redemptionCode',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _dark)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ej: LB-2024-003401',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _purple)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => _ctrl.isPreviewingRedemptionCode.value
              ? const SizedBox(
                  width: 44, height: 44,
                  child: Center(
                    child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _purple)),
                  ))
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple, foregroundColor: Colors.white,
                    minimumSize: const Size(44, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: () => _ctrl.previewRedemptionCodeCode(_codeCtrl.text.trim()),
                  child: const Icon(Icons.search, size: 18),
                )),
        ]),
        // Error or redemptionCode preview
        Obx(() {
          final err = _ctrl.previewError.value;
          if (err.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.error_outline, size: 14, color: _red),
                const SizedBox(width: 4),
                Text(err,
                    style: const TextStyle(fontSize: 12, color: _red)),
              ]),
            );
          }
          final v = _ctrl.previewedRedemptionCode.value;
          if (v == null) return const SizedBox.shrink();
          return _redemptionCodePreviewTile(v);
        }),
        const SizedBox(height: 20),

        // ── Reason dropdown ────────────────────────────────────────────────
        const Text('Motivo de la incidencia',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _dark)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedReason,
          style: const TextStyle(fontSize: 13, color: _dark),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _purple)),
          ),
          items: _reasons
              .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r, style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedReason = v ?? _reasons.first),
        ),
        const SizedBox(height: 20),

        // ── Notes ──────────────────────────────────────────────────────────
        const Text('Descripción del problema',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _dark)),
        const SizedBox(height: 6),
        TextField(
          controller: _notesCtrl,
          maxLines: 4,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Describe el problema con el mayor detalle posible...',
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _purple)),
          ),
        ),
        const SizedBox(height: 20),

        // ── Submit ─────────────────────────────────────────────────────────
        Obx(() {
          final hasRedemptionCode = _ctrl.previewedRedemptionCode.value != null;
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: hasRedemptionCode ? _purple : Colors.grey.shade200,
                foregroundColor: hasRedemptionCode ? Colors.white : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(
                _isSubmitting ? 'Enviando...' : 'Enviar a soporte',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onPressed:
                  hasRedemptionCode && !_isSubmitting ? _submitIncident : null,
            ),
          );
        }),
      ]),
    );
  }

  Widget _redemptionCodePreviewTile(RedemptionCodeModel v) {
    final customerName = _ctrl.customerNameFor(v);
    final productName  = _ctrl.productNameFor(v);
    final statusLbl    = _redemptionCodeStatusLabel(v.status);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _purpleLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Color.fromRGBO(124, 58, 237, 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Row(children: [
            Icon(Icons.check_circle_outline, size: 14, color: _purple),
            SizedBox(width: 4),
            Text('Código de canje encontrado',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _purple)),
          ]),
          GestureDetector(
            onTap: () {
              _ctrl.clearRedemptionCodePreview();
              _codeCtrl.clear();
            },
            child: const Icon(Icons.close, size: 15, color: _purple),
          ),
        ]),
        const SizedBox(height: 8),
        _previewRow('Usuario',  customerName),
        _previewRow('Producto', productName),
        _previewRow('Estado',   statusLbl),
        _previewRow('Código',   v.code),
      ]),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(
          width: 64,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: _dark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  // ─── CRITERIA CARD ────────────────────────────────────────────────────────

  Widget _criteriaCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.policy_outlined, size: 20, color: _blue),
          ),
          const SizedBox(width: 12),
          const Text('Criterio funcional',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        ]),
        const SizedBox(height: 16),
        const Text(
          'Puedes iniciar una incidencia cuando hay un problema con un canje. Nuestro equipo revisará el caso y tomará las acciones necesarias.',
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 20),
        _criteriaItem(
          icon: Icons.error_outline, color: _red,
          title: 'Error de validación',
          desc: 'El redemptionCode no pudo procesarse correctamente en el sistema.',
        ),
        const SizedBox(height: 14),
        _criteriaItem(
          icon: Icons.money_off_outlined, color: _amber,
          title: 'Doble cobro',
          desc: 'El cliente fue cargado o canjeado dos veces por el mismo redemptionCode.',
        ),
        const SizedBox(height: 14),
        _criteriaItem(
          icon: Icons.inventory_2_outlined, color: _purple,
          title: 'Producto no disponible',
          desc: 'El producto vinculado al redemptionCode no estaba disponible al momento del canje.',
        ),
        const SizedBox(height: 14),
        _criteriaItem(
          icon: Icons.build_outlined, color: _blue,
          title: 'Problema técnico',
          desc: 'Fallo del sistema al procesar el canje o validar el código.',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.access_time_outlined, size: 15, color: _green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cada ticket es revisado por el equipo de soporte en un máximo de 48 horas hábiles.',
                  style: TextStyle(
                      fontSize: 12, color: _green, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _criteriaItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Color.fromRGBO(color.r.round(), color.g.round(), color.b.round(), 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
          const SizedBox(height: 2),
          Text(desc,
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey, height: 1.4)),
        ]),
      ),
    ]);
  }

  // ─── RECENT INCIDENTS ─────────────────────────────────────────────────────

  Widget _recentIncidentsList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Incidencias recientes',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
          if (_sessionIncidents.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _purpleLight,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${_sessionIncidents.length}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _purple)),
            ),
        ]),
        const SizedBox(height: 4),
        // ⚠️ MISSING ENDPOINT: backend needs GET /marketplace/stores/{id}/incidents/
        // Currently showing only tickets submitted in this session
        const Text('Tickets enviados a soporte desde esta sesión',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        if (_sessionIncidents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.inbox_outlined,
                      size: 24, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                const Text('No hay incidencias en esta sesión',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                const Text('Los tickets aparecerán aquí tras enviarlos',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
          )
        else
          Column(
            children: _sessionIncidents.map(_incidentRow).toList(),
          ),
      ]),
    );
  }

  Widget _incidentRow(Map<String, dynamic> incident) {
    final ticketId   = incident['ticket_id']?.toString() ?? '—';
    final reason     = incident['reason']?.toString() ?? '';
    final code       = incident['redemption_code']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: _purpleLight, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.confirmation_number_outlined,
              size: 16, color: _purple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ticket #$ticketId',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
            Text('$reason${code.isNotEmpty ? ' · $code' : ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(20)),
          child: const Text('Pendiente',
              style: TextStyle(
                  fontSize: 11,
                  color: _amber,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  // ─── BOTTOM BAR ──────────────────────────────────────────────────────────

  Widget _bottomBar() {
    return Container(
      color: const Color(0xFFFEF3C7),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: const Row(children: [
        Icon(Icons.warning_amber_outlined, size: 16, color: _amber),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Cada ticket enviado queda registrado y es revisado por el equipo de soporte de LetDem',
            style: TextStyle(
                fontSize: 12, color: _amber, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  String _redemptionCodeStatusLabel(RedemptionCodeStatus status) => switch (status) {
    RedemptionCodeStatus.pending    => 'Pendiente',
    RedemptionCodeStatus.paid       => 'Pagado',
    RedemptionCodeStatus.inProgress => 'En proceso',
    RedemptionCodeStatus.delivered  => 'Entregado',
    RedemptionCodeStatus.incident   => 'Incidencia',
    RedemptionCodeStatus.redeemed   => 'Entregado',
    RedemptionCodeStatus.expired    => 'Expirado',
    RedemptionCodeStatus.cancelled  => 'Cancelado',
    RedemptionCodeStatus.rejected   => 'Rechazado',
  };

  // ─── SUBMIT ───────────────────────────────────────────────────────────────

  Future<void> _submitIncident() async {
    final redemptionCode = _ctrl.previewedRedemptionCode.value;
    if (redemptionCode == null) return;
    if (_notesCtrl.text.trim().isEmpty) {
      Get.snackbar('Campo requerido', 'Describe el problema antes de enviar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: _dark);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final result = await _ctrl.reportRedemptionCodeIncident(
        redemptionCode.id,
        reason: _selectedReason,
        notes: _notesCtrl.text.trim(),
      );
      if (result != null) {
        setState(() {
          _sessionIncidents.insert(0, {
            'ticket_id':       result['ticket_id']?.toString() ?? '—',
            'reason':          _selectedReason,
            'redemption_code': result['redemption_code']?.toString() ?? _codeCtrl.text.trim(),
          });
        });
      }
      _codeCtrl.clear();
      _notesCtrl.clear();
      _ctrl.clearRedemptionCodePreview();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
