import 'package:flutter/material.dart';

const Color _background = Color(0xFF0D0D0D);
const Color _surface = Color(0xFF1A1A1A);
const Color _surfaceVariant = Color(0xFF252525);
const Color _accent = Color(0xFFE50914);
const Color _accentSecondary = Color(0xFF7B2FBE);
const Color _onBackground = Color(0xFFFFFFFF);
const Color _onSurface = Color(0xFFE0E0E0);
const Color _onSurfaceMuted = Color(0xFF888888);

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          secondary: _accentSecondary,
          surface: _surface,
          onPrimary: _onBackground,
          onSecondary: _onBackground,
          onSurface: _onSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _background,
          foregroundColor: _onBackground,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _onBackground,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
          labelStyle: const TextStyle(color: _onSurfaceMuted),
          hintStyle: const TextStyle(color: _onSurfaceMuted),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: _onBackground,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: _onBackground, fontWeight: FontWeight.w800),
          displayMedium: TextStyle(color: _onBackground, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: _onBackground, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: _onBackground, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: _onBackground, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: _onSurface, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: _onSurface),
          bodyMedium: TextStyle(color: _onSurface),
          bodySmall: TextStyle(color: _onSurfaceMuted),
          labelSmall: TextStyle(color: _onSurfaceMuted),
        ),
        dividerTheme: const DividerThemeData(color: _surfaceVariant),
        iconTheme: const IconThemeData(color: _onSurface),
        extensions: const [JellyColors()],
      );
}

class JellyColors extends ThemeExtension<JellyColors> {
  const JellyColors();

  final Color background = _background;
  final Color surface = _surface;
  final Color surfaceVariant = _surfaceVariant;
  final Color accent = _accent;
  final Color accentSecondary = _accentSecondary;
  final Color muted = _onSurfaceMuted;

  @override
  JellyColors copyWith() => this;

  @override
  JellyColors lerp(ThemeExtension<JellyColors>? other, double t) => this;
}
