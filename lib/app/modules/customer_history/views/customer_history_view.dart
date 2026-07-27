import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/order_model.dart';
import '../../../data/models/redemption_code_model.dart';
import '../controllers/customer_history_controller.dart';

class CustomerHistoryView extends GetView<CustomerHistoryController> {
  const CustomerHistoryView({Key? key}) : super(key: key);

  static const _purple = Color(0xFF7C3AED);
  static const _purpleLight = Color(0xFFEDE9FE);
  static const _bgTop = Color(0xFFF5F0FF);
  static const _bgBottom = Color(0xFFEADDFF);
  static const _darkQr1 = Color(0xFF1A1A2E);
  static const _darkQr2 = Color(0xFF2D1B4E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: _purple, size: 20),
              const SizedBox(width: 4),
              const Text(
                'Letdem',
                style: TextStyle(
                    color: _purple,
                    fontWeight: FontWeight.w800,
                    fontSize: 20),
              ),
            ],
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _navTab('Marketplace', false),
            const SizedBox(width: 24),
            _navTab('Earning', false),
            const SizedBox(width: 24),
            _navTab('My Rewards', true),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          ),
          const CircleAvatar(
            radius: 18,
            backgroundColor: _purpleLight,
            child: Icon(Icons.person_outline, color: _purple, size: 20),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: Obx(() => _body()),
      ),
    );
  }

  Widget _navTab(String label, bool selected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: selected ? _purple : Colors.black54,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        if (selected)
          Container(
            height: 2,
            width: 40,
            decoration: BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          const SizedBox(height: 2),
      ],
    );
  }

  Widget _body() {
    if (controller.loadingWallet.value || controller.loadingHistory.value) {
      return const Center(child: CircularProgressIndicator());
    }

    final all = controller.walletMovements;
    final pending = all.where((v) => !v.isRedeemed && !v.isExpired).toList();
    final past = all.where((v) => v.isRedeemed || v.isExpired).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          pending.isEmpty
              ? _emptyState()
              : _redemptionCodeSection(pending),
          _footerLinks(pending.isNotEmpty ? pending.first.storeName : null),
          const SizedBox(height: 32),
          if (past.isNotEmpty) _historySection(past),
          if (controller.orders.isNotEmpty) _ordersSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── RedemptionCode cards (pending) ──────────────────────────────────────────────

  Widget _redemptionCodeSection(List<RedemptionCodeModel> redemptionCodes) {
    if (redemptionCodes.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _redemptionCodeCard(redemptionCodes.first),
      );
    }
    return SizedBox(
      height: 680,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: redemptionCodes.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _redemptionCodeCard(redemptionCodes[i]),
        ),
      ),
    );
  }

  Widget _redemptionCodeCard(RedemptionCodeModel redemptionCode) {
    final productName = redemptionCode.productName?.isNotEmpty == true
        ? redemptionCode.productName!
        : controller.productNameFor(redemptionCode);
    final storeName =
        redemptionCode.storeName?.isNotEmpty == true ? redemptionCode.storeName! : '';
    final expiresAt = redemptionCode.expiresAt;
    final expiryStr =
        expiresAt != null ? _formatDate(expiresAt.toLocal()) : '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 28),
          _productImage(redemptionCode),
          const SizedBox(height: 14),
          _statusBadge(redemptionCode),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              productName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87),
            ),
          ),
          const SizedBox(height: 6),
          if (storeName.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  storeName,
                  style:
                      const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _DashedDivider(),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _qrArea(redemptionCode),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              'Show this QR code at the physical store\nto claim your reward.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey, height: 1.5),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'POINTS SPENT',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${redemptionCode.pointsUsed} pts',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _purple),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'EXPIRATION',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      expiryStr,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _fullButton(
                  label: 'Add to Apple Wallet',
                  icon: Icons.account_balance_wallet_outlined,
                  filled: true,
                  onTap: () => Get.snackbar(
                      'Próximamente', 'Add to Wallet estará disponible pronto.'),
                ),
                const SizedBox(height: 10),
                _fullButton(
                  label: 'Download PDF Receipt',
                  icon: Icons.download_outlined,
                  filled: false,
                  onTap: () => Get.snackbar(
                      'Próximamente', 'Descarga de PDF estará disponible pronto.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _productImage(RedemptionCodeModel redemptionCode) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _purpleLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.card_giftcard_outlined,
          size: 34, color: _purple),
    );
  }

  Widget _statusBadge(RedemptionCodeModel redemptionCode) {
    if (redemptionCode.isRedeemed) {
      return _badge('Redeemed', Colors.grey.shade500, Icons.check_circle_outline);
    }
    if (redemptionCode.isExpired) {
      return _badge('Expired', Colors.redAccent, Icons.cancel_outlined);
    }
    return _badge('Ready to Redeem', Colors.green.shade600, Icons.check_circle_outline);
  }

  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _qrArea(RedemptionCodeModel redemptionCode) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkQr1, _darkQr2],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: redemptionCode.qrCode != null &&
                (redemptionCode.qrCode!.startsWith('http') ||
                    redemptionCode.qrCode!.startsWith('data:'))
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  redemptionCode.qrCode!,
                  width: 148,
                  height: 148,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _qrPlaceholder(redemptionCode),
                ),
              )
            : _qrPlaceholder(redemptionCode),
      ),
    );
  }

  Widget _qrPlaceholder(RedemptionCodeModel redemptionCode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.qr_code_2, size: 100, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          redemptionCode.code,
          style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              letterSpacing: 2,
              fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _fullButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white, size: 18),
              label: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: _purple, size: 18),
              label: Text(label,
                  style: const TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _purple, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
    );
  }

  Widget _footerLinks(String? storeName) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.help_outline,
                size: 15, color: Colors.grey),
            label: const Text('Need help with redemption?',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const Text('|', style: TextStyle(color: Colors.grey)),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.location_on_outlined,
                size: 15, color: Colors.grey),
            label: Text(
              storeName != null && storeName.isNotEmpty
                  ? 'Find $storeName'
                  : 'Find the Store',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _purpleLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.confirmation_number_outlined,
                  size: 48, color: _purple),
            ),
            const SizedBox(height: 20),
            const Text('No tienes recompensas activas',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            const Text('Canjea puntos en el Marketplace para obtener redemptionCodes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ── History (redeemed / expired) ─────────────────────────────────────────

  Widget _historySection(List<RedemptionCodeModel> past) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...past.map(_historyTile),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _historyTile(RedemptionCodeModel redemptionCode) {
    final status = controller.statusLabel(redemptionCode);
    final statusColor = redemptionCode.isDelivered
        ? Colors.green.shade600
        : redemptionCode.isInProgress
            ? Colors.blue.shade600
            : status == 'Pendiente'
                ? Colors.orange
                : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              redemptionCode.isDelivered
                  ? Icons.check_circle_outline
                  : redemptionCode.isInProgress
                      ? Icons.hourglass_bottom
                      : Icons.cancel_outlined,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.productNameFor(redemptionCode),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  redemptionCode.redeemedAt != null
                      ? 'Entregado ${_formatDate(redemptionCode.redeemedAt!.toLocal())}'
                      : 'Expirado ${redemptionCode.expiresAt != null ? _formatDate(redemptionCode.expiresAt!.toLocal()) : ''}',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${redemptionCode.pointsUsed} pts',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _purple),
              ),
              if (controller.canRate(redemptionCode))
                Obx(() => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                          5,
                          (i) => GestureDetector(
                                onTap: () =>
                                    controller.rateRedemptionCode(redemptionCode.id, i + 1),
                                child: Icon(
                                  controller.ratingFor(redemptionCode.id) > i
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                              )),
                    )),
            ],
          ),
        ],
      ),
    );
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  Widget _ordersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mis compras',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...controller.orders.map(_orderTile),
          if (controller.ordersPage.value?.meta.hasMore == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Obx(
                  () => controller.loadingMoreOrders.value
                      ? const CircularProgressIndicator()
                      : OutlinedButton(
                          onPressed: controller.loadMoreOrders,
                          child: const Text('Cargar más'),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _orderTile(OrderModel order) {
    final statusColor =
        order.status == 'PAID' || order.status == 'CLOSED'
            ? Colors.green.shade600
            : order.status == 'CANCELLED'
                ? Colors.redAccent
                : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Orden #${order.id}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${order.items.length} artículo${order.items.length != 1 ? 's' : ''} · ${_formatDate(order.createdAt.toLocal())}',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedLinePainter(),
        size: const Size(double.infinity, 1),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    const dashW = 6.0;
    const gapW = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashW, 0), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => false;
}
