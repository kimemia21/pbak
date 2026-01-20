/// API Keys Configuration
///
/// IMPORTANT: In production, store API keys securely:
/// - Use environment variables
/// - Use flutter_dotenv package
/// - Use Firebase Remote Config
/// - Never commit API keys to version control
class ApiKeys {
  /// OpenWeather API Key
  ///
  /// Used by the Weather section to fetch current weather by lat/lon.
  static const String openWeatherApiKey = 'e02c0a4ae69aff9da5e280b3f7491679';

  static bool get isOpenWeatherConfigured =>
      openWeatherApiKey.isNotEmpty &&
      !openWeatherApiKey.contains('YOUR_OPENWEATHER');

  /// Google Places API Key
  ///
  /// To get your API key:
  /// 1. Go to Google Cloud Console: https://console.cloud.google.com/
  /// 2. Create a new project or select existing one
  /// 3. Enable "Places API" and "Maps SDK for Android/iOS"
  /// 4. Go to "Credentials" and create an API key
  /// 5. Restrict the API key to your app's package name for security
  /// 6. Replace the value below with your actual API key
  static const String googlePlacesApiKey =
      'AIzaSyCTn-pq0h-Cq7Jfk40lAp0v6aLz7XVDqJA';
    

  /// Web-only: Backend proxy base URL for Places API.
  ///
  /// Configure via:
  /// flutter run -d chrome --dart-define=GOOGLE_PLACES_PROXY_BASE_URL=https://your-backend.com/places
  ///
  /// Your backend should forward requests to Google Places and return JSON.
  static const String googlePlacesProxyBaseUrl = String.fromEnvironment(
    'GOOGLE_PLACES_PROXY_BASE_URL',
    defaultValue: '',
  );

  static bool get isGooglePlacesProxyConfigured =>
      googlePlacesProxyBaseUrl.isNotEmpty;

  /// Check if API key is configured
  static bool get isGooglePlacesConfigured =>
      googlePlacesApiKey.isNotEmpty &&
      !googlePlacesApiKey.contains('YOUR_GOOGLE');
}
