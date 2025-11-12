import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final storage = await LocalStorageService.getInstance();
    final mode = storage.getThemeMode();
    state = mode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    
    final storage = await LocalStorageService.getInstance();
    await storage.saveThemeMode(newMode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    
    final storage = await LocalStorageService.getInstance();
    await storage.saveThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
