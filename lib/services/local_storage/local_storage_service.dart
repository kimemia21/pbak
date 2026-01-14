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

  // Onboarding / First Launch
  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setBool(_keyOnboardingComplete, complete);
  }

  bool isOnboardingComplete() {
    return _prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  /// True if this is the first time the app is opened on this device.
  bool isFirstLaunch() {
    return !(_prefs.getBool(_keyOnboardingComplete) ?? false);
  }

  /// Call this once after the first launch has been handled.
  Future<void> markFirstLaunchHandled() async {
    await _prefs.setBool(_keyOnboardingComplete, true);
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

  // Registration mode: if true, user started registration via "Register with PBAK" promo
  // and we should skip ID/document image uploads.
  static const String _keyRegisterWithPbak = 'register_with_pbak';

  Future<void> setRegisterWithPbak(bool value) async {
    await _prefs.setBool(_keyRegisterWithPbak, value);
  }

  bool isRegisterWithPbak() {
    return _prefs.getBool(_keyRegisterWithPbak) ?? false;
  }

  Future<void> clearRegisterWithPbak() async {
    await _prefs.remove(_keyRegisterWithPbak);
  }

  Future<void> saveRegistrationProgress(
    Map<String, dynamic> progressData,
  ) async {
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
  // WARNING: This stores password temporarily for auto-fill after registration
  // Password is cleared immediately after first login attempt
  static const String _keyRegisteredEmail = 'registered_email';
  static const String _keyRegisteredPassword = 'registered_password';
  static const String _keyIsRegistered = 'is_registered';

  Future<void> saveRegisteredCredentials(String email, String password) async {
    await _prefs.setString(_keyRegisteredEmail, email);
    await _prefs.setString(_keyRegisteredPassword, password);
    await _prefs.setBool(_keyIsRegistered, true);
  }

  String? getRegisteredEmail() {
    return _prefs.getString(_keyRegisteredEmail);
  }

  String? getRegisteredPassword() {
    return _prefs.getString(_keyRegisteredPassword);
  }

  bool isUserRegistered() {
    return _prefs.getBool(_keyIsRegistered) ?? false;
  }

  Future<void> clearRegisteredCredentials() async {
    await _prefs.remove(_keyRegisteredEmail);
    await _prefs.remove(_keyRegisteredPassword);
    await _prefs.remove(_keyIsRegistered);
  }

  // Paid Events & Products (for registration flow)
  static const String _keyPaidEventIds = 'paid_event_ids';
  static const String _keyPaidProductIds = 'paid_product_ids';

  /// Save a paid event ID
  Future<void> addPaidEventId(int eventId) async {
    final ids = getPaidEventIds();
    if (!ids.contains(eventId)) {
      ids.add(eventId);
      await _prefs.setStringList(
        _keyPaidEventIds,
        ids.map((e) => e.toString()).toList(),
      );
    }
  }

  /// Get all paid event IDs
  List<int> getPaidEventIds() {
    final list = _prefs.getStringList(_keyPaidEventIds) ?? [];
    return list.map((e) => int.tryParse(e)).whereType<int>().toList();
  }

  /// Check if an event is already paid
  bool isEventPaid(int eventId) {
    return getPaidEventIds().contains(eventId);
  }

  /// Save paid product IDs for an event
  Future<void> addPaidProductIds(int eventId, List<int> productIds) async {
    final allPaid = getPaidProductIdsMap();
    final existing = allPaid[eventId] ?? <int>[];
    for (final pid in productIds) {
      if (!existing.contains(pid)) {
        existing.add(pid);
      }
    }
    allPaid[eventId] = existing;
    await _prefs.setString(
      _keyPaidProductIds,
      jsonEncode(allPaid.map((k, v) => MapEntry(k.toString(), v))),
    );
  }

  /// Get map of eventId -> List<productId> for all paid products
  Map<int, List<int>> getPaidProductIdsMap() {
    final str = _prefs.getString(_keyPaidProductIds);
    if (str == null) return {};
    try {
      final decoded = jsonDecode(str) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(
          int.tryParse(k) ?? 0,
          (v as List)
              .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .toList(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  /// Get paid product IDs for a specific event
  List<int> getPaidProductIds(int eventId) {
    return getPaidProductIdsMap()[eventId] ?? [];
  }

  /// Check if a product is already paid
  bool isProductPaid(int eventId, int productId) {
    return getPaidProductIds(eventId).contains(productId);
  }

  /// Clear all paid event/product data
  Future<void> clearPaidData() async {
    await _prefs.remove(_keyPaidEventIds);
    await _prefs.remove(_keyPaidProductIds);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
