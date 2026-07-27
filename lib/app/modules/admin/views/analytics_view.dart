import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../utils/constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/admin_controller.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({Key? key}) : super(key: key);

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  final AdminController _ctrl = Get.find<AdminController>();
  bool _weekMode = true;

  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg = Color(0xFFF8F7FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          _sidebar(context),
          Expanded(child: _mainArea()),
        ],
      ),
    );
  }

  // ── Sidebar ──────────────────────────────────────────────────────────────

  Widget _sidebar(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(Constants.logo, height: 24),
                const SizedBox(height: 4),
                const Text('Shop Management',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _navItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            onTap: () => Get.offNamed(Routes.ADMIN),
          ),
          _navItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            onTap: () => Get.offNamed(Routes.ADMIN),
          ),
          _navItem(
            icon: Icons.receipt_long_outlined,
            label: 'Canjes',
            onTap: () => Get.toNamed(Routes.REDEMPTION_CODE_HISTORY),
          ),
          _navItem(
            icon: Icons.analytics_outlined,
            label: 'Analytics',
            selected: true,
          ),
          _navItem(
            icon: Icons.store_outlined,
            label: 'Datos tienda',
            onTap: () => Get.offNamed(Routes.ADMIN),
          ),
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _purpleLight,
                  child: const Icon(Icons.person_outline, size: 16, color: _purple),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AuthService.currentUserEmail ?? 'Admin',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AuthService.isStoreAdmin ? 'Store Admin' : 'Store Viewer',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18, color: Colors.grey),
                  tooltip: 'Sign out',
                  onPressed: () async {
                    await AuthService.signOut();
                    Get.offAllNamed(Routes.WELCOME);
                  },
                ),
              ],
            ),
          ),
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
    return Material(
      color: selected ? _purpleLight : Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(icon,
            size: 18, color: selected ? _purple : Colors.grey.shade600),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? _purple : Colors.grey.shade800,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // ── Main area ─────────────────────────────────────────────────────────────

  Widget _mainArea() {
    return Obx(() {
      if (_ctrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 24),
            _statCards(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _chartCard()),
                const SizedBox(width: 20),
                SizedBox(width: 220, child: _topCategoriesCard()),
              ],
            ),
            const SizedBox(height: 24),
            _productTable(),
          ],
        ),
      );
    });
  }

  Widget _header() {
    final hasRealData = _ctrl.dailyRedemptionCodes.isNotEmpty;
    return Row(
      children: [
        const Text(
          'Analytics',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text(
          hasRealData
              ? 'Datos de los últimos 30 días (backend)'
              : 'Datos de ${_ctrl.redemptionCodes.length} canjes cargados',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _growthStr(String pctKey) {
    final summary = _ctrl.analyticsSummary.value;
    final raw = summary[pctKey];
    if (raw == null) return '';
    final pct = (raw as num).toDouble();
    final sign = pct >= 0 ? '+' : '';
    return ' ($sign${pct.toStringAsFixed(1)}% vs mes ant.)';
  }

  // ── Stat cards ────────────────────────────────────────────────────────────

  Widget _statCards() {
    final summary = _ctrl.analyticsSummary.value;
    final redeemed = _ctrl.redeemedRedemptionCodes;

    final totalRedemptions = summary['total_redemptions'] as int?
        ?? summary['this_month_redemptions'] as int?
        ?? redeemed.length;
    final totalPoints = summary['total_points_generated'] as int?
        ?? redeemed.fold<int>(0, (s, v) => s + v.pointsUsed);
    final marketValue = _ctrl.totalStock.value * _ctrl.averagePrice.value;
    final rating = _ctrl.storeRating.value;
    final reviewCount = _ctrl.storeReviewCount.value;

    return Row(
      children: [
        _StatCard(
          icon: Icons.confirmation_number_outlined,
          color: _purple,
          label: 'Canjes Totales',
          value: '$totalRedemptions',
          sub: 'Este mes${_growthStr('redemptions_growth_pct')}',
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.stars_outlined,
          color: const Color(0xFF059669),
          label: 'Puntos Generados',
          value: '$totalPoints',
          sub: 'Acumulado${_growthStr('points_growth_pct')}',
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.attach_money,
          color: const Color(0xFFD97706),
          label: 'Valor de Mercado',
          value: '\$${marketValue.toStringAsFixed(0)}',
          sub: '${_ctrl.totalStock.value} uds${_growthStr('market_value_growth_pct')}',
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.star_outlined,
          color: const Color(0xFFDB2777),
          label: 'Rating de Tienda',
          value: rating > 0 ? rating.toStringAsFixed(1) : '—',
          sub: reviewCount > 0
              ? '$reviewCount reseñas'
              : (rating > 0 ? 'Promedio de reseñas' : 'Sin datos'),
        ),
      ],
    );
  }

  // ── Chart ─────────────────────────────────────────────────────────────────

  Widget _chartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Rendimiento de Recompensas',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              _toggle(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _weekMode
                ? 'Canjes por día esta semana'
                : 'Canjes por semana este mes',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _weekMode ? _buildWeekChart() : _buildMonthChart(),
          ),
        ],
      ),
    );
  }

  Widget _toggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn('Semana', _weekMode, () => setState(() => _weekMode = true)),
          _toggleBtn('Mes', !_weekMode, () => setState(() => _weekMode = false)),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _purple : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekChart() {
    final now = DateTime.now();
    final weekdayOffset = now.weekday - 1;
    final weekStart = DateTime(now.year, now.month, now.day - weekdayOffset);
    const labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    if (_ctrl.dailyRedemptionCodes.isNotEmpty) {
      final counts = List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final dayStr =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final entry = _ctrl.dailyRedemptionCodes.firstWhere(
          (e) => e['date']?.toString() == dayStr,
          orElse: () => {'date': dayStr, 'count': 0},
        );
        return (entry['count'] as num?)?.toInt() ?? 0;
      });
      return _BarChart(counts: counts, labels: labels, color: _purple);
    }

    // fallback: compute from loaded redemptionCodes
    final counts = List.generate(7, (i) {
      final day = weekStart.add(Duration(days: i));
      return _ctrl.redeemedRedemptionCodes.where((v) {
        final d = v.redeemedAt ?? v.issuedAt;
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).length;
    });
    return _BarChart(counts: counts, labels: labels, color: _purple);
  }

  Widget _buildMonthChart() {
    final now = DateTime.now();
    const labels = ['S1', 'S2', 'S3', 'S4'];

    if (_ctrl.dailyRedemptionCodes.isNotEmpty) {
      final counts = List.generate(4, (week) {
        final wStart = DateTime(now.year, now.month, 1 + week * 7);
        final wEnd = wStart.add(const Duration(days: 7));
        int total = 0;
        for (final entry in _ctrl.dailyRedemptionCodes) {
          final date = DateTime.tryParse(entry['date']?.toString() ?? '');
          if (date != null && !date.isBefore(wStart) && date.isBefore(wEnd)) {
            total += (entry['count'] as num?)?.toInt() ?? 0;
          }
        }
        return total;
      });
      return _BarChart(counts: counts, labels: labels, color: _purple);
    }

    // fallback: compute from loaded redemptionCodes
    final counts = List.generate(4, (week) {
      final start = DateTime(now.year, now.month, 1 + week * 7);
      final end = start.add(const Duration(days: 7));
      return _ctrl.redeemedRedemptionCodes.where((v) {
        final d = v.redeemedAt ?? v.issuedAt;
        return !d.isBefore(start) && d.isBefore(end);
      }).length;
    });
    return _BarChart(counts: counts, labels: labels, color: _purple);
  }

  // ── Top categories ────────────────────────────────────────────────────────

  Widget _topCategoriesCard() {
    final categoryMap = <String, int>{};
    for (final p in _ctrl.products) {
      final cat = p.category.isEmpty ? 'Sin categoría' : p.category;
      categoryMap[cat] = (categoryMap[cat] ?? 0) + 1;
    }
    final sorted = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Categorías',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Por número de productos',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (top.isEmpty)
            const Text('Sin datos',
                style: TextStyle(color: Colors.grey, fontSize: 13))
          else
            ...top.asMap().entries.map((e) {
              final rank = e.key + 1;
              final entry = e.value;
              final maxVal = top.first.value;
              return _CategoryRow(
                rank: rank,
                name: entry.key,
                count: entry.value,
                pct: maxVal > 0 ? entry.value / maxVal : 0,
              );
            }),
        ],
      ),
    );
  }

  // ── Product performance table ─────────────────────────────────────────────

  Widget _productTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rendimiento por Producto',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Basado en canjes cargados',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _tableHeader(),
          const Divider(),
          if (_ctrl.products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Sin productos',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          else
            ..._ctrl.products.map(_tableRow),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    const style = TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey);
    return const Row(
      children: [
        Expanded(flex: 3, child: Text('Producto', style: style)),
        Expanded(
            child: Text('Pts req.', style: style, textAlign: TextAlign.center)),
        Expanded(
            child: Text('Stock', style: style, textAlign: TextAlign.center)),
        Expanded(
            child: Text('Canjes', style: style, textAlign: TextAlign.center)),
        Expanded(
            child: Text('Conv. %',
                style: style, textAlign: TextAlign.center)),
        Expanded(
            child: Text('Tendencia',
                style: style, textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _tableRow(ProductModel p) {
    final totalForProduct =
        _ctrl.redemptionCodes.where((v) => v.productId == p.id).length;
    final redeemedForProduct =
        _ctrl.redeemedRedemptionCodes.where((v) => v.productId == p.id).length;
    final conversionStr = totalForProduct > 0
        ? '${(redeemedForProduct / totalForProduct * 100).toStringAsFixed(1)}%'
        : '—';

    final lastWeek = DateTime.now().subtract(const Duration(days: 7));
    final recentRedeemed = _ctrl.redeemedRedemptionCodes
        .where((v) =>
            v.productId == p.id &&
            (v.redeemedAt ?? v.issuedAt).isAfter(lastWeek))
        .length;
    final olderRedeemed = redeemedForProduct - recentRedeemed;
    final trending = recentRedeemed > olderRedeemed
        ? '↑'
        : (recentRedeemed < olderRedeemed ? '↓' : '→');
    final trendColor = recentRedeemed > olderRedeemed
        ? Colors.green
        : (recentRedeemed < olderRedeemed ? Colors.red : Colors.grey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: p.image.startsWith('http')
                      ? Image.network(
                          p.image,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              p.pointsRequired > 0 ? '${p.pointsRequired}' : '—',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              '${p.stock > 0 ? p.stock : p.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              '$redeemedForProduct',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              conversionStr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              trending,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: trendColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _purpleLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.image_outlined, size: 16, color: _purple),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 2),
            Text(sub,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final int rank;
  final String name;
  final int count;
  final double pct;

  const _CategoryRow(
      {required this.rank,
      required this.name,
      required this.count,
      required this.pct});

  static const _colors = [
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFDB2777),
    Color(0xFF2563EB),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[(rank - 1) % _colors.length];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$rank.',
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(name,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
              Text('$count',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<int> counts;
  final List<String> labels;
  final Color color;

  const _BarChart(
      {required this.counts, required this.labels, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxVal =
        counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);
    return CustomPaint(
      painter: _BarChartPainter(
          counts: counts, labels: labels, max: maxVal, color: color),
      size: Size.infinite,
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<int> counts;
  final List<String> labels;
  final int max;
  final Color color;

  const _BarChartPainter({
    required this.counts,
    required this.labels,
    required this.max,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()..color = color;
    final bgPaint = Paint()..color = const Color(0xFFF3F4F6);

    final n = counts.length;
    if (n == 0) return;

    const labelHeight = 20.0;
    const topPadding = 20.0;
    final chartHeight = size.height - labelHeight;
    final slotW = size.width / n;
    final barWidth = slotW * 0.5;
    final barOffset = (slotW - barWidth) / 2;

    for (int i = 0; i < n; i++) {
      final x = i * slotW + barOffset;
      final maxBarH = chartHeight - topPadding;
      final barH = max > 0 ? (counts[i] / max) * maxBarH : 0.0;
      final barTop = chartHeight - barH;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, topPadding, barWidth, maxBarH),
          const Radius.circular(6),
        ),
        bgPaint,
      );

      if (barH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, barTop, barWidth, barH),
            const Radius.circular(6),
          ),
          barPaint,
        );

        final tp = TextPainter(
          text: TextSpan(
            text: '${counts[i]}',
            style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
                fontWeight: FontWeight.w600),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
            canvas,
            Offset(x + barWidth / 2 - tp.width / 2,
                barTop - tp.height - 2));
      }

      final ltp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ltp.paint(
          canvas,
          Offset(x + barWidth / 2 - ltp.width / 2, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.counts != counts || old.max != max;
}
