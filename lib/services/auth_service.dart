import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isLoggedIn = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;

  // Initialize - check if user is already logged in
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    final token = prefs.getString('auth_token');
    
    if (userData != null && token != null) {
      _currentUser = User.fromJson(jsonDecode(userData));
      _isLoggedIn = true;
      await ApiService.setToken(token);
      notifyListeners();
    }
  }

  // Login
  Future<AuthResult> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('login', body: {
        'email': email,
        'password': password,
      });

      if (response.success && response.data != null) {
        final data = response.data;
        String? token;
        Map<String, dynamic>? userData;

        // res.data sekarang = full body JSON
        // Format login: { success: true, data: { token: '...', user: {...} } }
        if (data is Map<String, dynamic>) {
          // Coba ambil dari body['data'] dulu (format baru)
          final inner = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
          token = inner['token'] ?? inner['access_token'];
          userData = inner['user'] is Map<String, dynamic>
              ? inner['user'] as Map<String, dynamic>
              : null;
        }

        if (token != null && userData != null) {
          await ApiService.setToken(token);
          userData['token'] = token;
          _currentUser = User.fromJson(userData);
          _isLoggedIn = true;

          // Save to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(userData));

          _isLoading = false;
          notifyListeners();
          return AuthResult(success: true, user: _currentUser);
        }
      }

      _isLoading = false;
      notifyListeners();
      return AuthResult(
        success: false, 
        message: response.message.isNotEmpty 
            ? response.message 
            : 'Email atau password salah',
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, message: 'Gagal: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await ApiService.post('logout');
    } catch (_) {}
    await ApiService.clearToken();
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String message;

  AuthResult({required this.success, this.user, this.message = ''});
}
