import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Launch Configuration Model
class LaunchConfig {
  final bool allowDiscount;
  final String version;

  LaunchConfig({required this.allowDiscount, required this.version});

  factory LaunchConfig.fromJson(Map<String, dynamic> json) {
    return LaunchConfig(
      allowDiscount: json['allow_discount'] == 1,
      version: json['version']?.toString() ?? '0.0',
    );
  }

  /// Default config when API call fails - no discount allowed
  factory LaunchConfig.defaultConfig() {
    return LaunchConfig(allowDiscount: false, version: '0.0');
  }
}

/// Launch Service
/// Handles fetching app launch configuration from the server
class LaunchService {
  static final LaunchService _instance = LaunchService._internal();
  factory LaunchService() => _instance;
  LaunchService._internal();

  final _comms = CommsService.instance;

  /// Cached launch config
  LaunchConfig? _cachedConfig;

  /// Get cached config or default
  LaunchConfig get config => _cachedConfig ?? LaunchConfig.defaultConfig();

  /// Whether discount is allowed (from cached config)
  bool get allowDiscount => config.allowDiscount;

  /// Fetch launch configuration from server
  /// Returns LaunchConfig with discount availability status
  /// This method NEVER throws - always returns a valid config
  Future<LaunchConfig> fetchLaunchConfig() async {
    try {
      print('🚀 LaunchService: Starting fetch...');
      
      final response = await _comms.get<Map<String, dynamic>>(
        ApiEndpoints.launch,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('🚀 LaunchService: Request timed out');
          return CommsResponse<Map<String, dynamic>>(
            success: false,
            message: 'Timeout',
          );
        },
      );

      print('🚀 LaunchService: Response success: ${response.success}');
      print('🚀 LaunchService: Response data: ${response.rawData}');

      if (response.success && response.rawData != null) {
        final responseData = response.rawData!;

        if (responseData['status'] == 'success' && responseData['data'] != null) {
          try {
            final dataList = responseData['data'] as List<dynamic>;
            if (dataList.isNotEmpty) {
              final configData = dataList[0] as Map<String, dynamic>;
              _cachedConfig = LaunchConfig.fromJson(configData);
              print('🚀 LaunchService: Allow discount: ${_cachedConfig!.allowDiscount}');
              print('🚀 LaunchService: Server version: ${_cachedConfig!.version}');
              return _cachedConfig!;
            }
          } catch (parseError) {
            print('🚀 LaunchService: Parse error: $parseError');
          }
        }
      }

      // Return default config if response is not as expected
      print('🚀 LaunchService: Using default config');
      _cachedConfig = LaunchConfig.defaultConfig();
      return _cachedConfig!;
    } catch (e, stackTrace) {
      print('🚀 LaunchService: Error fetching launch config: $e');
      print('🚀 LaunchService: Stack trace: $stackTrace');
      // Return default config on error - no discount
      _cachedConfig = LaunchConfig.defaultConfig();
      return _cachedConfig!;
    }
  }

  /// Clear cached config (useful for refresh)
  void clearCache() {
    _cachedConfig = null;
  }
}
