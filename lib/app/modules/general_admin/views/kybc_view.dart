import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/admin_user_model.dart';
import '../controllers/general_admin_controller.dart';
import 'backoffice_sidebar.dart';

class KybcView extends GetView<GeneralAdminController> {
  const KybcView({super.key});

  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg = Color(0xFFF8F7FF);
  static const Color _dark = Color(0xFF1E1B4B);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.kybcStats.value == null) {
        controller.loadKybcData();
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          BackofficeSidebar(current: 'kybc'),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  // ─── SIDEBAR ─────────────────────────────────────────────────────────────────

  // ─── BODY ─────────────────────────────────────────────────────────────────────

  Widget _body(BuildContext context) {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _leftPanel()),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: _rightPanel()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar() {
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, size: 16,
                      color: Color(0xFF9CA3AF)),
                  hintText: 'Buscar informador por ID o Email...',
                  hintStyle: TextStyle(
                      fontSize: 13, color: Color(0xFF9CA3AF)),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 20),
            onPressed: () {},
            color: const Color(0xFF6B7280),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () {},
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: _purpleLight,
            child:
                Icon(Icons.person, size: 16, color: _purple),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Control KYBC de Informadores',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _dark)),
              SizedBox(height: 4),
              Text(
                'Gestión de cumplimiento normativo y verificación de identidad',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.tune, size: 15),
          label: const Text('Filtros Avanzados'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            foregroundColor: const Color(0xFF374151),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined, size: 15),
          label: const Text('Exportar Reporte'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 13),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ─── LEFT PANEL ──────────────────────────────────────────────────────────────

  Widget _leftPanel() {
    return Column(
      children: [
        _queueCard(),
        const SizedBox(height: 20),
        Obx(() => controller.selectedKycUser.value != null
            ? _userDetailCard(controller.selectedKycUser.value!)
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _queueCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Queue header with tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Text('Cola de Verificación',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _dark)),
                const Spacer(),
                Obx(() => _queueTab('Pendiente',
                    controller.kybcStats.value?.pendingCount ?? 0, 0)),
                const SizedBox(width: 8),
                Obx(() => _queueTab('En Revisión',
                    controller.kybcStats.value?.inReviewCount ?? 0, 1)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _th('INFORMADOR', flex: 3),
                _th('KYBC STATUS', flex: 2),
                _th('ÚLTIMA ACTIVIDAD', flex: 2),
                _th('ACCIONES', flex: 1),
              ],
            ),
          ),
          const Divider(height: 1),
          // Queue rows
          Obx(() {
            if (controller.isLoadingKybc.value) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: CircularProgressIndicator(color: _purple)),
              );
            }
            if (controller.kycQueue.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('No hay usuarios en cola',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                ),
              );
            }
            return Column(
              children: controller.kycQueue
                  .map((u) => _queueRow(u))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _queueTab(String label, int count, int index) {
    return Obx(() {
      final selected = controller.kycQueueTab.value == index;
      return GestureDetector(
        onTap: () => controller.loadKycQueueTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _purple : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$label ($count)',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF6B7280))),
        ),
      );
    });
  }

  Widget _th(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9CA3AF))),
      ),
    );
  }

  Widget _queueRow(AdminUserModel user) {
    return GestureDetector(
      onTap: () => controller.selectKycUser(user),
      child: Obx(() {
        final sel =
            controller.selectedKycUser.value?.id == user.id;
        return Container(
          color: sel
              ? _purpleLight.withValues(alpha: 0.5)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Informador
              Expanded(
                flex: 3,
                child: Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _purpleLight,
                    child: Text(
                      _initials(user.name),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _purple),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _dark),
                            overflow: TextOverflow.ellipsis),
                        Text(user.emailFull.isNotEmpty
                            ? user.emailFull
                            : user.emailMasked,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF)),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ]),
              ),
              // Status
              Expanded(
                  flex: 2, child: _kycBadge(user.kycStatus)),
              // Last activity
              Expanded(
                flex: 2,
                child: Text(
                  _formatRelative(user.lastAccessAt),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ),
              // Action
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: _purple),
                  onPressed: () => controller.selectKycUser(user),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _kycBadge(String status) {
    Color bg, fg;
    String label;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'compliant':
        bg = const Color(0xFFD1FAE5); fg = const Color(0xFF065F46);
        label = 'Aprobado'; break;
      case 'pending':
        bg = const Color(0xFFEDE9FE); fg = _purple;
        label = 'Pendiente'; break;
      case 'in_review':
      case 'in review':
        bg = const Color(0xFFFEF3C7); fg = const Color(0xFFD97706);
        label = 'En Revisión'; break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2); fg = const Color(0xFFB91C1C);
        label = 'Rechazado'; break;
      case 'suspended':
        bg = const Color(0xFFFEE2E2); fg = const Color(0xFFB91C1C);
        label = 'Suspendido'; break;
      case 'notified':
      case 'notificado':
        bg = const Color(0xFFDBEAFE); fg = const Color(0xFF1D4ED8);
        label = 'Notificado'; break;
      default:
        bg = const Color(0xFFF3F4F6); fg = const Color(0xFF6B7280);
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ─── USER DETAIL CARD ────────────────────────────────────────────────────────

  Widget _userDetailCard(AdminUserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: avatar + basic info
          Expanded(flex: 5, child: _userInfoLeft(user)),
          const SizedBox(width: 24),
          // Right: certificate history
          Expanded(flex: 4, child: _certificateHistory()),
        ],
      ),
    );
  }

  Widget _userInfoLeft(AdminUserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar + name
        Row(children: [
          Stack(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _purpleLight,
              child: Text(_initials(user.name),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _purple)),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: user.isActive
                      ? const Color(0xFF10B981)
                      : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _dark)),
                const SizedBox(height: 2),
                Text(
                  'Informador · ID: ${user.id}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Text(user.country.isNotEmpty ? user.country : '—',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'JOINED: ${_formatDate(user.registeredAt, 'MMM yyyy').toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 16),
        // Auto-certification badge
        Obx(() {
          final kyc = controller.userKyc;
          final certType = kyc['certification_type']?.toString() ??
              kyc['type']?.toString() ?? 'Auto-certificación';
          final isCompliant = user.kycStatus.toLowerCase() == 'approved' ||
              user.kycStatus.toLowerCase() == 'compliant';
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isCompliant ? 'ACTIVO' : 'INACTIVO',
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(certType,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF065F46),
                      fontWeight: FontWeight.w600)),
            ]),
          );
        }),
        const SizedBox(height: 16),
        // KYC detail fields
        Obx(() {
          final kyc = controller.userKyc;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('VERSIÓN',
                  kyc['version']?.toString() ?? '—'),
              _detailRow('FECHA FIRMA',
                  _formatDateStr(kyc['signed_at'] ?? kyc['submitted_at'])),
              _detailRow('DIRECCIÓN IP',
                  kyc['ip_address']?.toString() ??
                      kyc['ip']?.toString() ?? '—'),
              _detailRow('ESTADO EXPIRACIÓN',
                  _expirationLabel(kyc['expires_at'])),
            ],
          );
        }),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF))),
        ),
        Flexible(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF374151))),
        ),
      ]),
    );
  }

  Widget _certificateHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Historial de Certificados',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _dark)),
        const SizedBox(height: 12),
        Obx(() {
          final kyc = controller.userKyc;
          final history = kyc['certificate_history'] ?? kyc['history'];
          if (history is! List || history.isEmpty) {
            return Text('Sin historial disponible',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500));
          }
          return Column(
            children: history.map((item) {
              final m = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6, height: 6,
                      margin: const EdgeInsets.only(top: 5, right: 10),
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _purple),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['label']?.toString() ??
                                m['title']?.toString() ?? '—',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _dark),
                          ),
                          Text(
                            _formatDateStr(m['date'] ?? m['created_at']),
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  // ─── RIGHT PANEL ─────────────────────────────────────────────────────────────

  Widget _rightPanel() {
    return Column(
      children: [
        _approvalRateCard(),
        const SizedBox(height: 16),
        _transparencyPanel(),
        const SizedBox(height: 16),
        Obx(() => controller.selectedKycUser.value != null
            ? Column(children: [
                _complianceActionsCard(),
                const SizedBox(height: 16),
                _sanctionsHistoryCard(),
              ])
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _approvalRateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TASA DE APROBACIÓN',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Obx(() {
            final stats = controller.kybcStats.value;
            final rate = stats?.approvalRate ?? 0.0;
            final delta = stats?.approvalRateDelta ?? 0.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                Row(children: [
                  Icon(
                    delta >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 16,
                    color: delta >= 0
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCA5A5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)}% este mes',
                    style: TextStyle(
                        fontSize: 12,
                        color: delta >= 0
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFFCA5A5)),
                  ),
                ]),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _transparencyPanel() {
    // Panel de Transparencia — configuración estática de la plataforma
    const visible = [
      'Nombre de usuario',
      'Nivel de actuación',
      'Imágenes de certificación',
    ];
    const hidden = [
      'Dirección IP',
      'Geolocalización',
      'Historial de Transacciones',
      'Documentos de Identidad',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Panel de Transparencia',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _dark)),
          const SizedBox(height: 4),
          const Text('Datos visibles públicamente',
              style: TextStyle(
                  fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 14),
          _transparencyGroup(
              'DATOS VISIBLES (MARCADOS)',
              visible,
              const Color(0xFFD1FAE5),
              const Color(0xFF065F46),
              Icons.check_circle_outline),
          const SizedBox(height: 12),
          _transparencyGroup(
              'DATOS OCULTOS (PRIVADOS)',
              hidden,
              const Color(0xFFFEE2E2),
              const Color(0xFFB91C1C),
              Icons.cancel_outlined),
        ],
      ),
    );
  }

  Widget _transparencyGroup(String title, List<String> items,
      Color bg, Color fg, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(4)),
          child: Text(title,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: 0.3)),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 8),
                Text(item,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF374151))),
              ]),
            )),
      ],
    );
  }

  // ─── COMPLIANCE ACTIONS ──────────────────────────────────────────────────────

  Widget _complianceActionsCard() {
    return _ComplianceActionsWidget(controller: controller);
  }

  // ─── SANCTIONS HISTORY ───────────────────────────────────────────────────────

  Widget _sanctionsHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registro de Sanciones e Historial',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _dark)),
          const SizedBox(height: 14),
          Obx(() {
            final history = controller.complianceHistory;
            if (history.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text('Sin sanciones registradas',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500)),
                ),
              );
            }
            return Column(
              children: history.map(_sanctionEntry).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _sanctionEntry(Map<String, dynamic> entry) {
    final action = (entry['action'] ?? entry['type'] ?? '').toString();
    final isSuspension = action.toLowerCase().contains('suspend') ||
        action.toLowerCase().contains('sanc');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSuspension
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFD1FAE5),
            ),
            child: Icon(
              isSuspension ? Icons.block : Icons.check_circle,
              size: 14,
              color: isSuspension
                  ? const Color(0xFFB91C1C)
                  : const Color(0xFF065F46),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['title']?.toString() ??
                      entry['action']?.toString() ?? '—',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _dark),
                ),
                if (entry['description'] != null ||
                    entry['notes'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry['description']?.toString() ??
                        entry['notes']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280)),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${_formatDateStr(entry['created_at'] ?? entry['date'])} · ADMIN:${(entry['admin'] ?? entry['performed_by'] ?? 'SISTEMA').toString().toUpperCase()}',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatRelative(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return _formatDate(dt, 'dd/MM/yyyy');
  }

  String _formatDate(DateTime? dt, String fmt) {
    if (dt == null) return '—';
    final months = ['Ene','Feb','Mar','Abr','May','Jun',
                    'Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDateStr(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    final months = ['Ene','Feb','Mar','Abr','May','Jun',
                    'Jul','Ago','Sep','Oct','Nov','Dic'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]}. ${dt.year} | $h:$m';
  }

  String _expirationLabel(dynamic expiresAt) {
    if (expiresAt == null) return '—';
    final dt = DateTime.tryParse(expiresAt.toString());
    if (dt == null) return expiresAt.toString();
    final diff = dt.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Expirado';
    return 'Vigente ($diff días más)';
  }
}

