import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/store_model.dart';
import '../../../data/models/store_user_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/general_admin_controller.dart';
import 'backoffice_sidebar.dart';

class ComerciosView extends GetView<GeneralAdminController> {
  const ComerciosView({super.key});

  static const Color _purple      = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg          = Color(0xFFF8F7FF);
  static const Color _border      = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(children: [
        BackofficeSidebar(current: 'tiendas'),
        _storeList(),
        const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        Expanded(child: _storeDetail()),
      ]),
    );
  }

  // ─── SIDEBAR ─────────────────────────────────────────────────────────────────

  void _openCreateStore() {
    Get.bottomSheet(
      _CreateStoreForm(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ─── STORE LIST ──────────────────────────────────────────────────────────────

  Widget _storeList() {
    return Container(
      width: 320,
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
          child: Row(children: [
            const Expanded(child: Text('Tiendas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: Color(0xFF111827)))),
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _purpleLight,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${controller.stores.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: _purple)),
            )),
            const SizedBox(width: 8),
            InkWell(
              onTap: _openCreateStore,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: _purple, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
            ),
          ]),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(height: 36,
            child: TextField(
              onChanged: (v) => controller.searchStores(v.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar tienda...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey.shade400),
                filled: true, fillColor: const Color(0xFFF5F5F5), isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none)),
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        // List
        Expanded(
          child: Obx(() {
            final q = controller.storeQuery.value;
            final list = q.isEmpty
                ? controller.stores.toList()
                : controller.stores.where((s) =>
                    s.name.toLowerCase().contains(q) ||
                    s.ownerEmail.toLowerCase().contains(q) ||
                    s.email.toLowerCase().contains(q)).toList();
            if (list.isEmpty) {
              return const Center(
                child: Text('Sin comercios registrados.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)));
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
              itemBuilder: (_, i) => _storeCard(list[i]),
            );
          }),
        ),
      ]),
    );
  }

  Widget _storeCard(StoreModel store) {
    return Obx(() {
      final selected = controller.selectedStore.value?.id == store.id;
      return GestureDetector(
        onTap: () => controller.loadStoreDetail(store.id, knownStore: store),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: selected ? _purpleLight.withValues(alpha: 0.4) : Colors.transparent,
          child: Row(children: [
            // Avatar
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: _purpleLight, borderRadius: BorderRadius.circular(10),
                  border: selected ? Border.all(color: _purple, width: 1.5) : null),
              child: store.logoUrl.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(10),
                      child: Image.network(store.logoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _storeInitial(store.name)))
                  : _storeInitial(store.name),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(store.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: selected ? _purple : const Color(0xFF111827)),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(store.ownerEmail.isNotEmpty ? store.ownerEmail : store.email,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 8),
            _kycBadge(store.kycStatus),
          ]),
        ),
      );
    });
  }

  Widget _storeInitial(String name) {
    return Center(child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _purple)));
  }

  Widget _kycBadge(String status) {
    Color bg; Color fg; String label;
    switch (status.toLowerCase()) {
      case 'approved':  bg = const Color(0xFFD1FAE5); fg = const Color(0xFF065F46); label = 'Activo'; break;
      case 'pending':   bg = const Color(0xFFFEF3C7); fg = const Color(0xFF92400E); label = 'Pendiente'; break;
      case 'rejected':  bg = const Color(0xFFFEE2E2); fg = const Color(0xFF991B1B); label = 'Rechazado'; break;
      case 'suspended': bg = const Color(0xFFFEE2E2); fg = const Color(0xFF991B1B); label = 'Suspendido'; break;
      default:          bg = const Color(0xFFF3F4F6); fg = Colors.grey; label = 'Sin KYC';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  // ─── STORE DETAIL ─────────────────────────────────────────────────────────────

  Widget _storeDetail() {
    return Obx(() {
      if (controller.isLoadingStore.value) {
        return const Center(child: CircularProgressIndicator(color: _purple));
      }
      final store = controller.selectedStore.value;
      if (store == null) {
        return Center(child: Column(
          mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.store_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Selecciona un comercio para ver sus usuarios',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ]));
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _detailHeader(store),
          const SizedBox(height: 20),
          _infoRow(store),
          const SizedBox(height: 20),
          _usersTable(store),
        ]),
      );
    });
  }

  Widget _detailHeader(StoreModel store) {
    return Row(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: _purpleLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border)),
        child: store.logoUrl.isNotEmpty
            ? ClipRRect(borderRadius: BorderRadius.circular(14),
                child: Image.network(store.logoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _storeInitial(store.name)))
            : _storeInitial(store.name),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(store.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: Color(0xFF111827))),
        const SizedBox(height: 4),
        Text(store.address.isNotEmpty ? store.address : 'Sin dirección registrada',
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ])),
      _kycBadge(store.kycStatus),
      const SizedBox(width: 12),
      OutlinedButton.icon(
        onPressed: () => Get.toNamed(Routes.STORE_CONFIG,
            arguments: {'storeId': store.id}),
        icon: const Icon(Icons.settings_outlined, size: 14),
        label: const Text('Configurar', style: TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _purple,
          side: const BorderSide(color: _purple),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    ]);
  }

  Widget _infoRow(StoreModel store) {
    return Row(children: [
      Expanded(child: _infoCard(Icons.person_outline, 'Propietario',
          store.ownerName.isNotEmpty ? store.ownerName : '—')),
      const SizedBox(width: 12),
      Expanded(child: _infoCard(Icons.email_outlined, 'Email',
          store.email.isNotEmpty ? store.email : store.ownerEmail)),
      const SizedBox(width: 12),
      Expanded(child: _infoCard(Icons.group_outlined, 'Usuarios',
          '${controller.selectedStoreUsers.length}')),
    ]);
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _purpleLight,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: _purple),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey,
              fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  // ─── USERS TABLE ─────────────────────────────────────────────────────────────

  Widget _usersTable(StoreModel store) {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Row(children: [
            const Text('Usuarios del comercio',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _showInviteDialog(store.id),
              icon: const Icon(Icons.person_add_outlined, size: 14),
              label: const Text('Invitar', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: const BorderSide(color: _purple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: const Color(0xFFF9FAFB),
          child: const Row(children: [
            Expanded(flex: 3, child: _HeaderCell('USUARIO')),
            Expanded(flex: 2, child: _HeaderCell('EMAIL')),
            SizedBox(width: 100,  child: _HeaderCell('ROL')),
            SizedBox(width: 90,   child: _HeaderCell('ESTADO')),
            SizedBox(width: 130,  child: _HeaderCell('ÚLTIMO ACCESO')),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        // Rows
        Obx(() {
          final users = controller.selectedStoreUsers;
          if (users.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Sin usuarios registrados en este comercio.',
                  style: TextStyle(color: Colors.grey, fontSize: 13))),
            );
          }
          return Column(children: users.map((u) => _userRow(u, store.id)).toList());
        }),
      ]),
    );
  }

  Widget _userRow(StoreUserModel user, String storeId) {
    const months = ['','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    String lastActive = '—';
    if (user.lastActiveAt != null) {
      final d = user.lastActiveAt!.toLocal();
      lastActive = '${d.day} ${months[d.month]} ${d.year}';
    }

    Color roleBg; Color roleFg;
    switch (user.role.toUpperCase()) {
      case 'OWNER':  roleBg = _purpleLight; roleFg = _purple; break;
      case 'ADMIN':  roleBg = const Color(0xFFDCFCE7); roleFg = const Color(0xFF166534); break;
      case 'VIEWER': roleBg = const Color(0xFFFEF3C7); roleFg = const Color(0xFF92400E); break;
      default:       roleBg = const Color(0xFFF3F4F6); roleFg = Colors.grey;
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          // Name + avatar
          Expanded(flex: 3, child: Row(children: [
            CircleAvatar(radius: 16, backgroundColor: _purpleLight,
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: _purple))),
            const SizedBox(width: 10),
            Expanded(child: Text(user.displayName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis)),
          ])),
          // Email
          Expanded(flex: 2, child: Text(user.email,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis)),
          // Role
          SizedBox(width: 100, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: roleBg, borderRadius: BorderRadius.circular(20)),
            child: Text(user.roleLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: roleFg)),
          )),
          // Status
          SizedBox(width: 90, child: Row(children: [
            Container(width: 7, height: 7,
                decoration: BoxDecoration(
                    color: user.isActive ? const Color(0xFF22C55E) : Colors.grey,
                    shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(user.isActive ? 'Activo' : 'Inactivo',
                style: TextStyle(fontSize: 12,
                    color: user.isActive ? const Color(0xFF15803D) : Colors.grey)),
          ])),
          // Last active
          SizedBox(width: 130, child: Text(lastActive,
              style: const TextStyle(fontSize: 12, color: Colors.grey))),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFF3F4F6)),
    ]);
  }

  // ─── INVITE DIALOG ───────────────────────────────────────────────────────────

  void _showInviteDialog(String storeId) {
    final emailCtrl = TextEditingController();
    String role = StoreUserModel.roleAdmin;
    showDialog<void>(
      context: Get.context!,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Invitar usuario'),
          content: SizedBox(width: 380, child: Column(
            mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true),
              items: const [
                DropdownMenuItem(value: StoreUserModel.roleOwner,  child: Text('Owner')),
                DropdownMenuItem(value: StoreUserModel.roleAdmin,  child: Text('Admin')),
                DropdownMenuItem(value: StoreUserModel.roleViewer, child: Text('Viewer')),
                DropdownMenuItem(value: StoreUserModel.roleMember, child: Text('Member')),
              ],
              onChanged: (v) => setState(() => role = v ?? role),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                Navigator.of(ctx).pop();
                await controller.inviteUserToSelectedStore(storeId, email, role);
              },
              child: const Text('Invitar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: Colors.grey, letterSpacing: 0.4));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Formulario de alta de tienda
// ══════════════════════════════════════════════════════════════════════════════

class _CreateStoreForm extends StatefulWidget {
  const _CreateStoreForm({required this.controller});
  final GeneralAdminController controller;

  @override
  State<_CreateStoreForm> createState() => _CreateStoreFormState();
}

class _CreateStoreFormState extends State<_CreateStoreForm> {
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _ink = Color(0xFF1E1B4B);
  static const Color _muted = Color(0xFF6B7280);

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _cif = TextEditingController();
  final _ownerEmail = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _description, _address, _phone, _email, _website, _cif, _ownerEmail]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Falta el nombre', 'El nombre de la tienda es obligatorio',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    String? v(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final payload = <String, dynamic>{
      'name': name,
      if (v(_description) != null) 'description': v(_description),
      if (v(_address) != null) 'address': v(_address),
      if (v(_phone) != null) 'phone': v(_phone),
      if (v(_email) != null) 'email': v(_email),
      if (v(_website) != null) 'website': v(_website),
      if (v(_cif) != null) 'cif': v(_cif),
      if (v(_ownerEmail) != null) 'owner_email': v(_ownerEmail),
    };
    final ok = await widget.controller.createStore(payload);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 44, height: 5,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(3))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(children: [
              const Text('Nueva tienda',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
              const Spacer(),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: _muted)),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _field('Nombre comercial *', _name, hint: 'Ej. Healthy Foods'),
                _field('Descripción', _description, hint: 'Breve descripción', lines: 2),
                _field('Dirección física', _address, hint: 'Calle, número, ciudad'),
                Row(children: [
                  Expanded(child: _field('Teléfono', _phone, keyboard: TextInputType.phone)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('CIF / NIF', _cif)),
                ]),
                _field('Email', _email, keyboard: TextInputType.emailAddress),
                _field('Sitio web', _website, keyboard: TextInputType.url, hint: 'https://...'),
                _field('Email del dueño', _ownerEmail,
                    keyboard: TextInputType.emailAddress, hint: 'propietario@...'),
                const SizedBox(height: 20),
              ]),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 16),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: Obx(() => FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: _purple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: widget.controller.isCreatingStore.value ? null : _submit,
                    child: widget.controller.isCreatingStore.value
                        ? const SizedBox(height: 22, width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Crear tienda',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {String? hint, TextInputType? keyboard, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
        ),
        TextField(
          controller: c,
          keyboardType: keyboard,
          maxLines: lines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _purple, width: 1.5),
            ),
          ),
        ),
      ]),
    );
  }
}
