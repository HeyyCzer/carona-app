import 'package:flutter/material.dart';

/// Paleta extraída do protótipo.
class AppColors {
  static const primary = Color(0xFF7054D8);
  static const primarySoft = Color(0xFFE8E5F4);
  static const primaryDisabled = Color(0xFFD9D3F5);
  static const background = Color(0xFFF5F7FF);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF4F6F9);
  static const text = Color(0xFF0F1226);
  static const textMuted = Color(0xFF6B7090);
  static const textHint = Color(0xFFAAAAC0);
  static const border = Color(0xFFE8E5F4);
  static const success = Color(0xFF18B26B);
  static const warning = Color(0xFFF5A524);
  static const danger = Color(0xFFF23F43);
  static const mapGreen = Color(0xFFD3EFD9);
  static const bubbleIncoming = Color(0xFFD9D9DC);
}

class AppRadius {
  static const card = 20.0;
  static const field = 18.0;
  static const button = 18.0;
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.primarySoft,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

/// Título grande usado no topo das telas ("Sua carona para o futuro.").
const headlineStyle = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  height: 1.15,
  color: AppColors.text,
  letterSpacing: -0.5,
);

const sectionTitleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text);
const mutedStyle = TextStyle(fontSize: 13, color: AppColors.textMuted);
