import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    const bg = Color(0xFF070B13);
    const surface = Color(0xFF0B1220);
    const accent = Color(0xFF00E5FF);

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent,
        surface: surface,
        background: bg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
