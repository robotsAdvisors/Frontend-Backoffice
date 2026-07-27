import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/review_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/admin_controller.dart';
import '../controllers/reviews_controller.dart';

class ReviewsView extends StatefulWidget {
  const ReviewsView({Key? key}) : super(key: key);

  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  static const _purple      = Color(0xFF7C3AED);
  static const _purpleLight = Color(0xFFEDE9FE);
  static const _bg          = Color(0xFFF5F3FF);

  late final AdminController   _admin;
  late final ReviewsController _ctrl;

  @override
  void initState() {
    super.initState();
    _admin = Get.find<AdminController>();
    _ctrl  = Get.put(ReviewsController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(children: [
        _sidebar(context),
        Expanded(child: _mainArea(context)),
      ]),
    );
  }

  // ─── SIDEBAR ─────────────────────────────────────────────────────────────

  Widget _sidebar(BuildContext context) {
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
                child: Obx(() {
                  _admin.storeId.value;
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_admin.currentStore.name,
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(_admin.currentStore.subtitle.isNotEmpty
                        ? _admin.currentStore.subtitle : 'Gestión de Tienda',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]);
                }),
              ),
            ]),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _nav(Icons.home_outlined,          'Inicio',
              onTap: () => Get.offNamed(Routes.ADMIN)),
          _nav(Icons.star_outline,           'Reseñas', selected: true),
          _nav(Icons.swap_horiz_rounded,     'Canjes',
              onTap: () => Get.offNamed(Routes.REDEMPTION_CODE_HISTORY)),
          _nav(Icons.card_giftcard_outlined, 'Canjes y Beneficios',
              onTap: () => Get.toNamed(Routes.PREMIOS)),
          _nav(Icons.history_outlined,       'Historial',
              onTap: () => Get.offNamed(Routes.REDEMPTION_CODE_HISTORY)),
          _nav(Icons.bar_chart_outlined,     'Estadísticas',
              onTap: () => Get.toNamed(Routes.ANALYTICS)),
          _nav(Icons.info_outline,           'Info',
              onTap: () => Get.toNamed(Routes.ADMIN_SETTINGS)),
          _nav(Icons.security_outlined,      'Seguridad',
              onTap: () => Get.toNamed(Routes.ADMIN_SETTINGS)),
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed(Routes.REDEMPTION_CODE_HISTORY),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('+ Nuevo Canje',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ),
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

  Widget _nav(IconData icon, String label,
      {bool selected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _purpleLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, size: 18,
              color: selected ? _purple : Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? _purple : Colors.grey.shade700)),
        ]),
      ),
    );
  }

  // ─── MAIN AREA ────────────────────────────────────────────────────────────

  Widget _mainArea(BuildContext context) {
    return Column(children: [
      _topBar(),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statsSection(),
              const SizedBox(height: 16),
              _protocolBanner(),
              const SizedBox(height: 20),
              _filterBar(),
              const SizedBox(height: 12),
              _reviewsList(context),
              const SizedBox(height: 16),
              _pagination(),
              const SizedBox(height: 24),
              _footer(),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _topBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(children: [
        const Text('Reseñas de la Tienda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: Color(0xFF111827))),
        const SizedBox(width: 20),
        Expanded(
          child: SizedBox(
            height: 38,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar en mis Reseñas...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                filled: true, fillColor: const Color(0xFFF5F5F5), isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Obx(() => _admin.pendingCount > 0
            ? Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.notifications_outlined, size: 22, color: Color(0xFF374151)),
                Positioned(top: -2, right: -2,
                    child: Container(width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.orange, shape: BoxShape.circle))),
              ])
            : const Icon(Icons.notifications_outlined, size: 22, color: Color(0xFF374151))),
        const SizedBox(width: 16),
        const Icon(Icons.settings_outlined, size: 22, color: Color(0xFF374151)),
        const SizedBox(width: 16),
        Obx(() {
          _admin.storeId.value;
          return CircleAvatar(
            radius: 16, backgroundColor: _purpleLight,
            child: _admin.currentStore.logoUrl.startsWith('http')
                ? ClipOval(child: Image.network(_admin.currentStore.logoUrl,
                    width: 32, height: 32, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 16, color: _purple)))
                : const Icon(Icons.person, size: 16, color: _purple),
          );
        }),
      ]),
    );
  }

  // ─── STATS ────────────────────────────────────────────────────────────────

  Widget _statsSection() {
    return Obx(() {
      final s = _ctrl.stats.value;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating card
          Container(
            width: 220,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MI CALIFICACIÓN PROMEDIO',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(s.avgRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 40,
                          fontWeight: FontWeight.w800, color: Color(0xFF111827),
                          height: 1)),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6, left: 2),
                    child: Text('/ 5.0',
                        style: TextStyle(fontSize: 14, color: Colors.grey))),
                ]),
                const SizedBox(height: 8),
                _starRow(s.avgRating),
                const SizedBox(height: 8),
                Text(
                  'Basado en ${_fmtNum(s.totalReviews)} reseñas los últimos dos años.',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Stats row (3 cards)
          Expanded(
            child: Row(children: [
              Expanded(child: _statMini(
                icon: Icons.thumb_up_outlined,
                iconBg: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF059669),
                value: '${s.positivePct.toStringAsFixed(0)}%',
                label: 'Sentimiento Positivo',
                change: s.positiveChangePct != 0
                    ? '${s.positiveChangePct >= 0 ? '+' : ''}${s.positiveChangePct.toStringAsFixed(0)}%'
                    : null,
              )),
              const SizedBox(width: 12),
              Expanded(child: _statMini(
                icon: Icons.rate_review_outlined,
                iconBg: _purpleLight,
                iconColor: _purple,
                value: _fmtNum(s.newReviewsCount),
                label: 'Nuevas Reseñas',
                badge: s.newReviewsRanking != null ? '#${s.newReviewsRanking}' : null,
              )),
              const SizedBox(width: 12),
              Expanded(child: _statMini(
                icon: Icons.star_border_outlined,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFD97706),
                value: '${s.daysWithoutAccumulation}',
                label: 'Días sin Acumulación',
              )),
            ]),
          ),
        ],
      );
    });
  }

  Widget _statMini({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    String? change,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: iconColor)),
          if (change != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(change,
                  style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700, color: Color(0xFF059669)))),
          ],
          if (badge != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: _purpleLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(badge,
                  style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700, color: _purple))),
          ],
        ]),
        const SizedBox(height: 10),
        Text(value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                color: Color(0xFF111827), height: 1)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }

  Widget _starRow(double avg) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < avg.floor();
        final half   = !filled && i < avg;
        return Icon(
          filled ? Icons.star_rounded
              : half ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          size: 18,
          color: const Color(0xFFF59E0B));
      }),
    );
  }

  // ─── PROTOCOL BANNER ─────────────────────────────────────────────────────

  Widget _protocolBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _purpleLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purple.withValues(alpha: 0.2))),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: _purple, shape: BoxShape.circle),
          child: const Icon(Icons.info_outline, size: 16, color: Colors.white)),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Protocolo de Gestión',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: _purple)),
            SizedBox(height: 2),
            Text(
              'Toda acción de respuesta genera un expediente auditado por el equipo central. '
              'La mediación final no puede ser editada retroactivamente por Super Admin.',
              style: TextStyle(fontSize: 11, color: Color(0xFF374151))),
          ]),
        ),
      ]),
    );
  }

  // ─── FILTER BAR ──────────────────────────────────────────────────────────

  Widget _filterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        _filterChip('all',           'Todas'),
        const SizedBox(width: 4),
        _filterChip('pending_reply','Sin Responder'),
        const SizedBox(width: 4),
        _filterChip('positive',    'Positivas'),
        const SizedBox(width: 4),
        _filterChip('negative',    'Negativas'),
        const SizedBox(width: 4),
        _filterChip('hidden',      'Ocultas'),
        const Spacer(),
        _sortDropdown(),
      ]),
    );
  }

  Widget _filterChip(String key, String label) {
    return Obx(() {
      final sel = _ctrl.activeFilter.value == key;
      return GestureDetector(
        onTap: () => _ctrl.setFilter(key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? _purple : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: sel ? _purple : const Color(0xFFE5E7EB))),
          child: Text(label,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: sel ? Colors.white : Colors.grey.shade700))),
      );
    });
  }

  Widget _sortDropdown() {
    const options = {
      'recent':      'Más Recientes',
      'rating_desc': 'Mejor Calificación',
      'rating_asc':  'Peor Calificación',
    };
    return Obx(() => DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _ctrl.activeSort.value,
        isDense: true,
        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        items: options.entries.map((e) =>
            DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (v) { if (v != null) _ctrl.setSort(v); },
        icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey)),
    ));
  }

  // ─── REVIEWS LIST ─────────────────────────────────────────────────────────

  Widget _reviewsList(BuildContext context) {
    return Obx(() {
      if (_ctrl.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator()));
      }
      if (_ctrl.reviews.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB))),
          child: const Center(
            child: Text('No hay reseñas en esta categoría.',
                style: TextStyle(color: Colors.grey))));
      }
      return Column(
        children: _ctrl.reviews
            .map((r) => _reviewCard(context, r))
            .toList());
    });
  }

  Widget _reviewCard(BuildContext context, ReviewModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          r.isAnonymous
              ? Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: Icon(Icons.person_outline,
                      size: 22, color: Colors.grey.shade400))
              : CircleAvatar(
                  radius: 20,
                  backgroundColor: _avatarColor(r.authorName),
                  backgroundImage: r.authorAvatarUrl?.startsWith('http') == true
                      ? NetworkImage(r.authorAvatarUrl!) : null,
                  child: r.authorAvatarUrl?.startsWith('http') != true
                      ? Text(r.initials,
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700, color: Colors.white))
                      : null),
          const SizedBox(width: 12),
          // Name + stars + time
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(r.authorName,
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(_relTime(r.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (r.badge?.isNotEmpty == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(r.badge!,
                        style: const TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669)))),
                ],
              ]),
              if (!r.isAnonymous && r.rating > 0)
                Row(children: List.generate(5, (i) => Icon(
                    i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14, color: const Color(0xFFF59E0B)))),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        // Review text
        Text(r.text, style: const TextStyle(fontSize: 13,
            color: Color(0xFF374151), height: 1.5)),
        // Reference code (anonymous/in_review)
        if (r.referenceCode?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text('Código: ${r.referenceCode}',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
        // In-review badge
        if (r.isInReview) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE68A))),
            child: const Text('EN PROCESO DE SISTEMA MANUAL',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706)))),
        ],
        // Replied content
        if (r.isReplied && r.replyText?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.reply, size: 16, color: _purple),
              const SizedBox(width: 8),
              Expanded(child: Text(r.replyText!,
                  style: const TextStyle(fontSize: 12,
                      color: Color(0xFF374151), height: 1.4))),
            ])),
        ],
        // Actions
        if (!r.isHidden && !r.isInReview) ...[
          const SizedBox(height: 14),
          Row(children: [
            if (!r.isReplied)
              OutlinedButton.icon(
                onPressed: () => _showReplyDialog(context, r),
                icon: const Icon(Icons.reply, size: 14),
                label: Text(r.rating <= 3 ? 'Responder Ahora' : 'Responder',
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: _purple),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)))),
            if (r.isReplied)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check, size: 13, color: Color(0xFF059669)),
                  SizedBox(width: 4),
                  Text('Respondida',
                      style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                ])),
            const Spacer(),
            GestureDetector(
              onTap: () => _showReportDialog(context, r),
              child: Row(children: [
                Icon(Icons.flag_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('Reportar Incidencia',
                    style: TextStyle(fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500)),
              ])),
          ]),
        ],
      ]),
    );
  }

  // ─── PAGINATION ───────────────────────────────────────────────────────────

  Widget _pagination() {
    return Obx(() {
      final meta     = _ctrl.meta.value;
      final page     = _ctrl.currentPage.value;
      final lastPage = meta.lastPage.clamp(1, 9999);
      if (lastPage <= 1) return const SizedBox.shrink();
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pgBtn(Icons.chevron_left,
              page > 1 ? () => _ctrl.loadReviews(page: page - 1) : null),
          const SizedBox(width: 4),
          ..._pageNums(page, lastPage).map((n) => n == -1
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('...', style: TextStyle(color: Colors.grey)))
              : _pgNum(n, n == page, () => _ctrl.loadReviews(page: n))),
          const SizedBox(width: 4),
          _pgBtn(Icons.chevron_right,
              page < lastPage ? () => _ctrl.loadReviews(page: page + 1) : null),
        ],
      );
    });
  }

  List<int> _pageNums(int page, int last) {
    if (last <= 5) return List.generate(last, (i) => i + 1);
    if (page <= 3) return [1, 2, 3, -1, last];
    if (page >= last - 2) return [1, -1, last - 2, last - 1, last];
    return [1, -1, page, -1, last];
  }

  Widget _pgBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white),
        child: Icon(icon, size: 18,
            color: onTap != null ? Colors.black87 : Colors.grey.shade300)));
  }

  Widget _pgNum(int n, bool current, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: current ? _purple : Colors.white,
          border: Border.all(color: current ? _purple : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text('$n',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: current ? Colors.white : Colors.black87)))));
  }

  // ─── FOOTER ──────────────────────────────────────────────────────────────

  Widget _footer() {
    return const Text(
      '© Letdem Almacén. Todos los derechos reservados. '
      'Todo escrito en reporte genera un expediente auditado por el equipo central.',
      style: TextStyle(fontSize: 10, color: Colors.grey),
      textAlign: TextAlign.center);
  }

  // ─── DIALOGS ─────────────────────────────────────────────────────────────

  void _showReplyDialog(BuildContext context, ReviewModel r) {
    final textCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Responder a ${r.authorName}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('"${r.text}"',
              style: const TextStyle(fontSize: 12, color: Colors.grey,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          TextField(
            controller: textCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Escribe tu respuesta...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10)),
            autofocus: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
            onPressed: _ctrl.isSubmitting.value ? null : () async {
              final msg = textCtrl.text.trim();
              if (msg.isEmpty) return;
              Navigator.of(ctx).pop();
              await _ctrl.replyToReview(r.id, msg);
            },
            child: _ctrl.isSubmitting.value
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Publicar respuesta'))),
        ]));
  }

  void _showReportDialog(BuildContext context, ReviewModel r) {
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reportar Incidencia'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Indica el motivo del reporte:',
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl, maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ej: Contenido inapropiado, spam...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10)),
            autofocus: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(ctx).pop();
              await _ctrl.reportReview(r.id, reason);
            },
            child: const Text('Reportar'))]));
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF7C3AED), const Color(0xFF059669),
      const Color(0xFF2563EB), const Color(0xFFD97706),
      const Color(0xFFDC2626),
    ];
    int hash = 0;
    for (final c in name.runes) { hash = (hash * 31 + c) & 0xFFFFFFFF; }
    return colors[hash % colors.length];
  }

  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 60)  return 'Hace ${diff.inMinutes} min';
    if (diff.inHours   < 24)  return 'Hace ${diff.inHours} horas';
    if (diff.inDays    < 30)  return 'Hace ${diff.inDays} días';
    return 'Hace ${(diff.inDays / 30).floor()} meses';
  }

  String _fmtNum(int n) {
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
}
