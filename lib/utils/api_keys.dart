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
  static const String openWeatherApiKey = '195deee3e11a49bfb58153821260501';

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
      'AIzaSyCGKb1PbURd1hv1QqOPGooDK_lGXoFQlsY';

  /// Check if API key is configured
  static bool get isGooglePlacesConfigured =>
      googlePlacesApiKey.isNotEmpty &&
      !googlePlacesApiKey.contains('YOUR_GOOGLE');
}
