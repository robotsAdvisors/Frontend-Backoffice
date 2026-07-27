import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/data_subject_request_model.dart';
import '../../../data/models/legal_consent_model.dart';
import '../../../data/models/legal_version_model.dart';
import '../controllers/general_admin_controller.dart';
import 'backoffice_sidebar.dart';

class LegalConsentsView extends GetView<GeneralAdminController> {
  const LegalConsentsView({super.key});

  static const Color _purple      = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg          = Color(0xFFF8F7FF);
  static const Color _dark        = Color(0xFF1E1B4B);
  static const Color _border      = Color(0xFFEEEEEE);
  static const Color _green       = Color(0xFF10B981);
  static const Color _amber       = Color(0xFFF59E0B);
  static const Color _red         = Color(0xFFEF4444);
  static const Color _blue        = Color(0xFF3B82F6);

  static const TextStyle _hdrStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: Colors.grey,
      letterSpacing: 0.5);

  @override
  Widget build(BuildContext context) {
    controller.loadLegalConsents();
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bg,
        body: Row(children: [
          BackofficeSidebar(current: 'legal'),
          Expanded(child: _body(context)),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      drawer: Drawer(child: SafeArea(child: BackofficeSidebar(current: 'legal'))),
      body: _body(context),
    );
  }

  // ─── SIDEBAR ────────────────────────────────────────────────────────────────

  // ─── BODY ───────────────────────────────────────────────────────────────────

  Widget _body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Legal & Consentimientos',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, color: _dark)),
                  SizedBox(height: 4),
                  Text('Trazabilidad, RGPD, consentimientos y versiones legales',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showNewDocumentDialog(context),
              icon: const Icon(Icons.add, size: 15, color: Colors.white),
              label: const Text('Nuevo documento',
                  style: TextStyle(fontSize: 12, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _statsRow(),
          const SizedBox(height: 28),
          _sectionLabel('Consentimientos', Icons.verified_outlined),
          const SizedBox(height: 12),
          _consentsTable(context),
          const SizedBox(height: 28),
          _sectionLabel('Solicitudes RGPD', Icons.privacy_tip_outlined),
          const SizedBox(height: 12),
          _rgpdTable(context),
          const SizedBox(height: 28),
          _sectionLabel('Documentos legales', Icons.description_outlined),
          const SizedBox(height: 12),
          _legalDocsSection(context),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: _purple),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
    ]);
  }

  // ─── STAT CARDS ─────────────────────────────────────────────────────────────

  Widget _statsRow() {
    return Obx(() {
      final stats = controller.legalStats.value;
      final gdprPending = controller.dataSubjectRequests
          .where((r) => r.status == 'pending' || r.status == 'in_progress')
          .length;
      return Row(children: [
        Expanded(child: _statCard(
          icon: Icons.check_circle_outline,
          color: _purple,
          iconBg: _purpleLight,
          label: 'Consentimientos activos',
          value: '${stats?.totalActive ?? 0}',
        )),
        const SizedBox(width: 12),
        Expanded(child: _statCard(
          icon: Icons.hourglass_empty_outlined,
          color: _amber,
          iconBg: const Color(0xFFFFFBEB),
          label: 'Pendientes revisión',
          value: '${stats?.pendingApproval ?? 0}',
        )),
        const SizedBox(width: 12),
        Expanded(child: _statCard(
          icon: Icons.privacy_tip_outlined,
          color: _blue,
          iconBg: const Color(0xFFEFF6FF),
          label: 'RGPD pendientes',
          value: gdprPending.toString(),
        )),
      ]);
    });
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration:
              BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
      ]),
    );
  }

  // ─── CONSENTIMIENTOS TABLE ──────────────────────────────────────────────────

  Widget _consentsTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Row(children: [
            Expanded(flex: 3, child: Text('USUARIO',   style: _hdrStyle)),
            Expanded(flex: 3, child: Text('DOCUMENTO', style: _hdrStyle)),
            Expanded(flex: 2, child: Text('ESTADO',    style: _hdrStyle)),
            SizedBox(width: 100,
                child: Text('ACCIÓN', style: _hdrStyle, textAlign: TextAlign.center)),
          ]),
        ),
        Container(height: 1, color: _border),
        Obx(() {
          final consents = controller.legalConsents;
          if (consents.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: Text('Sin consentimientos registrados',
                      style: TextStyle(fontSize: 13, color: Colors.grey))),
            );
          }
          return Column(
            children: consents.asMap().entries
                .map((e) => _consentRow(context, e.value, e.key.isEven))
                .toList(),
          );
        }),
      ]),
    );
  }

  Widget _consentRow(BuildContext context, LegalConsentModel c, bool even) {
    final (label, color, bg) = _statusBadge(c.status);
    final isPending = c.status == 'pending';
    return Container(
      color: even ? Colors.white : const Color(0xFFFAFAFB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.userName.isNotEmpty ? c.userName : '—',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(c.userEmail,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
        Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_shortDocType(c.documentType),
                  style: const TextStyle(fontSize: 12)),
              Text('v${c.version}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ])),
        Expanded(flex: 2, child: _badge(label, color, bg)),
        SizedBox(
          width: 100,
          child: Center(
            child: _actionBtn(
              isPending ? 'Resolver' : 'Historial',
              isPending ? _purple : Colors.grey.shade600,
              () => _showConsentDialog(context, c),
            ),
          ),
        ),
      ]),
    );
  }

  // ─── RGPD TABLE ─────────────────────────────────────────────────────────────

  Widget _rgpdTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Row(children: [
            Expanded(flex: 3, child: Text('USUARIO',  style: _hdrStyle)),
            Expanded(flex: 2, child: Text('DERECHO',  style: _hdrStyle)),
            Expanded(flex: 2, child: Text('ESTADO',   style: _hdrStyle)),
            Expanded(flex: 2, child: Text('VENCE',    style: _hdrStyle)),
            SizedBox(width: 100,
                child: Text('ACCIÓN', style: _hdrStyle, textAlign: TextAlign.center)),
          ]),
        ),
        Container(height: 1, color: _border),
        Obx(() {
          final requests = controller.dataSubjectRequests;
          if (requests.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: Text('Sin solicitudes RGPD activas',
                      style: TextStyle(fontSize: 13, color: Colors.grey))),
            );
          }
          return Column(
            children: requests.asMap().entries
                .map((e) => _rgpdRow(context, e.value, e.key.isEven))
                .toList(),
          );
        }),
      ]),
    );
  }

  Widget _rgpdRow(BuildContext context, DataSubjectRequestModel r, bool even) {
    final (label, color, bg) = _statusBadge(r.status);
    final daysLeft = r.dueAt?.difference(DateTime.now()).inDays;
    final urgentColor =
        daysLeft != null && daysLeft <= 5 ? _red : Colors.grey.shade600;
    return Container(
      color: even ? Colors.white : const Color(0xFFFAFAFB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.userName.isNotEmpty ? r.userName : '—',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(r.userEmail,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
        Expanded(
            flex: 2,
            child: Text(_rightLabel(r.rightType),
                style: const TextStyle(fontSize: 12))),
        Expanded(flex: 2, child: _badge(label, color, bg)),
        Expanded(
            flex: 2,
            child: Text(
              daysLeft != null ? '$daysLeft días' : '—',
              style: TextStyle(
                  fontSize: 12,
                  color: urgentColor,
                  fontWeight: FontWeight.w600),
            )),
        SizedBox(
          width: 100,
          child: Center(
            child: _actionBtn('Resolver', _purple,
                () => _showRgpdDialog(context, r)),
          ),
        ),
      ]),
    );
  }

  // ─── LEGAL DOCUMENTS SECTION ─────────────────────────────────────────────────

  Widget _legalDocsSection(BuildContext context) {
    return Obx(() {
      final versions = controller.legalVersions;
      if (versions.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: const Center(
              child: Text('Sin documentos legales',
                  style: TextStyle(fontSize: 13, color: Colors.grey))),
        );
      }
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: versions.map((v) => _docCard(v)).toList(),
      );
    });
  }

  Widget _docCard(LegalVersionModel v) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: v.isActive ? _border : const Color(0xFFFEF3C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                  v.title.isNotEmpty ? v.title : v.documentName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            _badge(
              v.isActive ? 'Activo' : 'Borrador',
              v.isActive ? _green : _amber,
              v.isActive
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFFFBEB),
            ),
          ]),
          const SizedBox(height: 4),
          Text('v${v.currentVersion}',
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
          if (v.summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(v.summary,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          if (!v.isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => controller.activateLegalDocument(v.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: _purple),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Activar',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── DIALOGS ────────────────────────────────────────────────────────────────

  void _showConsentDialog(BuildContext context, LegalConsentModel c) {
    final canWithdraw = c.status == 'accepted';
    final canRestore  = c.status == 'rejected' || c.status == 'expired';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Detalle de consentimiento'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Usuario', c.userName),
              _detailRow('Email', c.userEmail),
              _detailRow('Documento', _shortDocType(c.documentType)),
              _detailRow('Versión', 'v${c.version}'),
              _detailRow('Estado', _getStatusLabel(c.status)),
              _detailRow('Fecha', _formatDate(c.acceptedAt)),
              if (c.ipAddress.isNotEmpty) _detailRow('IP', c.ipAddress),
              if (c.rejectionReason != null)
                _detailRow('Motivo', c.rejectionReason!),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
          if (canWithdraw)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: _red,
                  side: const BorderSide(color: _red)),
              onPressed: () {
                Navigator.pop(ctx);
                controller.updateLegalConsent(c.id, action: 'withdraw');
              },
              child: const Text('Retirar consentimiento'),
            ),
          if (canRestore)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _purple, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                controller.updateLegalConsent(c.id, action: 'restore');
              },
              child: const Text('Restaurar'),
            ),
        ],
      ),
    );
  }

  void _showRgpdDialog(BuildContext context, DataSubjectRequestModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Solicitud RGPD'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Usuario', r.userName),
              _detailRow('Email', r.userEmail),
              _detailRow('Derecho', _rightLabel(r.rightType)),
              _detailRow('Estado', _getStatusLabel(r.status)),
              _detailRow('Creada', _formatDate(r.createdAt)),
              if (r.dueAt != null) _detailRow('Vence', _formatDate(r.dueAt!)),
              if (r.resultUrl != null) _detailRow('Resultado', r.resultUrl!),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                side: const BorderSide(color: _red)),
            onPressed: () {
              Navigator.pop(ctx);
              controller.updateDataSubjectRequest(r.id, action: 'reject');
            },
            child: const Text('Rechazar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _purple, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              controller.updateDataSubjectRequest(r.id, action: 'complete');
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }

  void _showNewDocumentDialog(BuildContext context) {
    final typeCtrl    = TextEditingController();
    final versionCtrl = TextEditingController();
    final titleCtrl   = TextEditingController();
    final summaryCtrl = TextEditingController();
    final activateNow = ValueNotifier(false);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nuevo Documento Legal'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _formField(typeCtrl, 'Tipo de documento',
                  'right_to_access, privacy_policy...'),
              const SizedBox(height: 12),
              _formField(versionCtrl, 'Versión', '1.0'),
              const SizedBox(height: 12),
              _formField(titleCtrl, 'Título', 'Política de Privacidad'),
              const SizedBox(height: 12),
              _formField(summaryCtrl, 'Resumen', 'Descripción...', maxLines: 3),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: activateNow,
                builder: (_, val, __) => Row(children: [
                  Checkbox(
                    value: val,
                    activeColor: _purple,
                    onChanged: (v) => activateNow.value = v ?? false,
                  ),
                  const Text('Activar inmediatamente',
                      style: TextStyle(fontSize: 12)),
                ]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(ctx);
              controller.createLegalDocument(
                documentType: typeCtrl.text.trim(),
                version: versionCtrl.text.trim(),
                title: titleCtrl.text.trim(),
                summary: summaryCtrl.text.trim(),
                activateImmediately: activateNow.value,
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  // ─── SHARED HELPERS ─────────────────────────────────────────────────────────

  Widget _badge(String label, Color color, Color bg) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ]),
    );
  }

  Widget _formField(TextEditingController ctrl, String label, String hint,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  (String, Color, Color) _statusBadge(String status) {
    return switch (status.toLowerCase()) {
      'accepted'    => ('Aceptado',   _green,  const Color(0xFFECFDF5)),
      'rejected'    => ('Rechazado',  _red,    const Color(0xFFFEF2F2)),
      'expired'     => ('Expirado',   Colors.grey, const Color(0xFFF5F5F5)),
      'pending'     => ('Pendiente',  _amber,  const Color(0xFFFFFBEB)),
      'in_progress' => ('En proceso', _blue,   const Color(0xFFEFF6FF)),
      'completed'   => ('Completado', _green,  const Color(0xFFECFDF5)),
      _             => (status.isEmpty ? '—' : status,
                        Colors.grey, const Color(0xFFF5F5F5)),
    };
  }

  String _shortDocType(String type) {
    return switch (type.toLowerCase()) {
      'terms of service' || 'terms_of_service' => 'Términos de Servicio',
      'privacy policy'   || 'privacy_policy'   => 'Política de Privacidad',
      'gdpr'                                   => 'RGPD',
      'cookie_policy'    || 'cookie policy'    => 'Política de Cookies',
      _                                        => type.isEmpty ? '—' : type,
    };
  }

  String _rightLabel(String type) {
    return switch (type.toLowerCase()) {
      'access'              => 'Acceso',
      'erasure'             => 'Olvido',
      'portability'         => 'Portabilidad',
      'rectification'       => 'Rectificación',
      'restrict_processing' => 'Restricción',
      'object'              => 'Oposición',
      _                     => type,
    };
  }

  String _getStatusLabel(String s) {
    return switch (s.toLowerCase()) {
      'accepted'    => 'Aceptado',
      'rejected'    => 'Rechazado',
      'pending'     => 'Pendiente',
      'in_progress' => 'En proceso',
      'completed'   => 'Completado',
      'expired'     => 'Expirado',
      _             => s,
    };
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}
