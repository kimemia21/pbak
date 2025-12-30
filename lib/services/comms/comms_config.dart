
class CommsConfig {
  /// Environment types
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';


  static const String currentEnvironment = development;

  static const Map<String, String> baseUrls = {
    development: 'http://167.99.202.246:5020/api/v1',
    staging: 'https://staging-api.pbak.co.ke/v1',
    production: 'https://api.pbak.co.ke/v1',
  };



  /// Get the base URL for current environment
  static String get baseUrl => baseUrls[currentEnvironment] ?? baseUrls[development]!;

  /// API version
  static const String apiVersion = 'v1';

  /// Enable/disable debug logging
  static const bool enableLogging = true;

  /// Timeout configurations (in seconds)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;

  /// Retry configuration
  static const int maxRetries = 3;
  static const int retryDelay = 2; // seconds

  /// API Keys (if needed)
  static const String? googleMapsApiKey = null;
  static const String? mpesaApiKey = null;

  /// Feature flags
  static const bool useMockApi = true; 
  static const bool enableCrashReporting = false;
  static const bool enableAnalytics = false;
}
