import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/remote_config_service.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._internal();
  static final ThemeController instance = ThemeController._internal();
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load({required RemoteConfigService rc}) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved == null && rc.useRemoteTheme) {
      _mode = rc.remoteThemeMode;
    } else {
      _mode = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });
    notifyListeners();
  }

  Future<void> clearUserPreferenceAndFollowRemote(RemoteConfigService rc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('theme_mode');
    _mode = rc.remoteThemeMode;
    notifyListeners();
  }
}
