import 'dart:async';

import 'package:get/get.dart';

import '../../../../utils/app_config.dart';
import '../../../../utils/dummy_helper.dart';
import '../../../data/models/paginated.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/marketplace_repository.dart';

class ProductsController extends GetxController {
  static const int _pageSize = 20;

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString storeId = ''.obs;
  final RxString storeName = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<PageMeta> meta = const PageMeta().obs;

  Timer? _searchDebounce;
  bool _usingFallback = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      storeId.value = (args['storeId'] ?? '').toString();
      storeName.value = (args['storeName'] ?? '').toString();
    }
    fetchProducts();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  /// Trae la primera página de productos aplicando los filtros actuales.
  Future<void> fetchProducts() async {
    isLoading.value = true;
    errorMessage.value = '';
    _usingFallback = false;
    try {
      final page = await MarketplaceRepository.instance.fetchProductsPage(
        storeId: _storeIdOrNull,
        search: _searchOrNull,
        categoryName: _categoryOrNull,
        page: 1,
        pageSize: _pageSize,
      );
      products.assignAll(page.data);
      meta.value = page.meta;
    } catch (e) {
      errorMessage.value = e.toString();
      // En builds reales no se rellena con dummy: se muestra el error/estado vacío.
      if (AppConfig.useDummyData && products.isEmpty) {
        _usingFallback = true;
        products.assignAll(DummyHelper.products);
        meta.value = PageMeta(
          total: DummyHelper.products.length,
          page: 1,
          lastPage: 1,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Carga la siguiente página y la concatena a la lista actual.
  Future<void> loadMore() async {
    if (_usingFallback) return;
    if (isLoading.value || isLoadingMore.value) return;
    if (!meta.value.hasMore) return;
    isLoadingMore.value = true;
    try {
      final next = meta.value.page + 1;
      final page = await MarketplaceRepository.instance.fetchProductsPage(
        storeId: _storeIdOrNull,
        search: _searchOrNull,
        categoryName: _categoryOrNull,
        page: next,
        pageSize: _pageSize,
      );
      products.addAll(page.data);
      meta.value = page.meta;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoadingMore.value = false;
    }
  }

  String? get _searchOrNull {
    final s = searchQuery.value.trim();
    return s.isEmpty ? null : s;
  }

  String? get _categoryOrNull {
    return selectedCategory.value == 'All' ? null : selectedCategory.value;
  }

  String? get _storeIdOrNull {
    final s = storeId.value.trim();
    return s.isEmpty ? null : s;
  }

  /// Quita el filtro de tienda y recarga.
  void clearStoreFilter() {
    if (storeId.value.isEmpty) return;
    storeId.value = '';
    storeName.value = '';
    fetchProducts();
  }

  List<String> get categories {
    final values = products.map((product) => product.category).toSet().toList();
    values.sort();
    return ['All', ...values];
  }

  /// Filtrado en cliente (defensivo) sobre los resultados ya recibidos.
  List<ProductModel> get filteredProducts {
    return products.where((product) {
      final matchesCategory = selectedCategory.value == 'All' ||
          product.category == selectedCategory.value;
      final term = searchQuery.value.trim().toLowerCase();
      if (term.isEmpty) {
        return matchesCategory;
      }
      final matchesText = product.name.toLowerCase().contains(term) ||
          product.description.toLowerCase().contains(term) ||
          product.sku.toLowerCase().contains(term) ||
          product.category.toLowerCase().contains(term);
      return matchesCategory && matchesText;
    }).toList();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), fetchProducts);
  }

  void clearSearch() {
    searchQuery.value = '';
    fetchProducts();
  }

  void onCategorySelected(String category) {
    selectedCategory.value = category;
    fetchProducts();
  }
}
