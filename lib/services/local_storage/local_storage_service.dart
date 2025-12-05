import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static const String _keyUser = 'user';
  static const String _keyToken = 'token';
  static const String _keyRefreshToken = 'refresh_token';
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

  // Refresh Token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _prefs.setString(_keyRefreshToken, refreshToken);
  }

  String? getRefreshToken() {
    return _prefs.getString(_keyRefreshToken);
  }

  Future<void> clearRefreshToken() async {
    await _prefs.remove(_keyRefreshToken);
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

  // Trip Data
  static const String _keyCurrentTrip = 'current_trip';
  static const String _keyTripHistory = 'trip_history';
  
  Future<void> saveCurrentTrip(Map<String, dynamic> tripData) async {
    await _prefs.setString(_keyCurrentTrip, jsonEncode(tripData));
  }
  
  Map<String, dynamic>? getCurrentTrip() {
    final tripStr = _prefs.getString(_keyCurrentTrip);
    if (tripStr != null) {
      return jsonDecode(tripStr);
    }
    return null;
  }
  
  Future<void> clearCurrentTrip() async {
    await _prefs.remove(_keyCurrentTrip);
  }
  
  Future<void> saveTripToHistory(Map<String, dynamic> tripData) async {
    final history = getTripHistory();
    history.insert(0, tripData);
    // Keep only last 100 trips
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    await _prefs.setString(_keyTripHistory, jsonEncode(history));
  }
  
  List<Map<String, dynamic>> getTripHistory() {
    final historyStr = _prefs.getString(_keyTripHistory);
    if (historyStr != null) {
      final List<dynamic> decoded = jsonDecode(historyStr);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }
  
  Future<void> clearTripHistory() async {
    await _prefs.remove(_keyTripHistory);
  }

  // Registration Progress
  static const String _keyRegistrationProgress = 'registration_progress';
  
  Future<void> saveRegistrationProgress(Map<String, dynamic> progressData) async {
    await _prefs.setString(_keyRegistrationProgress, jsonEncode(progressData));
  }
  
  Map<String, dynamic>? getRegistrationProgress() {
    final progressStr = _prefs.getString(_keyRegistrationProgress);
    if (progressStr != null) {
      return jsonDecode(progressStr);
    }
    return null;
  }
  
  Future<void> clearRegistrationProgress() async {
    await _prefs.remove(_keyRegistrationProgress);
  }

  // Saved Login Credentials (for registered users only)
  static const String _keyRegisteredEmail = 'registered_email';
  static const String _keyIsRegistered = 'is_registered';
  
  Future<void> saveRegisteredCredentials(String email) async {
    await _prefs.setString(_keyRegisteredEmail, email);
    await _prefs.setBool(_keyIsRegistered, true);
  }
  
  String? getRegisteredEmail() {
    return _prefs.getString(_keyRegisteredEmail);
  }
  
  bool isUserRegistered() {
    return _prefs.getBool(_keyIsRegistered) ?? false;
  }
  
  Future<void> clearRegisteredCredentials() async {
    await _prefs.remove(_keyRegisteredEmail);
    await _prefs.remove(_keyIsRegistered);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
