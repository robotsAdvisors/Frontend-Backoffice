import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/models/redemption_code_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/admin_controller.dart';

class RedemptionCodeHistoryView extends StatefulWidget {
  const RedemptionCodeHistoryView({Key? key}) : super(key: key);

  @override
  State<RedemptionCodeHistoryView> createState() => _RedemptionCodeHistoryViewState();
}

class _RedemptionCodeHistoryViewState extends State<RedemptionCodeHistoryView> {
  final AdminController _ctrl = Get.find<AdminController>();

  static const _purple      = Color(0xFF7C3AED);
  static const _purpleLight = Color(0xFFEDE9FE);
  static const _bg          = Color(0xFFF5F3FF);

  // tabs: 0 = Validar, 1 = Panel (historial)
  int _mainTab = 0;

  // Historial state — 0=Todos, 1=Pendientes, 2=Entregados, 3=Expirados
  int _histTab  = 0;
  int _page     = 1;
  int _pageSize = 10;
  String _search    = '';
  String _dateFilter = '';
  final _searchCtrl  = TextEditingController();
  final _dateCtrl    = TextEditingController();

  // Validar state
  final _codeCtrl    = TextEditingController();
  bool _verifiedIdentity = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _dateCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  // ─── Filtered / paginated ─────────────────────────────────────────────────

