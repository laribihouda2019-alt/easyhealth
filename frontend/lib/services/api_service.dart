import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/appointment_model.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  static final _storage = FlutterSecureStorage();

  late final Dio _dio;
  String? _currentUserId;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Ajouter l'interceptor JWT
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          

          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          
          handler.next(response);
        },
        onError: (error, handler) async {
          
          

          // Gestion automatique du token expiré
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'jwt_token');
            
          }
          handler.next(error);
        },
      ),
    );
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  String? get currentUserId => _currentUserId;

  // AUTH ENDPOINTS

  Future<Map<String, dynamic>> register({
    required String userId,
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
      final Map<String, dynamic> data = {
        'userId': userId,
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
        'wilaya': wilaya,
        'commune': commune,
      };

      if (extraFields != null) {
        data.addAll(extraFields);
      }

      final response = await _dio.post('auth/register', data: data);
      return response.data;
    } catch (e) {
      
      rethrow;
    }
  }

  Future<List<UserModel>> searchByCommune(String commune, {String? query}) async {
    try {
      final response = await _dio.get(
        'profiles/search', 
        queryParameters: {
          'commune': commune,
          if (query != null) 'query': query,
        }
      );
      final List data = response.data;
      return data.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      
      return [];
    }
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) async {
    try {
      final response = await _dio.post(
        'auth/login',
        data: credentials,
      );

      // Sauvegarder le token si présent
      if (response.data['token'] != null) {
        await _storage.write(key: 'jwt_token', value: response.data['token']);
      }

      return response.data;
    } catch (e) {
      
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('auth/logout');
    } catch (e) {
      
    } finally {
      await _storage.delete(key: 'jwt_token');
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        'auth/forgot-password',
        data: {'email': email},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dio.post(
        'auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // PROFILE ENDPOINTS

  Future<UserModel> getMyProfile() async {
    final response = await _dio.get('profile/me');
    return UserModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('profile/me', data: data);
    return response.data;
  }
  
  Future<Map<String, dynamic>> getProfileStats() async {
    final response = await _dio.get('profile/stats');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfileAvatar({
    List<int>? bytes,
    String? path,
    String? fileName,
  }) async {
    final formData = FormData();
    
    if (bytes != null) {
      final extension = fileName?.split('.').last.toLowerCase() ?? 'jpg';
      formData.files.add(
        MapEntry(
          'avatar',
          MultipartFile.fromBytes(
            bytes,
            filename: fileName ?? 'avatar.jpg',
            contentType: MediaType('image', extension == 'png' ? 'png' : 'jpeg'),
          ),
        ),
      );
    } else if (path != null) {
      formData.files.add(
        MapEntry('avatar', await MultipartFile.fromFile(path)),
      );
    }

    final response = await _dio.post('profile/avatar', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _dio.get('profiles/$userId');
    return response.data;
  }

  Future<List<dynamic>> getPharmacies() async {
    final response = await _dio.get('pharmacies');
    return response.data as List;
  }

  Future<List<dynamic>> getLaboratories() async {
    final response = await _dio.get('laboratories');
    return response.data as List;
  }

  // ENHANCED MESSAGING ENDPOINTS

  Future<Map<String, dynamic>> sendMessage({
    required String recipientId,
    required String content,
    String? imagePath,
    List<int>? imageBytes,
    String? imageFileName,
    bool deliveryRequested = false,
    String? deliveryAddress,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'recipientId': recipientId,
        'content': content,
        'deliveryRequested': deliveryRequested,
        'deliveryAddress': deliveryAddress,
        'messageType': messageType,
        'metadata': metadata,
      };

      final formData = FormData.fromMap(data);

      // Web-compatible file upload
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final extension = imageFileName?.split('.').last.toLowerCase() ?? 'jpg';
        final type = (extension == 'pdf') ? 'application' : 'image';
        final subtype = (extension == 'pdf') ? 'pdf' : (extension == 'png' ? 'png' : 'jpeg');

        formData.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(
              imageBytes,
              filename: imageFileName ?? 'attachment.jpg',
              contentType: MediaType(type, subtype),
            ),
          ),
        );
        
      } else if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          formData.files.add(
            MapEntry('image', await MultipartFile.fromFile(imagePath)),
          );
          
        }
      }

      final response = await _dio.post(
        'enhanced-messages/send',
        data: formData,
      );
      return response.data;
    } catch (e) {
      
      rethrow;
    }
  }

  Future<List<dynamic>> getMyConversations() async {
    final response = await _dio.get('enhanced-messages/my-conversations');
    return response.data['data'] as List;
  }

  Future<List<dynamic>> getConversation(String otherUserId) async {
    final response = await _dio.get(
      'enhanced-messages/conversation/$otherUserId',
    );
    return response.data['data'] as List;
  }

  Future<Map<String, dynamic>> updateDeliveryStatus(
    String messageId,
    String status,
  ) async {
    final response = await _dio.put(
      'enhanced-messages/$messageId/delivery-status',
      data: {'deliveryStatus': status},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> markMessageAsRead(String messageId) async {
    final response = await _dio.put('enhanced-messages/$messageId/read');
    return response.data;
  }

  // CHAT ENDPOINTS (Legacy)

  Future<MessageModel> sendMessageLegacy({
    required String recipientId,
    required String content,
    String messageType = 'text',
    int? appointmentId,
  }) async {
    final response = await _dio.post(
      'chat/',
      data: {
        'recipientId': recipientId,
        'content': content,
        'messageType': messageType,
        'appointmentId': appointmentId,
      },
    );
    return MessageModel.fromJson(response.data);
  }

  Future<List<MessageModel>> getConversationLegacy(
    String otherUserId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      'chat/$otherUserId',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => MessageModel.fromJson(json)).toList();
  }

  // APPOINTMENT ENDPOINTS

  Future<AppointmentModel> createAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    String appointmentType = 'consultation',
    int? durationMinutes,
    String? location,
    String? meetingUrl,
    String? notes,
  }) async {
    final response = await _dio.post(
      'appointments/',
      data: {
        'doctorId': doctorId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'appointmentType': appointmentType,
        'durationMinutes': durationMinutes,
        'location': location,
        'meetingUrl': meetingUrl,
        'notes': notes,
      },
    );
    return AppointmentModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    final user = AuthService().currentUser;
    final String path = user?.role == UserRole.doctor 
        ? 'doctor/appointments/$appointmentId/status'
        : 'appointments/$appointmentId/status';
        
    final response = await _dio.put(
      path,
      data: {'status': status.name}, // Using .name (e.g., 'accepted') to match backend enum
    );
    return response.data;
  }

  // VERIFICATION ENDPOINTS

  Future<Map<String, dynamic>> createVerificationRequest({
    required String roleRequested,
    required String documentType,
    String? documentUrl,
    Map<String, dynamic>? ocrRawData,
    Map<String, dynamic>? extractedFields,
  }) async {
    final response = await _dio.post(
      'verification/requests',
      data: {
        'roleRequested': roleRequested,
        'documentType': documentType,
        'documentUrl': documentUrl,
        'ocrRawData': ocrRawData,
        'extractedFields': extractedFields,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> reviewVerificationRequest(
    int requestId, {
    required String status,
    String? adminNotes,
  }) async {
    final response = await _dio.post(
      'verification/$requestId/review',
      data: {'status': status, 'adminNotes': adminNotes},
    );
    return response.data;
  }

  // PROFILES BY ROLE
  Future<List<dynamic>> getProfilesByRole(String role) async {
    final response = await _dio.get('profiles/role/$role');
    return response.data as List;
  }

  Future<List<dynamic>> searchProfiles(String query) async {
    final response = await _dio.get(
      'profiles/search',
      queryParameters: {'q': query},
    );
    return response.data as List;
  }

  // UTILITY METHODS
  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<bool> isTokenValid() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  static Future<bool> testConnection() async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: Duration(seconds: 5),
          receiveTimeout: Duration(seconds: 5),
        ),
      );

      final response = await dio.get('profile/me');
      return response.statusCode == 200;
    } catch (e) {
      
      return false;
    }
  }

  // Enhanced endpoints for new features
  Future<List<dynamic>> getMyMedications({bool active = true}) async {
    final response = await _dio.get('patient/medications', queryParameters: {'active': active});
    // The patient controller returns { success: true, medications: [...] }
    if (response.data is Map && response.data.containsKey('medications')) {
      return response.data['medications'] as List<dynamic>;
    }
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getTodaysReminders() async {
    final response = await _dio.get('medications/reminders/today');
    return response.data;
  }

  Future<Map<String, dynamic>> markMedicationTaken(String reminderId) async {
    final response = await _dio.put('medications/reminders/$reminderId/taken');
    return response.data;
  }

  Future<Map<String, dynamic>> analyzeSymptoms(Map<String, dynamic> symptomsData) async {
    final response = await _dio.post('patient/ai/analyze-symptoms', data: symptomsData);
    return response.data;
  }

  Future<Map<String, dynamic>> getDoctorAvailability(String doctorId, {String? date}) async {
    final queryParams = <String, dynamic>{};
    if (date != null) queryParams['date'] = date;

    final response = await _dio.get('patient/appointments/availability/$doctorId', queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> getAvailableSlots(String doctorId, {String? date}) async {
    final queryParams = <String, dynamic>{};
    if (date != null) queryParams['date'] = date;

    final response = await _dio.get('availability/$doctorId', queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> createRealAppointment(Map<String, dynamic> appointmentData) async {
    final response = await _dio.post('patient/appointments', data: appointmentData);
    return response.data;
  }

  Future<Map<String, dynamic>> getMyAppointments({String? status, bool? upcoming}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (upcoming != null) queryParams['upcoming'] = upcoming.toString();

    final response = await _dio.get('patient/appointments', queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> addMedicationSchedule(Map<String, dynamic> medicationData) async {
    final response = await _dio.post('medications', data: medicationData);
    return response.data;
  }

  // PAYMENT ENDPOINTS (Chargily V2 & CCP)
  Future<Map<String, dynamic>> createChargilyV2Checkout({
    required double amount,
    int? appointmentId,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _dio.post(
      'payments/chargily-v2/checkout',
      data: {
        'amount': amount,
        'appointmentId': appointmentId,
        'metadata': metadata,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> uploadCcpProof({
    required int appointmentId,
    required String accountName,
    required String ccpNumber,
    required File proofFile,
  }) async {
    final formData = FormData.fromMap({
      'appointmentId': appointmentId,
      'accountName': accountName,
      'ccpNumber': ccpNumber,
      'proof': await MultipartFile.fromFile(proofFile.path),
    });

    final response = await _dio.post('payments/ccp/upload', data: formData);
    return response.data;
  }

  // Doctor endpoints
  Future<Map<String, dynamic>> getDoctorAppointments({String? status, String? date, bool? upcoming}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (date != null) queryParams['date'] = date;
    if (upcoming != null) queryParams['upcoming'] = upcoming.toString();

    final response = await _dio.get('doctor/appointments', queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> setAvailability(List<Map<String, dynamic>> availabilityData) async {
    final response = await _dio.post('doctor/availability', data: {'availability': availabilityData});
    return response.data;
  }

  Future<Map<String, dynamic>> getMyAvailability() async {
    final response = await _dio.get('doctor/availability');
    return response.data;
  }

  Future<List<dynamic>> getAvailabilitySlots() async {
    final response = await _dio.get('doctor/availability-slots');
    return response.data as List;
  }

  Future<void> addAvailabilitySlots(List<Map<String, dynamic>> slots) async {
    await _dio.post('doctor/availability-slots', data: {'slots': slots});
  }

  Future<void> deleteAvailabilitySlot(int id) async {
    await _dio.delete('doctor/availability-slots/$id');
  }

  Future<Map<String, dynamic>> recordDiseaseObservation(Map<String, dynamic> observationData) async {
    final response = await _dio.post('doctor/disease-observations', data: observationData);
    return response.data;
  }

  Future<Map<String, dynamic>> getMyDiseaseObservations({String? date, String? diseaseName, String? category}) async {
    final queryParams = <String, dynamic>{};
    if (date != null) queryParams['date'] = date;
    if (diseaseName != null) queryParams['diseaseName'] = diseaseName;
    if (category != null) queryParams['category'] = category;

    final response = await _dio.get('doctor/disease-observations', queryParameters: queryParams);
    return response.data;
  }

  // ============== ANALYTICS ENDPOINTS ==============

  Future<List<dynamic>> getConditionStatistics() async {
    final response = await _dio.get('analytics/statistics/conditions');
    return response.data as List;
  }

  Future<List<dynamic>> getAgeConditionStatistics() async {
    final response = await _dio.get('analytics/statistics/age-conditions');
    return response.data as List;
  }

  Future<List<dynamic>> getCommonSymptoms() async {
    final response = await _dio.get('analytics/statistics/common-symptoms');
    return response.data as List;
  }

  // Generic POST method for analytics
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    final response = await _dio.post(path, data: data);
    return response.data;
  }

  // Generic GET method
  Future<Map<String, dynamic>?> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } catch (e) {
      
      return null;
    }
  }

  // ============== AI ENDPOINTS ==============

  static Map<String, String> get _aiHeaders => {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  /// Recommandation médecin selon symptômes
  /// Recommandation médecin selon symptômes (Redirigé vers le backend Node.js)
  Future<Map<String, dynamic>> aiRecommendDoctor(String symptoms) async {
    final response = await _dio.post(
      'patient/ai/analyze-symptoms', 
      data: {'symptomsDescription': symptoms}
    );
    
    // Map backend response to what UI expects
    final data = response.data;
    if (data['success'] == true && data['analysis'] != null) {
      final analysis = data['analysis'];
      
      // Safe parsing of confidence score
      double confidence = 0.7; // Default
      final rawConfidence = analysis['confidence_score'];
      if (rawConfidence != null) {
        if (rawConfidence is num) {
          confidence = rawConfidence.toDouble() / 100.0;
        } else if (rawConfidence is String) {
          confidence = (double.tryParse(rawConfidence) ?? 70.0) / 100.0;
        }
      }

      return {
        'recommended_specialty': analysis['recommended_specialization'],
        'confidence': confidence,
        'message': data['message'],
        'recommended_doctors': data['recommendedDoctors'],
      };
    }
    return data;
  }

  /// Vérification documents (admin)
  Future<Map<String, dynamic>> aiCheckDocuments({
    required String documentUrl,
    required String roleRequested,
    String documentType = 'certificate',
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.aiBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: _aiHeaders,
      ),
    );
    final response = await dio.post(
      '/admin/check_documents',
      data: {
        'document_url': documentUrl,
        'role_requested': roleRequested,
        'document_type': documentType,
      },
    );
    return response.data;
  }

  /// Rappels de médicaments
  Future<Map<String, dynamic>> aiMedicationReminders({
    required String userId,
    int minutesBefore = 15,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.aiBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: _aiHeaders,
      ),
    );
    final response = await dio.post(
      '/medication/reminders',
      data: {'user_id': userId, 'minutes_before': minutesBefore},
    );
    return response.data;
  }

  /// Maladies fréquentes (admin)
  Future<Map<String, dynamic>> aiFrequentDiseases({int days = 30}) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.aiBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: _aiHeaders,
      ),
    );
    final response = await dio.get(
      '/admin/frequent_diseases',
      queryParameters: {'days': days},
    );
    return response.data;
  }

  /// Create a medication order with prescription upload
  Future<Map<String, dynamic>> createMedicationOrder({
    required String pharmacyId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? deliveryAddress,
    String? prescriptionPath,
    List<int>? prescriptionBytes,
    String? prescriptionFileName,
    String paymentMethod = 'cod',
  }) async {
    try {
      final Map<String, dynamic> data = {
        'pharmacyId': pharmacyId,
        'items': jsonEncode(items), // STRINGIFY FOR MULTIPART
        'totalAmount': totalAmount,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
      };

      final formData = FormData.fromMap(data);

      if (kIsWeb && prescriptionBytes != null) {
        final extension = prescriptionFileName?.split('.').last.toLowerCase() ?? 'jpg';
        final type = (extension == 'pdf') ? 'application' : 'image';
        final subtype = (extension == 'pdf') ? 'pdf' : (extension == 'png' ? 'png' : 'jpeg');

        formData.files.add(
          MapEntry(
            'prescription',
            MultipartFile.fromBytes(
              prescriptionBytes,
              filename: prescriptionFileName ?? 'prescription.jpg',
              contentType: MediaType(type, subtype),
            ),
          ),
        );
      } else if (prescriptionPath != null && prescriptionPath.isNotEmpty) {
        formData.files.add(
          MapEntry('prescription', await MultipartFile.fromFile(prescriptionPath)),
        );
      }

      final response = await _dio.post('medication-orders', data: formData);
      return response.data;
    } catch (e) {
      
      rethrow;
    }
  }

  Future<List<dynamic>> getMyMedicationOrders() async {
    final response = await _dio.get('medication-orders/me');
    if (response.data is Map && response.data.containsKey('data')) {
      return response.data['data'] as List;
    }
    return response.data is List ? response.data as List : [];
  }

  Future<Map<String, dynamic>> updateMedicationOrderStatus(String orderId, String status) async {
    final response = await _dio.put(
      'medication-orders/$orderId/status',
      data: {'status': status},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createLabRequest({
    required String labId,
    required List<int> serviceIds,
    DateTime? scheduledAt,
    String paymentMethod = 'cod',
  }) async {
    final response = await _dio.post(
      'lab-requests',
      data: {
        'labId': labId,
        'serviceIds': serviceIds,
        'paymentMethod': paymentMethod,
        'scheduledAt': scheduledAt?.toIso8601String(),
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getMyLabRequests() async {
    final response = await _dio.get('lab-requests/me');
    if (response.data is Map && response.data.containsKey('data')) {
      return response.data['data'] as List;
    }
    return response.data is List ? response.data as List : [];
  }

  // MEDICAL RECORDS
  Future<Map<String, dynamic>> uploadMedicalRecord({
    required String title,
    required String category,
    String? notes,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final Map<String, dynamic> data = {
      'title': title,
      'category': category,
      'notes': notes,
    };

    final formData = FormData.fromMap(data);

    if (fileBytes != null) {
      final extension = fileName?.split('.').last.toLowerCase() ?? 'pdf';
      final type = (extension == 'pdf') ? 'application' : 'image';
      final subtype = (extension == 'pdf') ? 'pdf' : (extension == 'png' ? 'png' : 'jpeg');

      formData.files.add(
        MapEntry(
          'record',
          MultipartFile.fromBytes(
            fileBytes,
            filename: fileName ?? 'doc.pdf',
            contentType: MediaType(type, subtype),
          ),
        ),
      );
    }

    final response = await _dio.post('medical-records', data: formData);
    return response.data;
  }

  Future<List<dynamic>> getMyMedicalRecords() async {
    final response = await _dio.get('medical-records/me');
    if (response.data is Map && response.data.containsKey('data')) {
      return response.data['data'] as List;
    }
    return response.data is List ? response.data as List : [];
  }

  Future<List<dynamic>> getPatientMedicalRecords(String patientId) async {
    final response = await _dio.get('doctor/patient/$patientId/medical-records');
    if (response.data is Map && response.data.containsKey('data')) {
      return response.data['data'] as List;
    }
    return response.data is List ? response.data as List : [];
  }

  Future<void> deleteMedicalRecord(String id) async {
    await _dio.delete('medical-records/$id');
  }

  Future<List<dynamic>> getPharmacyOrders() async {
    final response = await _dio.get('pharmacy/orders');
    if (response.data is Map && response.data.containsKey('data')) {
      return response.data['data'] as List;
    }
    return response.data is List ? response.data as List : [];
  }

  Future<List<dynamic>> getLabRequests() async {
    final response = await _dio.get('lab/requests');
    if (response.data is Map && response.data.containsKey('data')) {
      return response.data['data'] as List;
    }
    return response.data is List ? response.data as List : [];
  }

  /// Récupérer le résumé des statistiques pour le tableau de bord
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await _dio.get('/analytics/summary');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== SYSTEM NOTIFICATIONS ====================
  
  Future<List<dynamic>> getMyNotifications() async {
    final response = await _dio.get('notifications/me');
    return response.data['data'] as List;
  }

  Future<void> markNotificationAsRead(String id) async {
    await _dio.put('notifications/$id/read');
  }

  Future<void> markAllNotificationsAsRead() async {
    await _dio.put('notifications/read-all');
  }

  // ==================== NEW MODULES: LAB & PHARMACY & RESULTS ====================

  Future<List<dynamic>> getLabServices(String labId) async {
    final response = await _dio.get('lab/$labId/services');
    return response.data as List;
  }

  Future<Map<String, dynamic>> addLabService(String testName, double price) async {
    final response = await _dio.post(
      'lab/services',
      data: {'testName': testName, 'price': price},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> uploadTestResult({
    required String requestId,
    required String status,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final formData = FormData.fromMap({
      'requestId': requestId,
      'status': status,
    });

    if (fileBytes != null) {
      final extension = fileName?.split('.').last.toLowerCase() ?? 'pdf';
      final type = (extension == 'pdf') ? 'application' : 'image';
      final subtype = (extension == 'pdf') ? 'pdf' : (extension == 'png' ? 'png' : 'jpeg');

      formData.files.add(
        MapEntry(
          'result',
          MultipartFile.fromBytes(
            fileBytes,
            filename: fileName ?? 'result.pdf',
            contentType: MediaType(type, subtype),
          ),
        ),
      );
    }

    final response = await _dio.post('lab/upload-result', data: formData);
    return response.data;
  }

  Future<List<dynamic>> getPharmacyInventory(String pharmacyId) async {
    final response = await _dio.get('pharmacy/$pharmacyId/inventory');
    return response.data as List;
  }

  Future<Map<String, dynamic>> addInventoryItem(String medName, double price) async {
    final response = await _dio.post(
      'pharmacy/inventory',
      data: {'medName': medName, 'price': price},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateInventoryItemStatus(int itemId, bool isAvailable) async {
    final response = await _dio.put(
      'pharmacy/inventory/$itemId',
      data: {'isAvailable': isAvailable},
    );
    return response.data;
  }

  Future<List<dynamic>> getTestResults(String requestId) async {
    final response = await _dio.get('lab/results/$requestId');
    return response.data as List;
  }

  Future<Map<String, dynamic>> updateLabRequestStatus(String requestId, String status) async {
    final response = await _dio.put(
      'lab/requests/$requestId/status',
      data: {'status': status},
    );
    return response.data;
  }

  // ==================== DIGITAL PRESCRIPTION ====================

  Future<List<dynamic>> getMyPrescriptions() async {
    final response = await _dio.get('prescriptions/me');
    if (response.data is Map && response.data.containsKey('data')) {
      return response.data['data'] as List;
    }
    return response.data is List ? response.data as List : [];
  }

  Future<Map<String, dynamic>> getPrescriptionById(int id) async {
    final response = await _dio.get('prescriptions/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createPrescription({
    required String patientId,
    int? appointmentId,
    required List<Map<String, dynamic>> medications,
    String? notes,
  }) async {
    final response = await _dio.post(
      'prescriptions',
      data: {
        'patientId': patientId,
        'appointmentId': appointmentId,
        'medications': medications,
        'notes': notes,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> verifyPrescription(String code) async {
    final response = await _dio.get('prescriptions/verify/$code');
    return response.data;
  }

  // ==================== AGORA VIDEO CALL ====================
  Future<Map<String, dynamic>> getAgoraToken(String channelName) async {
    final response = await _dio.get(
      'agora/token',
      queryParameters: {'channelName': channelName},
    );
    return response.data;
  }

  // ==================== MEDICAL ROUTER ====================
  Future<Map<String, dynamic>> medicalRouterRecommend(String symptoms) async {
    final response = await _dio.post(
      'medical-router/recommend',
      data: {'symptomsDescription': symptoms},
    );
    return response.data;
  }

  // ==================== SOCIAL SECURITY (CHIFA & MEDICAL CONTROL) ====================
  
  // Chifa Card Methods
  Future<List<String>> uploadChifaDocuments(List<PlatformFile> files) async {
    final formData = FormData();
    for (var file in files) {
      if (kIsWeb) {
        formData.files.add(MapEntry(
          'documents',
          MultipartFile.fromBytes(file.bytes!, filename: file.name),
        ));
      } else {
        formData.files.add(MapEntry(
          'documents',
          await MultipartFile.fromFile(file.path!),
        ));
      }
    }
    final response = await _dio.post('social-security/upload-documents', data: formData);
    return List<String>.from(response.data['fileUrls'] ?? []);
  }

  Future<Map<String, dynamic>> submitChifaRequest({
    required List<String> documentUrls,
    String? notes,
  }) async {
    final response = await _dio.post(
      'social-security/requests',
      data: {
        'documentUrls': documentUrls,
        'notes': notes,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getMyChifaRequests() async {
    final response = await _dio.get('social-security/requests/my');
    return response.data is Map ? (response.data['data'] as List) : (response.data as List);
  }

  Future<List<dynamic>> getAllChifaRequests() async {
    final response = await _dio.get('social-security/requests/all');
    if (response.data is Map && response.data.containsKey('data')) {
      return response.data['data'] as List;
    }
    return response.data is List ? response.data as List : [];
  }

  Future<Map<String, dynamic>> updateChifaRequestStatus(String requestId, String status, {String? rejectionReason}) async {
    final response = await _dio.put(
      'social-security/requests/$requestId/status',
      data: {
        'status': status,
        'rejectionReason': rejectionReason,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getChifaStats() async {
    final response = await _dio.get('social-security/stats');
    return response.data;
  }

  // Medical Approval Methods
  Future<Map<String, dynamic>> getMyMedicalRequests() async {
    final response = await _dio.get('social-security/medical-requests/my');
    return response.data;
  }

  Future<Map<String, dynamic>> submitMedicalRequest({
    required String requestType,
    required String description,
    required PlatformFile prescription,
    List<PlatformFile>? supportingDocs,
  }) async {
    final formData = FormData.fromMap({
      'requestType': requestType,
      'description': description,
    });

    if (kIsWeb) {
      final ext = prescription.name.split('.').last.toLowerCase();
      formData.files.add(MapEntry(
        'prescription',
        MultipartFile.fromBytes(
          prescription.bytes!,
          filename: prescription.name,
          contentType: MediaType(ext == 'pdf' ? 'application' : 'image', ext == 'pdf' ? 'pdf' : 'jpeg'),
        ),
      ));
    } else {
      formData.files.add(MapEntry(
        'prescription',
        await MultipartFile.fromFile(prescription.path!),
      ));
    }

    if (supportingDocs != null && supportingDocs.isNotEmpty) {
      for (var doc in supportingDocs) {
        if (kIsWeb) {
          final ext = doc.name.split('.').last.toLowerCase();
          formData.files.add(MapEntry(
            'supportingDocs',
            MultipartFile.fromBytes(
              doc.bytes!,
              filename: doc.name,
              contentType: MediaType(ext == 'pdf' ? 'application' : 'image', ext == 'pdf' ? 'pdf' : 'jpeg'),
            ),
          ));
        } else {
          formData.files.add(MapEntry(
            'supportingDocs',
            await MultipartFile.fromFile(doc.path!),
          ));
        }
      }
    }

    final response = await _dio.post('social-security/medical-requests', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> getPendingMedicalRequests() async {
    final response = await _dio.get('social-security/medical-requests/pending');
    return response.data;
  }

  Future<Map<String, dynamic>> reviewMedicalRequest({
    required int requestId,
    required String status,
    String? comment,
  }) async {
    final response = await _dio.put(
      'social-security/medical-requests/$requestId/review',
      data: {
        'status': status,
        'comment': comment,
      },
    );
    return response.data;
  }
}


