import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/stripe_dispute_model.dart';
import '../controllers/general_admin_controller.dart';
import 'backoffice_sidebar.dart';

class StripeDisputesView extends GetView<GeneralAdminController> {
  const StripeDisputesView({super.key});

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
    controller.loadStripeDisputes();
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bg,
        body: Row(children: [
          BackofficeSidebar(current: 'pagos'),
          Expanded(child: _body(context)),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      drawer: Drawer(child: SafeArea(child: BackofficeSidebar(current: 'pagos'))),
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
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Disputas y reembolsos Stripe',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _dark)),
            SizedBox(height: 4),
            Text(
                'Disputas, devoluciones y reembolsos directo con Stripe',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          const SizedBox(height: 24),
          _statsRow(),
          const SizedBox(height: 28),
          _disputesTable(context),
        ],
      ),
    );
  }

  // ─── STAT CARDS ─────────────────────────────────────────────────────────────

  Widget _statsRow() {
    return Obx(() {
      final stats = controller.stripeDisputeStats.value;
      final pct = stats?.successRate ?? 0;
      return Row(children: [
        Expanded(child: _statCard(
          icon: Icons.gavel_rounded,
          color: _purple,
          iconBg: _purpleLight,
          label: 'Disputas abiertas',
          value: '${stats?.totalDisputes ?? 0}',
        )),
        const SizedBox(width: 12),
        Expanded(child: _statCard(
          icon: Icons.check_circle_outline,
          color: _blue,
          iconBg: const Color(0xFFEFF6FF),
          label: 'Completadas',
          value: '${stats?.completed ?? 0}',
        )),
        const SizedBox(width: 12),
        Expanded(child: _statCard(
          icon: Icons.trending_up_outlined,
          color: _green,
          iconBg: const Color(0xFFECFDF5),
          label: 'Éxito',
          value: '${pct.toStringAsFixed(0)}%',
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
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ]),
        ),
      ]),
    );
  }

  // ─── DISPUTES TABLE ─────────────────────────────────────────────────────────

  Widget _disputesTable(BuildContext context) {
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
            Expanded(flex: 3, child: Text('DISPUTA',  style: _hdrStyle)),
            Expanded(flex: 3, child: Text('IMPORTE',  style: _hdrStyle)),
            Expanded(flex: 2, child: Text('FASE',     style: _hdrStyle)),
            SizedBox(width: 110,
                child: Text('ACCIÓN', style: _hdrStyle,
                    textAlign: TextAlign.center)),
          ]),
        ),
        Container(height: 1, color: _border),
        Obx(() {
          if (controller.isLoadingDisputes.value) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final disputes = controller.stripeDisputes;
          if (disputes.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: Text('Sin disputas activas',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey))),
            );
          }
          return Column(
            children: disputes.asMap().entries
                .map((e) => _disputeRow(context, e.value, e.key.isEven))
                .toList(),
          );
        }),
      ]),
    );
  }

  Widget _disputeRow(
      BuildContext context, StripeDisputeModel d, bool even) {
    final (faseLabel, faseColor, faseBg) = _faseBadge(d.fase);
    final (actionLabel, actionColor)     = _actionConfig(d.fase, d.status);
    return Container(
      color: even ? Colors.white : const Color(0xFFFAFAFB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(
            flex: 3,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.id,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  if (d.userName.isNotEmpty)
                    Text(d.userName,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                ])),
        Expanded(
            flex: 3,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatAmount(d.amount, d.currency),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  if (d.reason.isNotEmpty)
                    Text(_reasonLabel(d.reason),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                ])),
        Expanded(flex: 2, child: _badge(faseLabel, faseColor, faseBg)),
        SizedBox(
          width: 110,
          child: Center(
            child: _actionBtn(
              actionLabel,
              actionColor,
              () => _showDisputeDialog(context, d),
            ),
          ),
        ),
      ]),
    );
  }

  // ─── DIALOG ─────────────────────────────────────────────────────────────────

  void _showDisputeDialog(BuildContext context, StripeDisputeModel d) {
    final notesCtrl = TextEditingController();
    final (_, actionColor) = _actionConfig(d.fase, d.status);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Disputa ${d.id}'),
          content: SizedBox(
            width: 420,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('ID', d.id),
                  if (d.stripeId.isNotEmpty) _detailRow('Stripe ID', d.stripeId),
                  _detailRow('Usuario', d.userName.isNotEmpty ? d.userName : '—'),
                  _detailRow('Email', d.userEmail.isNotEmpty ? d.userEmail : '—'),
                  _detailRow('Importe', _formatAmount(d.amount, d.currency)),
                  _detailRow('Fase', d.fase),
                  _detailRow('Estado', _statusLabel(d.status)),
                  if (d.reason.isNotEmpty)
                    _detailRow('Motivo', _reasonLabel(d.reason)),
                  _detailRow('Creada', _formatDate(d.createdAt)),
                  if (d.resolvedAt != null)
                    _detailRow('Resuelta', _formatDate(d.resolvedAt!)),
                  const SizedBox(height: 12),
                  const Text('Notas (opcional)',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Añadir nota interna...',
                      hintStyle: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar')),
            if (_canAct(d.status))
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  controller.performDisputeAction(
                    d.id,
                    action: _actionVerb(d.fase, d.status),
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  );
                },
                child: Text(_actionConfig(d.fase, d.status).$1),
              ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  Widget _badge(String label, Color color, Color bg) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color)),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12))),
      ]),
    );
  }

  (String, Color, Color) _faseBadge(String fase) {
    return switch (fase.toLowerCase()) {
      'backoffice'     => ('Backoffice', _purple, _purpleLight),
      'stripe'         => ('Stripe',     _blue,   const Color(0xFFEFF6FF)),
      'needs_response' => ('Pendiente',  _amber,  const Color(0xFFFFFBEB)),
      'under_review'   => ('En revisión', _blue,  const Color(0xFFEFF6FF)),
      'won'            => ('Ganada',     _green,  const Color(0xFFECFDF5)),
      'lost'           => ('Perdida',    _red,    const Color(0xFFFEF2F2)),
      'completed' || 'charge_refunded'
                       => ('Completada', _green,  const Color(0xFFECFDF5)),
      _                => (fase.isEmpty ? '—' : fase, Colors.grey,
                           const Color(0xFFF5F5F5)),
    };
  }

  (String, Color) _actionConfig(String fase, String status) {
    return switch (fase.toLowerCase()) {
      'backoffice' || 'needs_response' => ('Revisar',   _purple),
      'stripe' || 'under_review'       => ('Continuar', _blue),
      'won' || 'completed' || 'charge_refunded'
                                       => ('Auditar',   Colors.grey.shade600),
      'lost'                           => ('Apelar',    _amber),
      _                                => ('Ver',       Colors.grey.shade600),
    };
  }

  String _actionVerb(String fase, String status) {
    return switch (fase.toLowerCase()) {
      'backoffice' || 'needs_response' => 'review',
      'stripe' || 'under_review'       => 'continue',
      'won' || 'completed'             => 'audit',
      'lost'                           => 'appeal',
      _                                => 'view',
    };
  }

  bool _canAct(String status) =>
      !['won', 'lost', 'charge_refunded', 'completed'].contains(status.toLowerCase());

  String _formatAmount(double amount, String currency) {
    final sym = currency.toLowerCase() == 'eur' ? '€' : currency.toUpperCase();
    return '${amount.toStringAsFixed(2)} $sym';
  }

  String _reasonLabel(String reason) {
    return switch (reason.toLowerCase()) {
      'fraudulent'          => 'Fraude',
      'duplicate'           => 'Duplicado',
      'product_not_received'=> 'No recibido',
      'product_unacceptable'=> 'Inaceptable',
      'credit_not_processed'=> 'Crédito no procesado',
      'subscription_canceled'=> 'Suscripción cancelada',
      'unrecognized'        => 'No reconocido',
      _                     => reason.isEmpty ? '—' : reason,
    };
  }

  String _statusLabel(String s) {
    return switch (s.toLowerCase()) {
      'open'             => 'Abierta',
      'under_review'     => 'En revisión',
      'needs_response'   => 'Necesita respuesta',
      'won'              => 'Ganada',
      'lost'             => 'Perdida',
      'completed'        => 'Completada',
      'charge_refunded'  => 'Reembolsada',
      _                  => s,
    };
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}
