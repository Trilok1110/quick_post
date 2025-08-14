import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  late final FirebaseRemoteConfig _rc;

  Future<void> init() async {
    _rc = FirebaseRemoteConfig.instance;

    await _rc.setDefaults({
      'use_remote_theme': false,
      'theme_mode': 'system',
      'seed_color': '#4B69FF',
      'accent_color': '#FF61A6',
      'surface_bg': '#F7F8FA',
      'surface_bg_dark': '#0E1116',
      'font_family': 'Roboto',
    });

    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(seconds: 30), // dev; increase in prod
    ));

    await fetchAndActivate();
  }

  Future<bool> fetchAndActivate() async {
    try {
      return await _rc.fetchAndActivate();
    } catch (_) {
      return false;
    }
  }

  // Typed getters
  bool get useRemoteTheme => _rc.getBool('use_remote_theme');

  ThemeMode get remoteThemeMode {
    final v = _rc.getString('theme_mode').toLowerCase();
    return v == 'light' ? ThemeMode.light : v == 'dark' ? ThemeMode.dark : ThemeMode.system;
  }

  String get fontFamily => _rc.getString('font_family');

  Color get seedColor => _parseHex(_rc.getString('seed_color'), fallback: const Color(0xFF4B69FF));
  Color get accentColor => _parseHex(_rc.getString('accent_color'), fallback: const Color(0xFFFF61A6));
  Color get surfaceBg => _parseHex(_rc.getString('surface_bg'), fallback: const Color(0xFFF7F8FA));
  Color get surfaceBgDark => _parseHex(_rc.getString('surface_bg_dark'), fallback: const Color(0xFF0E1116));

  Color _parseHex(String hex, {required Color fallback}) {
    final v = hex.replaceAll('#', '');
    if (v.length == 6) {
      return Color(int.parse('FF$v', radix: 16));
    }
    if (v.length == 8) {
      return Color(int.parse(v, radix: 16));
    }
    return fallback;
  }
}
