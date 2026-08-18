import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cadence design system — deep plum, sage, dusty rose and amber,
/// paired with Fraunces (display), Public Sans (body) and IBM Plex Mono (data).
class AppColors {
  static const Color ink = Color(0xFF241C2E);
  static const Color plum = Color(0xFF4A2E5C);
  static const Color plumDeep = Color(0xFF341F41);
  static const Color sage = Color(0xFF7C9885);
  static const Color sageLight = Color(0xFFA9C2AE);
  static const Color sand = Color(0xFFF5EFE6);
  static const Color sandDeep = Color(0xFFEDE3D3);
  static const Color rose = Color(0xFFB5657A);
  static const Color amber = Color(0xFFD9A24B);
  static const Color white = Color(0xFFFFFEFC);
  static const Color muted = Color(0xFF9C93A8);
}

class AppText {
  static TextStyle display({required BuildContext context, double size = 24, FontWeight weight = FontWeight.w600, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color ?? (isDark ? Colors.white : AppColors.ink));
  }

  static TextStyle body({required BuildContext context, double size = 14, FontWeight weight = FontWeight.w400, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.publicSans(fontSize: size, fontWeight: weight, color: color ?? (isDark ? Colors.white70 : AppColors.ink));
  }

  static TextStyle mono({required BuildContext context, double size = 12, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.ibmPlexMono(fontSize: size, color: color ?? (isDark ? AppColors.sageLight : AppColors.plum));
  }
}

ThemeData buildAppTheme({bool isDark = false}) {
  final textColor = isDark ? AppColors.white : AppColors.ink;
  return ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : AppColors.sand,
    cardColor: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
    fontFamily: GoogleFonts.publicSans().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.plum,
      brightness: isDark ? Brightness.dark : Brightness.light,
      surface: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
    ),
    useMaterial3: true,
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.publicSans(color: textColor),
      bodyMedium: GoogleFonts.publicSans(color: textColor),
      displayLarge: GoogleFonts.fraunces(color: textColor),
      displayMedium: GoogleFonts.fraunces(color: textColor),
      displaySmall: GoogleFonts.fraunces(color: textColor),
    ),
  );
}
