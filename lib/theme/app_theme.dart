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
  static TextStyle display({double size = 24, FontWeight weight = FontWeight.w600, Color color = AppColors.ink}) {
    return GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color);
  }

  static TextStyle body({double size = 14, FontWeight weight = FontWeight.w400, Color color = AppColors.ink}) {
    return GoogleFonts.publicSans(fontSize: size, fontWeight: weight, color: color);
  }

  static TextStyle mono({double size = 12, Color color = AppColors.plum}) {
    return GoogleFonts.ibmPlexMono(fontSize: size, color: color);
  }
}

ThemeData buildAppTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.sand,
    fontFamily: GoogleFonts.publicSans().fontFamily,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.plum, brightness: Brightness.light),
    useMaterial3: true,
  );
}