// ─── COMPLIANCE ACTIONS STATEFUL WIDGET ──────────────────────────────────────

class _ComplianceActionsWidget extends StatefulWidget {
  final GeneralAdminController controller;
  const _ComplianceActionsWidget({required this.controller});

  @override
  State<_ComplianceActionsWidget> createState() =>
      _ComplianceActionsWidgetState();
}

class _ComplianceActionsWidgetState
    extends State<_ComplianceActionsWidget> {
  static const Color _dark = Color(0xFF1E1B4B);

  String? _selectedAction;
  final _notesCtrl = TextEditingController();

  static const _actions = [
    ('suspend_payments', 'Suspender pagos'),
    ('suspend_certification', 'Suspender certificación'),
    ('reactivate_account', 'Reactivar cuenta'),
    ('flag_review', 'Marcar para revisión'),
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.flash_on, size: 16, color: Color(0xFFF59E0B)),
            SizedBox(width: 6),
            Text('Acciones de Cumplimiento',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _dark)),
          ]),
          const SizedBox(height: 4),
          Obx(() {
            final user = widget.controller.selectedKycUser.value;
            return Text(
              'Suspender capacidades de pago / certificación de ${user?.name ?? ""}',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280)),
            );
          }),
          const SizedBox(height: 14),
          // Action dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedAction,
            hint: const Text('Seleccionar motivo de la suspensión...',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF9CA3AF))),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB))),
            ),
            items: _actions
                .map((a) => DropdownMenuItem(
                    value: a.$1, child: Text(a.$2,
                        style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (v) => setState(() => _selectedAction = v),
          ),
          const SizedBox(height: 10),
          // Notes textarea
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  'Añadir notas internas adicionales para el historial...',
              hintStyle: const TextStyle(
                  fontSize: 12, color: Color(0xFF9CA3AF)),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB))),
            ),
          ),
          const SizedBox(height: 14),
          // Execute button
          Obx(() {
            final loading =
                widget.controller.isExecutingAction.value;
            final user = widget.controller.selectedKycUser.value;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedAction == null ||
                        user == null ||
                        loading)
                    ? null
                    : () {
                        widget.controller.executeComplianceAction(
                          user.id,
                          action: _selectedAction!,
                          notes: _notesCtrl.text.trim(),
                        );
                        setState(() => _selectedAction = null);
                        _notesCtrl.clear();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFFEE2E2),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('EJECUTAR SUSPENSIÓN INMEDIATA',
                        textAlign: TextAlign.center),
              ),
            );
          }),
        ],
      ),
    );
  }
}
