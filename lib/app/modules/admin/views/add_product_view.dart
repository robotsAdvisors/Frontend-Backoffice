import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/product_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/admin_controller.dart';

class AddProductView extends StatefulWidget {
  const AddProductView({Key? key}) : super(key: key);

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg = Color(0xFFF8F7FF);

  final AdminController _ctrl = Get.find<AdminController>();

  ProductModel? _editingProduct;

  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pointValueCtrl = TextEditingController(text: '500');
  final _originalPriceCtrl = TextEditingController(text: '10.00');
  final _discountCtrl = TextEditingController(text: '50');
  final _imageUrlCtrl = TextEditingController();

  String? _selectedCategory;
  DateTime? _expirationDate;
  bool _isActive = true;
  bool _isFeatured = false;
  bool _isSaving = false;
  int _stock = 100;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is ProductModel) {
      _editingProduct = args;
      _nameCtrl.text = args.name;
      _descCtrl.text = args.description;
      _imageUrlCtrl.text = args.image;
      _selectedCategory = args.category.isNotEmpty ? args.category : null;
      _originalPriceCtrl.text = args.originalPrice.toStringAsFixed(2);
      _pointValueCtrl.text = args.discountPrice.toStringAsFixed(0);
      _discountCtrl.text = args.discountPercent.toStringAsFixed(0);
      _stock = args.quantity > 0 ? args.quantity : (args.stock > 0 ? args.stock : 100);
      _expirationDate = args.expiryDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _descCtrl.dispose();
    _pointValueCtrl.dispose();
    _originalPriceCtrl.dispose();
    _discountCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  double get _discountPercent => double.tryParse(_discountCtrl.text) ?? 0;

  double get _marketStrength => (_discountPercent / 100).clamp(0.0, 1.0);

  String get _marketLabel {
    if (_discountPercent < 20) return 'Low Value';
    if (_discountPercent < 40) return 'Fair Deal';
    if (_discountPercent < 60) return 'Good Deal';
    if (_discountPercent < 80) return 'Great Deal';
    return 'Amazing Deal';
  }

  Color get _marketColor {
    if (_discountPercent < 20) return Colors.red.shade400;
    if (_discountPercent < 40) return Colors.orange;
    if (_discountPercent < 60) return _purple;
    return Colors.green;
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final originalPrice = double.tryParse(_originalPriceCtrl.text.trim());
    final pointValue = double.tryParse(_pointValueCtrl.text.trim());
    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0;

    if (name.isEmpty || desc.isEmpty || originalPrice == null || pointValue == null) {
      Get.snackbar('Campos obligatorios', 'Completa nombre, descripción, precio y valor en puntos.',
          backgroundColor: Colors.red.shade50, colorText: Colors.red.shade700);
      return;
    }

    setState(() => _isSaving = true);

    // 1) Crear/editar el producto PRIMERO (el endpoint de imagen exige product_id).
    String? productId;
    if (_editingProduct != null) {
      final payload = <String, dynamic>{
        'name': name,
        'description': desc,
        'price': originalPrice,
        'discount': discount,
        'stock': _stock,
        if (_selectedCategory != null && _selectedCategory!.isNotEmpty)
          'category': _selectedCategory,
        // Solo se conserva la imagen actual si NO se eligió una nueva (que se
        // sube aparte con el product_id más abajo).
        if (_selectedImage == null && _imageUrlCtrl.text.trim().isNotEmpty)
          'image_url': _imageUrlCtrl.text.trim(),
        if (_expirationDate != null)
          'expiry_date':
              '${_expirationDate!.year.toString().padLeft(4, '0')}-'
              '${_expirationDate!.month.toString().padLeft(2, '0')}-'
              '${_expirationDate!.day.toString().padLeft(2, '0')}',
      };
      final updated = await _ctrl.updateProduct(_editingProduct!.id, payload);
      productId = updated?.id ?? _editingProduct!.id;
    } else {
      final product = ProductModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        image: '',
        name: name,
        description: desc,
        category: _selectedCategory ?? '',
        sku: '${name.replaceAll(' ', '-').toUpperCase()}-${DateTime.now().millisecondsSinceEpoch % 10000}',
        quantity: _stock,
        originalPrice: originalPrice,
        discountPrice: pointValue,
        discountPercent: discount,
        stock: _stock,
        storeId: _ctrl.storeId.value.isNotEmpty ? _ctrl.storeId.value : 'store_1',
        expiryDate: _expirationDate,
      );
      final created = await _ctrl.addProduct(product);
      productId = created?.id;
    }

    // 2) Con el id ya disponible, subir la imagen (si se eligió una nueva).
    if (_selectedImage != null && productId != null && productId.isNotEmpty) {
      await _ctrl.uploadProductImage(_selectedImage!, productId: productId);
    }

    if (mounted) setState(() => _isSaving = false);
    // Solo salir si se guardó (si falló la creación, productId es null y se
    // queda en el formulario con el error ya mostrado).
    if (productId != null && productId.isNotEmpty) Get.offNamed(Routes.ADMIN);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _topBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: isDesktop ? _desktopBody() : _mobileBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF1E1B4B)),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingProduct != null ? 'Edit Reward Product' : 'Add New Reward Product',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B)),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 11),
                  children: [
                    const TextSpan(text: 'Inventory', style: TextStyle(color: Colors.grey)),
                    const TextSpan(text: ' / ', style: TextStyle(color: Colors.grey)),
                    TextSpan(
                      text: _editingProduct != null ? 'Edit Product' : 'New Product',
                      style: const TextStyle(color: _purple, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    _editingProduct != null ? 'Update Product' : 'Save Product',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _desktopBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _leftColumn()),
        const SizedBox(width: 20),
        SizedBox(width: 300, child: _rightColumn()),
      ],
    );
  }

  Widget _mobileBody() {
    return Column(
      children: [
        _leftColumn(),
        const SizedBox(height: 16),
        _rightColumn(),
      ],
    );
  }

  // ─── LEFT COLUMN ─────────────────────────────────────────────────────────────

  Widget _leftColumn() {
    return Column(
      children: [
        _basicInfoCard(),
        const SizedBox(height: 16),
        _rewardDetailsCard(),
        const SizedBox(height: 16),
        _inventorySettingsCard(),
      ],
    );
  }

  Widget _basicInfoCard() {
    return _card(
      icon: Icons.info_outline,
      title: 'Basic Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Product Name'),
          const SizedBox(height: 6),
          _field(
            controller: _nameCtrl,
            hint: 'e.g. Premium Coffee Redemption Code',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Category'),
                    const SizedBox(height: 6),
                    Obx(() {
                      final cats = _ctrl.categories
                          .map((c) => c.title)
                          .where((t) => t.isNotEmpty)
                          .toList();
                      return DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        hint: const Text('Select category', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        decoration: _inputDecoration(),
                        items: cats.isEmpty
                            ? [const DropdownMenuItem(value: 'Other', child: Text('Other'))]
                            : cats.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Brand / Partner'),
                    const SizedBox(height: 6),
                    _field(controller: _brandCtrl, hint: 'Partner Name'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Description'),
          const SizedBox(height: 6),
          _field(
            controller: _descCtrl,
            hint: 'Describe the reward and how to redeem it...',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _rewardDetailsCard() {
    return _card(
      icon: Icons.card_giftcard_outlined,
      title: 'Reward Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Point Value'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pointValueCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration().copyWith(
                        suffixIcon: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 18),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _purple),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Original Price (\$)'),
                    const SizedBox(height: 6),
                    _field(
                      controller: _originalPriceCtrl,
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Discount Value (%)'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showDiscountPicker(),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _purple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${_discountPercent.toStringAsFixed(0)}% Worth',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('MARKET VALUE STRENGTH',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.8)),
                        const Spacer(),
                        Text(_marketLabel,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _marketColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _marketStrength,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation<Color>(_marketColor),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inventorySettingsCard() {
    return _card(
      icon: Icons.inventory_2_outlined,
      title: 'Inventory & Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Stock Level'),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          _stockButton(Icons.remove, () => setState(() { if (_stock > 0) _stock--; })),
                          Expanded(
                            child: Text(
                              '$_stock',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          _stockButton(Icons.add, () => setState(() => _stock++)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Expiration Date (Optional)'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (picked != null) setState(() => _expirationDate = picked);
                      },
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFDDDDDD)),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _expirationDate != null
                                    ? '${_expirationDate!.month.toString().padLeft(2, '0')}/${_expirationDate!.day.toString().padLeft(2, '0')}/${_expirationDate!.year}'
                                    : 'mm/dd/yyyy',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _expirationDate != null ? const Color(0xFF1E1B4B) : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Store Branches'),
          const SizedBox(height: 6),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _branchChip(_ctrl.currentStore.name),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: _purple, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14, color: _purple),
                        SizedBox(width: 4),
                        Text('Add Branch', style: TextStyle(fontSize: 12, color: _purple, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _stockButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: const Color(0xFF1E1B4B)),
      ),
    );
  }

  Widget _branchChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _purple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          const Icon(Icons.close, size: 12, color: Colors.white),
        ],
      ),
    );
  }

  // ─── RIGHT COLUMN ─────────────────────────────────────────────────────────────

  Widget _rightColumn() {
    return Column(
      children: [
        _mediaCard(),
        const SizedBox(height: 16),
        _visibilityCard(),
        const SizedBox(height: 16),
        _suggestionsCard(),
      ],
    );
  }

  Widget _mediaCard() {
    return _card(
      icon: Icons.image_outlined,
      title: 'Media',
      child: Column(
        children: [
          // Image preview — priority: local picked > remote URL
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: _purpleLight, width: 2),
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFFBF9FF),
              ),
              child: _selectedImageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.memory(
                        _selectedImageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : _imageUrlCtrl.text.trim().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.network(
                            _imageUrlCtrl.text.trim(),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _uploadPlaceholder(),
                          ),
                        )
                      : _uploadPlaceholder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library_outlined,
                      size: 16),
                  label: const Text('Galería',
                      style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _purple,
                    side: const BorderSide(color: _purple),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showImageUrlDialog,
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('URL',
                      style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ...List.generate(2, (i) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  height: 60,
                  decoration: BoxDecoration(
                    color: _purpleLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )),
              Expanded(
                child: GestureDetector(
                  onTap: _showImageUrlDialog,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: _purpleLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: _purple),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _uploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text('Drop image here or click',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        Text('PNG, JPG (Max 5MB)',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
      ],
    );
  }

  Widget _visibilityCard() {
    return _card(
      icon: Icons.visibility_outlined,
      title: 'Visibility',
      child: Column(
        children: [
          _toggleRow(
            label: 'Active Status',
            subtitle: 'Product visible to users',
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const Divider(height: 24),
          _toggleRow(
            label: 'Featured Product',
            subtitle: 'Highlight on homepage',
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _purple,
        ),
      ],
    );
  }

  Widget _suggestionsCard() {
    final pts = int.tryParse(_pointValueCtrl.text) ?? 500;
    final suggested = (pts * 0.9).toInt();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purpleLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, size: 16, color: _purple),
              SizedBox(width: 6),
              Text('Smart Suggestions',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _purple)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Based on similar rewards, a point value of $suggested pts might increase redemption rates by 12%.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _card({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _purple),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B))),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)));
  }

  Widget _field({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged != null ? (v) { onChanged(v); setState(() {}); } : null,
      decoration: _inputDecoration(hint: hint),
      style: const TextStyle(fontSize: 13),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _purple, width: 1.5),
      ),
    );
  }

  void _showDiscountPicker() {
    final ctrl = TextEditingController(text: _discountCtrl.text);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discount Value (%)'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: _inputDecoration(hint: '0-100'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim()) ?? 0;
              setState(() => _discountCtrl.text = v.clamp(0, 100).toStringAsFixed(0));
              Navigator.of(ctx).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _selectedImage = file;
      _selectedImageBytes = bytes;
    });
  }

  void _showImageUrlDialog() {
    final ctrl = TextEditingController(text: _imageUrlCtrl.text);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Image URL'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: _inputDecoration(hint: 'https://example.com/image.jpg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() {
                _imageUrlCtrl.text = ctrl.text.trim();
                _selectedImage = null;
                _selectedImageBytes = null;
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
