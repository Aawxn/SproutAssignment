import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  Sprout Design System — Colors
// ─────────────────────────────────────────────

// Brand greens
const kSproutGreen      = Color(0xFF3DAA6E);
const kSproutGreenLight = Color(0xFF71C995);
const kSproutGreenDark  = Color(0xFF236B45);

// Accent palette — slightly desaturated for a less "vibe coded" feel
const kSunshineYellow = Color(0xFFFFBF47);
const kSkyBlue        = Color(0xFF4BAED4);
const kCoralPink      = Color(0xFFE8624A);
const kSoftPurple     = Color(0xFF8A7EC8);
const kOrange         = Color(0xFFE8894A);
const kTeal           = Color(0xFF3ABCB0);

// Backgrounds
const kWarmCream  = Color(0xFFF7F4EF);  // Slightly warmer, less yellow
const kDeepCream  = Color(0xFFEEE8DF);
const kCardWhite  = Color(0xFFFFFFFF);

// Text
const kTextDark   = Color(0xFF1E2026);
const kTextMedium = Color(0xFF5A5F6A);
const kTextLight  = Color(0xFF9099A8);

// Activity accent colors
const kShapeColor  = kSkyBlue;
const kCountColor  = kSunshineYellow;
const kColorColor  = kCoralPink;
const kTraceColor  = kSoftPurple;
const kAnimalColor = kSproutGreen;
const kCameraColor = kTeal;

// ─────────────────────────────────────────────
//  Sprout Design System — Typography (Nunito)
// ─────────────────────────────────────────────

TextStyle get kTitleStyle => GoogleFonts.nunito(
  fontSize: 28,
  fontWeight: FontWeight.w800,
  color: kTextDark,
  letterSpacing: -0.3,
  height: 1.15,
);

TextStyle get kHeadingStyle => GoogleFonts.nunito(
  fontSize: 22,
  fontWeight: FontWeight.w700,
  color: kTextDark,
  height: 1.2,
);

TextStyle get kBodyStyle => GoogleFonts.nunito(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: kTextMedium,
  height: 1.3,
);

TextStyle get kSmallBodyStyle => GoogleFonts.nunito(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: kTextMedium,
  height: 1.3,
);

TextStyle get kLabelStyle => GoogleFonts.nunito(
  fontSize: 18,
  fontWeight: FontWeight.w800,
  color: kTextDark,
);

TextStyle get kActivityPromptStyle => GoogleFonts.nunito(
  fontSize: 22,
  fontWeight: FontWeight.w800,
  color: kTextDark,
  height: 1.2,
);

TextStyle get kNumberStyle => GoogleFonts.nunito(
  fontSize: 40,
  fontWeight: FontWeight.w900,
  color: kTextDark,
  height: 1,
);

// ─────────────────────────────────────────────
//  Sprout Design System — Dimensions
// ─────────────────────────────────────────────
const double kMinTapTarget  = 72.0;  // Generous but not overdone
const double kBorderRadius  = 20.0;
const double kCardRadius    = 16.0;
const double kSpacingXS     =  4.0;
const double kSpacingS      =  8.0;
const double kSpacingM      = 14.0;
const double kSpacingL      = 20.0;
const double kSpacingXL     = 32.0;

// ─────────────────────────────────────────────
//  Shadows
// ─────────────────────────────────────────────
List<BoxShadow> kCardShadow(Color color) => [
  BoxShadow(
    color: color.withValues(alpha: 0.25),
    blurRadius: 14,
    offset: const Offset(0, 6),
  ),
];

List<BoxShadow> get kSoftShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.07),
    blurRadius: 10,
    offset: const Offset(0, 3),
  ),
];

// ─────────────────────────────────────────────
//  ThemeData
// ─────────────────────────────────────────────
ThemeData buildSproutTheme() {
  final base = GoogleFonts.nunitoTextTheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kSproutGreen,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: kWarmCream,
    textTheme: base,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        textStyle: kLabelStyle,
      ),
    ),
  );
}
