import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/admin_controller.dart';

class PremiosView extends StatefulWidget {
  const PremiosView({Key? key}) : super(key: key);

  @override
  State<PremiosView> createState() => _PremiosViewState();
}

class _PremiosViewState extends State<PremiosView> {
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg = Color(0xFFF5F3FF);

  late final AdminController _ctrl;

  // Tab index: 0=Premios, 1=Ventas, 2=Usuarios
  int _tab = 0;

  // Panel state
  bool _showPanel = false;
  ProductModel? _editingProduct;

  // Panel form controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _ptsCtrl = TextEditingController(text: '0');
  final _priceCtrl = TextEditingController(text: '0.00');
  final _imageUrlCtrl = TextEditingController();
  String? _panelCategory;
  bool _isCanjeable = true;
  bool _isSavingPanel = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;

  // Search
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.loadInventoryPage(page: 1);
    });
    _searchCtrl.addListener(() {
      if (_searchCtrl.text != _search) {
        setState(() => _search = _searchCtrl.text);
        if (_searchCtrl.text.isEmpty) {
          _ctrl.loadInventoryPage(page: 1);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _stockCtrl.dispose();
    _ptsCtrl.dispose();
    _priceCtrl.dispose();
    _imageUrlCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openCreatePanel() {
    _editingProduct = null;
    _nameCtrl.clear();
    _descCtrl.clear();
    _stockCtrl.text = '0';
    _ptsCtrl.text = '0';
    _priceCtrl.text = '0.00';
    _imageUrlCtrl.clear();
    _panelCategory = null;
    _isCanjeable = true;
    _selectedImage = null;
    _selectedImageBytes = null;
    setState(() => _showPanel = true);
  }

  void _openEditPanel(ProductModel p) {
    _editingProduct = p;
    _nameCtrl.text = p.name;
    _descCtrl.text = p.description;
    _stockCtrl.text = '${p.quantity}';
    _ptsCtrl.text = '${p.pointsRequired}';
    _priceCtrl.text = p.monetaryPrice.toStringAsFixed(2);
    _imageUrlCtrl.text = p.image;
    _panelCategory = p.category.isNotEmpty ? p.category : null;
    _isCanjeable = p.isRedeemable;
    _selectedImage = null;
    _selectedImageBytes = null;
    setState(() => _showPanel = true);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _selectedImage = file;
      _selectedImageBytes = bytes;
    });
  }

  void _closePanel() => setState(() => _showPanel = false);

  Future<void> _savePanel() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'El nombre del premio es obligatorio.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isSavingPanel = true);
    try {
      // 1. Upload image if the user selected a new one.
      String imageUrl = _imageUrlCtrl.text.trim();
      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);
        final uploaded = await _ctrl.uploadProductImage(_selectedImage!);
        setState(() => _isUploadingImage = false);
        if (uploaded != null) imageUrl = uploaded;
      }

      // 2. Build payload and save.
      final stock = int.tryParse(_stockCtrl.text) ?? 0;
      final pts = int.tryParse(_ptsCtrl.text) ?? 0;
      final price = double.tryParse(_priceCtrl.text) ?? 0.0;

      if (_editingProduct != null) {
        final payload = <String, dynamic>{
          'name': name,
          'description': _descCtrl.text.trim(),
          'stock': stock,
          'points_required': pts,
          'monetary_price': price > 0 ? price : null,
          'is_redeemable': _isCanjeable,
          if (_panelCategory != null) 'category': _panelCategory,
          if (imageUrl.isNotEmpty) 'image_url': imageUrl,
        }..removeWhere((_, v) => v == null);
        await _ctrl.updateProduct(_editingProduct!.id, payload);
      } else {
        final product = ProductModel(
          id: '',
          name: name,
          description: _descCtrl.text.trim(),
          image: imageUrl,
          category: _panelCategory ?? '',
          sku: '',
          quantity: stock,
          originalPrice: price,
          discountPrice: price,
          storeId: _ctrl.storeId.value,
          pointsRequired: pts,
          isRedeemable: _isCanjeable,
          monetaryPrice: price,
        );
        await _ctrl.addProduct(product);
      }
      _closePanel();
      _ctrl.loadInventoryPage(page: 1);
    } finally {
      if (mounted) setState(() => _isSavingPanel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _topHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sidebar(context),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _mainContent(context)),
                            if (_showPanel)
                              _creationPanel(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TOP HEADER ──────────────────────────────────────────────────────────────

  Widget _topHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          const Text('LetDem Tienda',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _purple)),
          const SizedBox(width: 32),
          _headerTab('Premios', 0),
          const SizedBox(width: 24),
          _headerTab('Ventas', 1),
          const SizedBox(width: 24),
          _headerTab('Usuarios', 2),
          const Spacer(),
          const Icon(Icons.notifications_outlined,
              size: 20, color: Color(0xFF6B7280)),
          const SizedBox(width: 16),
          const Icon(Icons.settings_outlined,
              size: 20, color: Color(0xFF6B7280)),
          const SizedBox(width: 16),
          const Icon(Icons.help_outline,
              size: 20, color: Color(0xFF6B7280)),
          const SizedBox(width: 16),
          Obx(() {
            _ctrl.storeId.value;
            return Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _purpleLight,
                  child: const Icon(Icons.person,
                      size: 14, color: _purple),
                ),
                const SizedBox(width: 8),
                Text(_ctrl.currentStore.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _headerTab(String label, int index) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _tab = index);
        if (index == 1 && _ctrl.storeOrders.isEmpty) {
          _ctrl.loadStoreOrders();
        } else if (index == 2 && _ctrl.storeUsers.isEmpty) {
          _ctrl.reloadStoreUsers();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? _purple : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? _purple : const Color(0xFF6B7280))),
      ),
    );
  }

  // ─── SIDEBAR ─────────────────────────────────────────────────────────────────

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
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                }),
              ),
            ]),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _navItem(icon: Icons.home_outlined, label: 'Inicio',
              onTap: () => Get.offNamed(Routes.ADMIN)),
          _navItem(icon: Icons.swap_horiz_rounded, label: 'Canjes',
              onTap: () => Get.offNamed(Routes.REDEMPTION_CODE_HISTORY)),
          _navItem(icon: Icons.card_giftcard_outlined,
              label: 'Canjes y Beneficios', selected: true),
          _navItem(icon: Icons.history_outlined, label: 'Historial',
              onTap: () => Get.offNamed(Routes.REDEMPTION_CODE_HISTORY)),
          _navItem(icon: Icons.bar_chart_outlined, label: 'Estadísticas',
              onTap: () => Get.offNamed(Routes.ANALYTICS)),
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Obx(() {
              _ctrl.storeId.value;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Admin LetDem',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
                Text(_ctrl.currentStore.subtitle.isNotEmpty
                    ? _ctrl.currentStore.subtitle : 'Gestión de Tienda',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]);
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openCreatePanel,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('+ Nuevo Canje',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.logout, size: 18, color: Colors.grey),
            title: const Text('Cerrar Sesión',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 8),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _purpleLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? _purple : Colors.grey.shade500),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? _purple
                      : Colors.grey.shade700,
                )),
          ],
        ),
      ),
    );
  }

  // ─── MAIN CONTENT ─────────────────────────────────────────────────────────────

  Widget _mainContent(BuildContext context) {
    return Container(
      color: _bg,
      child: _tab == 0
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _titleBar(),
              Expanded(child: _tableSection(context)),
            ])
          : _tab == 1
              ? _ventasContent()
              : _usuariosContent(),
    );
  }

  Widget _titleBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gestión de Canjes y beneficios',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827))),
              SizedBox(height: 2),
              Text(
                  'Administra el catálogo de recompensas y puntos de tu tienda.',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 220,
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar premios...',
                hintStyle: TextStyle(
                    fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search,
                    size: 18, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB)),
                ),
              ),
              onSubmitted: (_) => _ctrl.loadInventoryPage(
                  page: 1, search: _search),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TABLE SECTION ────────────────────────────────────────────────────────────

  Widget _tableSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            _tableHeader(),
            Expanded(
              child: Obx(() {
                if (_ctrl.isLoadingInventory.value) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final items = _ctrl.inventoryProducts;
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No se encontraron premios.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) =>
                      _productRow(context, items[i]),
                );
              }),
            ),
            _paginationFooter(),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader() {
    const style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.5);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: const Row(
        children: [
          SizedBox(width: 60, child: Text('IMAGEN', style: style)),
          Expanded(
              flex: 3, child: Text('NOMBRE', style: style)),
          Expanded(
              flex: 2, child: Text('CATEGORÍA', style: style)),
          SizedBox(
              width: 70, child: Text('STOCK', style: style)),
          SizedBox(
              width: 110,
              child:
                  Text('COSTE', style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 100,
              child: Text('ESTADO', style: style)),
          SizedBox(
              width: 80,
              child: Text('ACCIONES', style: style)),
        ],
      ),
    );
  }

  Widget _productRow(BuildContext context, ProductModel p) {
    final pts = p.pointsRequired;
    final status = p.statusLabel;
    final statusColor = _statusColor(status);
    final statusBg = _statusBg(status);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color(0xFFF9FAFB))),
      ),
      child: Row(
        children: [
          // Image
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: p.image.startsWith('http')
                  ? Image.network(p.image,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _imgPlaceholder())
                  : _imgPlaceholder(),
            ),
          ),
          // Name
          Expanded(
            flex: 3,
            child: Text(p.name,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          // Category
          Expanded(
            flex: 2,
            child: p.category.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _catColor(p.category)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(p.category,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _catColor(p.category)),
                        overflow: TextOverflow.ellipsis),
                  )
                : const Text('—',
                    style: TextStyle(color: Colors.grey)),
          ),
          // Stock
          SizedBox(
            width: 70,
            child: Text('${p.quantity}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
          ),
          // Cost pts
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
        color: Color(0xFFF59E0B),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.star,
                      size: 9, color: Colors.white),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_fmtNum(pts)}\nPts',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                      height: 1.2),
                ),
              ],
            ),
          ),
          // Status
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor),
                  textAlign: TextAlign.center),
            ),
          ),
          // Actions
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: Color(0xFF6B7280)),
                  onPressed: () => _openEditPanel(p),
                  tooltip: 'Editar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                      p.isPublished
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 18,
                      color: p.isPublished
                          ? Colors.orange
                          : Colors.green),
                  onPressed: () =>
                      _ctrl.toggleProductPublished(p),
                  tooltip:
                      p.isPublished ? 'Pausar' : 'Activar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Color(0xFFEF4444)),
                  onPressed: () =>
                      _confirmDelete(context, p),
                  tooltip: 'Eliminar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _purpleLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.card_giftcard_outlined,
          size: 22, color: _purple),
    );
  }

  Widget _paginationFooter() {
    return Obx(() {
      final meta = _ctrl.inventoryMeta.value;
      final page = _ctrl.inventoryCurrentPage.value;
      final last = meta.lastPage.clamp(1, 9999);
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            Text(
              'Mostrando ${_ctrl.inventoryProducts.length} de ${meta.total} premios',
              style: const TextStyle(
                  fontSize: 13, color: Colors.grey),
            ),
            const Spacer(),
            _pgBtn(
              icon: Icons.chevron_left,
              enabled: page > 1,
              onTap: () => _ctrl.loadInventoryPage(
                  page: page - 1, search: _search),
            ),
            const SizedBox(width: 4),
            _pgBtn(
              icon: Icons.chevron_right,
              enabled: page < last,
              onTap: () => _ctrl.loadInventoryPage(
                  page: page + 1, search: _search),
            ),
          ],
        ),
      );
    });
  }

  Widget _pgBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled
                ? const Color(0xFF374151)
                : Colors.grey.shade300),
      ),
    );
  }

  // ─── CREATION PANEL ──────────────────────────────────────────────────────────

  Widget _creationPanel(BuildContext context) {
    return Container(
      width: 380,
      color: Colors.white,
      child: Column(
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE)),
                  left: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Text(
                  _editingProduct == null
                      ? 'Crear Nuevo Canje'
                      : 'Editar Canje',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _closePanel,
                  child: const Icon(Icons.close,
                      size: 20, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          // Panel body
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                    left: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _panelLabel('Nombre del Canje'),
                    const SizedBox(height: 6),
                    _panelTextField(
                      _nameCtrl,
                      hint: 'Ej. Tarjeta Regalo 50€',
                    ),
                    const SizedBox(height: 16),
                    _panelLabel('Descripción'),
                    const SizedBox(height: 6),
                    _panelTextField(
                      _descCtrl,
                      hint: 'Cuéntanos las características del canje o beneficio...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    // Image upload area
                    _imageUploadArea(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _panelLabel('Categoría'),
                              const SizedBox(height: 6),
                              Obx(() {
                                final cats = _ctrl.categories
                                    .map((c) => c.title)
                                    .where((t) => t.isNotEmpty)
                                    .toList();
                                return _panelDropdown(
                                  value: _panelCategory,
                                  items: cats,
                                  hint: 'Categoría',
                                  onChanged: (v) => setState(
                                      () => _panelCategory = v),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _panelLabel('Stock Inicial'),
                              const SizedBox(height: 6),
                              _panelTextField(_stockCtrl,
                                  hint: '0',
                                  keyboardType:
                                      TextInputType.number),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Points config section
                    _pointsConfigSection(),
                    const SizedBox(height: 16),
                    // Stripe section
                    _stripeSection(),
                  ],
                ),
              ),
            ),
          ),
          // Panel footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
        color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEEEEEE)),
                left: BorderSide(color: Color(0xFFEEEEEE)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _closePanel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      side: const BorderSide(
                          color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancelar',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isSavingPanel ? null : _savePanel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                    ),
                    child: _isSavingPanel
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : Text(
                            _editingProduct == null
                                ? 'Crear Canje'
                                : 'Guardar',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageUploadArea() {
    // Priority: newly picked local image → existing URL from product
    final hasPickedImage = _selectedImageBytes != null;
    final hasRemoteUrl = _imageUrlCtrl.text.trim().startsWith('http');

    Widget preview;
    if (hasPickedImage) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.memory(
          _selectedImageBytes!,
          width: double.infinity,
          height: 110,
          fit: BoxFit.cover,
        ),
      );
    } else if (hasRemoteUrl) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.network(
          _imageUrlCtrl.text.trim(),
          width: double.infinity,
          height: 110,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _uploadPlaceholder(),
        ),
      );
    } else {
      preview = _uploadPlaceholder();
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: _isUploadingImage ? null : _pickImage,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _purple.withValues(alpha: 0.35),
                width: 1.5,
              ),
              color: _purpleLight.withValues(alpha: 0.3),
            ),
            child: preview,
          ),
        ),
        if (_isUploadingImage)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            ),
          ),
        // Small "change image" badge when there's already an image
        if (hasPickedImage || hasRemoteUrl)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _pickImage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Cambiar',
                        style: TextStyle(
                            fontSize: 11, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _uploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _purpleLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.cloud_upload_outlined,
              size: 22, color: _purple),
        ),
        const SizedBox(height: 8),
        const Text('Subir Imagen del Premio',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const Text('Formatos: PNG, JPG, Max 5MB',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _pointsConfigSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _purpleLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Configuración de Puntos',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _purple)),
              const Spacer(),
              const Text('Compatible',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF374151))),
              const SizedBox(width: 8),
              Switch(
                value: _isCanjeable,
                onChanged: (v) =>
                    setState(() => _isCanjeable = v),
                activeColor: _purple,
                materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Coste en puntos',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _purple)),
          const SizedBox(height: 6),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _purple.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ptsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12),
                  child: const Text('Pts',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _purple)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stripeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF635BFF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text('S',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Precio monetario vía Stripe (Opcional)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
          ],
        ),
        const SizedBox(height: 10),
        _panelLabel('Importe en Euros (€)'),
        const SizedBox(height: 6),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12),
                child: const Text('€',
                    style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280))),
              ),
              Container(
                  width: 1,
                  height: 24,
                  color: const Color(0xFFE5E7EB)),
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType
                      .numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── PANEL HELPERS ────────────────────────────────────────────────────────────

  Widget _panelLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151)));
  }

  Widget _panelTextField(
    TextEditingController ctrl, {
    String hint = '',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 13, color: Color(0xFFD1D5DB)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: _purple, width: 1.5),
        ),
      ),
    );
  }

  Widget _panelDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:
              (value != null && items.contains(value)) ? value : null,
          isExpanded: true,
          hint: Text(hint,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFFD1D5DB))),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e,
                        style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: Colors.grey),
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF374151)),
        ),
      ),
    );
  }

  // ─── DIALOGS ─────────────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, ProductModel p) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar premio'),
        content: Text(
            '¿Eliminar "${p.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _ctrl.deleteProduct(p);
              _ctrl.loadInventoryPage(
                  page: _ctrl.inventoryCurrentPage.value,
                  search: _search);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              Get.offAllNamed(Routes.LOGIN);
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

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

  Color _statusColor(String status) {
    switch (status) {
      case 'Activo':
        return const Color(0xFF166534);
      case 'Pausado':
        return const Color(0xFF374151);
      case 'Sin Stock':
        return const Color(0xFF991B1B);
      default:
        return Colors.grey;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Activo':
        return const Color(0xFFDCFCE7);
      case 'Pausado':
        return const Color(0xFFF3F4F6);
      case 'Sin Stock':
        return const Color(0xFFFEE2E2);
      default:
        return Colors.grey.shade100;
    }
  }

  /// Devuelve el color de la categoría desde el backend (campo `color`).
  /// Fallback: colores semánticos por keyword.
  Color _catColor(String categoryTitle) {
    try {
      final cat = _ctrl.categories.firstWhere(
        (c) => c.title == categoryTitle,
        orElse: () => CategoryModel(id: 0, title: '', image: ''),
      );
      final hex = cat.color.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      }
    } catch (_) {}
    // Fallback semántico
    final lower = categoryTitle.toLowerCase();
    if (lower.contains('deporte') || lower.contains('sport'))  return const Color(0xFF059669);
    if (lower.contains('tecn') || lower.contains('electr'))    return const Color(0xFF2563EB);
    if (lower.contains('audio') || lower.contains('music'))    return const Color(0xFF7C3AED);
    if (lower.contains('moda') || lower.contains('ropa'))      return const Color(0xFF9333EA);
    return _purple;
  }

  // ─── TAB: VENTAS ─────────────────────────────────────────────────────────────

  Widget _ventasContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
          child: Row(
            children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ventas de la Tienda',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                        color: Color(0xFF111827))),
                SizedBox(height: 2),
                Text('Órdenes de compra registradas en tu tienda.',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ]),
              const Spacer(),
              _ventasFilterBtn('Todos', ''),
              const SizedBox(width: 6),
              _ventasFilterBtn('Pagados', 'PAID'),
              const SizedBox(width: 6),
              _ventasFilterBtn('Pendientes', 'PENDING'),
              const SizedBox(width: 6),
              _ventasFilterBtn('Cancelados', 'CANCELLED'),
            ],
          ),
        ),
        // Stats row
        Obx(() {
          final meta = _ctrl.storeOrdersMeta.value;
          final revenue = (meta['total_revenue'] as num?)?.toDouble() ?? 0;
          final pts     = (meta['total_points_used'] as num?)?.toInt() ?? 0;
          final total   = (meta['total'] as num?)?.toInt() ?? 0;
          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
            child: Row(children: [
              _ventasStat('Total Ventas', '$total', Icons.shopping_bag_outlined),
              const SizedBox(width: 12),
              _ventasStat('Ingresos', '${revenue.toStringAsFixed(2)} €',
                  Icons.euro_outlined),
              const SizedBox(width: 12),
              _ventasStat('Puntos usados', '$pts pts', Icons.stars_outlined),
            ]),
          );
        }),
        // Table
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(children: [
                _ventasTableHeader(),
                Expanded(child: Obx(() {
                  if (_ctrl.isLoadingOrders.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final orders = _ctrl.storeOrders;
                  if (orders.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No hay ventas registradas.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (_, i) => _ventasRow(orders[i]),
                  );
                })),
                _ventasPagination(),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ventasFilterBtn(String label, String status) {
    return Obx(() {
      final active = _ctrl.storeOrdersStatusFilter.value == status;
      return GestureDetector(
        onTap: () => _ctrl.loadStoreOrders(status: status.isNotEmpty ? status : null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? _purple : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? _purple : const Color(0xFFE5E7EB))),
          child: Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: active ? Colors.white : Colors.grey.shade700)),
        ),
      );
    });
  }

  Widget _ventasStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Icon(icon, size: 18, color: _purple),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Widget _ventasTableHeader() {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
        color: Color(0xFF9CA3AF), letterSpacing: 0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFFF9FAFB),
      child: const Row(children: [
        SizedBox(width: 120, child: Text('ORDEN ID', style: style)),
        Expanded(flex: 2, child: Text('CLIENTE', style: style)),
        Expanded(flex: 2, child: Text('PRODUCTO', style: style)),
        SizedBox(width: 90, child: Text('IMPORTE', style: style)),
        SizedBox(width: 90, child: Text('PUNTOS', style: style)),
        SizedBox(width: 100, child: Text('ESTADO', style: style)),
        SizedBox(width: 100, child: Text('FECHA', style: style)),
      ]),
    );
  }

  Widget _ventasRow(Map<String, dynamic> order) {
    final id       = (order['id'] ?? '').toString();
    final shortId  = '#${id.length > 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()}';
    final status   = (order['status'] ?? '').toString();
    final total    = (order['total'] as num?)?.toDouble() ?? 0;
    final ptsUsed  = (order['points_used'] as num?)?.toInt() ?? 0;
    final userRaw  = order['user'] ?? order['customer'];
    final userName = userRaw is Map
        ? (userRaw['name'] ?? userRaw['email'] ?? '').toString()
        : (order['customer_name'] ?? '').toString();
    final items    = order['items'] as List? ?? const [];
    final firstItem = items.isNotEmpty && items.first is Map
        ? (items.first as Map)['product_name']?.toString() ?? '—'
        : '—';
    final createdAt = DateTime.tryParse(
        (order['created_at'] ?? '').toString())?.toLocal();

    Color statusBg, statusFg;
    String statusLabel;
    switch (status.toUpperCase()) {
      case 'PAID':
        statusBg = const Color(0xFFD1FAE5); statusFg = const Color(0xFF059669);
        statusLabel = 'Pagado'; break;
      case 'PENDING':
        statusBg = const Color(0xFFFFF7ED); statusFg = const Color(0xFFD97706);
        statusLabel = 'Pendiente'; break;
      case 'CANCELLED':
        statusBg = const Color(0xFFFEE2E2); statusFg = const Color(0xFFDC2626);
        statusLabel = 'Cancelado'; break;
      default:
        statusBg = const Color(0xFFF3F4F6); statusFg = Colors.grey;
        statusLabel = status;
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          SizedBox(width: 120,
              child: Text(shortId, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _purple))),
          Expanded(flex: 2, child: Text(userName,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(firstItem,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              overflow: TextOverflow.ellipsis)),
          SizedBox(width: 90, child: Text(
              '${total.toStringAsFixed(2)} €',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          SizedBox(width: 90, child: Text('$ptsUsed pts',
              style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w600))),
          SizedBox(width: 100, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: statusBg, borderRadius: BorderRadius.circular(20)),
            child: Text(statusLabel, style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: statusFg),
                textAlign: TextAlign.center))),
          SizedBox(width: 100, child: Text(
            createdAt != null ? _fmtDate(createdAt) : '—',
            style: const TextStyle(fontSize: 12, color: Colors.grey))),
        ]),
      ),
      const Divider(height: 1),
    ]);
  }

  Widget _ventasPagination() {
    return Obx(() {
      final meta     = _ctrl.storeOrdersMeta.value;
      final page     = _ctrl.storeOrdersPage.value;
      final lastPage = (meta['last_page'] as num?)?.toInt() ?? 1;
      final statusF  = _ctrl.storeOrdersStatusFilter.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
        color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
        child: Row(children: [
          Text('Página $page de $lastPage',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          _pgBtn(icon: Icons.chevron_left, enabled: page > 1,
              onTap: () => _ctrl.loadStoreOrders(
                  page: page - 1,
                  status: statusF.isNotEmpty ? statusF : null)),
          const SizedBox(width: 4),
          _pgBtn(icon: Icons.chevron_right, enabled: page < lastPage,
              onTap: () => _ctrl.loadStoreOrders(
                  page: page + 1,
                  status: statusF.isNotEmpty ? statusF : null)),
        ]),
      );
    });
  }

  static String _fmtDate(DateTime d) {
    const m = ['', 'Ene','Feb','Mar','Abr','May','Jun',
                'Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }

  // ─── TAB: USUARIOS ───────────────────────────────────────────────────────────

  Widget _usuariosContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
          child: Row(children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Personal de la Tienda',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                      color: Color(0xFF111827))),
              SizedBox(height: 2),
              Text('Usuarios con acceso al panel de administración.',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ]),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(Routes.ADMIN_SETTINGS),
              icon: const Icon(Icons.person_add_outlined,
                  size: 16, color: Colors.white),
              label: const Text('Gestionar Staff',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(children: [
                _usuariosTableHeader(),
                Expanded(child: Obx(() {
                  final users = _ctrl.storeUsers;
                  if (users.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Sin usuarios registrados.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (_, i) => _usuarioRow(users[i]),
                  );
                })),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _usuariosTableHeader() {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
        color: Color(0xFF9CA3AF), letterSpacing: 0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFFF9FAFB),
      child: const Row(children: [
        Expanded(flex: 3, child: Text('USUARIO', style: style)),
        Expanded(flex: 2, child: Text('ROL', style: style)),
        Expanded(child: Text('ESTADO', style: style)),
      ]),
    );
  }

  Widget _usuarioRow(dynamic user) {
    final name    = user.displayName as String? ?? '';
    final email   = user.email as String? ?? '';
    final role    = user.roleLabel as String? ?? '';
    final online  = user.isOnline as bool? ?? false;
    final presence= user.presenceLabel as String? ?? (online ? 'En línea' : 'Desconectado');
    final initials = name.split(' ').where((w) => w.isNotEmpty)
        .take(2).map((w) => w[0].toUpperCase()).join();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Expanded(flex: 3, child: Row(children: [
            CircleAvatar(radius: 18, backgroundColor: _purpleLight,
                child: Text(initials.isEmpty ? '?' : initials,
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700, color: _purple))),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              Text(email, style: const TextStyle(
                  fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis),
            ])),
          ])),
          Expanded(flex: 2, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _purpleLight, borderRadius: BorderRadius.circular(20)),
            child: Text(role, style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: _purple),
                overflow: TextOverflow.ellipsis))),
          Expanded(child: Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(
                    color: online ? Colors.green : Colors.grey,
                    shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(presence, style: const TextStyle(fontSize: 12)),
          ])),
        ]),
      ),
      const Divider(height: 1),
    ]);
  }
}
