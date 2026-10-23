class ApiConfig {
  // ── Production backend (Render) ──────────────────────────────────────────
  static const String baseUrl = 'https://easyhealth-backend.onrender.com/api/';
  static const String mediaBaseUrl = 'https://easyhealth-backend.onrender.com';

  /// AI API - Flask (not deployed, disabled in production).
  static const String aiBaseUrl = 'https://easyhealth-backend.onrender.com';
  static const String aiBaseUrlLocal = 'https://easyhealth-backend.onrender.com';

  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
