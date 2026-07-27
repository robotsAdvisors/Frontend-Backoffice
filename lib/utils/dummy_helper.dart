import '../app/data/models/category_model.dart';
import '../app/data/models/customer_model.dart';
import '../app/data/models/product_model.dart';
import '../app/data/models/store_model.dart';
import '../app/data/models/store_user_model.dart';
import '../app/data/models/campaign_model.dart';
import '../app/data/models/redemption_code_model.dart';
import 'constants.dart';

class DummyHelper {
  const DummyHelper._();


  static List<Map<String, String>> cards = [
    {'icon': Constants.lotus, 'title': '100%', 'subtitle': 'Organic'},
    {'icon': Constants.calendar, 'title': '1 Year', 'subtitle': 'Expiration'},
    {'icon': Constants.favourites, 'title': '4.8 (256)', 'subtitle': 'Reviews'},
    {'icon': Constants.matches, 'title': '80 kcal', 'subtitle': '100 Gram'},
  ];

  static const String _techDesc =
      'Producto tecnológico de última generación, diseñado para ofrecerte la mejor experiencia. Canjea tus puntos y llévalo a casa.';
  static const String _foodDesc =
      'Selección gourmet de primera calidad, elaborada con los mejores ingredientes. Perfecta para los amantes del buen gusto.';
  static const String _fashionDesc =
      'Diseño moderno y materiales premium que combinan estilo y comodidad en cada paso.';
  static const String _expDesc =
      'Una experiencia única e inolvidable, cuidadosamente diseñada para crear recuerdos que duran para siempre.';

  static List<CategoryModel> categories = [
    CategoryModel(id: 1, title: 'Comida', image: Constants.apple),
    CategoryModel(id: 2, title: 'Tecnología', image: Constants.broccoli),
    CategoryModel(id: 3, title: 'Moda', image: Constants.cheese),
    CategoryModel(id: 4, title: 'Experiencias', image: Constants.meat),
  ];

  static List<ProductModel> products = [
    ProductModel(
      id: '1',
      image: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=700&q=80',
      name: 'Smartwatch Pro Gen 5',
      description: _techDesc,
      category: 'Tecnología',
      sku: 'SW-001',
      quantity: 30,
      originalPrice: 3500,
      discountPrice: 3000,
      storeId: 'store_tech',
      storeName: 'TechZone',
      rating: 4.8,
      reviewCount: 142,
    ),
    ProductModel(
      id: '2',
      image: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=700&q=80',
      name: 'Pack Café Gourmet',
      description: _foodDesc,
      category: 'Comida',
      sku: 'CF-001',
      quantity: 80,
      originalPrice: 500,
      discountPrice: 450,
      storeId: 'store_coffee',
      storeName: 'The Coffee Club',
      rating: 4.7,
      reviewCount: 98,
    ),
    ProductModel(
      id: '3',
      image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=700&q=80',
      name: 'Zapatillas UltraBoost',
      description: _fashionDesc,
      category: 'Moda',
      sku: 'ZP-001',
      quantity: 50,
      originalPrice: 2500,
      discountPrice: 2200,
      storeId: 'store_sport',
      storeName: 'SportZone',
      rating: 4.9,
      reviewCount: 215,
    ),
    ProductModel(
      id: '4',
      image: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=700&q=80',
      name: 'Cámara Alpha 4K',
      description: _techDesc,
      category: 'Tecnología',
      sku: 'CM-001',
      quantity: 20,
      originalPrice: 5000,
      discountPrice: 4500,
      storeId: 'store_photo',
      storeName: 'PhotoMaster',
      rating: 4.6,
      reviewCount: 87,
    ),
    ProductModel(
      id: '5',
      image: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=700&q=80',
      name: 'Cena para Dos',
      description: _expDesc,
      category: 'Experiencias',
      sku: 'CE-001',
      quantity: 40,
      originalPrice: 900,
      discountPrice: 800,
      storeId: 'store_bistro',
      storeName: 'Skyline Bistro',
      rating: 4.9,
      reviewCount: 63,
    ),
    ProductModel(
      id: '6',
      image: 'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=700&q=80',
      name: 'Laptop UltraSlim Pro',
      description: _techDesc,
      category: 'Tecnología',
      sku: 'LP-001',
      quantity: 15,
      originalPrice: 8000,
      discountPrice: 7500,
      storeId: 'store_tech',
      storeName: 'TechZone',
      rating: 4.7,
      reviewCount: 56,
    ),
    ProductModel(
      id: '7',
      image: 'https://images.unsplash.com/photo-1551963831-b3b1ca40c98e?w=700&q=80',
      name: 'Desayuno Gourmet',
      description: _foodDesc,
      category: 'Comida',
      sku: 'DG-001',
      quantity: 60,
      originalPrice: 350,
      discountPrice: 300,
      storeId: 'store_coffee',
      storeName: 'The Coffee Club',
      rating: 4.5,
      reviewCount: 112,
    ),
    ProductModel(
      id: '8',
      image: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=700&q=80',
      name: 'Chaqueta Premium',
      description: _fashionDesc,
      category: 'Moda',
      sku: 'CJ-001',
      quantity: 35,
      originalPrice: 1800,
      discountPrice: 1500,
      storeId: 'store_sport',
      storeName: 'SportZone',
      rating: 4.4,
      reviewCount: 74,
    ),
  ];

