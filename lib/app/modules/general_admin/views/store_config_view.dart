import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/store_model.dart';
import '../../../data/models/store_user_model.dart';
import '../controllers/general_admin_controller.dart';
import 'backoffice_sidebar.dart';

class StoreConfigView extends GetView<GeneralAdminController> {
  const StoreConfigView({super.key});

  static const Color _purple = Color(0xFF7C3AED);
  static const Color _bg = Color(0xFFF8F7FF);

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final String? storeId = args is Map
        ? args['storeId']?.toString()
        : args?.toString();

    if (storeId != null && storeId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadStoreDetail(storeId);
      });
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          BackofficeSidebar(current: 'tiendas'),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingStore.value) {
                return const Center(
                    child: CircularProgressIndicator(color: _purple));
              }
              return _StoreFormBody(
                storeId: storeId ?? '',
                controller: controller,
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── SIDEBAR ─────────────────────────────────────────────────────────────────

}

// ─── FORM BODY ───────────────────────────────────────────────────────────────

class _StoreFormBody extends StatefulWidget {
  final String storeId;
  final GeneralAdminController controller;

  const _StoreFormBody({required this.storeId, required this.controller});

  @override
  State<_StoreFormBody> createState() => _StoreFormBodyState();
}

class _StoreFormBodyState extends State<_StoreFormBody> {
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _cifCtrl;
  late final TextEditingController _billingAddressCtrl;

