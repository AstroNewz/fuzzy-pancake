import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_motion.dart';

/// SmashDeck Design System — Stitch UI
/// Navy deep-space base + electric lime-neon accents
/// Matching stitch_smashdeck_badminton_club_manager mockups exactly
class AppTheme {
  // ─── Stitch Primary Palette ────────────────────────────────────────────────
  static const Color limeNeon = Color(0xFFC3F400); // Primary CTA / OVR numbers
  static const Color limeDim = Color(0xFFABD600); // Dimmed lime (fixed-dim)
  static const Color mintTeal = Color(0xFF4EDEA3); // Secondary accent
  static const Color mintEmerald = mintTeal; // Match court emerald
  static const Color mintBright = Color(0xFF6FFBBE); // Secondary fixed

  // ─── Background & Surfaces ────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0A122A); // Main canvas (deep navy)
  static const Color bgDarker = Color(0xFF050D25); // Lowest surface
  static const Color cardDark = Color(0xFF171E37); // Elevated card
  static const Color cardMid = Color(0xFF212942); // container-high
  static const Color cardBright = Color(0xFF313852); // surface-bright
  static const Color surfaceVar =
      Color(0xFF2C344D); // surface-variant / container-highest

  // ─── Borders ──────────────────────────────────────────────────────────────
  static const Color borderDark = Color(0xFF2A3550);
  static const Color borderLight = Color(0xFF8E9379); // outline

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textWhite = Color(0xFFDBE1FF); // on-surface
  static const Color textMuted = Color(0xFFA7B3CA);
  static const Color textMutedDark = Color(0xFF8997B1);

  // ─── Semantic Status ──────────────────────────────────────────────────────
  static const Color errorRed = Color(0xFFFFB4AB); // error
  static const Color gold = Color(0xFFF59E0B);
  static const Color silver = Color(0xFFCBD5E1);
  static const Color bronze = Color(0xFFD97706);

  // ─── Compatibility aliases (old tokens → new) ─────────────────────────────
  static const Color primaryEmerald = limeNeon;
  static const Color primaryBright = limeNeon;
  static const Color primaryNeon = limeNeon;
  static const Color primaryDark = Color(0xFF3C4D00);
  static const Color primaryLight = Color(0xFFC3F400);
  static const Color secondaryCyan = mintTeal;
  static const Color accentPurple = Color(0xFF9C89FF);
  static const Color actionLogMatch = limeNeon;
  static const Color actionAttendance = mintTeal;
  static const Color actionRankings = Color(0xFF9C89FF);
  static const Color actionClubPlayers = Color(0xFFFB923C);
  // cardDarker / textLight used by unrebuilt screens
  static const Color cardDarker = bgDarker;
  static const Color textLight = textWhite;

  // ─── Typography Helpers ───────────────────────────────────────────────────
  static TextStyle chivo({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = textWhite,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.chivo(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle spaceGrotesk({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = textWhite,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle jetBrainsMono({
    double size = 12,
    FontWeight weight = FontWeight.w600,
    Color color = textWhite,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  // Stitch UI Typography Tokens
  static TextStyle get headlineXl =>
      chivo(size: 32, weight: FontWeight.w900, letterSpacing: -0.8);
  static TextStyle get headlineLg =>
      chivo(size: 22, weight: FontWeight.w800, letterSpacing: -0.4);
  static TextStyle get headlineMd =>
      chivo(size: 18, weight: FontWeight.w800, letterSpacing: -0.2);
  static TextStyle get bodyLg =>
      spaceGrotesk(size: 15, weight: FontWeight.w500, height: 1.35);
  static TextStyle get bodyMd =>
      spaceGrotesk(size: 13.5, weight: FontWeight.w400, height: 1.35);
  static TextStyle get bodySm =>
      spaceGrotesk(size: 11.5, weight: FontWeight.w400, height: 1.3);
  static TextStyle get labelCaps =>
      jetBrainsMono(size: 10, weight: FontWeight.w700, letterSpacing: 0.8);
  static TextStyle get statBadge =>
      jetBrainsMono(size: 13.5, weight: FontWeight.w800, letterSpacing: 0.3);
  static TextStyle get displayOvr =>
      chivo(size: 58, weight: FontWeight.w900, letterSpacing: -2.0);

  // ─── Material Theme ────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: DeckPageTransitions(),
        TargetPlatform.iOS: DeckPageTransitions(),
        TargetPlatform.windows: DeckPageTransitions(),
        TargetPlatform.macOS: DeckPageTransitions(),
        TargetPlatform.linux: DeckPageTransitions(),
      }),
      tooltipTheme:
          const TooltipThemeData(waitDuration: Duration(milliseconds: 450)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: limeNeon,
          foregroundColor: bgDarker,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              chivo(size: 13, weight: FontWeight.w800, letterSpacing: .5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardDark,
        selectedColor: limeNeon,
        showCheckmark: false,
        side: const BorderSide(color: borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        labelStyle:
            spaceGrotesk(size: 12, weight: FontWeight.w700, color: textMuted),
        secondaryLabelStyle:
            spaceGrotesk(size: 12, weight: FontWeight.w700, color: bgDarker),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardMid,
        contentTextStyle: spaceGrotesk(color: textWhite),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      colorScheme: const ColorScheme.dark(
        primary: limeNeon,
        secondary: mintTeal,
        surface: cardDark,
        error: errorRed,
        onPrimary: Color(0xFF283500), // dark text on lime
        onSecondary: Color(0xFF003824),
        onSurface: textWhite,
        onError: Color(0xFF690005),
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textWhite,
        displayColor: textWhite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.chivo(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textWhite,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textWhite),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: limeNeon,
          foregroundColor: const Color(0xFF283500),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08 * 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVar,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: limeNeon, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: TextStyle(
          color: textMuted.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgDarker,
        selectedItemColor: limeNeon,
        unselectedItemColor: textMutedDark,
        selectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
