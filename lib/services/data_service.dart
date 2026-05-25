import '../models/product.dart';
import '../models/category.dart';
import '../models/unit_model.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/order.dart';
import '../models/incoming_product.dart';
import '../models/manufacture.dart';
import '../models/expense.dart';
import '../models/ingredient.dart';
import '../models/ingredient_history.dart';
import '../models/user.dart';
import '../models/pegawai.dart';
import '../models/app_notification.dart';
import 'api_service.dart';

class DataService {
  // ==================== PRODUCTS ====================
  static Future<List<Product>> getProducts({String? search, int? categoryId}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoryId != null) params['category_id'] = '$categoryId';
    final res = await ApiService.get('products', params: params);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => Product.fromJson(e)).toList();
    }
    return [];
  }

  static Future<ApiResponse> createProduct(Map<String, dynamic> data) =>
      ApiService.post('products', body: data);

  static Future<ApiResponse> updateProduct(int id, Map<String, dynamic> data) =>
      ApiService.put('products/$id', body: data);

  static Future<ApiResponse> deleteProduct(int id) =>
      ApiService.delete('products/$id');

  // ==================== CATEGORIES ====================
  static Future<List<Category>> getCategories({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get('categories', params: params.isNotEmpty ? params : null);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => Category.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getCategoriesPaged({String? search, int page = 1, int perPage = 15}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get('categories', params: params);
    if (res.success && res.data != null) {
      final raw = res.data as Map<String, dynamic>;
      final list = (raw['data'] as List? ?? []).map((e) => Category.fromJson(e)).toList();
      return {'data': list, 'meta': raw['meta'] ?? {}};
    }
    return {'data': <Category>[], 'meta': {}};
  }

  static Future<ApiResponse> createCategory(Map<String, dynamic> data) =>
      ApiService.post('categories', body: data);

  static Future<ApiResponse> updateCategory(int id, Map<String, dynamic> data) =>
      ApiService.put('categories/$id', body: data);

  static Future<ApiResponse> deleteCategory(int id) =>
      ApiService.delete('categories/$id');

  // ==================== UNITS ====================
  static Future<List<UnitModel>> getUnits({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get('units', params: params.isNotEmpty ? params : null);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => UnitModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getUnitsPaged({String? search, int page = 1, int perPage = 15}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get('units', params: params);
    if (res.success && res.data != null) {
      final raw = res.data as Map<String, dynamic>;
      final list = (raw['data'] as List? ?? []).map((e) => UnitModel.fromJson(e)).toList();
      return {'data': list, 'meta': raw['meta'] ?? {}};
    }
    return {'data': <UnitModel>[], 'meta': {}};
  }

  static Future<ApiResponse> createUnit(Map<String, dynamic> data) =>
      ApiService.post('units', body: data);

  static Future<ApiResponse> updateUnit(int id, Map<String, dynamic> data) =>
      ApiService.put('units/$id', body: data);

  static Future<ApiResponse> deleteUnit(int id) =>
      ApiService.delete('units/$id');

  // ==================== CUSTOMERS ====================
  static Future<List<Customer>> getCustomers({String? search, String? type}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (type != null) params['type'] = type;
    final res = await ApiService.get('customers', params: params);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => Customer.fromJson(e)).toList();
    }
    return [];
  }

  /// Paginated version — returns {data, meta}
  static Future<Map<String, dynamic>> getCustomersPaged({String? search, String? type, int page = 1, int perPage = 15}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (type != null) params['type'] = type;
    final res = await ApiService.get('customers', params: params);
    if (res.success && res.data != null) {
      final raw = res.data as Map<String, dynamic>;
      final list = (raw['data'] as List? ?? []).map((e) => Customer.fromJson(e)).toList();
      return {'data': list, 'meta': raw['meta'] ?? {}};
    }
    return {'data': <Customer>[], 'meta': {}};
  }

  static Future<ApiResponse> createCustomer(Map<String, dynamic> data) =>
      ApiService.post('customers', body: data);

  static Future<ApiResponse> updateCustomer(int id, Map<String, dynamic> data) =>
      ApiService.put('customers/$id', body: data);

  static Future<ApiResponse> deleteCustomer(int id) =>
      ApiService.delete('customers/$id');

  // ==================== SUPPLIERS ====================
  static Future<List<Supplier>> getSuppliers({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get('suppliers', params: params);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => Supplier.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getSuppliersPaged({String? search, int page = 1, int perPage = 15}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get('suppliers', params: params);
    if (res.success && res.data != null) {
      final raw = res.data as Map<String, dynamic>;
      final list = (raw['data'] as List? ?? []).map((e) => Supplier.fromJson(e)).toList();
      return {'data': list, 'meta': raw['meta'] ?? {}};
    }
    return {'data': <Supplier>[], 'meta': {}};
  }

  static Future<ApiResponse> createSupplier(Map<String, dynamic> data) =>
      ApiService.post('suppliers', body: data);

  static Future<ApiResponse> updateSupplier(int id, Map<String, dynamic> data) =>
      ApiService.put('suppliers/$id', body: data);

  static Future<ApiResponse> deleteSupplier(int id) =>
      ApiService.delete('suppliers/$id');

  // ==================== ORDERS ====================
  static Future<List<Order>> getOrders({
    String? search,
    String? status,
    String? paymentStatus,
    String? dateFrom,
    String? dateTo,
    int? customerId,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status;
    if (paymentStatus != null) params['payment_status'] = paymentStatus;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (customerId != null) params['customer_id'] = '$customerId';
    params['limit'] = '$limit';
    params['offset'] = '$offset';
    final res = await ApiService.get('orders', params: params);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => Order.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getOrdersPaged({
    String? search, String? status, String? paymentStatus,
    String? dateFrom, String? dateTo, int? customerId,
    int page = 1, int perPage = 15,
  }) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status;
    if (paymentStatus != null) params['payment_status'] = paymentStatus;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (customerId != null) params['customer_id'] = '$customerId';
    final res = await ApiService.get('orders', params: params);
    if (res.success && res.data != null) {
      final raw = res.data as Map<String, dynamic>;
      final list = (raw['data'] as List? ?? []).map((e) => Order.fromJson(e)).toList();
      return {'data': list, 'meta': raw['meta'] ?? {}};
    }
    return {'data': <Order>[], 'meta': {}};
  }

  static Future<Order?> getOrderDetail(int id) async {
    final res = await ApiService.get('orders/$id');
    if (res.success && res.data != null) {
      final d = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      return Order.fromJson(d as Map<String, dynamic>);
    }
    return null;
  }

  static Future<ApiResponse> createOrder(Map<String, dynamic> data) =>
      ApiService.post('orders', body: data);

  static Future<ApiResponse> updateOrder(int id, Map<String, dynamic> data) =>
      ApiService.put('orders/$id', body: data);

  static Future<ApiResponse> deleteOrder(int id) =>
      ApiService.delete('orders/$id');

  static Future<ApiResponse> markOrderAsPaid(int orderId) =>
      ApiService.post('orders/$orderId/mark-as-paid', body: {});

  static Future<ApiResponse> addOrderPayment(int orderId, Map<String, dynamic> data) =>
      ApiService.post('orders/$orderId/payments', body: data);

  // ==================== INCOMING PRODUCTS ====================
  static Future<List<IncomingProduct>> getIncomingProducts({
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    params['limit'] = '$limit';
    params['offset'] = '$offset';
    final res = await ApiService.get('incoming-products', params: params);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => IncomingProduct.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getIncomingProductsPaged({
    String? search, String? paymentStatus, int? supplierId,
    int page = 1, int perPage = 15,
  }) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (paymentStatus != null) params['payment_status'] = paymentStatus;
    if (supplierId != null) params['supplier_id'] = '$supplierId';
    final res = await ApiService.get('incoming-products', params: params);
    if (res.success && res.data != null) {
      final raw = res.data as Map<String, dynamic>;
      final list = (raw['data'] as List? ?? []).map((e) => IncomingProduct.fromJson(e)).toList();
      return {'data': list, 'meta': raw['meta'] ?? {}};
    }
    return {'data': <IncomingProduct>[], 'meta': {}};
  }

  static Future<ApiResponse> createIncomingProduct(Map<String, dynamic> data) =>
      ApiService.post('incoming-products', body: data);

  static Future<IncomingProduct?> getIncomingProductDetail(int id) async {
    final res = await ApiService.get('incoming-products/$id');
    if (res.success && res.data != null) {
      final d = res.data is Map ? res.data['data'] ?? res.data : res.data;
      return IncomingProduct.fromJson(d);
    }
    return null;
  }

  static Future<ApiResponse> updateIncomingProduct(int id, Map<String, dynamic> data) =>
      ApiService.put('incoming-products/$id', body: data);

  static Future<ApiResponse> deleteIncomingProduct(int id) =>
      ApiService.delete('incoming-products/$id');

  static Future<ApiResponse> markIncomingProductAsPaid(int id) =>
      ApiService.post('incoming-products/$id/mark-as-paid', body: {});

  static Future<ApiResponse> addIncomingProductPayment(int id, Map<String, dynamic> data) =>
      ApiService.post('incoming-products/$id/payments', body: data);

  // ==================== MANUFACTURES ====================
  static Future<List<Manufacture>> getManufactures({String? search, String? type}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (type != null) params['type'] = type;
    final res = await ApiService.get('manufactures', params: params);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => Manufacture.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getManufacturesPaged({String? search, String? type, int page = 1, int perPage = 15}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (type != null) params['type'] = type;
    final res = await ApiService.get('manufactures', params: params);
    if (res.success && res.data != null) {
      final raw = res.data as Map<String, dynamic>;
      final list = (raw['data'] as List? ?? []).map((e) => Manufacture.fromJson(e)).toList();
      return {'data': list, 'meta': raw['meta'] ?? {}};
    }
    return {'data': <Manufacture>[], 'meta': {}};
  }

  static Future<Manufacture?> getManufactureDetail(int id) async {
    final res = await ApiService.get('manufactures/$id');
    if (res.success && res.data != null) {
      final d = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      if (d != null) return Manufacture.fromJson(d as Map<String, dynamic>);
    }
    return null;
  }

  static Future<ApiResponse> createManufacture(Map<String, dynamic> data) =>
      ApiService.post('manufactures', body: data);

  static Future<ApiResponse> updateManufacture(int id, Map<String, dynamic> data) =>
      ApiService.put('manufactures/$id', body: data);

  static Future<ApiResponse> deleteManufacture(int id) =>
      ApiService.delete('manufactures/$id');

  // ==================== INGREDIENTS ====================
  static Future<List<Ingredient>> getIngredients({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get('ingredients', params: params);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => Ingredient.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getIngredientsPaged({String? search, int page = 1, int perPage = 15}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get('ingredients', params: params);
    if (res.success && res.data != null) {
      final raw = res.data as Map<String, dynamic>;
      final list = (raw['data'] as List? ?? []).map((e) => Ingredient.fromJson(e)).toList();
      return {'data': list, 'meta': raw['meta'] ?? {}};
    }
    return {'data': <Ingredient>[], 'meta': {}};
  }

  static Future<ApiResponse> createIngredient(Map<String, dynamic> data) =>
      ApiService.post('ingredients', body: data);

  static Future<ApiResponse> updateIngredient(int id, Map<String, dynamic> data) =>
      ApiService.put('ingredients/$id', body: data);

  static Future<ApiResponse> deleteIngredient(int id) =>
      ApiService.delete('ingredients/$id');

  static Future<ApiResponse> tambahStokIngredient(int id, Map<String, dynamic> data) =>
      ApiService.post('ingredients/$id/tambah-stok', body: data);

  static Future<ApiResponse> kurangiStokIngredient(int id, Map<String, dynamic> data) =>
      ApiService.post('ingredients/$id/kurangi-stok', body: data);

  static Future<ApiResponse> penyesuaianStokIngredient(int id, Map<String, dynamic> data) =>
      ApiService.post('ingredients/$id/penyesuaian-stok', body: data);

  // ==================== INGREDIENT HISTORIES ====================
  static Future<List<IngredientHistory>> getIngredientHistories({int? ingredientId}) async {
    final params = <String, String>{};
    if (ingredientId != null) params['ingredient_id'] = '$ingredientId';
    final res = await ApiService.get('ingredient-histories', params: params);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => IngredientHistory.fromJson(e)).toList();
    }
    return [];
  }

  static Future<ApiResponse> createIngredientHistory(Map<String, dynamic> data) =>
      ApiService.post('ingredient-histories', body: data);

  // ==================== EXPENSES ====================
  static Future<List<Expense>> getExpenses({String? month}) async {
    final params = <String, String>{};
    if (month != null) params['month'] = month;
    final res = await ApiService.get('expenses', params: params);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => Expense.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getExpensesPaged({String? search, String? month, String? year, int page = 1, int perPage = 15}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;
    final res = await ApiService.get('expenses', params: params);
    if (res.success && res.data != null) {
      final raw = res.data as Map<String, dynamic>;
      final list = (raw['data'] as List? ?? []).map((e) => Expense.fromJson(e)).toList();
      return {'data': list, 'meta': raw['meta'] ?? {}};
    }
    return {'data': <Expense>[], 'meta': {}};
  }

  static Future<ApiResponse> createExpense(Map<String, dynamic> data) =>
      ApiService.post('expenses', body: data);

  static Future<ApiResponse> updateExpense(int id, Map<String, dynamic> data) =>
      ApiService.put('expenses/$id', body: data);

  static Future<ApiResponse> deleteExpense(int id) =>
      ApiService.delete('expenses/$id');

  // ==================== USERS (Employees) ====================
  static Future<List<User>> getUsers() async {
    final res = await ApiService.get('users');
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => User.fromJson(e)).toList();
    }
    return [];
  }

  static Future<ApiResponse> createUser(Map<String, dynamic> data) =>
      ApiService.post('users', body: data);

  static Future<ApiResponse> updateUser(int id, Map<String, dynamic> data) =>
      ApiService.put('users/$id', body: data);

  static Future<ApiResponse> deleteUser(int id) =>
      ApiService.delete('users/$id');

  // ==================== DASHBOARD ====================
  static Future<Map<String, dynamic>> getDashboardData({int? month, int? year, String? date}) async {
    final params = <String, String>{};
    if (month != null) params['month'] = '$month';
    if (year != null) params['year'] = '$year';
    if (date != null) params['date'] = date;

    final res = await ApiService.get('dashboard', params: params.isNotEmpty ? params : null);
    if (res.success && res.data != null && res.data is Map<String, dynamic>) {
      // res.data = full body, data aktual ada di body['data']
      final d = res.data is Map<String, dynamic> ? (res.data['data'] ?? res.data) : res.data;
      return d is Map<String, dynamic> ? d : {};
    }
    return {};
  }

  // ==================== PEGAWAI ====================
  static Future<List<Pegawai>> getPegawai({String? search, String? status}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status;
    final res = await ApiService.get('pegawai', params: params);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => Pegawai.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getPegawaiPaged({String? search, String? status, int page = 1, int perPage = 15}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status != 'semua') params['status'] = status;
    final res = await ApiService.get('pegawai', params: params);
    if (res.success && res.data != null) {
      final raw = res.data as Map<String, dynamic>;
      final list = (raw['data'] as List? ?? []).map((e) => Pegawai.fromJson(e)).toList();
      return {'data': list, 'meta': raw['meta'] ?? {}};
    }
    return {'data': <Pegawai>[], 'meta': {}};
  }

  static Future<ApiResponse> createPegawai(Map<String, dynamic> data) =>
      ApiService.post('pegawai', body: data);

  static Future<ApiResponse> updatePegawai(int id, Map<String, dynamic> data) =>
      ApiService.put('pegawai/$id', body: data);

  static Future<ApiResponse> deletePegawai(int id) =>
      ApiService.delete('pegawai/$id');

  // ==================== REPORTS (Laporan Laba) ====================
  static Future<Map<String, dynamic>> getReports({int? month, int? year, String type = 'per_tanggal'}) async {
    final params = <String, String>{'type': type};
    if (month != null) params['month'] = '$month';
    if (year != null) params['year'] = '$year';
    final res = await ApiService.get('reports', params: params);
    if (res.success && res.data != null) {
      final d = res.data is Map<String, dynamic> ? (res.data['data'] ?? res.data) : {};
      return d is Map<String, dynamic> ? d : {};
    }
    return {};
  }

  // ==================== NOTIFICATIONS ====================
  static Future<List<AppNotification>> getNotifications({int limit = 30}) async {
    final res = await ApiService.get('notifications', params: {'limit': '$limit'});
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => AppNotification.fromJson(e)).toList();
    }
    return [];
  }

  static Future<int> getUnreadNotificationCount() async {
    final res = await ApiService.get('notifications/unread-count');
    if (res.success && res.data != null) {
      final data = res.data is Map ? (res.data['data'] ?? res.data) : {};
      return (data['unread_count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  static Future<ApiResponse> markNotificationRead(int id) =>
      ApiService.post('notifications/$id/read', body: {});

  static Future<ApiResponse> markAllNotificationsRead() =>
      ApiService.post('notifications/read-all', body: {});

  // ==================== CUSTOMER DETAIL ====================
  static Future<Map<String, dynamic>> getCustomerTransactions(int id, {int? month, int? year, int limit = 20, int offset = 0}) async {
    final params = <String, String>{'limit': '$limit', 'offset': '$offset'};
    if (month != null) params['month'] = '$month';
    if (year != null) params['year'] = '$year';
    final res = await ApiService.get('customers/$id/transactions', params: params);
    if (res.success && res.data != null) {
      final d = res.data is Map<String, dynamic> ? (res.data['data'] ?? res.data) : {};
      return d is Map<String, dynamic> ? d : {};
    }
    return {};
  }

  static Future<List<Map<String, dynamic>>> getCustomerProdukTerbeli(int id, {int? bulan, int? tahun}) async {
    final params = <String, String>{};
    if (bulan != null) params['bulan'] = '$bulan';
    if (tahun != null) params['tahun'] = '$tahun';
    final res = await ApiService.get('customers/$id/produk-terbeli', params: params);
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getCustomerHargaKhusus(int id) async {
    final res = await ApiService.get('customers/$id/harga-khusus');
    if (res.success && res.data != null) {
      final list = res.data is List ? res.data : (res.data['data'] ?? []);
      return (list as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<ApiResponse> setCustomerHargaKhusus(int id, List<Map<String, dynamic>> prices) =>
      ApiService.post('customers/$id/harga-khusus', body: {'prices': prices});

  // Alias untuk konsistensi penamaan (dipakai di AppBar badge)
  static Future<int> getNotificationUnreadCount() => getUnreadNotificationCount();}
}

