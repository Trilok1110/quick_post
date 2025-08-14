import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Brand colors (fallbacks)
  static const Color seed = Color(0xFF4B69FF);
  static const Color accent = Color(0xFFFF61A6);
  static const Color success = Color(0xFF2EB872);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFE53935);

  // Standard light/dark themes based on local brand seed
  static final ThemeData light = _buildTheme(
    brightness: Brightness.light,
    scheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
    scaffoldBg: const Color(0xFFF7F8FA),
  );

  static final ThemeData dark = _buildTheme(
    brightness: Brightness.dark,
    scheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
    scaffoldBg: const Color(0xFF0E1116),
  );

  // Build theme from Remote Config values
  static ThemeData fromRemote({
    required Brightness brightness,
    required Color seedColor,
    required Color surfaceBg,
  }) {
    final scheme = ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
    return _buildTheme(
      brightness: brightness,
      scheme: scheme,
      scaffoldBg: surfaceBg,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffoldBg,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: scheme.onSurface,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(isDark ? 0.25 : 0.12),
        color: isDark ? const Color(0xFF151A21) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A2029) : scheme.surfaceVariant.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.55)),
        labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isDark ? const Color(0xFF1E252E) : const Color(0xFF1F2937),
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.primary.withOpacity(0.2)),
        backgroundColor: scheme.primary.withOpacity(0.08),
        labelStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: isDark ? const Color(0xFF151A21) : Colors.white,
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: scheme.outline.withOpacity(0.18),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      iconTheme: IconThemeData(color: scheme.onSurface.withOpacity(0.9)),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