  bool _sameAddress = false;
  bool _twoFactor = false;
  List<String> _selectedCategoryIds = [];
  StoreModel? _lastStore;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _latCtrl = TextEditingController();
    _lngCtrl = TextEditingController();
    _cifCtrl = TextEditingController();
    _billingAddressCtrl = TextEditingController();
    _syncFromStore(widget.controller.selectedStore.value);
    // Listen for store updates
    ever(widget.controller.selectedStore, _syncFromStore);
  }

  void _syncFromStore(StoreModel? s) {
    if (s == null || s == _lastStore) return;
    _lastStore = s;
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = s.name;
      _addressCtrl.text = s.address;
      _latCtrl.text = s.latitude?.toString() ?? '';
      _lngCtrl.text = s.longitude?.toString() ?? '';
      _cifCtrl.text = s.fiscalId;
      _billingAddressCtrl.text = s.billingAddress;
      _twoFactor = s.twoFactorEnabled;
      _selectedCategoryIds = List.from(s.categories);
      _sameAddress = s.billingAddress.isEmpty ||
          s.billingAddress == s.address;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _cifCtrl.dispose();
    _billingAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Información de la Tienda'),
                const SizedBox(height: 16),
                _storeInfoSection(),
                const SizedBox(height: 32),
                _sectionTitle('Gestión de Roles'),
                const SizedBox(height: 16),
                _rolesSection(),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _securitySection()),
                    const SizedBox(width: 24),
                    Expanded(child: _fiscalSection()),
                  ],
                ),
                const SizedBox(height: 32),
                _bottomButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 16, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 8),
          const Text('Tiendas',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right,
              size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Obx(() {
            final name =
                widget.controller.selectedStore.value?.name ?? 'Nueva Tienda';
            return Text(name,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF1E1B4B),
                    fontWeight: FontWeight.w600));
          }),
          const Spacer(),
          _searchBar(),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFEDE9FE),
            child: Icon(Icons.person, size: 16, color: Color(0xFF7C3AED)),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      width: 220,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
          hintText: 'Buscar...',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // ─── SECTION TITLE ───────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1B4B)));
  }

  // ─── SECTION 1: STORE INFO ───────────────────────────────────────────────────

  Widget _storeInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: banner + logo
          Column(
            children: [
              _bannerUpload(),
              const SizedBox(height: 12),
              _logoUpload(),
            ],
          ),
          const SizedBox(width: 32),
          // Right: form fields
          Expanded(child: _storeFormFields()),
        ],
      ),
    );
  }

  Widget _bannerUpload() {
    return Obx(() {
      final bannerUrl =
          widget.controller.selectedStore.value?.banner ?? '';
      return GestureDetector(
        onTap: _pickBanner,
        child: Container(
          width: 320,
          height: 140,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bannerUrl.isEmpty)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 32, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Subir banner',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                )
              else
                Image.network(
                  bannerUrl,
                  fit: BoxFit.cover,
                  // Diagnóstico: si la imagen no carga, muestra la URL real que
                  // se intentó cargar para saber por qué (relativa, 404, auth…).
                  errorBuilder: (_, err, __) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_outlined,
                            color: Colors.grey),
                        const SizedBox(height: 4),
                        const Text('No se pudo cargar la imagen',
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(bannerUrl,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 9, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ),
              if (bannerUrl.isNotEmpty)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Cambiar',
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _logoUpload() {
    return Obx(() {
      final logoUrl =
          widget.controller.selectedStore.value?.logoUrl ?? '';
      return GestureDetector(
        onTap: _pickLogo,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            image: logoUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(logoUrl),
                    fit: BoxFit.cover)
                : null,
          ),
          child: logoUrl.isEmpty
              ? Icon(Icons.store, size: 28, color: Colors.grey.shade400)
              : null,
        ),
      );
    });
  }

  Widget _storeFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('Nombre Comercial', _nameCtrl,
            hint: 'Ej. Cafetería Central'),
        const SizedBox(height: 16),
        _categoryDropdown(),
        const SizedBox(height: 16),
        _field('Dirección Física', _addressCtrl,
            hint: 'Calle, número, ciudad'),
        const SizedBox(height: 16),
        _gpsFields(),
      ],
    );
  }

  Widget _categoryDropdown() {
    return Obx(() {
      final allCategories = widget.controller.categories;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Categoría',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: allCategories.isEmpty
                ? const Text('Sin categorías disponibles',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allCategories.map((cat) {
                      final selected =
                          _selectedCategoryIds.contains(cat.id.toString());
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedCategoryIds.remove(cat.id.toString());
                          } else {
                            _selectedCategoryIds.add(cat.id.toString());
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: selected
                                ? _purpleLight
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? _purple
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            cat.displayName != null && cat.displayName!.isNotEmpty
                                ? cat.displayName!
                                : cat.title,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? _purple
                                  : const Color(0xFF374151),
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      );
    });
  }

  Widget _gpsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ubicación GPS',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _fieldRaw(_latCtrl, hint: 'Latitud (ej. 40.4168)'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _fieldRaw(_lngCtrl, hint: 'Longitud (ej. -3.7038)'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _mapPreview(),
      ],
    );
  }

  Widget _mapPreview() {
    return Obx(() {
      final store = widget.controller.selectedStore.value;
      final lat = store?.latitude;
      final lng = store?.longitude;
      if (lat == null || lng == null) {
        return Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Center(
            child: Text('Introduce coordenadas para ver el mapa',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ),
        );
      }
      // Static map via OpenStreetMap tile (no API key needed)
      final zoom = 15;
      final mapUrl =
          'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=$zoom&size=400x100&markers=$lat,$lng,lightblue1';
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          mapUrl,
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('$lat, $lng',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280))),
            ),
          ),
        ),
      );
    });
  }

  // ─── SECTION 2: ROLES ────────────────────────────────────────────────────────

  Widget _rolesSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Equipo de la Tienda',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
              ElevatedButton.icon(
                onPressed: () => _showInviteDialog(),
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Invitar Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 13),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final users = widget.controller.selectedStoreUsers;
            if (users.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('Sin usuarios asignados',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                ),
              );
            }
            return Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1),
              },
              children: [
                _tableHeader(),
                ...users.map(_tableRow),
              ],
            );
          }),
        ],
      ),
    );
  }

  TableRow _tableHeader() {
    return TableRow(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      children: ['Usuario', 'Rol', 'Estado', 'Acciones']
          .map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(h,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF))),
              ))
          .toList(),
    );
  }

  TableRow _tableRow(StoreUserModel user) {
    return TableRow(
      children: [
        // Usuario
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _purpleLight,
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(user.initials,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _purple))
                    : null,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E1B4B)),
                        overflow: TextOverflow.ellipsis),
                    Text(user.email,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Rol
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: _roleBadge(user.roleLabel, user.role),
        ),
        // Estado
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: user.isActive
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                user.isActive ? 'Activo' : 'Inactivo',
                style: TextStyle(
                    fontSize: 12,
                    color: user.isActive
                        ? const Color(0xFF10B981)
                        : Colors.grey.shade500),
              ),
            ],
          ),
        ),
        // Acciones
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: user.canBeRemoved
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: Color(0xFF6B7280)),
                  onSelected: (val) => _handleUserAction(val, user),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'change_role',
                        child: Text('Cambiar Rol',
                            style: TextStyle(fontSize: 13))),
                    PopupMenuItem(
                        value: 'remove',
                        child: Text('Eliminar',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade600))),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _roleBadge(String label, String role) {
    Color bg, fg;
    switch (role.toUpperCase()) {
      case 'OWNER':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case 'ADMIN':
      case 'STORE_ADMIN':
        bg = _purpleLight;
        fg = _purple;
        break;
      default:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ─── SECTION 3a: SECURITY ────────────────────────────────────────────────────

  Widget _securitySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seguridad',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1B4B))),
          const SizedBox(height: 20),
          // PIN
          const Text('PIN de la Tienda',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
          const SizedBox(height: 8),
          Row(
            children: [
              Obx(() {
                final pin = widget.controller.selectedStorePinMasked.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    pin.isNotEmpty ? pin : '••••',
                    style: const TextStyle(
                        fontSize: 18,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151)),
                  ),
                );
              }),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: widget.storeId.isEmpty
                    ? null
                    : () => _confirmRegeneratePin(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _purple),
                  foregroundColor: _purple,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('Regenerar PIN'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 2FA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Doble Factor (2FA)',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151))),
                  SizedBox(height: 4),
                  Text('Verificación en dos pasos para accesos',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
              ),
              Switch(
                value: _twoFactor,
                onChanged: (val) {
                  setState(() => _twoFactor = val);
                  if (widget.storeId.isNotEmpty) {
                    widget.controller.toggleStore2FA(
                        widget.storeId, enabled: val);
                  }
                },
                activeThumbColor: _purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SECTION 3b: FISCAL ──────────────────────────────────────────────────────

  Widget _fiscalSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Datos Fiscales',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1B4B))),
          const SizedBox(height: 20),
          _field('CIF / NIF', _cifCtrl, hint: 'Ej. B87654321'),
          const SizedBox(height: 16),
          _field('Dirección de Facturación', _billingAddressCtrl,
              hint: 'Calle, número, ciudad',
              enabled: !_sameAddress),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _sameAddress,
                activeColor: _purple,
                onChanged: (val) {
                  setState(() {
                    _sameAddress = val ?? false;
                    if (_sameAddress) {
                      _billingAddressCtrl.text = _addressCtrl.text;
                    }
                  });
                },
              ),
              const Flexible(
                child: Text(
                  'Usar la misma dirección que la tienda física',
                  style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM BUTTONS ──────────────────────────────────────────────────────────

  Widget _bottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Get.back(),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            foregroundColor: const Color(0xFF374151),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 14),
          ),
          child: const Text('Descartar'),
        ),
        const SizedBox(width: 12),
        Obx(() {
          final saving = widget.controller.isSavingStore.value;
          return ElevatedButton(
            onPressed: saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFDDD6FE),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
              elevation: 0,
            ),
            child: saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Guardar Cambios'),
          );
        }),
      ],
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        _fieldRaw(ctrl, hint: hint, enabled: enabled),
      ],
    );
  }

  Widget _fieldRaw(TextEditingController ctrl,
      {String? hint, bool enabled = true}) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      style: const TextStyle(fontSize: 13, color: Color(0xFF1E1B4B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        filled: !enabled,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _purple)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      ),
    );
  }

  // ─── ACTIONS ─────────────────────────────────────────────────────────────────

  void _save() {
    if (widget.storeId.isEmpty) return;
    final billingAddr = _sameAddress ? _addressCtrl.text : _billingAddressCtrl.text;
    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      if (_cifCtrl.text.trim().isNotEmpty) 'cif': _cifCtrl.text.trim(),
      if (billingAddr.isNotEmpty) 'billing_address': billingAddr.trim(),
      if (_selectedCategoryIds.isNotEmpty) 'categories': _selectedCategoryIds,
    };
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (lat != null) payload['latitude'] = lat;
    if (lng != null) payload['longitude'] = lng;
    widget.controller.saveStoreChanges(widget.storeId, payload);
  }

  Future<void> _pickBanner() async {
    if (widget.storeId.isEmpty) {
      Get.snackbar('Selecciona una tienda',
          'Abre una tienda desde Comercios para subir su banner',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    // El controlador sube, recarga la ficha y refleja el banner.
    await widget.controller.uploadSelectedStoreBanner(widget.storeId, file);
  }

  Future<void> _pickLogo() async {
    if (widget.storeId.isEmpty) {
      Get.snackbar('Selecciona una tienda',
          'Abre una tienda desde Comercios para subir su logo',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await widget.controller.uploadSelectedStoreLogo(widget.storeId, file);
  }

  void _confirmRegeneratePin() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Regenerar PIN',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Se generará un nuevo PIN aleatorio. El PIN actual quedará inválido.\n\nEl nuevo PIN se mostrará una sola vez.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.controller.regenerateSelectedStorePIN(widget.storeId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Regenerar'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    String selectedRole = StoreUserModel.roleAdmin;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Invitar Usuario',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Email',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'usuario@ejemplo.com',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: Color(0xFF9CA3AF)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Rol',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                ),
                items: const [
                  DropdownMenuItem(
                      value: StoreUserModel.roleAdmin,
                      child: Text('Administrador')),
                  DropdownMenuItem(
                      value: StoreUserModel.roleMember,
                      child: Text('Miembro')),
                ],
                onChanged: (v) =>
                    setDialogState(() => selectedRole = v ?? selectedRole),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailCtrl.text.trim();
                if (email.isEmpty || !email.contains('@')) return;
                Navigator.pop(ctx);
                widget.controller.inviteUserToSelectedStore(
                    widget.storeId, email, selectedRole);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Invitar'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUserAction(String action, StoreUserModel user) {
    if (action == 'remove') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Eliminar usuario'),
          content:
              Text('¿Eliminar a ${user.displayName} de la tienda?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.controller.removeUserFromSelectedStore(
                    widget.storeId, user.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
    } else if (action == 'change_role') {
      _showChangeRoleDialog(user);
    }
  }

  void _showChangeRoleDialog(StoreUserModel user) {
    String newRole = user.role;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Cambiar rol de ${user.displayName}',
              style: const TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 15)),
          content: DropdownButtonFormField<String>(
            initialValue: newRole,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
            items: const [
              DropdownMenuItem(
                  value: StoreUserModel.roleAdmin,
                  child: Text('Administrador')),
              DropdownMenuItem(
                  value: StoreUserModel.roleMember,
                  child: Text('Miembro')),
            ],
            onChanged: (v) =>
                setDialogState(() => newRole = v ?? newRole),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.controller.changeUserRoleInStore(
                    widget.storeId, user.id, newRole);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
