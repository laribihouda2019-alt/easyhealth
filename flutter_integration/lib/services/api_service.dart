import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class ApiService {
  static final Dio _dio = Dio();
  static final _storage = FlutterSecureStorage();

  static const String _baseUrl = 'https://easy-backend-w8hz.onrender.com/api';

  static void init() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Interceptor pour ajouter le token JWT
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('API Request: ${options.method} ${options.path}');
          
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('Token added to request');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('API Response: ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (error, handler) async {
          print('API Error: ${error.response?.statusCode} ${error.requestOptions.path}');
          print('Error message: ${error.message}');
          
          // Gestion automatique du token expiré
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'jwt_token');
            print('Token expired, removed from storage');
            
            // Vous pouvez ajouter une navigation vers l'écran de login ici
            // NavigationService.navigateToLogin();
          }
          handler.next(error);
        },
      ),
    );
  }

  // Authentification
  static Future<Response> register(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/auth/register', data: userData);
      return response;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  static Future<Response> login(Map<String, dynamic> credentials) async {
    try {
      final response = await _dio.post('/auth/login', data: credentials);
      
      // Sauvegarder le token si présent
      if (response.data['token'] != null) {
        await _storage.write(key: 'jwt_token', value: response.data['token']);
      }
      
      return response;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await _storage.delete(key: 'jwt_token');
    }
  }

  // Profile
  static Future<Response> getMyProfile() async {
    return await _dio.get('/profile/me');
  }

  // Conversations
  static Future<Response> getMyConversations() async {
    return await _dio.get('/enhanced-messages/my-conversations');
  }

  static Future<Response> getConversation(String otherUserId) async {
    return await _dio.get('/enhanced-messages/conversation/$otherUserId');
  }

  // Messaging with images and delivery
  static Future<Response> sendMessage({
    required String recipientId,
    required String content,
    String? imagePath,
    bool deliveryRequested = false,
    String? deliveryAddress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'recipientId': recipientId,
        'content': content,
        'deliveryRequested': deliveryRequested,
        'deliveryAddress': deliveryAddress,
      });

      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          formData.files.add(
            MapEntry('image', await MultipartFile.fromFile(imagePath)),
          );
          print('Image added to message: $imagePath');
        }
      }

      final response = await _dio.post('/enhanced-messages/send', data: formData);
      return response;
    } catch (e) {
      print('Send message error: $e');
      rethrow;
    }
  }

  static Future<Response> updateDeliveryStatus(String messageId, String status) async {
    return await _dio.put('/enhanced-messages/$messageId/delivery-status', 
      data: {'deliveryStatus': status}
    );
  }

  static Future<Response> markMessageAsRead(String messageId) async {
    return await _dio.put('/enhanced-messages/$messageId/read');
  }

  // Profiles by role
  static Future<Response> getProfilesByRole(String role) async {
    return await _dio.get('/profiles/role/$role');
  }

  static Future<Response> searchProfiles(String query) async {
    return await _dio.get('/profiles/search', queryParameters: {'q': query});
  }

  // Utility methods
  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<bool> isTokenValid() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // Test connection
  static Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/profile/me');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