  static const String currentAdminEmail = 'admin1@tiendacentral.com';

  static String? storeIdForAdminEmail(String email) {
    final user = storeUsers.firstWhere(
      (item) => item.email == email,
      orElse: () => StoreUserModel(
        id: '',
        email: '',
        role: '',
        storeId: '',
        createdAt: DateTime.now(),
      ),
    );
    return user.id.isNotEmpty ? user.storeId : null;
  }

  static List<StoreModel> stores = [
    StoreModel(
      id: 'store_1',
      name: 'Luxe Vintage',
      description: 'Tienda de ropa vintage de lujo y accesorios exclusivos',
      ownerId: 'owner_1',
      ownerEmail: 'sarah.jenkins@example.com',
      adminUserIds: ['admin_1', 'admin_2'],
      fiscalId: 'FISCAL-1001',
      address: 'Av. Reforma 100, CDMX',
      logoUrl: Constants.logo,
      billingEmail: 'billing@luxevintage.com',
      billingPhone: '+52 55 1234 5678',
      pin: '1234',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      isPublished: true,
    ),
    StoreModel(
      id: 'store_2',
      name: 'BioTech Gear',
      description: 'Tecnología biotecnológica y gadgets de salud avanzados',
      ownerId: 'owner_2',
      ownerEmail: 'marcus.thorne@example.com',
      adminUserIds: ['admin_3'],
      fiscalId: 'FISCAL-1002',
      address: 'Paseo de la Reforma 200, CDMX',
      logoUrl: Constants.logo,
      billingEmail: 'billing@biotechgear.com',
      billingPhone: '+52 55 2345 6789',
      pin: '2345',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      isPublished: true,
    ),
    StoreModel(
      id: 'store_3',
      name: 'Urban Sneaker',
      description: 'Zapatillas urbanas y calzado deportivo de edición limitada',
      ownerId: 'owner_3',
      ownerEmail: 'lila.chen@example.com',
      adminUserIds: [],
      fiscalId: 'FISCAL-1003',
      address: 'Insurgentes Sur 300, CDMX',
      logoUrl: Constants.logo,
      billingEmail: 'billing@urbansneaker.com',
      billingPhone: '+52 55 3456 7890',
      pin: '3456',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isPublished: false,
    ),
    StoreModel(
      id: 'store_4',
      name: 'Healthy Foods',
      description: 'Alimentos saludables, orgánicos y superfoods premium',
      ownerId: 'owner_4',
      ownerEmail: 'david.miller@example.com',
      adminUserIds: ['admin_4', 'admin_5'],
      fiscalId: 'FISCAL-1004',
      address: 'Polanco 400, CDMX',
      logoUrl: Constants.logo,
      billingEmail: 'billing@healthyfoods.com',
      billingPhone: '+52 55 4567 8901',
      pin: '4567',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      isPublished: true,
    ),
  ];

