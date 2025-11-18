import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/user_model.dart';
import 'package:pbak/services/auth_service.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';

// Service provider
final authServiceProvider = Provider((ref) => AuthService());

// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = const AsyncValue.data(null);
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result.success && result.user != null) {
        state = AsyncValue.data(result.user);
        return true;
      }
      
      state = AsyncValue.error(
        Exception(result.message ?? 'Login failed. Please check your credentials.'),
        StackTrace.current,
      );
      return false;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.register(userData);

      if (result.success) {
        if (result.user != null) {
          state = AsyncValue.data(result.user);
        } else {
          state = const AsyncValue.data(null);
        }
        return true;
      }
      
      state = AsyncValue.error(
        Exception(result.message ?? 'Registration failed. Please try again.'),
        StackTrace.current,
      );
      return false;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    final storage = await LocalStorageService.getInstance();
    await storage.saveUser(updatedUser.toJson());
    state = AsyncValue.data(updatedUser);
  }

  Future<void> refreshAuth() async {
    await _checkAuth();
  }
}
