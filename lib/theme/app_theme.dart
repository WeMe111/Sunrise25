import 'package:flutter/material.dart';

class AppColors {
  // Primary - Premium dark
  static const Color primary = Color(0xFF1B2838);
  static const Color primaryDark = Color(0xFF111927);
  static const Color primaryLight = Color(0xFF2C3E50);

  // Secondary - Emerald green (premium)
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF6EE7B7);
  static const Color secondaryDark = Color(0xFF059669);

  // Accent - Indigo (luxurious)
  static const Color accent = Color(0xFF6366F1);
  static const Color accentLight = Color(0xFFA5B4FC);
  static const Color accentWarm = Color(0xFFF59E0B);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Neutral
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;

  // Category
  static const Color categoryNotice = Color(0xFF3B82F6);
  static const Color categoryEducation = Color(0xFF10B981);
  static const Color categoryEvent = Color(0xFFF59E0B);
}

class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get medium => [
    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get elevated => [
    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 16)),
    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(color: color.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 4)),
  ];
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.secondary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: AppColors.background,
      );
}
