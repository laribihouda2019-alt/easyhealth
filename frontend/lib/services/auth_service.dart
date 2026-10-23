import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  UserModel? _currentUser;
  final ApiService _apiService = ApiService();

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isApproved => _currentUser?.isApproved ?? false;
  UserRole? get userRole => _currentUser?.role;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final apiService = ApiService();
      final response = await apiService.login({'email': email, 'password': password});
      
      if (response['success'] == true) {
        final user = UserModel.fromJson(response['user']);
        _currentUser = user;
        
        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', response['token'] ?? '');
        await prefs.setString('user_data', jsonEncode(user.toJson()));
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String role,
    required String wilaya,
    required String commune,
    Map<String, dynamic>? extraFields,
  }) async {
    try {
      final apiService = ApiService();
      final response = await apiService.register(
        userId: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: fullName,
        email: email,
        password: password,
        phone: phone ?? '',
        role: role,
        wilaya: wilaya,
        commune: commune,
        extraFields: extraFields,
      );
      
      if (response['success'] == true) {
        final user = UserModel.fromJson(response['profile']);
        _currentUser = user;
        
        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', response['token'] ?? '');
        await prefs.setString('user_data', jsonEncode(user.toJson()));
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData != null) {
        final userMap = jsonDecode(userData) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userMap);
      }
    } catch (e) {
      
    }
  }

  Future<void> refreshProfile() async {
    try {
      if (_currentUser == null) return;
      
      final updatedUser = await _apiService.getMyProfile();
      _currentUser = updatedUser;
      
      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));
    } catch (e) {
      
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      if (_currentUser == null) return;
      
      await _apiService.updateProfile(data);
      await refreshProfile();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<Map<String, dynamic>> getDashboardSummary() async {
    return await _apiService.getDashboardSummary();
  }
}


