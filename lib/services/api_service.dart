import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // API backend sudah siap - gunakan data real dari Laravel
  static const bool useMockData = false;

  static const String baseUrl = 'https://stokku.id/api/';
  static String? _token;

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  static Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // GET request
  static Future<ApiResponse> get(String endpoint, {Map<String, String>? params}) async {
    if (useMockData) return _getMockResponse(endpoint, 'GET');
    try {
      await getToken(); // pastikan token sudah dimuat dari SharedPreferences
      var uri = Uri.parse('$baseUrl/$endpoint');
      if (params != null) uri = uri.replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 12));
      return _handleResponse(response);
    } catch (e) { return ApiResponse(success: false, message: 'Koneksi gagal: $e'); }
  }

  // POST request
  static Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body}) async {
    if (useMockData) return _getMockResponse(endpoint, 'POST', body: body);
    try {
      await getToken();
      final uri = Uri.parse('$baseUrl/$endpoint');
      final response = await http.post(uri, headers: _headers(), body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 12));
      return _handleResponse(response);
    } catch (e) { return ApiResponse(success: false, message: 'Koneksi gagal: $e'); }
  }

  // PUT request
  static Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    if (useMockData) return _getMockResponse(endpoint, 'PUT', body: body);
    try {
      await getToken(); // pastikan token sudah dimuat
      final uri = Uri.parse('$baseUrl/$endpoint');
      final response = await http.put(uri, headers: _headers(), body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) { return ApiResponse(success: false, message: 'Koneksi gagal: $e'); }
  }

  // DELETE request
  static Future<ApiResponse> delete(String endpoint) async {
    if (useMockData) return _getMockResponse(endpoint, 'DELETE');
    try {
      await getToken(); // pastikan token sudah dimuat
      final uri = Uri.parse('$baseUrl/$endpoint');
      final response = await http.delete(uri, headers: _headers()).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) { return ApiResponse(success: false, message: 'Koneksi gagal: $e'); }
  }

  static ApiResponse _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Simpan seluruh body — DataService akan ekstrak 'data'/'meta' sesuai kebutuhan
        return ApiResponse(success: true, data: body, message: body is Map ? body['message'] ?? 'Success' : 'Success');
      } else if (response.statusCode == 401) {
        clearToken();
        return ApiResponse(success: false, message: 'Sesi habis, silakan login kembali', statusCode: 401);
      } else {
        return ApiResponse(success: false, message: body is Map ? body['message'] ?? 'Terjadi kesalahan (${response.statusCode})' : 'Terjadi kesalahan (${response.statusCode})');
      }
    } catch (e) { return ApiResponse(success: false, message: 'Gagal memproses respons server'); }
  }

  // ==========================================
  // DUMMY DATA UNTUK TESTING TANPA BACKEND
  // ==========================================
  static Future<ApiResponse> _getMockResponse(String endpoint, String method, {Map<String, dynamic>? body}) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulasi loading

    if (method == 'POST' || method == 'PUT' || method == 'DELETE') {
      if (endpoint == 'login') {
        bool isAdmin = body?['email'] == 'admin@stokku.id';
        return ApiResponse(success: true, message: 'Login Mock Berhasil', data: <String, dynamic>{
          'token': 'mock_token_123',
          'user': <String, dynamic>{'id': 1, 'role_id': isAdmin ? 1 : 2, 'name': isAdmin ? 'Admin Dummy' : 'Kasir Dummy', 'email': body?['email'] ?? 'dummy@stokku.id', 'role_display_name': isAdmin ? 'Admin' : 'Kasir'}
        });
      }
      return ApiResponse(success: true, message: 'Aksi berhasil (Mode Dummy)', data: body);
    }

    dynamic mockData;
    if (endpoint == 'products') {
      mockData = [
        {'id': 1, 'name': 'Jelly Powder Melon', 'stock': 120, 'base_price': 10000, 'unit_price': 15000, 'grosir_price': 14000, 'reseller_price': 13000, 'category_id': 1, 'category_name': 'Jelly Powder', 'status': 'active', 'is_manufacture': false, 'unit_id': 1, 'unit_name': 'Pcs'},
        {'id': 2, 'name': 'Sari Kelapa Original', 'stock': 5, 'base_price': 5000, 'unit_price': 8000, 'grosir_price': 7500, 'reseller_price': 7000, 'category_id': 2, 'category_name': 'Sari Kelapa', 'status': 'active', 'is_manufacture': true, 'unit_id': 9, 'unit_name': 'Bak'},
        {'id': 3, 'name': 'Mutiara Zebra', 'stock': 8, 'base_price': 12000, 'unit_price': 16000, 'grosir_price': 15000, 'reseller_price': 14500, 'category_id': 1, 'category_name': 'Jelly Powder', 'status': 'active', 'is_manufacture': false, 'unit_id': 1, 'unit_name': 'Pcs'},
        {'id': 4, 'name': 'Cincau Hitam', 'stock': 3, 'base_price': 8000, 'unit_price': 12000, 'grosir_price': 11000, 'reseller_price': 10500, 'category_id': 3, 'category_name': 'Cincau', 'status': 'active', 'is_manufacture': true, 'unit_id': 9, 'unit_name': 'Bak'},
        {'id': 5, 'name': 'Cup 12oz', 'stock': 500, 'base_price': 800, 'unit_price': 1200, 'grosir_price': 1100, 'reseller_price': 1050, 'category_id': 4, 'category_name': 'Kemasan', 'status': 'active', 'is_manufacture': false, 'unit_id': 5, 'unit_name': 'Cup'},
      ];
    } else if (endpoint == 'customers') {
      mockData = [
        {'id': 1, 'name': 'Bapak Budi Santoso', 'type': 'customer', 'phone': '08123456789', 'address': 'Jl. Merdeka No. 1, Bekasi'},
        {'id': 2, 'name': 'Toko Sumber Rejeki', 'type': 'pasar', 'phone': '08987654321', 'address': 'Pasar Induk Kramat Jati'},
        {'id': 3, 'name': 'Akun Shopee Safira', 'type': 'shopee', 'phone': '-', 'address': 'Online - Shopee'},
        {'id': 4, 'name': 'Ibu Sari Minuet', 'type': 'reseller', 'phone': '081299887766', 'address': 'Jl. Anggrek 5, Depok'},
      ];
    } else if (endpoint == 'suppliers') {
      mockData = [
        {'id': 1, 'name': 'PT Sumber Bahan Prima', 'phone': '021-98765432', 'address': 'Jakarta Barat'},
        {'id': 2, 'name': 'Toko Plastik Maju Jaya', 'phone': '08512345678', 'address': 'Jakarta Pusat'},
        {'id': 3, 'name': 'CV Bahan Industri', 'phone': '08765432100', 'address': 'Tangerang'},
      ];
    } else if (endpoint == 'orders') {
      mockData = [
        {'id': 1, 'order_number': 'ORD-20260423-001', 'total_price': 150000, 'shipping_cost': 0, 'status': 'completed', 'payment_status': 'paid', 'order_date': '2026-04-23', 'customer_name': 'Bapak Budi Santoso', 'customer_id': 1, 'user_id': 1},
        {'id': 2, 'order_number': 'ORD-20260423-002', 'total_price': 350000, 'shipping_cost': 15000, 'status': 'processing', 'payment_status': 'unpaid', 'order_date': '2026-04-23', 'customer_name': 'Toko Sumber Rejeki', 'customer_id': 2, 'user_id': 2},
        {'id': 3, 'order_number': 'ORD-20260422-003', 'total_price': 75000, 'shipping_cost': 0, 'status': 'completed', 'payment_status': 'partial', 'order_date': '2026-04-22', 'customer_name': 'Akun Shopee Safira', 'customer_id': 3, 'user_id': 2},
        {'id': 4, 'order_number': 'ORD-20260422-004', 'total_price': 520000, 'shipping_cost': 25000, 'status': 'completed', 'payment_status': 'paid', 'order_date': '2026-04-22', 'customer_name': 'Ibu Sari Minuet', 'customer_id': 4, 'user_id': 1},
        {'id': 5, 'order_number': 'ORD-20260421-005', 'total_price': 180000, 'shipping_cost': 10000, 'status': 'completed', 'payment_status': 'paid', 'order_date': '2026-04-21', 'customer_name': 'Bapak Budi Santoso', 'customer_id': 1, 'user_id': 2},
      ];
    } else if (endpoint == 'incoming-products') {
      mockData = [
        {'id': 1, 'order_number': 'PO/20260420/0001', 'supplier_id': 1, 'total_price': 1500000, 'status': 'pending', 'payment_status': 'paid', 'payment_date': '2026-04-21', 'incoming_date': '2026-04-20', 'supplier_name': 'PT Sumber Bahan Prima', 'user_id': 1},
        {'id': 2, 'order_number': 'PO/20260421/0001', 'supplier_id': 2, 'total_price': 450000, 'status': 'pending', 'payment_status': 'unpaid', 'incoming_date': '2026-04-21', 'due_date': '2026-05-21', 'supplier_name': 'Toko Plastik Maju Jaya', 'user_id': 1},
        {'id': 3, 'order_number': 'PO/20260422/0001', 'supplier_id': 3, 'total_price': 2300000, 'status': 'pending', 'payment_status': 'partial', 'incoming_date': '2026-04-22', 'supplier_name': 'CV Bahan Industri', 'user_id': 1},
      ];
    } else if (endpoint == 'manufactures') {
      mockData = [
        {
          'id': 1, 'code': 'PROD/20260423/0001', 'type': 'manufacture', 'manufacture_date': '2026-04-23',
          'total_price': 937150, 'user_id': 1, 'user': {'name': 'Admin Dummy'},
          'products': '[{"product_id":"2","quantity":30,"unit_id":"9","cost_per_item":15000,"total_cost":450000},{"product_id":"3","quantity":20,"unit_id":"9","cost_per_item":15000,"total_cost":300000},{"product_id":"4","quantity":8,"unit_id":"9","cost_per_item":15000,"total_cost":120000}]'
        },
        {
          'id': 2, 'code': 'PROD/20260422/0001', 'type': 'manufacture', 'manufacture_date': '2026-04-22',
          'total_price': 75600, 'user_id': 2, 'user': {'name': 'Kasir Dummy'},
          'products': '[{"product_id":"5","quantity":63,"unit_id":"5","cost_per_item":1200,"total_cost":75600}]'
        },
      ];
    } else if (endpoint == 'expenses') {
      mockData = [
        {'id': 1, 'description': 'Bensin Grand Max', 'qty': 1, 'price': 350000, 'total_price': 350000, 'date': '2026-04-22', 'user_id': 1, 'user': {'name': 'Admin Dummy'}},
        {'id': 2, 'description': 'Beli Cup 12oz', 'qty': 20, 'price': 8500, 'total_price': 170000, 'date': '2026-04-21', 'user_id': 1, 'user': {'name': 'Admin Dummy'}},
        {'id': 3, 'description': 'Ongkos Kirim', 'qty': 1, 'price': 100000, 'total_price': 100000, 'date': '2026-04-20', 'user_id': 2, 'user': {'name': 'Kasir Dummy'}},
      ];
    } else if (endpoint == 'users') {
      mockData = [
        {'id': 1, 'role_id': 1, 'name': 'Admin Dummy', 'email': 'admin@stokku.id', 'role_display_name': 'Admin'},
        {'id': 2, 'role_id': 2, 'name': 'Kasir Dummy', 'email': 'kasir@stokku.id', 'role_display_name': 'Kasir'},
      ];
    } else if (endpoint == 'categories') {
      mockData = [
        {'id': 1, 'name': 'Jelly Powder', 'status': 'active'},
        {'id': 2, 'name': 'Sari Kelapa', 'status': 'active'},
        {'id': 3, 'name': 'Cincau', 'status': 'active'},
        {'id': 4, 'name': 'Kemasan', 'status': 'active'},
        {'id': 16, 'name': 'Operasional', 'status': 'active'},
        {'id': 17, 'name': 'Jasa', 'status': 'active'},
      ];
    } else if (endpoint == 'units') {
      mockData = [
        {'id': 1, 'name': 'Pcs'},
        {'id': 3, 'name': 'Gram'},
        {'id': 4, 'name': 'Kg'},
        {'id': 5, 'name': 'Cup'},
        {'id': 9, 'name': 'Bak'},
        {'id': 12, 'name': 'Hari'},
        {'id': 13, 'name': 'Pickup'},
        {'id': 14, 'name': 'Drum'},
      ];
    } else if (endpoint == 'ingredients') {
      mockData = [
        {'id': 1, 'name': 'Kayu Bakar', 'type': 'barang', 'category_id': 16, 'category_name': 'Operasional', 'unit_id': 13, 'unit_name': 'Pickup', 'price': 75000.0, 'stock': 2.0, 'created_at': '2025-08-05T08:15:45Z'},
        {'id': 3, 'name': 'Ongkos Kerja', 'type': 'jasa', 'category_id': 17, 'category_name': 'Jasa', 'unit_id': 12, 'unit_name': 'Hari', 'price': 120000.0, 'stock': 38.0, 'created_at': '2025-08-05T08:17:29Z'},
        {'id': 4, 'name': 'Potassium Citrate', 'type': 'barang', 'category_id': 1, 'category_name': 'Jelly Powder', 'unit_id': 1, 'unit_name': 'Pcs', 'price': 2090.0, 'stock': 7.0, 'created_at': '2025-08-05T08:18:15Z'},
        {'id': 6, 'name': 'Cup Gelas', 'type': 'barang', 'category_id': 4, 'category_name': 'Kemasan', 'unit_id': 1, 'unit_name': 'Pcs', 'price': 180.0, 'stock': 3759.0, 'created_at': '2025-08-05T08:45:03Z'},
        {'id': 7, 'name': 'Cup Sealer', 'type': 'barang', 'category_id': 4, 'category_name': 'Kemasan', 'unit_id': 1, 'unit_name': 'Pcs', 'price': 100.0, 'stock': 6485.0, 'created_at': '2025-08-05T08:45:40Z'},
        {'id': 10, 'name': 'Tepung Jelly', 'type': 'barang', 'category_id': 1, 'category_name': 'Jelly Powder', 'unit_id': 1, 'unit_name': 'Pcs', 'price': 12800.0, 'stock': 211.0, 'created_at': '2025-08-05T09:07:46Z'},
      ];
    } else if (endpoint == 'ingredient-histories') {
      mockData = [
        {'id': 1, 'ingredient_id': 10, 'user_id': 1, 'user_name': 'Admin Dummy', 'role': 'Administrator', 'tipe': 'masuk', 'qty': 250.0, 'stok_sebelum': 46.0, 'stok_sesudah': 296.0, 'referensi_tipe': 'manual', 'catatan': 'Tambah stok manual', 'created_at': '2026-04-18T02:59:40Z'},
        {'id': 2, 'ingredient_id': 10, 'user_id': 2, 'user_name': 'Kasir Dummy', 'role': 'Cashier', 'tipe': 'keluar', 'qty': 85.0, 'stok_sebelum': 296.0, 'stok_sesudah': 211.0, 'referensi_tipe': 'manufaktur', 'referensi_id': 1, 'catatan': 'Pemakaian bahan baku untuk manufaktur PROD/20260423/0001', 'created_at': '2026-04-23T05:55:44Z'},
        {'id': 3, 'ingredient_id': 6, 'user_id': 1, 'user_name': 'Admin Dummy', 'role': 'Administrator', 'tipe': 'penyesuaian', 'qty': 100.0, 'stok_sebelum': 4188.0, 'stok_sesudah': 3759.0, 'referensi_tipe': 'koreksi', 'catatan': 'Koreksi stok cup gelas', 'created_at': '2026-04-22T10:00:00Z'},
      ];
    } else {
      mockData = []; // Default empty list
    }

    return ApiResponse(success: true, message: 'Data Dummy (Bypass Mode)', data: mockData);
  }
}

class ApiResponse {
  final bool success;
  final dynamic data;
  final String message;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.message = '', this.statusCode});
}
