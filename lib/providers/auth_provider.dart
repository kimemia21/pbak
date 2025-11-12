import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/user_model.dart';
import 'package:pbak/services/mock_api/mock_api_service.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final _apiService = MockApiService();

  AuthNotifier() : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final userJson = storage.getUser();
      final token = storage.getToken();

      if (userJson != null && token != null) {
        state = AsyncValue.data(UserModel.fromJson(userJson));
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
      final response = await _apiService.login(email, password);
      final user = UserModel.fromJson(response['user']);
      final token = response['token'];

      final storage = await LocalStorageService.getInstance();
      await storage.saveUser(user.toJson());
      await storage.saveToken(token);

      state = AsyncValue.data(user);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.register(userData);
      final user = UserModel.fromJson(response['user']);
      final token = response['token'];

      final storage = await LocalStorageService.getInstance();
      await storage.saveUser(user.toJson());
      await storage.saveToken(token);

      state = AsyncValue.data(user);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    final storage = await LocalStorageService.getInstance();
    await storage.clearUser();
    await storage.clearToken();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    final storage = await LocalStorageService.getInstance();
    await storage.saveUser(updatedUser.toJson());
    state = AsyncValue.data(updatedUser);
  }
}