  List<RedemptionCodeModel> get _filtered {
    // When a date filter is active, use the server-fetched list (or client fallback).
    final sourceAll = _dateFilter.isNotEmpty && _ctrl.dateFilteredRedemptionCodes.isNotEmpty
        ? _ctrl.dateFilteredRedemptionCodes.toList()
        : _ctrl.redemptionCodes.toList();

    List<RedemptionCodeModel> base;
    switch (_histTab) {
      case 1: base = sourceAll.where((v) => !v.isRedeemed && !v.isExpired).toList(); break;
      case 2: base = sourceAll.where((v) => v.isRedeemed).toList(); break;
      case 3: base = sourceAll.where((v) => v.isExpired && !v.isRedeemed).toList(); break;
      default: base = sourceAll;
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      base = base.where((v) =>
          v.id.toLowerCase().contains(q) ||
          v.code.toLowerCase().contains(q) ||
          _ctrl.customerNameFor(v).toLowerCase().contains(q) ||
          _ctrl.productNameFor(v).toLowerCase().contains(q)).toList();
    }
    // Client-side date fallback for partially-typed dates
    if (_dateFilter.isNotEmpty && _ctrl.dateFilteredRedemptionCodes.isEmpty
        && !_ctrl.isLoadingDateFilter.value) {
      final parts = _dateFilter.split('/');
      if (parts.length == 3) {
        final day   = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year  = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          base = base.where((v) {
            final d = v.redeemedAt ?? v.issuedAt;
            return d.day == day && d.month == month && d.year == year;
          }).toList();
        }
      }
    }
    base.sort((a, b) => (b.redeemedAt ?? b.issuedAt)
        .compareTo(a.redeemedAt ?? a.issuedAt));
    return base;
  }

  List<RedemptionCodeModel> get _paginated {
    final f = _filtered;
    final start = (_page - 1) * _pageSize;
    if (start >= f.length) return [];
    return f.sublist(start, (start + _pageSize).clamp(0, f.length));
  }

  int get _totalPages => (_filtered.length / _pageSize).ceil().clamp(1, 9999);

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(children: [
        _sidebar(),
        Expanded(child: _mainArea()),
      ]),
    );
  }

  // ─── SIDEBAR ─────────────────────────────────────────────────────────────

  Widget _sidebar() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _purple, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.store, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      _ctrl.storeId.value;
                      return Text(_ctrl.currentStore.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800,
                              color: Color(0xFF111827)),
                          maxLines: 1, overflow: TextOverflow.ellipsis);
                    }),
                    Obx(() {
                      _ctrl.storeId.value;
                      final sub = _ctrl.currentStore.subtitle;
                      return Text(sub.isNotEmpty ? sub : 'Gestión de Tienda',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                          maxLines: 1, overflow: TextOverflow.ellipsis);
                    }),
                  ],
                ),
              ),
            ]),
          ),
          const Divider(height: 1),
          // User profile row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
            child: Obx(() {
              _ctrl.storeId.value;
              return Row(children: [
                CircleAvatar(
                  radius: 18, backgroundColor: _purple,
                  child: _ctrl.currentStore.logoUrl.startsWith('http')
                      ? ClipOval(child: Image.network(
                          _ctrl.currentStore.logoUrl,
                          width: 36, height: 36, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Text('AD',
                              style: TextStyle(fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white))))
                      : const Text('AD',
                          style: TextStyle(fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                      _ctrl.currentStore.ownerName.isNotEmpty
                          ? _ctrl.currentStore.ownerName
                          : 'Admin LetDem',
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    _ctrl.currentStore.subtitle.isNotEmpty
                        ? _ctrl.currentStore.subtitle : 'Gestión de Tienda',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
              ]);
            }),
          ),
          // Nuevo Canje button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _mainTab = 0;
                  _codeCtrl.clear();
                  _ctrl.clearRedemptionCodePreview();
                }),
                icon: const Icon(Icons.add, size: 15, color: Colors.white),
                label: const Text('Nuevo Canje',
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 6),
          _navItem(icon: Icons.home_outlined, label: 'Inicio',
              onTap: () => Get.offNamed(Routes.ADMIN)),
          _navItem(icon: Icons.swap_horiz_rounded, label: 'Canjes',
              selected: _mainTab == 0,
              onTap: () => setState(() => _mainTab = 0)),
          _navItem(icon: Icons.card_giftcard_outlined, label: 'Canjes y Beneficios',
              onTap: () => Get.toNamed(Routes.PREMIOS)),
          _navItem(icon: Icons.history_outlined, label: 'Historial',
              selected: _mainTab == 1,
              onTap: () => setState(() => _mainTab = 1)),
          _navItem(icon: Icons.bar_chart_outlined, label: 'Estadísticas',
              onTap: () => Get.toNamed(Routes.ANALYTICS)),
          const Spacer(),
          const Divider(height: 1),
          _navItem(icon: Icons.lock_outline, label: 'PIN',
              onTap: () => Get.toNamed(Routes.ADMIN_SETTINGS)),
          _navItem(icon: Icons.security_outlined, label: 'Seguridad',
              onTap: () => Get.toNamed(Routes.ADMIN_SETTINGS)),
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
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label,
      bool selected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _purpleLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: selected ? _purple : Colors.grey.shade500),
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

  // ─── MAIN AREA ───────────────────────────────────────────────────────────

  Widget _mainArea() {
    return Column(children: [
      _topBar(),
      Expanded(child: _mainTab == 0 ? _validarTab() : _panelTab()),
    ]);
  }

  Widget _topBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(children: [
        _topTab('Validación', 0),
        const SizedBox(width: 20),
        _topTab('Panel', 1),
        const Spacer(),
        const Icon(Icons.settings_outlined, size: 20, color: Color(0xFF374151)),
        const SizedBox(width: 14),
        const Icon(Icons.notifications_outlined, size: 20, color: Color(0xFF374151)),
        const SizedBox(width: 14),
        CircleAvatar(
          radius: 16, backgroundColor: _purpleLight,
          child: _ctrl.currentStore.logoUrl.startsWith('http')
              ? ClipOval(child: Image.network(_ctrl.currentStore.logoUrl,
                  width: 32, height: 32, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, size: 16, color: _purple)))
              : const Icon(Icons.person, size: 16, color: _purple),
        ),
      ]),
    );
  }

  Widget _topTab(String label, int index, {VoidCallback? onTap}) {
    final sel = _mainTab == index;
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _mainTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
              color: sel ? _purple : Colors.transparent, width: 2))),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
          color: sel ? _purple : Colors.grey.shade600)),
      ),
    );
  }

  // ─── TAB: VALIDAR ─────────────────────────────────────────────────────────

  Widget _validarTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left panel — entrada de código
        SizedBox(width: 380, child: _validarLeft()),
        // Right panel — detalle del redemptionCode
        Expanded(child: _validarRight()),
      ],
    );
  }

  Widget _validarLeft() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Validar Nuevo Canje',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: Color(0xFF111827))),
          const SizedBox(height: 6),
          const Text(
            'Introduce el código de canje o el número de tarjeta del cliente para comenzar.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text('Código de Verificación',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('CÓDIGO DE CANJE / TARJETA',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: Colors.grey, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          // ── Code input row ───────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB))),
                child: TextField(
                  controller: _codeCtrl,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      letterSpacing: 1, color: Color(0xFF111827)),
                  decoration: const InputDecoration.collapsed(
                      hintText: 'L STR - XXXX - X',
                      hintStyle: TextStyle(color: Colors.grey,
                          fontWeight: FontWeight.normal, fontSize: 13, letterSpacing: 0)),
                  onSubmitted: (_) { setState(() {}); _ctrl.previewRedemptionCodeCode(_codeCtrl.text); },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() => GestureDetector(
              onTap: _ctrl.isPreviewingRedemptionCode.value ? null
                  : () { setState(() {}); _ctrl.previewRedemptionCodeCode(_codeCtrl.text); },
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: _purple,
                    borderRadius: BorderRadius.circular(10)),
                child: _ctrl.isPreviewingRedemptionCode.value
                    ? const Center(child: SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                    : const Icon(Icons.arrow_forward, color: Colors.white, size: 20)),
            )),
          ]),
          Obx(() {
            final err = _ctrl.previewError.value;
            if (err.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(err, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))));
          }),
          const SizedBox(height: 16),
          // ── Acciones de escaneo / pago ────────────────────────────────────
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Get.snackbar(
                  'Escáner', 'Activa la cámara en un dispositivo móvil.',
                  snackPosition: SnackPosition.BOTTOM),
                icon: const Icon(Icons.qr_code_scanner, size: 16),
                label: const Text('Escanear Código',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple, side: const BorderSide(color: _purple),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(() => OutlinedButton.icon(
                onPressed: _ctrl.isInitiatingPayment.value
                    ? null
                    : () {
                        final code = _codeCtrl.text.trim();
                        if (code.isEmpty) {
                          Get.snackbar('Código requerido',
                              'Introduce primero el código de canje.',
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        _showInitiatePaymentDialog(context, code);
                      },
                icon: _ctrl.isInitiatingPayment.value
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.credit_card_outlined, size: 16),
                label: const Text('Pagar Código',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple, side: const BorderSide(color: _purple),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              )),
            ),
          ]),
          const SizedBox(height: 28),
          // ── Identidad del Cliente (cuando hay preview) ───────────────────
          Obx(() {
            final redemptionCode = _ctrl.previewedRedemptionCode.value;
            if (redemptionCode == null) return const SizedBox.shrink();
            final name     = _ctrl.customerNameFor(redemptionCode);
            final rawAlias = redemptionCode.customerAlias?.isNotEmpty == true
                ? redemptionCode.customerAlias! : name;
            final alias    = rawAlias.contains(' ') ? rawAlias : '@$rawAlias';
            final initials = name.split(' ').where((w) => w.isNotEmpty)
                .take(2).map((w) => w[0].toUpperCase()).join();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(height: 1),
              const SizedBox(height: 16),
              const Text('Identidad del Cliente',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                  radius: 26, backgroundColor: _purple,
                  child: Text(initials.isEmpty ? '?' : initials,
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w700, color: Colors.white))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text('Usuario Registrado',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const Spacer(),
                      if (redemptionCode.customerBadge?.isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(redemptionCode.customerBadge!,
                              style: const TextStyle(fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669))))
                      else if (redemptionCode.paymentVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text('Verificado',
                              style: TextStyle(fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669)))),
                    ]),
                    Text(alias,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Checkbox(
                  value: _verifiedIdentity,
                  onChanged: (v) => setState(() => _verifiedIdentity = v ?? false),
                  activeColor: _purple,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Confirmo que he verificado la identidad del cliente y que el producto está listo para ser entregado correctamente o activado digitalmente.',
                    style: TextStyle(fontSize: 11, color: Colors.grey))),
              ]),
              const SizedBox(height: 16),
            ]);
          }),

          // ── Instrucciones rápidas ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('INSTRUCCIONES RÁPIDAS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.grey, letterSpacing: 0.8)),
              const SizedBox(height: 12),
              _instruccion(1, 'Verifica que el código coincida con el cupón del cliente.'),
              _instruccion(2, 'Confirma la identidad del cliente con sus datos mostrados.'),
              _instruccion(3, 'Pulsa "Confirmar canje" para finalizar el registro.'),
            ]),
          ),
        ],
       ),
      ),
    );
  }

  Widget _instruccion(int n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 22, height: 22,
          decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle),
          child: Center(child: Text('$n',
              style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w700, color: Colors.white)))),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
      ]),
    );
  }

  Widget _validarRight() {
    final ctx = context;
    return Obx(() {
      final redemptionCode = _ctrl.previewedRedemptionCode.value;
      if (redemptionCode == null) {
        return Container(
          color: const Color(0xFFF8F7FF),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: _purpleLight, shape: BoxShape.circle),
                  child: const Icon(Icons.qr_code_scanner,
                      size: 48, color: _purple)),
                const SizedBox(height: 20),
                const Text('Escanea o ingresa un código',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 8),
                const Text(
                  'Los detalles del premio y el titular\naparecerán aquí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        );
      }

      final productName = _ctrl.productNameFor(redemptionCode);
      final imageUrl    = redemptionCode.productImageUrl ?? '';
      final pts         = redemptionCode.pointsUsed;
      final sku         = redemptionCode.productSku ?? '';
      final isAvailable = !redemptionCode.isRedeemed && !redemptionCode.isExpired;
      final payAmt      = redemptionCode.paymentAmountEur;
      final payOk       = redemptionCode.paymentVerified;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Product image + Disponible badge ──────────────────────
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: imageUrl.startsWith('http')
                    ? Image.network(imageUrl,
                        height: 180, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder())
                    : _imagePlaceholder()),
              Positioned(top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: isAvailable
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    isAvailable ? 'Disponible'
                        : redemptionCode.isRedeemed ? 'Canjeado' : 'Expirado',
                    style: const TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w700, color: Colors.white)))),
            ]),
            // ── Info section ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(productName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                    sku.isNotEmpty ? 'SKU: $sku' : 'Premio de la tienda',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 16),
                // Cost row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Coste en Pts',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Row(children: [
                      Text(_fmtNum(pts),
                          style: const TextStyle(fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: 4),
                      Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B), shape: BoxShape.circle),
                        child: const Icon(Icons.star,
                            size: 11, color: Colors.white)),
                    ]),
                  ]),
                const SizedBox(height: 8),
                // Estado row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estado:',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text(
                      isAvailable ? 'Listo para entrega'
                          : redemptionCode.isRedeemed ? 'Ya canjeado' : 'Expirado',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: isAvailable
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626))),
                  ]),
                // Stripe section
                if (payAmt != null && payAmt > 0) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  const Text('Pago externo vía Stripe',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                    'Se registrará un pago adicional por gestión de envío o tasa de gestión.',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text('${payAmt.toStringAsFixed(2)} €',
                        style: const TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    const Text('🇪🇸', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    const Text('🇪🇺', style: TextStyle(fontSize: 16)),
                  ]),
                  if (payOk) ...[
                    const SizedBox(height: 8),
                    const Row(children: [
                      Icon(Icons.check_circle, size: 14,
                          color: Color(0xFF059669)),
                      SizedBox(width: 6),
                      Text('Pago verificado con éxito',
                          style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669))),
                    ]),
                  ],
                ],
                const SizedBox(height: 20),
                // ── Confirmar canje button ──────────────────────────
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isAvailable && !_ctrl.isLoading.value
                        ? () async {
                            final ok = await _ctrl.validateRedemptionCodeCode(
                                redemptionCode.code);
                            if (ok) _ctrl.clearRedemptionCodePreview();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple, foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _purple.withValues(alpha: 0.4),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Confirmar canje',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 8),
                // ── Footer disclaimer ──────────────────────────────
                const Text(
                  'Al confirmar, los puntos se descontarán permanentemente de la cuenta del cliente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 12),
                // ── Incidencia / Cancelar ──────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  GestureDetector(
                    onTap: () => _showIncidentDialog(ctx, redemptionCode),
                    child: const Row(children: [
                      Icon(Icons.arrow_upward, size: 13, color: Colors.grey),
                      SizedBox(width: 3),
                      Text('Incidencia',
                          style: TextStyle(fontSize: 12, color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ])),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => _ctrl.clearRedemptionCodePreview(),
                    child: const Row(children: [
                      Icon(Icons.close, size: 13, color: Colors.grey),
                      SizedBox(width: 3),
                      Text('Cancelar',
                          style: TextStyle(fontSize: 12, color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ])),
                ]),
              ]),
            ),
          ]),
        ),
      );
    });
  }

  // ignore: unused_element — reservado para uso futuro en condiciones de canje
  Widget _condRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: color ?? _purple),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12,
            color: color ?? const Color(0xFF374151),
            fontWeight: FontWeight.w500)),
      ]),
    );
  }

  void _showIncidentDialog(BuildContext context, RedemptionCodeModel redemptionCode) {
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reportar Incidencia'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Describe el problema con este canje:',
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ej: El código no coincide con el cupón...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            autofocus: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(ctx).pop();
              await _ctrl.reportRedemptionCodeIncident(redemptionCode.id, reason: reason);
            },
            child: const Text('Reportar')),
        ],
      ),
    );
  }

  void _showInitiatePaymentDialog(BuildContext context, String code) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.credit_card_outlined, color: _purple, size: 20),
          SizedBox(width: 8),
          Text('Iniciar Pago del Canje'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Código: $code',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text(
            'Se generará un Payment Intent en Stripe por el importe monetario del redemptionCode.',
            style: TextStyle(fontSize: 13)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await _ctrl.initiateRedemptionCodePayment(code);
              if (result != null && context.mounted) {
                _showPaymentResultDialog(context, result);
              }
            },
            child: const Text('Confirmar Pago')),
        ],
      ),
    );
  }

  void _showPaymentResultDialog(
      BuildContext context, Map<String, dynamic> result) {
    final amountEur  = (result['amount_eur'] as num?)?.toDouble() ?? 0.0;
    final status     = result['status']?.toString() ?? '';
    final intentId   = result['payment_intent_id']?.toString() ?? '';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 20),
          SizedBox(width: 8),
          Text('Pago Iniciado'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _payResultRow('Importe', '${amountEur.toStringAsFixed(2)} €'),
          _payResultRow('Estado', status),
          if (intentId.isNotEmpty)
            _payResultRow('Intent ID', intentId),
          const SizedBox(height: 8),
          const Text(
            'Utiliza el client_secret con Stripe SDK para completar el pago.',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido')),
        ],
      ),
    );
  }

  Widget _payResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(child: Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 200, width: double.infinity,
      color: _purpleLight,
      child: const Icon(Icons.card_giftcard_outlined,
          size: 56, color: _purple),
    );
  }

  // ─── TAB: PANEL (historial) ────────────────────────────────────────────────

  Widget _panelTab() {
    return Obx(() {
      if (_ctrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _panelTitleRow(),
          const SizedBox(height: 20),
          _tableCard(),
          const SizedBox(height: 20),
          _analyticsRow(),
        ]),
      );
    });
  }

  // ── Panel title + search + export ─────────────────────────────────────────

  Widget _panelTitleRow() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Historial de Operaciones',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  color: Color(0xFF111827))),
          SizedBox(height: 2),
          Text('Registro completo de canjes, entregas y eventos por tienda.',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
      ),
      // Search
      SizedBox(
        width: 260, height: 38,
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Buscar alias, premio o referencia...',
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey.shade400),
            filled: true, fillColor: const Color(0xFFF5F5F5), isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide.none)),
          onChanged: (v) => setState(() { _search = v; _page = 1; }),
        ),
      ),
      const SizedBox(width: 10),
      // Date filter
      SizedBox(
        width: 160, height: 38,
        child: TextField(
          controller: _dateCtrl,
          decoration: InputDecoration(
            hintText: 'Filtrar por fecha...',
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.calendar_today_outlined, size: 15,
                color: Colors.grey.shade400),
            suffixIcon: _dateFilter.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    onPressed: () {
                      _dateCtrl.clear();
                      setState(() { _dateFilter = ''; _page = 1; });
                      _ctrl.loadRedemptionCodesForDate('');
                    })
                : null,
            filled: true, fillColor: const Color(0xFFF5F5F5), isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide.none)),
          onChanged: (v) {
            final trimmed = v.trim();
            setState(() { _dateFilter = trimmed; _page = 1; });
            // Convierte dd/MM/yyyy → YYYY-MM-DD para el backend
            if (trimmed.length == 10 && trimmed.contains('/')) {
              final parts = trimmed.split('/');
              if (parts.length == 3) {
                final iso = '${parts[2]}-${parts[1].padLeft(2,'0')}-${parts[0].padLeft(2,'0')}';
                _ctrl.loadRedemptionCodesForDate(iso);
              }
            } else if (trimmed.isEmpty) {
              _ctrl.loadRedemptionCodesForDate('');
            }
          },
        ),
      ),
      const SizedBox(width: 10),
      Obx(() => OutlinedButton.icon(
        onPressed: _ctrl.isExportingCsv.value ? null : _ctrl.exportInventoryCsv,
        icon: _ctrl.isExportingCsv.value
            ? const SizedBox(width: 13, height: 13,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.download_outlined, size: 15,
                color: Color(0xFF374151)),
        label: const Text('Exportar CSV',
            style: TextStyle(fontSize: 12, color: Color(0xFF374151))),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      )),
    ]);
  }

  // ── Table ─────────────────────────────────────────────────────────────────

  Widget _tableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        _tableTabs(),
        _tableHeader(),
        if (_paginated.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Column(children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 40, color: Color(0xFFD1D5DB)),
              const SizedBox(height: 12),
              Text(
                _search.isNotEmpty || _dateFilter.isNotEmpty
                    ? 'Sin resultados para los filtros aplicados'
                    : 'No hay operaciones en este periodo',
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ])))
        else ...[
          ..._paginated.map(_tableRow),
        ],
        _paginationBar(),
      ]),
    );
  }

  Widget _tableTabs() {
    final counts = [
      _ctrl.redemptionCodes.length,
      _ctrl.redemptionCodes.where((v) => !v.isRedeemed && !v.isExpired).length,
      _ctrl.redeemedRedemptionCodes.length,
      _ctrl.expiredUnredeemedRedemptionCodes.length,
    ];
    const labels = ['Todos', 'Pendientes', 'Entregados', 'Expirados sin canjear'];

    return Container(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(children: [
        ...List.generate(labels.length, (i) {
          final sel = _histTab == i;
          return GestureDetector(
            onTap: () => setState(() { _histTab = i; _page = 1; }),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                    color: sel ? _purple : Colors.transparent, width: 2))),
              child: Row(children: [
                Text(labels[i], style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                    color: sel ? _purple : Colors.grey.shade600)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: sel ? _purpleLight : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${counts[i]}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: sel ? _purple : Colors.grey.shade500))),
              ]),
            ),
          );
        }),
        const Spacer(),
        Text(
          _filtered.isEmpty
              ? 'Sin resultados'
              : 'Mostrando ${(_page - 1) * _pageSize + 1}–'
                '${((_page * _pageSize).clamp(0, _filtered.length))} '
                'de ${_filtered.length}',
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 14),
      ]),
    );
  }

  Widget _tableHeader() {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
        color: Colors.grey, letterSpacing: 0.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      child: const Row(children: [
        SizedBox(width: 110, child: Text('FECHA', style: style)),
        Expanded(flex: 2, child: Text('USUARIO ALIAS', style: style)),
        Expanded(flex: 3, child: Text('PREMIO / PTS', style: style)),
        SizedBox(width: 120, child: Text('ESTADO', style: style)),
        SizedBox(width: 140, child: Text('REFERENCIA', style: style)),
        SizedBox(width: 32),
      ]),
    );
  }

  Widget _tableRow(RedemptionCodeModel v) {
    final eventDate   = v.redeemedAt ?? v.issuedAt;
    final customerName = _ctrl.customerNameFor(v);
    final rawAlias    = v.customerAlias?.isNotEmpty == true ? v.customerAlias! : customerName;
    final alias       = rawAlias.contains(' ') ? rawAlias : '@$rawAlias';
    final initials    = customerName.split(' ')
        .where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join().toUpperCase();
    final productName = _ctrl.productNameFor(v);
    final pts         = v.pointsUsed;
    // Reference: use code or derive short id
    // NOTE: backend should return v.code directly — fallback uses id prefix
    final ref         = v.code.isNotEmpty
        ? v.code
        : 'A${v.id.substring(0, 2).toUpperCase()}-${v.id.substring(2, 7).toUpperCase()}';
    final hasWarning  = v.isExpired && !v.isRedeemed;
    final isPending   = !v.isRedeemed && !v.isExpired;

    Color statusBg; Color statusFg; String statusLabel;
    if (v.isRedeemed) {
      statusBg = const Color(0xFFECFDF5); statusFg = const Color(0xFF059669);
      statusLabel = 'Entregado';
    } else if (v.isIncident) {
      statusBg = const Color(0xFFFEF2F2); statusFg = const Color(0xFFDC2626);
      statusLabel = 'Incidencia';
    } else if (v.isExpired) {
      statusBg = const Color(0xFFF3F4F6); statusFg = const Color(0xFF6B7280);
      statusLabel = 'Expirado';
    } else if (v.isInProgress) {
      statusBg = const Color(0xFFDBEAFE); statusFg = const Color(0xFF1D4ED8);
      statusLabel = 'En proceso';
    } else {
      statusBg = const Color(0xFFFFF7ED); statusFg = const Color(0xFFD97706);
      statusLabel = 'Pendiente';
    }

    return Column(children: [
      InkWell(
        onTap: () => _showRedemptionCodeDetail(context, v),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            // Fecha
            SizedBox(width: 110, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_fmtDate(eventDate.toLocal()),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Color(0xFF111827))),
              Text(_fmtTime(eventDate.toLocal()),
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ])),

            // Usuario alias
            Expanded(flex: 2, child: Row(children: [
              CircleAvatar(radius: 16, backgroundColor: _purpleLight,
                  child: Text(initials.isEmpty ? '?' : initials,
                      style: const TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w700, color: _purple))),
              const SizedBox(width: 8),
              Expanded(child: Text(alias,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF111827)),
                  overflow: TextOverflow.ellipsis)),
            ])),

            // Premio / Pts
            Expanded(flex: 3, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(productName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF111827)),
                  overflow: TextOverflow.ellipsis, maxLines: 1),
              const SizedBox(height: 2),
              Text(
                pts > 0 ? '${_fmtNum(pts)} Pts' : (isPending ? 'Pendiente' : '—'),
                style: TextStyle(fontSize: 11,
                    color: pts > 0 ? const Color(0xFF7C3AED) : Colors.grey,
                    fontWeight: pts > 0 ? FontWeight.w700 : FontWeight.normal)),
            ])),

            // Estado badge
            SizedBox(width: 120, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: statusBg,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(statusLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: statusFg)))),

            // Referencia + warning
            SizedBox(width: 140, child: Row(children: [
              if (hasWarning)
                const Padding(padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.warning_amber_rounded, size: 14,
                        color: Color(0xFFD97706))),
              Expanded(child: Text(ref,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasWarning
                          ? const Color(0xFFD97706)
                          : const Color(0xFF374151)),
                  overflow: TextOverflow.ellipsis)),
            ])),

            // Chevron
            const SizedBox(width: 32,
                child: Icon(Icons.chevron_right, size: 18, color: Colors.grey)),
          ]),
        ),
      ),
      const Divider(height: 1, color: Color(0xFFF3F4F6)),
    ]);
  }

  void _showRedemptionCodeDetail(BuildContext context, RedemptionCodeModel v) {
    final productName  = _ctrl.productNameFor(v);
    final customerName = _ctrl.customerNameFor(v);
    final alias        = v.customerAlias?.isNotEmpty == true
        ? '@${v.customerAlias}' : customerName;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.receipt_long_outlined, color: _purple, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(productName, overflow: TextOverflow.ellipsis)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _detailRow('Cliente', alias),
          _detailRow('Email', _ctrl.customerEmailFor(v)),
          _detailRow('Código', v.code.isNotEmpty ? v.code : v.id),
          _detailRow('Puntos', '${v.pointsUsed}'),
          _detailRow('Estado',
              v.isRedeemed ? 'Entregado' : v.isExpired ? 'Expirado' : 'Pendiente'),
          if (v.redeemedAt != null)
            _detailRow('Entregado el',
                _fmtDate(v.redeemedAt!.toLocal())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar')),
          if (!v.isRedeemed && !v.isExpired)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final ok = await _ctrl.validateRedemptionCodeCode(v.code);
                if (ok) _ctrl.clearRedemptionCodePreview();
              },
              child: const Text('Confirmar entrega')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 100,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Expanded(child: Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  // ── Pagination ─────────────────────────────────────────────────────────────

  Widget _paginationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        const Text('Filas por página:',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: _pageSize,
          underline: const SizedBox.shrink(),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: [10, 20, 50].map((n) =>
              DropdownMenuItem(value: n, child: Text('$n'))).toList(),
          onChanged: (v) {
            if (v != null) setState(() { _pageSize = v; _page = 1; });
          },
        ),
        const Spacer(),
        _pgBtn(Icons.chevron_left, _page > 1 ? () => setState(() => _page--) : null),
        const SizedBox(width: 4),
        ..._pageNums().map((n) => n == -1
            ? const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('...', style: TextStyle(color: Colors.grey)))
            : _pgNum(n, n == _page, () => setState(() => _page = n))),
        const SizedBox(width: 4),
        _pgBtn(Icons.chevron_right,
            _page < _totalPages ? () => setState(() => _page++) : null),
      ]),
    );
  }

  // ── Analytics row (bottom) ─────────────────────────────────────────────────

  Widget _analyticsRow() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _canjesporEstadoCard()),
      const SizedBox(width: 16),
      Expanded(child: _topProductsCard()),
    ]);
  }

  // "Canjes por estado" — donut-style legend card
  Widget _canjesporEstadoCard() {
    // GET /marketplace/analytics/redemptionCodes/by-status/?store={id}
    // { entregados: N, pendientes: N, expirados: N }
    final status     = _ctrl.redemptionCodesByStatus.value;
    final entregados = status['entregados'] as int? ?? _ctrl.redeemedRedemptionCodes.length;
    final pendientes = status['pendientes'] as int?
        ?? _ctrl.redemptionCodes.where((v) => !v.isRedeemed && !v.isExpired).length;
    final expirados  = status['expirados'] as int?
        ?? _ctrl.expiredUnredeemedRedemptionCodes.length;
    final total      = entregados + pendientes + expirados;
    final safeTotal  = total == 0 ? 1 : total;

    final pEntregados = entregados / safeTotal;
    final pPendientes = pendientes / safeTotal;
    final pExpirados  = expirados  / safeTotal;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Canjes por estado',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: Color(0xFF111827)))),
          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
        ]),
        const SizedBox(height: 20),
        // Simple horizontal stacked bar
        if (total > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(height: 10,
              child: Row(children: [
                if (pEntregados > 0)
                  Expanded(flex: (pEntregados * 100).round(),
                      child: const ColoredBox(color: Color(0xFF059669))),
                if (pPendientes > 0)
                  Expanded(flex: (pPendientes * 100).round(),
                      child: const ColoredBox(color: Color(0xFFD97706))),
                if (pExpirados > 0)
                  Expanded(flex: (pExpirados * 100).round(),
                      child: const ColoredBox(color: Color(0xFF9CA3AF))),
              ]),
            ),
          ),
          const SizedBox(height: 20),
        ],
        _statusLegendRow(
          color: const Color(0xFF059669), label: 'Entregados',
          count: entregados, pct: pEntregados),
        const SizedBox(height: 12),
        _statusLegendRow(
          color: const Color(0xFFD97706), label: 'Pendientes',
          count: pendientes, pct: pPendientes),
        const SizedBox(height: 12),
        _statusLegendRow(
          color: const Color(0xFF9CA3AF), label: 'Expirados',
          count: expirados, pct: pExpirados),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 14),
        Row(children: [
          Text('$total', style: const TextStyle(fontSize: 28,
              fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          const SizedBox(width: 8),
          const Text('Canjes totales',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
      ]),
    );
  }

  Widget _statusLegendRow({
    required Color color,
    required String label,
    required int count,
    required double pct,
  }) {
    final pctStr = '${(pct * 100).round()}%';
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))),
      Text('$count',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: Color(0xFF111827))),
      const SizedBox(width: 10),
      SizedBox(width: 38,
          child: Text(pctStr, textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Colors.grey))),
    ]);
  }

  // "Premios más canjeados"
  // GET /marketplace/analytics/products/top-redeemed/?store={id}&limit=5
  // [{ id, name, redeemed_count, stock }]
  Widget _topProductsCard() {
    return Obx(() {
      final items    = _ctrl.topRedeemedProducts;
      final maxCount = items.isEmpty ? 1
          : (items.first['redeemed_count'] as int? ?? 1).clamp(1, 999999);

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Premios más canjeados',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Sin datos aún',
                  style: TextStyle(color: Colors.grey))))
          else
            ...items.map((item) {
              final name    = (item['name'] as String?) ?? '—';
              final count   = (item['redeemed_count'] as int?) ?? 0;
              final stock   = (item['stock'] as int?) ?? 0;
              final barFrac = count / maxCount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(name,
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827)),
                        overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text('$count canjes',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: barFrac.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF3F4F6),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF7C3AED))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Stock: $stock ud.',
                        style: const TextStyle(fontSize: 10,
                            color: Colors.grey, fontWeight: FontWeight.w500)),
                  ]),
                ]),
              );
            }),
        ]),
      );
    });
  }

  List<int> _pageNums() {
    final t = _totalPages;
    if (t <= 5) return List.generate(t, (i) => i + 1);
    if (_page <= 3) return [1, 2, 3, -1, t];
    if (_page >= t - 2) return [1, -1, t - 2, t - 1, t];
    return [1, -1, _page, -1, t];
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

  Widget _pgNum(int n, bool current, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: current ? _purple : Colors.transparent,
          border: Border.all(color: current ? _purple : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text('$n',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: current ? Colors.white : Colors.black87))),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _fmtNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000)   return '${(n / 1000).toStringAsFixed(0)}K';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  static String _fmtDate(DateTime d) {
    const meses = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                   'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${meses[d.month]} ${d.year}';
  }

  static String _fmtTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:${m} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }
}