  static List<StoreUserModel> storeUsers = [
    StoreUserModel(
      id: 'admin_letdem',
      email: 'admin@letdem.com',
      role: 'store_admin',
      storeId: 'store_1',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    StoreUserModel(
      id: 'admin_1',
      email: 'manager@luxevintage.com',
      role: 'store_admin',
      storeId: 'store_1',
      createdAt: DateTime.now().subtract(const Duration(days: 85)),
    ),
    StoreUserModel(
      id: 'admin_2',
      email: 'ops@luxevintage.com',
      role: 'store_viewer',
      storeId: 'store_1',
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
    ),
    StoreUserModel(
      id: 'admin_3',
      email: 'manager@biotechgear.com',
      role: 'store_admin',
      storeId: 'store_2',
      createdAt: DateTime.now().subtract(const Duration(days: 55)),
    ),
    StoreUserModel(
      id: 'admin_4',
      email: 'manager@healthyfoods.com',
      role: 'store_admin',
      storeId: 'store_4',
      createdAt: DateTime.now().subtract(const Duration(days: 115)),
    ),
    StoreUserModel(
      id: 'admin_5',
      email: 'ops@healthyfoods.com',
      role: 'store_viewer',
      storeId: 'store_4',
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
    ),
  ];

  static List<CustomerModel> customers = [
    CustomerModel(
      id: 'customer_1',
      storeId: 'store_1',
      name: 'Carlos Perez',
      email: 'carlos.perez@example.com',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    CustomerModel(
      id: 'customer_2',
      storeId: 'store_1',
      name: 'Lucia Fernandez',
      email: 'lucia.fernandez@example.com',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    CustomerModel(
      id: 'customer_3',
      storeId: 'store_1',
      name: 'Miguel Ramirez',
      email: 'miguel.ramirez@example.com',
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
    ),
    CustomerModel(
      id: 'customer_4',
      storeId: 'store_2',
      name: 'Ana Gomez',
      email: 'ana.gomez@example.com',
      createdAt: DateTime.now().subtract(const Duration(days: 70)),
    ),
    CustomerModel(
      id: 'customer_5',
      storeId: 'store_2',
      name: 'Pedro Sanchez',
      email: 'pedro.sanchez@example.com',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    CustomerModel(
      id: 'customer_demo',
      storeId: 'store_1',
      name: 'Cliente Demo',
      email: 'cliente@marketplace.com',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  static List<CampaignModel> redemptionCodeCampaigns = [
    CampaignModel(
      id: 'campaign_1',
      storeId: 'store_1',
      name: 'Campana bienvenida tienda 1',
      startDate: DateTime.now().subtract(const Duration(days: 120)),
      endDate: DateTime.now().add(const Duration(days: 120)),
      discountPercent: 20,
    ),
    CampaignModel(
      id: 'campaign_2',
      storeId: 'store_2',
      name: 'Campana bienvenida tienda 2',
      startDate: DateTime.now().subtract(const Duration(days: 120)),
      endDate: DateTime.now().add(const Duration(days: 120)),
      discountPercent: 15,
    ),
  ];

  static String customerNameById(String id) {
    final customer = customers.firstWhere(
      (item) => item.id == id,
      orElse: () => CustomerModel(
        id: '',
        storeId: '',
        name: 'Cliente desconocido',
        email: '',
        createdAt: DateTime.now(),
      ),
    );
    return customer.name;
  }

  static String customerEmailById(String id) {
    final customer = customers.firstWhere(
      (item) => item.id == id,
      orElse: () => CustomerModel(
        id: '',
        storeId: '',
        name: '',
        email: 'sin-email@example.com',
        createdAt: DateTime.now(),
      ),
    );
    return customer.email;
  }

  static String? customerIdForEmail(String email) {
    final customer = customers.firstWhere(
      (item) => item.email == email,
      orElse: () => CustomerModel(
        id: '',
        storeId: '',
        name: '',
        email: '',
        createdAt: DateTime.now(),
      ),
    );
    return customer.id.isEmpty ? null : customer.id;
  }

  static String productNameById(String productId) {
    final product = products.firstWhere(
      (item) => item.id == productId,
      orElse: () => ProductModel(
        id: '',
        image: '',
        name: 'Producto desconocido',
        description: '',
        category: '',
        sku: '',
        quantity: 0,
        originalPrice: 0,
        discountPrice: 0,
        storeId: '',
      ),
    );
    return product.name;
  }

  static List<RedemptionCodeModel> redemptionCodes = [
    RedemptionCodeModel(
      id: 'redemption_code_1',
      campaignId: 'campaign_1',
      storeId: 'store_1',
      customerUserId: 'customer_1',
      productId: '1',
      code: 'VCH-1001',
      issuedAt: DateTime.now().subtract(const Duration(days: 40)),
      redeemedAt: DateTime.now().subtract(const Duration(days: 38, hours: 4)),
      expiresAt: DateTime.now().subtract(const Duration(days: 30)),
      discountPercent: 20,
      status: RedemptionCodeStatus.redeemed,
    ),
    RedemptionCodeModel(
      id: 'redemption_code_2',
      campaignId: 'campaign_1',
      storeId: 'store_1',
      customerUserId: 'customer_2',
      productId: '2',
      code: 'VCH-1002',
      issuedAt: DateTime.now().subtract(const Duration(days: 15)),
      redeemedAt: null,
      expiresAt: DateTime.now().add(const Duration(days: 7, hours: 12)),
      discountPercent: 15,
      status: RedemptionCodeStatus.pending,
    ),
    RedemptionCodeModel(
      id: 'redemption_code_3',
      campaignId: 'campaign_1',
      storeId: 'store_1',
      customerUserId: 'customer_3',
      productId: '3',
      code: 'VCH-1003',
      issuedAt: DateTime.now().subtract(const Duration(days: 95)),
      redeemedAt: null,
      expiresAt: DateTime.now().subtract(const Duration(days: 5)),
      discountPercent: 10,
      status: RedemptionCodeStatus.expired,
    ),
    RedemptionCodeModel(
      id: 'redemption_code_4',
      campaignId: 'campaign_2',
      storeId: 'store_2',
      customerUserId: 'customer_4',
      productId: '4',
      code: 'VCH-2001',
      issuedAt: DateTime.now().subtract(const Duration(days: 20)),
      redeemedAt: DateTime.now().subtract(const Duration(days: 19, hours: 5)),
      expiresAt: DateTime.now().subtract(const Duration(days: 10)),
      discountPercent: 25,
      status: RedemptionCodeStatus.redeemed,
    ),
    RedemptionCodeModel(
      id: 'redemption_code_5',
      campaignId: 'campaign_2',
      storeId: 'store_2',
      customerUserId: 'customer_5',
      productId: '5',
      code: 'VCH-2002',
      issuedAt: DateTime.now().subtract(const Duration(days: 5)),
      redeemedAt: null,
      expiresAt: DateTime.now().add(const Duration(days: 3, hours: 2)),
      discountPercent: 12,
      status: RedemptionCodeStatus.pending,
    ),
    RedemptionCodeModel(
      id: 'redemption_code_6',
      campaignId: 'campaign_1',
      storeId: 'store_1',
      customerUserId: 'customer_demo',
      productId: '6',
      code: 'WLT-9001',
      issuedAt: DateTime.now().subtract(const Duration(days: 2)),
      redeemedAt: null,
      expiresAt: DateTime.now().add(const Duration(days: 5)),
      discountPercent: 18,
      status: RedemptionCodeStatus.pending,
    ),
    RedemptionCodeModel(
      id: 'redemption_code_7',
      campaignId: 'campaign_1',
      storeId: 'store_1',
      customerUserId: 'customer_demo',
      productId: '9',
      code: 'WLT-9002',
      issuedAt: DateTime.now().subtract(const Duration(days: 9)),
      redeemedAt: DateTime.now().subtract(const Duration(days: 8, hours: 1)),
      expiresAt: DateTime.now().subtract(const Duration(days: 7)),
      discountPercent: 22,
      status: RedemptionCodeStatus.redeemed,
    ),
  ];

}