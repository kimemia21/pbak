import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static const String _keyUser = 'user';
  static const String _keyToken = 'token';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyOnboardingComplete = 'onboarding_complete';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // User
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString(_keyUser, jsonEncode(user));
  }

  Map<String, dynamic>? getUser() {
    final userStr = _prefs.getString(_keyUser);
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  Future<void> clearUser() async {
    await _prefs.remove(_keyUser);
  }

  // Token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  String? getToken() {
    return _prefs.getString(_keyToken);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_keyToken);
  }

  // Theme Mode
  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'light';
  }

  // Onboarding
  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setBool(_keyOnboardingComplete, complete);
  }

  bool isOnboardingComplete() {
    return _prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
