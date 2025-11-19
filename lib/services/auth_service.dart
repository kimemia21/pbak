import 'package:pbak/models/user_model.dart';
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';

/// Authentication Service
/// Handles all authentication-related API calls
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _comms = CommsService.instance;

  /// Login user with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 AuthService: Attempting login for $email');
      
      final response = await _comms.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      print('📥 AuthService: Response success: ${response.success}');
      print('📥 AuthService: Response data: ${response.rawData}');

      if (response.success && response.rawData != null) {
        final responseData = response.rawData!;
        
        print('📦 AuthService: Response status: ${responseData['status']}');
        
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          final memberData = data['member'] as Map<String, dynamic>?;
          final token = data['token'] as String?;
          final refreshToken = data['refreshToken'] as String?;

          print('👤 AuthService: Member data: $memberData');
          print('🔑 AuthService: Token: ${token?.substring(0, 20)}...');

          if (memberData != null && token != null) {
            final user = UserModel.fromJson(memberData);
            
            print('✅ AuthService: User created: ${user.fullName}');
            
            // Save to local storage
            final storage = await LocalStorageService.getInstance();
            await storage.saveUser(user.toJson());
            await storage.saveToken(token);
            if (refreshToken != null) {
              await storage.saveRefreshToken(refreshToken);
            }
            
            // Set auth token for future requests
            _comms.setAuthToken(token);

            print('✅ AuthService: Login successful for ${user.fullName}');
            return AuthResult.success(user: user, token: token);
          }
        }
      }
      
      print('❌ AuthService: Login failed - ${response.message}');
      return AuthResult.failure(
        message: response.message ?? 'Login failed. Please check your credentials.',
      );
    } catch (e) {
      print('❌ AuthService: Login error - $e');
      return AuthResult.failure(message: e.toString());
    }
  }

  /// Register new user
  Future<AuthResult> register(Map<String, dynamic> userData) async {
    try {
      final response = await _comms.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: userData,
      );

      if (response.success && response.rawData != null) {
        final responseData = response.rawData!;
        
        if (responseData['status'] == 'success') {
          final data = responseData['data'] as Map<String, dynamic>?;
          
          if (data != null && data.containsKey('token') && data.containsKey('member')) {
            // Auto-login after registration
            final user = UserModel.fromJson(data['member']);
            final token = data['token'] as String;
            final refreshToken = data['refreshToken'] as String?;

            final storage = await LocalStorageService.getInstance();
            await storage.saveUser(user.toJson());
            await storage.saveToken(token);
            if (refreshToken != null) {
              await storage.saveRefreshToken(refreshToken);
            }
            
            _comms.setAuthToken(token);

            return AuthResult.success(user: user, token: token);
          } else {
            // Registration successful but no auto-login
            return AuthResult.success(
              message: responseData['message'] ?? 'Registration successful',
            );
          }
        }
      }
      
      return AuthResult.failure(
        message: response.message ?? 'Registration failed. Please try again.',
      );
    } catch (e) {
      return AuthResult.failure(message: e.toString());
    }
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      await _comms.post(ApiEndpoints.logout);
    } catch (e) {
      // Continue with local logout even if API call fails
    }
    
    // Clear local data
    final storage = await LocalStorageService.getInstance();
    await storage.clearUser();
    await storage.clearToken();
    await storage.clearRefreshToken();
    
    // Remove auth token from CommsService
    _comms.removeAuthToken();
    
    return true;
  }

  /// Refresh authentication token
  Future<AuthResult> refreshToken() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final refreshToken = storage.getRefreshToken();
      
      if (refreshToken == null) {
        return AuthResult.failure(message: 'No refresh token available');
      }

      final response = await _comms.post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.success && response.data != null) {
        final token = response.data!['token'] as String?;
        final newRefreshToken = response.data!['refreshToken'] as String?;

        if (token != null) {
          await storage.saveToken(token);
          if (newRefreshToken != null) {
            await storage.saveRefreshToken(newRefreshToken);
          }
          
          _comms.setAuthToken(token);
          
          return AuthResult.success(token: token);
        }
      }
      
      return AuthResult.failure(message: 'Failed to refresh token');
    } catch (e) {
      return AuthResult.failure(message: e.toString());
    }
  }

  /// Forgot password - send reset email
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _comms.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Reset password with token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _comms.post(
        ApiEndpoints.resetPassword,
        data: {
          'token': token,
          'password': newPassword,
        },
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Verify email with token
  Future<bool> verifyEmail(String token) async {
    try {
      final response = await _comms.post(
        ApiEndpoints.verifyEmail,
        data: {'token': token},
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Get current user from local storage
  Future<UserModel?> getCurrentUser() async {
    final storage = await LocalStorageService.getInstance();
    final userJson = storage.getUser();
    
    if (userJson != null) {
      return UserModel.fromJson(userJson);
    }
    return null;
  }
}

/// Authentication result wrapper
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? token;
  final String? message;

  AuthResult._({
    required this.success,
    this.user,
    this.token,
    this.message,
  });

  factory AuthResult.success({
    UserModel? user,
    String? token,
    String? message,
  }) {
    return AuthResult._(
      success: true,
      user: user,
      token: token,
      message: message,
    );
  }

  factory AuthResult.failure({required String message}) {
    return AuthResult._(
      success: false,
      message: message,
    );
  }
}
