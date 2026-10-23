class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:4001/api/';
  static const String mediaBaseUrl = 'http://127.0.0.1:4001';

  /// AI API - Flask. Using localhost for development.
  static const String aiBaseUrl = 'http://localhost:5000';
  static const String aiBaseUrlLocal = 'http://localhost:5000';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
