import 'package:flutter/material.dart';

class AppTheme {
  // 시니어 최적화 색상 팔레트
  static const Color primaryColor = Color(0xFF1565C0);      // 진한 파랑 (신뢰)
  static const Color safeColor = Color(0xFF2E7D32);          // 진한 초록 (안전)
  static const Color warningColor = Color(0xFFF57F17);       // 진한 주황 (주의)
  static const Color dangerColor = Color(0xFFC62828);        // 진한 빨강 (위험)
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF555555);

  // 시니어용 큰 폰트 사이즈
  static const double fontSizeXL = 26.0;
  static const double fontSizeLG = 22.0;
  static const double fontSizeMD = 19.0;
  static const double fontSizeSM = 16.0;
  static const double fontSizeXS = 14.0;

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: fontSizeLG,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 3,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMD,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: fontSizeXL, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: TextStyle(fontSize: fontSizeLG, fontWeight: FontWeight.bold, color: textPrimary),
        bodyLarge: TextStyle(fontSize: fontSizeMD, color: textPrimary),
        bodyMedium: TextStyle(fontSize: fontSizeSM, color: textSecondary),
        labelLarge: TextStyle(fontSize: fontSizeMD, fontWeight: FontWeight.bold),
      ),
    );
  }
}
