import 'package:flutter/material.dart';

/// Art Finance Hub Color Palette
/// Matching the landing page design at artfinhub.com
///
/// Design System based on HSL values from the landing page:
/// - Primary (Teal): HSL(168, 55%, 40%)
/// - Accent (Gold): HSL(28, 87%, 67%)
/// - Background (Cream): HSL(45, 20%, 98%)
/// - Foreground (Dark Teal): HSL(180, 25%, 15%)
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY COLORS (Teal - Artistic & Professional)
  // ============================================

  /// Primary teal color - main brand color
  /// HSL(168, 55%, 40%) → #2E9A85
  static const Color primary = Color(0xFF2E9A85);

  /// Light variant for hover states and backgrounds
  /// HSL(168, 55%, 50%) → #3FC0A8
  static const Color primaryLight = Color(0xFF3FC0A8);

  /// Dark variant for pressed states
  /// HSL(168, 55%, 30%) → #237563
  static const Color primaryDark = Color(0xFF237563);

  /// Very light primary for subtle backgrounds
  /// HSL(168, 55%, 95%) → #E8F7F4
  static const Color primarySurface = Color(0xFFE8F7F4);

  // ============================================
  // ACCENT COLORS (Gold/Orange - Warm & Creative)
  // ============================================

  /// Accent gold/orange - CTAs, highlights, important elements
  /// HSL(28, 87%, 67%) → #F5A54A
  static const Color accent = Color(0xFFF5A54A);

  /// Light accent for hover
  /// HSL(28, 87%, 75%) → #F8C078
  static const Color accentLight = Color(0xFFF8C078);

  /// Dark accent for pressed states
  /// HSL(28, 87%, 55%) → #E8872A
  static const Color accentDark = Color(0xFFE8872A);

  /// Very light accent for backgrounds
  /// HSL(28, 87%, 95%) → #FEF5EB
  static const Color accentSurface = Color(0xFFFEF5EB);

  // ============================================
  // BACKGROUND COLORS
  // ============================================

  /// Main background - warm cream
  /// HSL(45, 20%, 98%) → #FCFBF9
  static const Color background = Color(0xFFFCFBF9);

  /// Card/Surface background - pure white
  static const Color surface = Color(0xFFFFFFFF);

  /// Secondary background - slightly darker cream
  /// HSL(45, 20%, 92%) → #F0EDE7
  static const Color muted = Color(0xFFF0EDE7);

  // ============================================
  // TEXT COLORS
  // ============================================

  /// Primary text - dark teal
  /// HSL(180, 25%, 15%) → #1D2F2E
  static const Color textPrimary = Color(0xFF1D2F2E);

  /// Secondary text - muted teal
  /// HSL(180, 15%, 40%) → #577370
  static const Color textSecondary = Color(0xFF577370);

  /// Muted/disabled text
  /// HSL(180, 10%, 55%) → #7E9290
  static const Color textMuted = Color(0xFF7E9290);

  /// Inverse text (on dark backgrounds)
  static const Color textInverse = Color(0xFFFFFFFF);

  // ============================================
  // BORDER & DIVIDER COLORS
  // ============================================

  /// Subtle border color
  /// HSL(180, 15%, 85%) → #D4DEDD
  static const Color border = Color(0xFFD4DEDD);

  /// Slightly darker border for inputs
  /// HSL(180, 15%, 75%) → #B5C5C3
  static const Color inputBorder = Color(0xFFB5C5C3);

  // ============================================
  // SEMANTIC COLORS
  // ============================================

  /// Destructive/Error - Red
  /// HSL(0, 84%, 60%) → #EF4444
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveLight = Color(0xFFFEE2E2);

  /// Success - Green (using primary tint)
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);

  /// Warning - Amber (using accent tint)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  /// Info - Blue
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ============================================
  // INCOME & EXPENSE COLORS
  // ============================================

  /// Income color - green tint of primary
  static const Color income = Color(0xFF22C55E);

  /// Expense color - warm red
  static const Color expense = Color(0xFFEF4444);

  // ============================================
  // DARK MODE COLORS
  // ============================================

  /// Dark mode background
  /// HSL(180, 25%, 8%) → #101A1A
  static const Color darkBackground = Color(0xFF101A1A);

  /// Dark mode surface/card
  /// HSL(180, 20%, 12%) → #171F1F
  static const Color darkSurface = Color(0xFF171F1F);

  /// Dark mode muted
  /// HSL(180, 20%, 18%) → #253130
  static const Color darkMuted = Color(0xFF253130);

  /// Dark mode text
  /// HSL(45, 20%, 95%) → #F7F6F3
  static const Color darkTextPrimary = Color(0xFFF7F6F3);

  /// Dark mode secondary text
  /// HSL(45, 15%, 60%) → #A69F8F
  static const Color darkTextSecondary = Color(0xFFA69F8F);

  /// Dark mode border
  /// HSL(180, 15%, 20%) → #2B3938
  static const Color darkBorder = Color(0xFF2B3938);

  /// Dark mode primary (slightly brighter)
  /// HSL(168, 55%, 45%) → #36AD96
  static const Color darkPrimary = Color(0xFF36AD96);

  /// Dark mode accent (slightly adjusted)
  /// HSL(28, 87%, 60%) → #F29727
  static const Color darkAccent = Color(0xFFF29727);

  // ============================================
  // GRADIENTS
  // ============================================

  /// Primary gradient (teal)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  /// Accent gradient (gold)
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );

  /// Primary to Accent gradient (artistic blend)
  static const LinearGradient artisticGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, accentLight],
  );

  /// Subtle background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, muted],
  );

  // ============================================
  // SHADOW COLORS
  // ============================================

  /// Card shadow color
  static Color cardShadow = textPrimary.withValues(alpha: 0.08);

  /// Card hover shadow color
  static Color cardShadowHover = textPrimary.withValues(alpha: 0.12);

  /// Accent glow for highlighted elements
  static Color accentGlow = accent.withValues(alpha: 0.2);

  // ============================================
  // COLOR SCHEME BUILDERS
  // ============================================

  /// Light theme ColorScheme
  static ColorScheme get lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: textInverse,
        primaryContainer: primarySurface,
        onPrimaryContainer: primaryDark,
        secondary: accent,
        onSecondary: textPrimary,
        secondaryContainer: accentSurface,
        onSecondaryContainer: accentDark,
        tertiary: primaryLight,
        onTertiary: textInverse,
        tertiaryContainer: primarySurface,
        onTertiaryContainer: primaryDark,
        error: destructive,
        onError: textInverse,
        errorContainer: destructiveLight,
        onErrorContainer: destructive,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: muted,
        onSurfaceVariant: textSecondary,
        outline: border,
        outlineVariant: inputBorder,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: textPrimary,
        onInverseSurface: textInverse,
        inversePrimary: primaryLight,
      );

  /// Dark theme ColorScheme
  static ColorScheme get darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: textInverse,
        primaryContainer: primaryDark,
        onPrimaryContainer: primaryLight,
        secondary: darkAccent,
        onSecondary: textPrimary,
        secondaryContainer: accentDark,
        onSecondaryContainer: accentLight,
        tertiary: primaryLight,
        onTertiary: textPrimary,
        tertiaryContainer: primaryDark,
        onTertiaryContainer: primaryLight,
        error: destructive,
        onError: textInverse,
        errorContainer: Color(0xFF5C1B1B),
        onErrorContainer: destructiveLight,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        surfaceContainerHighest: darkMuted,
        onSurfaceVariant: darkTextSecondary,
        outline: darkBorder,
        outlineVariant: darkMuted,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: darkTextPrimary,
        onInverseSurface: darkBackground,
        inversePrimary: primary,
      );
}
