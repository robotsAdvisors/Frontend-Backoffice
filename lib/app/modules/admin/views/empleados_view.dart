import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/role_definition_model.dart';
import '../../../data/models/store_user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/admin_controller.dart';

class EmpleadosView extends StatefulWidget {
  const EmpleadosView({super.key});

  @override
  State<EmpleadosView> createState() => _EmpleadosViewState();
}

class _EmpleadosViewState extends State<EmpleadosView> {
  static const Color _purple      = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg          = Color(0xFFF8F7FF);
  static const Color _dark        = Color(0xFF1E1B4B);
  static const Color _border      = Color(0xFFEEEEEE);
  static const Color _green       = Color(0xFF10B981);

  late final AdminController _ctrl;
  StoreUserModel? _selectedUser;

  // Iconos para cada slug de permiso
  static IconData _iconFor(String slug) => switch (slug) {
    RolePermissionSlug.products        => Icons.inventory_2_outlined,
    RolePermissionSlug.redemptionCodes => Icons.confirmation_number_outlined,
    RolePermissionSlug.analytics       => Icons.bar_chart_outlined,
    RolePermissionSlug.team            => Icons.group_outlined,
    RolePermissionSlug.settings        => Icons.receipt_long_outlined,
    _                                  => Icons.lock_outline,
  };

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.reloadStoreUsers();
      _ctrl.loadRoleDefinitions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bg,
        body: Row(children: [
          _sidebar(context),
          Expanded(child: _body(context)),
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
        title: const Text('Empleados',
            style: TextStyle(color: _dark, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: _body(context),
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
        _navItem(icon: Icons.grid_view_outlined,  label: 'Inicio',
            onTap: () => Get.offAllNamed(Routes.ADMIN)),
        _navItem(icon: Icons.group_outlined,       label: 'Equipo',
            onTap: () => Get.toNamed(Routes.EMPLEADOS)),
        _navItem(icon: Icons.receipt_outlined,     label: 'Pedidos',
            onTap: () => Get.toNamed(Routes.CONFIRMAR_ENTREGA)),
        _navItem(icon: Icons.inventory_2_outlined, label: 'Productos',
            onTap: () => Get.toNamed(Routes.INVENTARIO)),
        _navItem(icon: Icons.badge_outlined,       label: 'Empleados', selected: true),
        _navItem(icon: Icons.security_outlined,    label: 'Seguridad',
            onTap: () => Get.toNamed(Routes.SEGURIDAD)),
        _navItem(icon: Icons.settings_outlined,    label: 'Configuraciones',
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

  Widget _body(BuildContext context) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _header(context),
            const SizedBox(height: 24),
            _twoColumns(context),
          ]),
        ),
      ),
      _infoBar(),
    ]);
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Roles y permisos de tienda',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _dark)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: _purpleLight, borderRadius: BorderRadius.circular(20)),
            child: const Text('Admin tienda',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _purple)),
          ),
        ]),
        const SizedBox(height: 4),
        const Text(
            'Gestiona los roles, permisos y el acceso de las diferentes funciones de tu tienda',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
      ])),
      const SizedBox(width: 16),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _purple, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.person_add_outlined, size: 18),
        label: const Text('Invitar usuario',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        onPressed: () => _showInviteDialog(context),
      ),
    ]);
  }

  // ─── TWO-COLUMN LAYOUT ────────────────────────────────────────────────────

  Widget _twoColumns(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 5, child: _usersPanel(context)),
      const SizedBox(width: 20),
      Expanded(flex: 4, child: _permissionsPanel()),
    ]);
  }

  // ─── USERS PANEL ──────────────────────────────────────────────────────────

  Widget _usersPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Row(children: [
            const Text('Usuarios de la tienda',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
            const Spacer(),
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: _purpleLight, borderRadius: BorderRadius.circular(20)),
              child: Text('${_ctrl.storeUsers.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _purple)),
            )),
          ]),
        ),
        Container(height: 1, color: _border),
        Obx(() {
          if (_ctrl.storeUsers.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Sin usuarios registrados',
                  style: TextStyle(fontSize: 13, color: Colors.grey))),
            );
          }
          return Column(
            children: _ctrl.storeUsers.asMap().entries.map((e) {
              return _userRow(context, e.value, e.key.isEven);
            }).toList(),
          );
        }),
      ]),
    );
  }

  Widget _userRow(BuildContext context, StoreUserModel user, bool even) {
    final isSelected = _selectedUser?.id == user.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedUser = user),
      child: Container(
        color: isSelected
            ? _purpleLight
            : (even ? Colors.white : const Color(0xFFFAFAFB)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _purpleLight,
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? Text(user.initials,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _purple))
                    : null,
              ),
              Positioned(
                right: -2, bottom: -2,
                child: Container(
                  width: 11, height: 11,
                  decoration: BoxDecoration(
                    color: user.isOnline ? _green : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _purple : _dark),
                  overflow: TextOverflow.ellipsis),
              Text(user.presenceLabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          )),
          const SizedBox(width: 8),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: user.isAdmin ? _purpleLight : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(user.roleLabel,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: user.isAdmin ? _purple : Colors.grey.shade600)),
          ),
          if (user.canBeRemoved) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'role', child: Text('Cambiar rol')),
                const PopupMenuItem(
                    value: 'remove',
                    child: Text('Eliminar', style: TextStyle(color: Colors.red))),
              ],
              onSelected: (v) {
                if (v == 'remove') _confirmRemove(context, user);
                if (v == 'role')   _changeRole(context, user);
              },
            ),
          ],
        ]),
      ),
    );
  }

  // ─── PERMISSIONS PANEL ────────────────────────────────────────────────────

  Widget _permissionsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Permisos por rol',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
            const SizedBox(height: 2),
            Text(
              _selectedUser != null
                  ? _selectedUser!.roleLabel
                  : 'Selecciona un usuario',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ]),
        ),
        Container(height: 1, color: _border),
        Padding(
          padding: const EdgeInsets.all(16),
          child: _selectedUser != null
              ? _permissionsList(_selectedUser!)
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Selecciona un usuario para\nver sus permisos',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _permissionsList(StoreUserModel user) {
    return Obx(() {
      final defs = _ctrl.roleDefinitions;
      // Fallback a todos los slugs conocidos si aún no cargaron
      final allSlugs = defs.isNotEmpty
          ? defs.expand((d) => d.permissions).toSet().toList()
          : [
              RolePermissionSlug.products,
              RolePermissionSlug.redemptionCodes,
              RolePermissionSlug.analytics,
              RolePermissionSlug.team,
              RolePermissionSlug.settings,
            ];
      final roleDef = defs.cast<RoleDefinitionModel?>().firstWhere(
            (d) => d!.role.toUpperCase() == user.role.toUpperCase(),
            orElse: () => null);
      final granted = roleDef?.permissions.toSet() ?? <String>{};

      return Column(
        children: allSlugs.map((slug) {
          final hasAccess = granted.contains(slug);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasAccess ? _purpleLight : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: hasAccess ? _purple.withValues(alpha: 0.25) : _border),
            ),
            child: Row(children: [
              Icon(_iconFor(slug), size: 18,
                  color: hasAccess ? _purple : Colors.grey.shade400),
              const SizedBox(width: 10),
              Expanded(
                child: Text(RolePermissionSlug.toLabel(slug),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasAccess ? _purple : Colors.grey.shade500)),
              ),
              Icon(
                hasAccess ? Icons.check_circle : Icons.cancel_outlined,
                size: 16,
                color: hasAccess ? _purple : Colors.grey.shade400,
              ),
            ]),
          );
        }).toList(),
      );
    });
  }

  // ─── INFO BAR ─────────────────────────────────────────────────────────────

  Widget _infoBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _purpleLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _purple.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, size: 16, color: _purple),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
              'Por ejemplo: El admin de la tienda es el que tiene funciones de gestión global de productos, canjes y configuración.',
              style: TextStyle(fontSize: 12, color: _purple)),
        ),
      ]),
    );
  }

  // ─── DIALOGS ──────────────────────────────────────────────────────────────

  void _showInviteDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final assignable = _ctrl.roleDefinitions
        .where((d) => d.assignable)
        .toList();
    final fallback = [
      RoleDefinitionModel(role: 'ADMIN',  label: 'Administrador', permissions: [], assignable: true),
      RoleDefinitionModel(role: 'VIEWER', label: 'Visualizador',  permissions: [], assignable: true),
      RoleDefinitionModel(role: 'MEMBER', label: 'Miembro',       permissions: [], assignable: true),
    ];
    final roles = assignable.isNotEmpty ? assignable : fallback;
    String selectedRole = roles.first.role;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Invitar usuario'),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'usuario@ejemplo.com',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Rol',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: roles
                    .map((d) => DropdownMenuItem(value: d.role, child: Text(d.label)))
                    .toList(),
                onChanged: (v) => setState(() => selectedRole = v ?? selectedRole),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _purple, foregroundColor: Colors.white),
              onPressed: () {
                final email = emailCtrl.text.trim();
                if (email.isEmpty || !email.contains('@')) return;
                Navigator.pop(ctx);
                _ctrl.inviteUser(email, selectedRole);
              },
              child: const Text('Invitar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, StoreUserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar a ${user.displayName} de la tienda?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _ctrl.removeUser(user.id);
              if (_selectedUser?.id == user.id) {
                setState(() => _selectedUser = null);
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _changeRole(BuildContext context, StoreUserModel user) {
    final assignable = _ctrl.roleDefinitions
        .where((d) => d.assignable && d.role.toUpperCase() != 'OWNER')
        .toList();

    // Fallback si aún no cargaron las definiciones
    if (assignable.isEmpty) {
      _ctrl.updateUserRole(
        user.id,
        user.role.toUpperCase() == StoreUserModel.roleAdmin
            ? StoreUserModel.roleMember
            : StoreUserModel.roleAdmin,
      );
      return;
    }

    String selectedRole = user.role.toUpperCase();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Cambiar rol de ${user.displayName}'),
          content: DropdownButtonFormField<String>(
            value: assignable.any((d) => d.role.toUpperCase() == selectedRole)
                ? selectedRole
                : assignable.first.role,
            decoration: InputDecoration(
              labelText: 'Rol',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: assignable
                .map((d) => DropdownMenuItem(value: d.role, child: Text(d.label)))
                .toList(),
            onChanged: (v) => setState(() => selectedRole = v ?? selectedRole),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _purple, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _ctrl.updateUserRole(user.id, selectedRole);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
