import 'package:flutter/material.dart';

/// Theme cho Notes theo phong cách Ocean Mint - mát, hiện đại, dễ nhìn lâu
class NoteTheme {
  // Colors - Ocean Mint theme
  static const Color background = Color(0xFFF6F8FC); // nền sáng xanh nhạt
  static const Color surface = Color(0xFFFFFFFF); // trắng
  static const Color textPrimary = Color(0xFF0F172A); // đen xanh đậm
  static const Color textSecondary = Color(0xFF64748B); // xám xanh
  static const Color border = Color(0xFFE6EAF2); // viền xanh nhạt
  
  // Primary colors
  static const Color primaryBlue = Color(0xFF2F80FF); // xanh dương đậm
  static const Color accentMint = Color(0xFF2DD4BF); // xanh mint
  
  // State colors
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF60A5FA);
  
  // Theme specific colors
  static const Color activePillBackground = Color(0xFFEAF2FF); // nền pill active
  static const Color accentBackground = Color(0xFFE6FFFB); // nền accent nhẹ
  
  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF111827).withOpacity(0.08),
      offset: const Offset(0, 6),
      blurRadius: 18,
    ),
  ];
  
  static List<BoxShadow> get cardShadowHover => [
    BoxShadow(
      color: const Color(0xFF111827).withOpacity(0.12),
      offset: const Offset(0, 10),
      blurRadius: 24,
    ),
  ];
  
  static List<BoxShadow> get fabShadow => [
    BoxShadow(
      color: const Color(0xFF111827).withOpacity(0.18),
      offset: const Offset(0, 10),
      blurRadius: 30,
    ),
  ];
  
  // Border radius
  static const double cardRadius = 20.0;
  static const double bottomSheetRadius = 24.0;
  static const double chipRadius = 999.0; // pill
  static const double inputRadius = 16.0;
  
  // Spacing (8pt grid)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Typography
  static const TextStyle pageTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle noteTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle notePreview = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.5,
  );
  
  static const TextStyle chipText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle helperText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );
  
  // Gradient background - Ocean Mint
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF6F8FC), // background
      Color(0xFFFFFFFF), // trắng
      Color(0xFFF6F8FC), // background
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Primary gradient (cho FAB, buttons)
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2F80FF), // primary blue
      Color(0xFF2DD4BF), // accent mint
    ],
  );
  
  // Light gradient (cho background nhẹ)
  static LinearGradient get lightGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEAF2FF), // blue light
      Color(0xFFE6FFFB), // mint light
    ],
  );
}

