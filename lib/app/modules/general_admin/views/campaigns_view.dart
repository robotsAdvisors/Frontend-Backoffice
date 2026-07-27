import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/campaign_model.dart';
import '../controllers/general_admin_controller.dart';
import 'backoffice_sidebar.dart';

/// Campañas promocionales del superadmin, cableada al backend
/// (`/admin/campaigns/`). Mismo layout de backoffice que Tiendas: sidebar +
/// contenido.
class CampaignsView extends GetView<GeneralAdminController> {
  const CampaignsView({super.key});

  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleDark = Color(0xFF5B21B6);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg = Color(0xFFF8F7FF);
  static const Color _ink = Color(0xFF1E1B4B);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.campaigns.isEmpty) controller.loadCampaigns();
    });
    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          BackofficeSidebar(current: 'campanias'),
          const VerticalDivider(width: 1, thickness: 1, color: _border),
          Expanded(child: _content()),
        ],
      ),
    );
  }

  // ─── SIDEBAR (igual que Tiendas) ─────────────────────────────────────────────
  // ─── CONTENIDO ───────────────────────────────────────────────────────────────
  Widget _content() {
    return Column(
      children: [
        // Top bar
        Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              const Text('Campañas Promocionales',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva campaña',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingCampaigns.value &&
                controller.campaigns.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: _purple));
            }
            if (controller.campaigns.isEmpty) return _emptyState();
            return RefreshIndicator(
              color: _purple,
              onRefresh: controller.loadCampaigns,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                    itemCount: controller.campaigns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) =>
                        _campaignCard(controller.campaigns[i]),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration:
                const BoxDecoration(color: _purpleLight, shape: BoxShape.circle),
            child: const Icon(Icons.campaign_outlined, size: 44, color: _purple),
          ),
          const SizedBox(height: 20),
          const Text('Aún no hay campañas',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 6),
          const Text('Crea tu primera campaña promocional de puntos.',
              style: TextStyle(color: _muted)),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _purple,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
            onPressed: _openForm,
            icon: const Icon(Icons.add),
            label: const Text('Crear campaña'),
          ),
        ],
      ),
    );
  }

  // ─── CARD ────────────────────────────────────────────────────────────────────
  Widget _campaignCard(CampaignModel c) {
    final hasBanner =
        c.bannerImage != null && c.bannerImage!.startsWith('http');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _ink.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 96,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasBanner)
                  Image.network(c.bannerImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradientHeader())
                else
                  _gradientHeader(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x99000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(c.name.isNotEmpty ? c.name : 'Sin nombre',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                      ),
                      _statusBadge(c.isActive),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (c.affects.isNotEmpty) _affectsChip(c.affects),
                    if (_multiplier(c).isNotEmpty)
                      _chip(Icons.close, '×${_multiplier(c)}', _purple),
                    if (c.discountPercent > 0)
                      _chip(Icons.percent,
                          '${c.discountPercent.toStringAsFixed(0)}%',
                          Colors.teal),
                  ],
                ),
                const SizedBox(height: 14),
                _budgetRow(c),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 16, color: _muted),
                    const SizedBox(width: 6),
                    Text('${_fmtDate(c.startDate)}  →  ${_fmtDate(c.endDate)}',
                        style: const TextStyle(color: _muted, fontSize: 13)),
                    const Spacer(),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: _purpleDark),
                      onPressed: () => _openForm(campaign: c),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                    ),
                    IconButton(
                      tooltip: 'Eliminar',
                      color: Colors.red.shade400,
                      onPressed: () => _confirmDelete(c),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientHeader() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_purple, _purpleDark],
          ),
        ),
        child: Center(
          child:
              Icon(Icons.local_offer_outlined, color: Colors.white24, size: 48),
        ),
      );

  Widget _statusBadge(bool active) {
    final c = active ? const Color(0xFF16A34A) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(active ? 'Activa' : 'Inactiva',
              style: TextStyle(
                  color: c, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _affectsChip(String affects) {
    final earning = affects.toUpperCase() == 'EARNING';
    return _chip(
      earning ? Icons.trending_up : Icons.redeem,
      earning ? 'Ganar puntos' : 'Canje',
      earning ? const Color(0xFF2563EB) : const Color(0xFFDB2777),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _budgetRow(CampaignModel c) {
    final b = c.budget;
    if (b == null) return const SizedBox.shrink();
    final hasCap = b.maxPointsGlobal != null && b.maxPointsGlobal! > 0;
    final pct =
        hasCap ? (b.consumedPoints / b.maxPointsGlobal!).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Presupuesto',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
            const Spacer(),
            Text(
              hasCap
                  ? '${b.consumedPoints} / ${b.maxPointsGlobal} pts'
                  : '${b.consumedPoints} pts · sin tope',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _ink),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: hasCap ? pct : null,
            minHeight: 7,
            backgroundColor: _purpleLight,
            valueColor:
                AlwaysStoppedAnimation(b.exhausted ? Colors.red : _purple),
          ),
        ),
      ],
    );
  }

  static String _multiplier(CampaignModel c) {
    if (c.earningMultiplier.isNotEmpty) return c.earningMultiplier;
    if (c.redemptionMultiplier.isNotEmpty) return c.redemptionMultiplier;
    return '';
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    const m = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${d.day} ${m[d.month - 1]}';
  }

  void _confirmDelete(CampaignModel c) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Eliminar campaña'),
      content: Text('¿Seguro que quieres eliminar "${c.name}"?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Get.back();
            controller.removeCampaign(c.id);
          },
          child: const Text('Eliminar'),
        ),
      ],
    ));
  }

  void _openForm({CampaignModel? campaign}) {
    Get.bottomSheet(
      _CampaignForm(controller: controller, campaign: campaign),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Formulario
// ══════════════════════════════════════════════════════════════════════════════

class _CampaignForm extends StatefulWidget {
  const _CampaignForm({required this.controller, this.campaign});
  final GeneralAdminController controller;
  final CampaignModel? campaign;

  @override
  State<_CampaignForm> createState() => _CampaignFormState();
}

class _CampaignFormState extends State<_CampaignForm> {
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _ink = Color(0xFF1E1B4B);
  static const Color _muted = Color(0xFF6B7280);

  late final TextEditingController _name;
  late final TextEditingController _multiplier;
  late final TextEditingController _budget;
  String _affects = 'EARNING';
  String _startDate = '';
  String _endDate = '';
  XFile? _image;
  Uint8List? _imageBytes;

  bool get _isEdit => widget.campaign != null;

  @override
  void initState() {
    super.initState();
    final c = widget.campaign;
    _name = TextEditingController(text: c?.name ?? '');
    _affects = (c?.affects.isNotEmpty ?? false) ? c!.affects : 'EARNING';
    final mult = _affects == 'REDEMPTION'
        ? (c?.redemptionMultiplier ?? '')
        : (c?.earningMultiplier ?? '');
    _multiplier = TextEditingController(text: mult);
    _budget = TextEditingController(
        text: c?.budget?.maxPointsGlobal?.toString() ?? '');
    _startDate = _fmt(c?.startDate);
    _endDate = _fmt(c?.endDate);
  }

  @override
  void dispose() {
    _name.dispose();
    _multiplier.dispose();
    _budget.dispose();
    super.dispose();
  }

  static String _fmt(DateTime? d) =>
      d == null ? '' : '${d.year}-${_two(d.month)}-${_two(d.day)}';
  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _slugify(String s) {
    var out = s.toLowerCase().trim();
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    out = out.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    out = out.replaceAll(RegExp(r'(^-+)|(-+$)'), '');
    return out;
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        final v = '${picked.year}-${_two(picked.month)}-${_two(picked.day)}';
        isStart ? _startDate = v : _endDate = v;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _image = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Falta el nombre', 'El nombre de la campaña es obligatorio',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_startDate.isEmpty || _endDate.isEmpty) {
      Get.snackbar('Faltan fechas', 'Selecciona la fecha de inicio y de fin',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final mult = _multiplier.text.trim();
    final budgetVal = int.tryParse(_budget.text.trim());
    final slug = _isEdit && widget.campaign!.slug.isNotEmpty
        ? widget.campaign!.slug
        : _slugify(name);
    final payload = <String, dynamic>{
      'name': name,
      'slug': slug,
      'affects': _affects,
      if (mult.isNotEmpty && _affects == 'EARNING') 'earning_multiplier': mult,
      if (mult.isNotEmpty && _affects == 'REDEMPTION')
        'redemption_multiplier': mult,
      'starts_at': _startDate,
      'ends_at': _endDate,
      if (budgetVal != null) 'max_points_global': budgetVal,
    };

    final ok = await widget.controller.submitCampaign(
      payload,
      image: _image,
      editId: _isEdit ? widget.campaign!.id : null,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(3)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Text(_isEdit ? 'Editar campaña' : 'Nueva campaña',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: _muted)),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _bannerPicker(),
                  const SizedBox(height: 20),
                  _label('Nombre'),
                  _input(_name, hint: 'Ej. Black Friday x2'),
                  const SizedBox(height: 18),
                  _label('¿A qué afecta?'),
                  _affectsSelector(),
                  const SizedBox(height: 18),
                  _label('Multiplicador'),
                  _input(_multiplier,
                      hint: 'Ej. 2',
                      keyboard:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefix: '×'),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Fecha inicio'),
                            _dateField(_startDate, () => _pickDate(true)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Fecha fin'),
                            _dateField(_endDate, () => _pickDate(false)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _label('Tope de puntos (opcional)'),
                  _input(_budget,
                      hint: 'Sin límite si se deja vacío',
                      keyboard: TextInputType.number),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _footer(),
        ],
      ),
    );
  }

  Widget _bannerPicker() {
    final existing = widget.campaign?.bannerImage;
    Widget preview;
    if (_imageBytes != null) {
      preview = Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (existing != null && existing.startsWith('http')) {
      preview = Image.network(existing,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _emptyBanner());
    } else {
      preview = _emptyBanner();
    }
    return GestureDetector(
      onTap: _pickImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(height: 140, width: double.infinity, child: preview),
      ),
    );
  }

  Widget _emptyBanner() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        border: Border.all(color: const Color(0xFFE5E0FA)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, color: _purple, size: 30),
          SizedBox(height: 6),
          Text('Subir banner', style: TextStyle(color: _purple, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _affectsSelector() {
    Widget seg(String value, IconData icon, String label) {
      final selected = _affects == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _affects = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? _purple : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? Colors.white : _muted),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        color: selected ? Colors.white : _muted,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg('EARNING', Icons.trending_up, 'Ganar'),
        const SizedBox(width: 10),
        seg('REDEMPTION', Icons.redeem, 'Canje'),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
      );

  Widget _input(TextEditingController c,
      {String? hint, TextInputType? keyboard, String? prefix}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
      ),
    );
  }

  Widget _dateField(String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: _muted),
            const SizedBox(width: 10),
            Text(value.isEmpty ? 'Seleccionar' : value,
                style: TextStyle(
                    color: value.isEmpty ? _muted : _ink,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F1F5))),
      ),
      child: Obx(() {
        final saving = widget.controller.isSavingCampaign.value;
        return SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _purple,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: saving ? null : _submit,
            child: saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_isEdit ? 'Guardar cambios' : 'Crear campaña',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        );
      }),
    );
  }
}
