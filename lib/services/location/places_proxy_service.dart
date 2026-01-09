import 'package:dio/dio.dart';

/// Simple proxy service for Google Places REST APIs.
///
/// Why: Flutter Web cannot call Google Places REST endpoints directly due to CORS.
/// The recommended solution is to proxy requests through your own backend.
///
/// Expected proxy behavior:
/// - Accepts GET /places?input=... (or similar)
/// - Forwards to Google Places API using a server-side key
/// - Returns the raw JSON from Google (with a `predictions` array)
class PlacesProxyService {
  final Dio _dio;
  final String baseUrl;

  PlacesProxyService({required this.baseUrl, Dio? dio}) : _dio = dio ?? Dio();

  String _join(String path) {
    final b = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return '$b$p';
  }

  /// Fetch autocomplete predictions.
  ///
  /// For this project (web), the backend endpoint is expected to be:
  /// GET {baseUrl}?input=...
  Future<Map<String, dynamic>> autocomplete({
    required String input,
    String language = 'en',
    String components = 'country:ke',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      // baseUrl is expected to be the full endpoint, e.g. http://host/api/v1/places
      baseUrl,
      queryParameters: {
        'input': input,
        // Keep optional params for compatibility if backend supports them.
        'language': language,
        'components': components,
      },
      options: Options(responseType: ResponseType.json),
    );

    return response.data ?? <String, dynamic>{};
  }

  // NOTE: Place details is intentionally not used on web in this app currently.
  // If you later add a backend details endpoint, we can re-enable lat/lng fetching here.
  // Future<Map<String, dynamic>> details(...)
}
