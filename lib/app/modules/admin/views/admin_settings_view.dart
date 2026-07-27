import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/store_user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/admin_controller.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({Key? key}) : super(key: key);

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  static const Color _purple      = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg          = Color(0xFFF5F3FF);

  late final AdminController _ctrl;

  final _nameCtrl           = TextEditingController();
  final _addressCtrl        = TextEditingController();
  final _billingAddressCtrl = TextEditingController();
  final _fiscalIdCtrl       = TextEditingController();
  String? _selectedCategory;
  bool _sameAddressForBilling = false;
  bool _twoFactorEnabled      = false;

  bool _isSaving         = false;
  bool _isUploadingBanner = false;
  bool _isUploadingLogo   = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
    _populateForm();
    _ctrl.reloadStoreUsers();
  }

  void _populateForm() {
    final s = _ctrl.currentStore;
    _nameCtrl.text           = s.name;
    _addressCtrl.text        = s.address;
    _billingAddressCtrl.text =
        s.billingAddress.isNotEmpty ? s.billingAddress : s.address;
    _fiscalIdCtrl.text       = s.fiscalId;
    _selectedCategory =
        s.categories.isNotEmpty ? s.categories.first : null;
    _twoFactorEnabled      = s.twoFactorEnabled;
    _sameAddressForBilling =
        s.billingAddress.isEmpty || s.billingAddress == s.address;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _billingAddressCtrl.dispose();
    _fiscalIdCtrl.dispose();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

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
      width: 220, color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: _purple, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.store, color: Colors.white, size: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(() {
                _ctrl.storeId.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_ctrl.currentStore.name,
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      _ctrl.currentStore.subtitle.isNotEmpty
                          ? _ctrl.currentStore.subtitle
                          : 'Gestión de Tienda',
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
        _nav(Icons.swap_horiz_rounded,     'Canjes',
            onTap: () => Get.offNamed(Routes.REDEMPTION_CODE_HISTORY)),
        _nav(Icons.card_giftcard_outlined, 'Canjes y Beneficios',
            onTap: () => Get.toNamed(Routes.PREMIOS)),
        _nav(Icons.history_outlined,       'Historial',
            onTap: () => Get.offNamed(Routes.REDEMPTION_CODE_HISTORY)),
        _nav(Icons.bar_chart_outlined,     'Estadísticas',
            onTap: () => Get.offNamed(Routes.ANALYTICS)),
        _nav(Icons.lock_outline,           'PIN',
            onTap: () => _showChangePinDialog(context)),
        _nav(Icons.security_outlined,      'Seguridad', selected: true),
        const Spacer(),
        const Divider(height: 1),
        ListTile(
          dense: true,
          leading: const Icon(Icons.logout, size: 18, color: Colors.grey),
          title: const Text('Cerrar Sesión',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          onTap: () async {
            await AuthService.signOut();
            Get.offAllNamed(Routes.LOGIN);
          }),
        const SizedBox(height: 8),
      ]),
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
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(Icons.store_outlined, 'Información de la Tienda'),
              const SizedBox(height: 16),
              _storeInfoSection(context),
              const SizedBox(height: 28),
              _rolesSection(context),
              const SizedBox(height: 28),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _securitySection(context)),
                const SizedBox(width: 20),
                Expanded(child: _fiscalSection()),
              ]),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      _bottomBar(context),
    ]);
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(children: [
        const Text('Configuración',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: _purple)),
        const Spacer(),
        SizedBox(
          width: 200, height: 36,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar ajuste...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
              filled: true, fillColor: const Color(0xFFF5F5F5), isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 9),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none)),
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.upload_outlined, size: 22, color: Color(0xFF374151)),
        const SizedBox(width: 16),
        Obx(() {
          _ctrl.storeId.value;
          return CircleAvatar(
            radius: 16, backgroundColor: _purpleLight,
            child: _ctrl.currentStore.logoUrl.startsWith('http')
                ? ClipOval(child: Image.network(_ctrl.currentStore.logoUrl,
                    width: 32, height: 32, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 16, color: _purple)))
                : const Icon(Icons.person, size: 16, color: _purple));
        }),
      ]),
    );
  }

  // ─── SECTION TITLE ───────────────────────────────────────────────────────

  Widget _sectionTitle(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 20, color: _purple),
      const SizedBox(width: 10),
      Text(label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: Color(0xFF111827))),
    ]);
  }

  // ─── STORE INFO ───────────────────────────────────────────────────────────

  Widget _storeInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 200, child: _bannerLogoColumn()),
        const SizedBox(width: 28),
        Expanded(child: _storeFormFields(context)),
      ]),
    );
  }

  Widget _bannerLogoColumn() {
    return Column(children: [
      // Banner
      GestureDetector(
        onTap: _isUploadingBanner ? null : () => _pickImage(isBanner: true),
        child: Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Obx(() {
              _ctrl.storeId.value;
              final url = _ctrl.currentStore.banner;
              return url.startsWith('http')
                  ? Image.network(url, width: 200, height: 120, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _bannerPlaceholder())
                  : _bannerPlaceholder();
            }),
          ),
          Positioned(top: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _purple, borderRadius: BorderRadius.circular(12)),
              child: const Text('Portada',
                  style: TextStyle(color: Colors.white,
                      fontSize: 10, fontWeight: FontWeight.w600)))),
          if (_isUploadingBanner)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12)),
                child: const Center(
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))))),
        ]),
      ),
      const SizedBox(height: 16),
      // Logo
      GestureDetector(
        onTap: _isUploadingLogo ? null : () => _pickImage(isBanner: false),
        child: Column(children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _purpleLight, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8, offset: const Offset(0, 2))]),
            child: Obx(() {
              _ctrl.storeId.value;
              final url = _ctrl.currentStore.logoUrl;
              return url.startsWith('http')
                  ? ClipOval(child: Image.network(url,
                      width: 72, height: 72, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _logoFallback()))
                  : _logoFallback();
            }),
          ),
          const SizedBox(height: 8),
          const Text('Logo de Tienda',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: _purple)),
          const Text('Formato PNG a SVG\n1200×200px',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
    ]);
  }

  Widget _bannerPlaceholder() {
    return Container(
      width: 200, height: 120,
      decoration: BoxDecoration(
          color: const Color(0xFFE8D5FF),
          borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.store, size: 40, color: _purple));
  }

  Widget _logoFallback() {
    final initials = _ctrl.currentStore.name.isNotEmpty
        ? _ctrl.currentStore.name.split(' ').take(2)
            .map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase()
        : 'LD';
    return Center(child: Text(initials,
        style: const TextStyle(fontSize: 20,
            fontWeight: FontWeight.w800, color: _purple)));
  }

  Widget _storeFormFields(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _labeledField('Nombre Comercial',
            child: _textField(_nameCtrl))),
        const SizedBox(width: 16),
        Expanded(child: _labeledField('Categoría',
            child: Obx(() {
              final cats = _ctrl.categories
                  .map((c) => c.title).where((t) => t.isNotEmpty).toList();
              if (_selectedCategory != null && !cats.contains(_selectedCategory)) {
                cats.insert(0, _selectedCategory!);
              }
              return _dropdown(
                value: _selectedCategory ?? (cats.isNotEmpty ? cats.first : null),
                items: cats,
                onChanged: (v) => setState(() => _selectedCategory = v));
            }))),
      ]),
      const SizedBox(height: 16),
      _labeledField('Dirección Física', child: _textField(_addressCtrl)),
      const SizedBox(height: 16),
      _labeledField(
        'Ubicación GPS',
        trailing: TextButton(
          onPressed: () => _showGeocodingDialog(context),
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero, minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('Abrir Selector en Mapa',
              style: TextStyle(fontSize: 12, color: _purple,
                  fontWeight: FontWeight.w600))),
        child: _gpsWidget()),
    ]);
  }

  Widget _gpsWidget() {
    return Obx(() {
      _ctrl.storeId.value;
      final lat = _ctrl.currentStore.latitude;
      final lng = _ctrl.currentStore.longitude;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4FD),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                  size: const Size(double.infinity, 150),
                  painter: _MapGrid())),
            const Center(child: Icon(Icons.location_on, size: 36, color: _purple)),
            if (lat != null && lng != null)
              Positioned(bottom: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4)]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: _purple),
                    const SizedBox(width: 4),
                    Text(
                      'Coord: ${lat.toStringAsFixed(4)} / ${lng.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w600)),
                  ]))),
            if (lat != null && lng != null)
              Positioned(bottom: 10, right: 10,
                child: GestureDetector(
                  onTap: () => _resolveAddress(lat, lng),
                  child: Text('Lectura y copiar coordenadas físicas',
                      style: TextStyle(fontSize: 9,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.underline)))),
          ]),
        ),
        if (_geocodedAddress != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.place_outlined, size: 13, color: _purple),
            const SizedBox(width: 4),
            Expanded(child: Text(_geocodedAddress!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF374151)))),
          ]),
        ],
      ]);
    });
  }

  String? _geocodedAddress;
  bool    _isGeocoding = false;

  Future<void> _resolveAddress(double lat, double lng) async {
    if (_isGeocoding) return;
    setState(() => _isGeocoding = true);
    final address = await _ctrl.reverseGeocode(lat, lng);
    if (mounted) setState(() {
      _geocodedAddress = address;
      _isGeocoding     = false;
    });
  }

  // ─── ROLES ────────────────────────────────────────────────────────────────

  Widget _rolesSection(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _sectionTitle(Icons.people_outline, 'Gestión de Roles'),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showInviteDialog(context),
          icon: const Icon(Icons.person_add_outlined, size: 16, color: Colors.white),
          label: const Text('Invitar Usuario',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)))),
      ]),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(children: [
          _usersHeader(),
          const Divider(height: 1),
          Obx(() {
            if (_ctrl.storeUsers.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text('Sin usuarios registrados.',
                    style: TextStyle(color: Colors.grey))));
            }
            return Column(
                children: _ctrl.storeUsers
                    .map((u) => _userRow(context, u)).toList());
          }),
        ]),
      ),
    ]);
  }

  Widget _usersHeader() {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
        color: Colors.grey, letterSpacing: 0.4);
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Expanded(flex: 3, child: Text('USUARIO', style: style)),
        Expanded(flex: 2, child: Text('ROL', style: style)),
        Expanded(child: Text('ESTADO', style: style)),
        SizedBox(width: 60, child: Text('ACCIONES', style: style)),
      ]));
  }

  Widget _userRow(BuildContext context, StoreUserModel user) {
    final isPriv = user.isAdmin;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(children: [
          Expanded(flex: 3, child: Row(children: [
            CircleAvatar(
              radius: 18, backgroundColor: _purpleLight,
              child: user.avatarUrl != null
                  ? ClipOval(child: Image.network(user.avatarUrl!,
                      width: 36, height: 36, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initials(user)))
                  : _initials(user)),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.displayName,
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              Text(user.email,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis),
            ])),
          ])),
          Expanded(flex: 2, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPriv ? _purpleLight : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20)),
            child: Text(user.roleLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: isPriv ? _purple : Colors.grey.shade700),
                textAlign: TextAlign.center))),
          Expanded(child: Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(
                    color: user.isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(user.isOnline ? 'Activo' : 'Inactivo',
                style: const TextStyle(fontSize: 12)),
          ])),
          SizedBox(width: 60, child: user.isOwner
              ? const SizedBox.shrink()
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onSelected: (v) => _handleUserAction(context, user, v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'change_role',
                        child: Text('Cambiar rol', style: TextStyle(fontSize: 13))),
                    if (user.canBeRemoved)
                      const PopupMenuItem(value: 'remove',
                          child: Text('Eliminar',
                              style: TextStyle(fontSize: 13, color: Colors.red))),
                  ])),
        ])),
      const Divider(height: 1),
    ]);
  }

  Widget _initials(StoreUserModel user) {
    return Text(user.initials,
        style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700, color: _purple));
  }

  // ─── SECURITY ─────────────────────────────────────────────────────────────

  Widget _securitySection(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(Icons.shield_outlined, 'Seguridad'),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(children: [
          // PIN row
          Row(children: [
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PIN de la Tienda',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              const Text('Requerido para autorizar canjes manuales',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            OutlinedButton(
              onPressed: () => _showChangePinDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple, side: const BorderSide(color: _purple),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
              child: const Text('Cambiar\nPIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // 2FA row
          Row(children: [
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Doble Factor (2FA)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              const Text('Confirmación vía App móvil para cambios críticos',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            Switch(
              value: _twoFactorEnabled,
              onChanged: (v) {
                setState(() => _twoFactorEnabled = v);
                _ctrl.toggleTwoFactor(v);
              },
              activeColor: _purple,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ]),
        ]),
      ),
    ]);
  }

  // ─── FISCAL ───────────────────────────────────────────────────────────────

  Widget _fiscalSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(Icons.receipt_long_outlined, 'Datos Fiscales'),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _labeledField('CIF / NIF', child: _textField(_fiscalIdCtrl)),
          const SizedBox(height: 16),
          _labeledField('Dirección de Facturación',
              child: _textField(_billingAddressCtrl,
                  enabled: !_sameAddressForBilling, maxLines: 2)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() {
              _sameAddressForBilling = !_sameAddressForBilling;
              if (_sameAddressForBilling) {
                _billingAddressCtrl.text = _addressCtrl.text;
              }
            }),
            child: Row(children: [
              SizedBox(width: 20, height: 20,
                child: Checkbox(
                  value: _sameAddressForBilling,
                  onChanged: (v) => setState(() {
                    _sameAddressForBilling = v ?? false;
                    if (_sameAddressForBilling) {
                      _billingAddressCtrl.text = _addressCtrl.text;
                    }
                  }),
                  activeColor: _purple,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
              const SizedBox(width: 8),
              const Text('Usar la misma dirección que la tienda física',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
        ]),
      ),
    ]);
  }

  // ─── BOTTOM BAR ───────────────────────────────────────────────────────────

  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(
          onPressed: () => setState(() => _populateForm()),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          child: const Text('Descartar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        const SizedBox(width: 12),
        Obx(() => ElevatedButton(
          onPressed: (_isSaving || _ctrl.isSavingSettings.value)
              ? null : () => _save(),
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple, foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
          child: (_isSaving || _ctrl.isSavingSettings.value)
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar Cambios',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))),
      ]),
    );
  }

  // ─── FORM HELPERS ─────────────────────────────────────────────────────────

  Widget _labeledField(String label,
      {required Widget child, Widget? trailing}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                color: Color(0xFF374151))),
        if (trailing != null) ...[const Spacer(), trailing],
      ]),
      const SizedBox(height: 6),
      child,
    ]);
  }

  Widget _textField(TextEditingController ctrl,
      {bool enabled = true, int maxLines = 1}) {
    return TextField(
      controller: ctrl, enabled: enabled, maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _purple, width: 1.5)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)))));
  }

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 46, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (value != null && items.contains(value)) ? value : null,
          isExpanded: true,
          hint: const Text('Seleccionar',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          items: items.map((e) =>
              DropdownMenuItem(value: e, child: Text(e,
                  style: const TextStyle(fontSize: 13,
                      color: Color(0xFF374151))))).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))));
  }

  // ─── ACTIONS ──────────────────────────────────────────────────────────────

  void _showGeocodingDialog(BuildContext context) {
    final addressCtrl = TextEditingController(text: _addressCtrl.text);
    double? previewLat;
    double? previewLng;
    String? previewAddress;
    bool isSearching = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.location_on, color: _purple, size: 20),
            SizedBox(width: 8),
            Text('Selector de Ubicación GPS'),
          ]),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Dirección o ciudad',
                  hintText: 'Ej: Calle Principal 123, Madrid',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: isSearching
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : const Icon(Icons.search, color: _purple),
                    onPressed: isSearching ? null : () async {
                      final q = addressCtrl.text.trim();
                      if (q.isEmpty) return;
                      setDlg(() => isSearching = true);
                      final coords = await _ctrl.geocode(q);
                      setDlg(() {
                        isSearching = false;
                        if (coords != null) {
                          previewLat     = coords['lat'];
                          previewLng     = coords['lng'];
                          previewAddress = q;
                        }
                      });
                    }))),
              if (previewLat != null && previewLng != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Coordenadas encontradas:',
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${previewLat!.toStringAsFixed(6)}  '
                      'Lng: ${previewLng!.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700)),
                    if (previewAddress != null) ...[
                      const SizedBox(height: 4),
                      Text(previewAddress!,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ])),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
              onPressed: previewLat == null ? null : () async {
                Navigator.of(ctx).pop();
                await _ctrl.saveStoreSettings({
                  'latitude':  previewLat,
                  'longitude': previewLng,
                });
                if (previewAddress != null) {
                  setState(() => _geocodedAddress = previewAddress);
                }
              },
              child: const Text('Confirmar ubicación')),
          ])));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'cif': _fiscalIdCtrl.text.trim(),
        'billing_address': _sameAddressForBilling
            ? _addressCtrl.text.trim()
            : _billingAddressCtrl.text.trim(),
        if (_selectedCategory != null) 'category': _selectedCategory,
      };
      await _ctrl.saveStoreSettings(payload);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage({required bool isBanner}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (file == null) return;
    if (mounted) setState(() {
      if (isBanner) _isUploadingBanner = true;
      else          _isUploadingLogo   = true;
    });
    try {
      if (isBanner) {
        await _ctrl.uploadStoreBanner(file); // endpoint dedicado
      } else {
        await _ctrl.uploadStoreLogo(file);   // endpoint dedicado
      }
    } finally {
      if (mounted) setState(() {
        _isUploadingBanner = false;
        _isUploadingLogo   = false;
      });
    }
  }

  void _showChangePinDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cambiar PIN'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _pinField(currentCtrl, 'PIN actual'),
          const SizedBox(height: 12),
          _pinField(newCtrl, 'Nuevo PIN'),
          const SizedBox(height: 12),
          _pinField(confirmCtrl, 'Confirmar nuevo PIN'),
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
              if (newCtrl.text != confirmCtrl.text) {
                Get.snackbar('Error', 'Los PINs no coinciden',
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              Navigator.of(ctx).pop();
              await _ctrl.changePin(currentCtrl.text, newCtrl.text);
            },
            child: const Text('Cambiar PIN'))]));
  }

  Widget _pinField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl, obscureText: true,
      keyboardType: TextInputType.number, maxLength: 6,
      decoration: InputDecoration(
        labelText: label, counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)));
  }

  void _showInviteDialog(BuildContext context) {
    final emailCtrl   = TextEditingController();
    String role       = StoreUserModel.roleAdmin;
    const roleOptions = {
      StoreUserModel.roleAdmin:  'Administrador',
      StoreUserModel.roleMember: 'Miembro',
      'MANAGER':   'Manager',
      'VALIDATOR':  'Visualizador',
    };
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Invitar Usuario'),
          content: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Email:', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'usuario@empresa.com',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10)),
              autofocus: true),
            const SizedBox(height: 14),
            const Text('Rol:', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              height: 46, padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: role, isExpanded: true,
                  items: roleOptions.entries.map((e) =>
                      DropdownMenuItem(value: e.key,
                          child: Text(e.value,
                              style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) { if (v != null) set(() => role = v); },
                  icon: const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: Colors.grey)))),
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
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                Navigator.of(ctx).pop();
                await _ctrl.inviteUser(email, role);
              },
              child: const Text('Invitar'))])));
  }

  void _handleUserAction(
      BuildContext context, StoreUserModel user, String action) {
    if (action == 'remove') {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Eliminar usuario'),
          content: Text('¿Eliminar a ${user.displayName} de la tienda?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _ctrl.removeUser(user.id);
              },
              child: const Text('Eliminar'))]));
    } else if (action == 'change_role') {
      final newRole = user.role.toUpperCase() == StoreUserModel.roleAdmin
          ? StoreUserModel.roleMember : StoreUserModel.roleAdmin;
      _ctrl.updateUserRole(user.id, newRole);
    }
  }
}

// ─── MAP GRID PAINTER ─────────────────────────────────────────────────────────

class _MapGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road  = Paint()..color = const Color(0xFFCBE0F5)..strokeWidth = 1.5;
    final block = Paint()..color = const Color(0xFFD4EAF7);
    for (double x = 0; x < size.width;  x += 36) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawRect(Rect.fromLTWH(x + 2, y + 2, 28, 22), block);
      }
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), road);
    }
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), road);
    }
  }

  @override bool shouldRepaint(_) => false;
}
