class ResetTokenService {
  /// Extracts the 'token' query parameter from the browser URL.
  /// Works with both standard paths and Flutter's default hash-routing:
  /// - Standard: http://localhost:PORT/reset-password?token=TOKEN
  /// - Hash-route: http://localhost:PORT/#/reset-password?token=TOKEN
  static String? getTokenFromUrl() {
    // 1. Try direct query parameter search (standard path routing)
    final directToken = Uri.base.queryParameters['token'];
    if (directToken != null && directToken.isNotEmpty) {
      return directToken;
    }

    // 2. Try parsing fragment parameters (default hash routing /#/)
    final fragment = Uri.base.fragment;
    if (fragment.isNotEmpty) {
      try {
        // If fragment is "/reset-password?token=XYZ", prepend dummy scheme for Uri.parse
        final cleanFragment = fragment.startsWith('/') ? fragment : '/$fragment';
        final parsedUri = Uri.parse('http://dummy$cleanFragment');
        final hashToken = parsedUri.queryParameters['token'];
        if (hashToken != null && hashToken.isNotEmpty) {
          return hashToken;
        }
      } catch (_) {
        // Fallback on error
      }
    }

    return null;
  }
}
