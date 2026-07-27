import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/models/redemption_code_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/admin_controller.dart';

class ConfirmarEntregaView extends StatefulWidget {
  const ConfirmarEntregaView({super.key});

  @override
  State<ConfirmarEntregaView> createState() => _ConfirmarEntregaViewState();
}

class _ConfirmarEntregaViewState extends State<ConfirmarEntregaView> {
  static const Color _purple      = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg          = Color(0xFFF8F7FF);
  static const Color _dark        = Color(0xFF1E1B4B);
  static const Color _border      = Color(0xFFEEEEEE);
  static const Color _green       = Color(0xFF10B981);
  static const Color _red         = Color(0xFFEF4444);
  static const Color _amber       = Color(0xFFF59E0B);

  late final AdminController _ctrl;
  final _codeCtrl = TextEditingController();
  // PIN del mostrador: el backend lo exige al validar solo si la tienda tiene
  // uno definido. Si se deja vacío, no se envía (tiendas sin PIN).
  final _pinCtrl = TextEditingController();
  bool _isConfirming = false;
  bool _justConfirmed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pinCtrl.dispose();
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
        title: const Text('Confirmar entrega',
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
        _navItem(icon: Icons.grid_view_outlined, label: 'Inicio',
            onTap: () => Get.offAllNamed(Routes.ADMIN)),
        _navItem(icon: Icons.receipt_long_outlined, label: 'Canjes', selected: true),
        _navItem(icon: Icons.inventory_2_outlined, label: 'Productos',
            onTap: () => Get.toNamed(Routes.INVENTARIO)),
        _navItem(icon: Icons.history_outlined, label: 'Historial',
            onTap: () => Get.toNamed(Routes.REDEMPTION_CODE_HISTORY)),
        _navItem(icon: Icons.security_outlined, label: 'Seguridad',
            onTap: () => Get.toNamed(Routes.SEGURIDAD)),
        _navItem(icon: Icons.settings_outlined, label: 'Configuraciones',
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
            const SizedBox(height: 20),
            _searchBar(),
            const SizedBox(height: 20),
            if (_justConfirmed)
              _successBanner()
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _codeCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _detailCard()),
                ],
              ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
      _bottomBar(),
    ]);
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _header() {
    return Row(children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Confirmar entrega de canje',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: _dark)),
        SizedBox(height: 4),
        Text('Busca el código de canje para verificar y confirmar la entrega al cliente.',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
      ]),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _purpleLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: _purple, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.store_outlined, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(_ctrl.currentStore.name.isNotEmpty ? _ctrl.currentStore.name : 'Admin Tienda',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _purple)),
        ]),
      ),
    ]);
  }

  // ─── SEARCH BAR ───────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        const Icon(Icons.search, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]'))],
            style: const TextStyle(fontSize: 14, color: _dark),
            decoration: const InputDecoration(
              hintText: 'Ingresa el código de canje para confirmar...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (v) => _ctrl.previewRedemptionCodeCode(v.trim()),
          ),
        ),
        const SizedBox(width: 8),
        Obx(() => _ctrl.isPreviewingRedemptionCode.value
            ? const SizedBox(
                width: 36, height: 36,
                child: Center(
                  child: SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _purple)),
                ))
            : TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () =>
                    _ctrl.previewRedemptionCodeCode(_codeCtrl.text.trim()),
                child: const Text('Buscar',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              )),
      ]),
    );
  }

  // ─── CODE CARD ────────────────────────────────────────────────────────────

  Widget _codeCard() {
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
            child: const Icon(Icons.qr_code_outlined, size: 20, color: _purple),
          ),
          const SizedBox(width: 12),
          const Text('Código de canje',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        ]),
        const SizedBox(height: 20),

        // ── Found code badge ────────────────────────────────────────────────
        Obx(() {
          final v = _ctrl.previewedRedemptionCode.value;
          final err = _ctrl.previewError.value;

          if (err.isNotEmpty) {
            return _errorChip(err);
          }

          if (v == null) {
            return _emptyCodeState();
          }

          return _foundCodeBadge(v.code);
        }),

        const SizedBox(height: 20),

        // ── Scan button ─────────────────────────────────────────────────────
        // ⚠️ HARDCODED: QR scanning requires mobile_scanner plugin (not in pubspec).
        // Currently shows "próximamente" toast. Add to pubspec and implement when ready.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _purple,
              side: const BorderSide(color: _purple),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.qr_code_scanner_outlined, size: 18),
            label: const Text('Escanear código',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            onPressed: () => Get.snackbar(
              'Próximamente',
              'El escáner QR estará disponible en la próxima versión.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.white,
              colorText: _dark,
              duration: const Duration(seconds: 2),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Clear button ────────────────────────────────────────────────────
        Obx(() => _ctrl.previewedRedemptionCode.value != null
            ? SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Limpiar código',
                      style: TextStyle(fontSize: 13)),
                  onPressed: () {
                    _codeCtrl.clear();
                    _ctrl.clearRedemptionCodePreview();
                    setState(() => _justConfirmed = false);
                  },
                ),
              )
            : const SizedBox.shrink()),

        const SizedBox(height: 20),
        Container(height: 1, color: _border),
        const SizedBox(height: 16),

        // ── Verification info ────────────────────────────────────────────────
        _infoPoint(
          icon: Icons.verified_user_outlined,
          color: _purple,
          text: 'Verifica siempre el estado del código de canje antes de confirmar.',
        ),
        const SizedBox(height: 8),
        _infoPoint(
          icon: Icons.block_outlined,
          color: _red,
          text: 'No confirmes códigos de canje expirados o ya canjeados.',
        ),
        const SizedBox(height: 8),
        _infoPoint(
          icon: Icons.person_outline,
          color: _amber,
          text: 'Asegúrate de que el cliente está presente en la tienda.',
        ),
      ]),
    );
  }

  Widget _emptyCodeState() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, style: BorderStyle.solid),
      ),
      child: const Center(
        child: Text(
          'Ingresa o escanea un código para comenzar',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _foundCodeBadge(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: _purpleLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromRGBO(124, 58, 237, 0.25)),
      ),
      child: Column(children: [
        const Icon(Icons.check_circle_outline, size: 22, color: _purple),
        const SizedBox(height: 8),
        Text(code,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _purple,
                letterSpacing: 1.5)),
        const SizedBox(height: 4),
        const Text('Código de canje encontrado',
            style: TextStyle(fontSize: 11, color: _purple)),
      ]),
    );
  }

  Widget _errorChip(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color.fromRGBO(239, 68, 68, 0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 16, color: _red),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: const TextStyle(fontSize: 13, color: _red)),
        ),
      ]),
    );
  }

  Widget _infoPoint({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: const TextStyle(
                fontSize: 12, color: Colors.grey, height: 1.4)),
      ),
    ]);
  }

  // ─── DETAIL CARD ──────────────────────────────────────────────────────────

  Widget _detailCard() {
    return Obx(() {
      final v = _ctrl.previewedRedemptionCode.value;

      if (v == null) {
        return _emptyDetailCard();
      }

      final customerName = _ctrl.customerNameFor(v);
      final productName  = _ctrl.productNameFor(v);
      final pointsFmt    = _formatNumber(v.pointsUsed);
      final issuedFmt    = _formatDate(v.issuedAt.toLocal());
      final expiresFmt   = v.expiresAt != null
          ? _formatDate(v.expiresAt!.toLocal())
          : '—';
      // Mostrador en dos pasos (§3): primero validar (→ IN_PROGRESS), luego
      // entregar (→ DELIVERED, aquí se consumen los puntos). No se puede
      // entregar sin validar antes.
      final canValidate = v.status == RedemptionCodeStatus.paid ||
          v.status == RedemptionCodeStatus.pending;
      final canDeliver = v.status == RedemptionCodeStatus.inProgress;

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
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.local_offer_outlined,
                  size: 20, color: _green),
            ),
            const SizedBox(width: 12),
            const Text('Detalle del canje',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
          ]),
          const SizedBox(height: 20),

          // Product image placeholder or network image
          if (v.productImageUrl != null && v.productImageUrl!.isNotEmpty)
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _purpleLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  v.productImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey),
                ),
              ),
            ),

          // Product name
          Text(productName,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
          const SizedBox(height: 4),

          // Points
          Row(children: [
            const Icon(Icons.stars_rounded, size: 16, color: _purple),
            const SizedBox(width: 4),
            Text('$pointsFmt puntos',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _purple)),
          ]),

          if (v.paymentAmountEur != null && v.paymentAmountEur! > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Pago adicional: €${v.paymentAmountEur!.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],

          const SizedBox(height: 16),
          Container(height: 1, color: _border),
          const SizedBox(height: 14),

          _detailRow('Cliente',   customerName),
          _detailRow('Estado',    _statusLabel(v.status)),
          _detailRow('Emitido',   issuedFmt),
          _detailRow('Vence',     expiresFmt),
          if (v.redeemType.isNotEmpty)
            _detailRow('Tipo', v.redeemType == 'IN_STORE' ? 'En tienda' : 'Online'),

          // Payment verified badge
          if (v.paymentVerified) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.verified_outlined, size: 14, color: _green),
                SizedBox(width: 6),
                Text('Pago verificado',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _green)),
              ]),
            ),
          ],

          const SizedBox(height: 20),

          // ── Aviso si el código no admite ninguna acción ─────────────────
          if (!canValidate && !canDeliver)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: v.isDelivered
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(
                    v.isDelivered
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_outlined,
                    size: 14,
                    color: v.isDelivered ? _green : _red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    v.isDelivered
                        ? 'Este canje ya fue entregado.'
                        : 'Este código de canje no admite entrega (${_statusLabel(v.status)}).',
                    style: TextStyle(
                        fontSize: 12,
                        color: v.isDelivered ? _green : _red,
                        height: 1.4),
                  ),
                ),
              ]),
            ),

          // ── Paso 1: validar ─────────────────────────────────────────────
          if (canValidate) ...[
            TextField(
              controller: _pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'PIN de la tienda (si aplica)',
                helperText:
                    'Solo si tu tienda tiene PIN. Déjalo vacío si no.',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: _isConfirming
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.qr_code_scanner, size: 18),
                label: Text(
                  _isConfirming ? 'Validando...' : 'Validar código',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onPressed: _isConfirming ? null : () => _validate(v),
              ),
            ),
          ],

          // ── Paso 2: entregar ────────────────────────────────────────────
          if (canDeliver) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, size: 14, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Código validado, canje en proceso. Confirma la entrega solo cuando el cliente reciba el producto: al hacerlo se consumen sus puntos.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF2563EB), height: 1.4),
                  ),
                ),
              ]),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: _isConfirming
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  _isConfirming ? 'Confirmando...' : 'Confirmar entrega',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onPressed: _isConfirming ? null : () => _deliver(v),
              ),
            ),
          ],
        ]),
      );
    });
  }

  Widget _emptyDetailCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        const SizedBox(height: 32),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: _purpleLight, borderRadius: BorderRadius.circular(14)),
          child:
              const Icon(Icons.local_offer_outlined, size: 26, color: _purple),
        ),
        const SizedBox(height: 14),
        const Text('Sin código de canje seleccionado',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _dark)),
        const SizedBox(height: 6),
        const Text(
          'Busca o escanea el código de canje para ver el detalle y confirmar la entrega.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _dark),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  // ─── SUCCESS BANNER ───────────────────────────────────────────────────────

  Widget _successBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color.fromRGBO(16, 185, 129, 0.3)),
      ),
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              color: _green, borderRadius: BorderRadius.circular(32)),
          child:
              const Icon(Icons.check, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text('¡Entrega confirmada!',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: _green)),
        const SizedBox(height: 6),
        const Text(
          'El canje se entregó y los puntos del cliente se consumieron.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          icon: const Icon(Icons.add_circle_outline, size: 16),
          label: const Text('Confirmar otro canje',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          onPressed: () {
            _codeCtrl.clear();
            _pinCtrl.clear();
            _ctrl.clearRedemptionCodePreview();
            setState(() => _justConfirmed = false);
          },
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
            'Cada entrega confirmada queda registrada. Asegúrate de que el cliente recibió el producto antes de confirmar.',
            style: TextStyle(
                fontSize: 12,
                color: _amber,
                fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _statusLabel(RedemptionCodeStatus status) => switch (status) {
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

  /// Paso 1: validar el código (→ IN_PROGRESS). No abre el banner de éxito; el
  /// flujo continúa mostrando el botón de entregar.
  Future<void> _validate(RedemptionCodeModel redemptionCode) async {
    setState(() => _isConfirming = true);
    try {
      final ok = await _ctrl.validateRedemptionCodeCode(
        redemptionCode.code,
        pin: _pinCtrl.text.trim(),
      );
      if (ok) _pinCtrl.clear();
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  /// Paso 2: entregar (→ DELIVERED). Aquí el backend consume los puntos.
  Future<void> _deliver(RedemptionCodeModel redemptionCode) async {
    setState(() => _isConfirming = true);
    try {
      final ok = await _ctrl.deliverRedemptionCodeCode(redemptionCode.id);
      if (ok && mounted) {
        setState(() => _justConfirmed = true);
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }
}
