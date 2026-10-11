import 'package:flutter/material.dart';

/// Brand accent — Sharp Amber. Identical in Day and Night.
const Color kTapFocusAmber = Color(0xFFFFBF00);
const Color kTapFocusAmberDeep = Color(0xFFE6AC00);
const Color kTapFocusAmberDim = Color(0xFF3D2E05);
const Color kTapFocusAmberOn = Color(0xFF1A1200);

/// Executive dual-theme palette (Night Onyx / Day Alabaster).
@immutable
class TapFocusColors extends ThemeExtension<TapFocusColors> {
  const TapFocusColors({
    required this.voidBlack,
    required this.graphite,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentDeep,
    required this.accentDim,
    required this.onAccent,
    required this.danger,
    required this.warning,
    required this.warningDeep,
    required this.dangerDim,
    required this.warningDim,
    required this.cardShadow,
  });

  /// Scaffold / deepest background.
  final Color voidBlack;
  final Color graphite;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceBorder;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Sharp Amber — same hex in both modes.
  final Color accent;
  final Color accentDeep;
  final Color accentDim;
  final Color onAccent;

  final Color danger;
  final Color warning;
  final Color warningDeep;
  final Color dangerDim;
  final Color warningDim;

  /// Soft elevation for Day cards; near-zero for Night.
  final List<BoxShadow> cardShadow;

  /// Night Mode (Onyx) — matte black executive.
  static const night = TapFocusColors(
    voidBlack: Color(0xFF0A0A0A),
    graphite: Color(0xFF111111),
    surface: Color(0xFF1C1C1E),
    surfaceElevated: Color(0xFF242426),
    surfaceBorder: Color(0xFF2E2E30),
    textPrimary: Color(0xFFEBEBF5),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF6B6B76),
    accent: kTapFocusAmber,
    accentDeep: kTapFocusAmberDeep,
    accentDim: kTapFocusAmberDim,
    onAccent: kTapFocusAmberOn,
    danger: Color(0xFFFF6B4A),
    warning: kTapFocusAmber,
    warningDeep: Color(0xFFE67E22),
    dangerDim: Color(0xFF3D1F1A),
    warningDim: Color(0xFF3D2E14),
    cardShadow: <BoxShadow>[],
  );

  /// Day Mode (Executive Light) — alabaster / titanium.
  static const day = TapFocusColors(
    voidBlack: Color(0xFFF7F7F5),
    graphite: Color(0xFFF0F0EE),
    surface: Color(0xFFEAEAEA),
    surfaceElevated: Color(0xFFE3E3E1),
    surfaceBorder: Color(0xFFD4D4D0),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF52525B),
    textMuted: Color(0xFF8B8B93),
    accent: kTapFocusAmber,
    accentDeep: kTapFocusAmberDeep,
    accentDim: Color(0xFFFFF3CC),
    onAccent: kTapFocusAmberOn,
    danger: Color(0xFFE04E36),
    warning: kTapFocusAmberDeep,
    warningDeep: Color(0xFFC96A12),
    dangerDim: Color(0xFFFBE8E4),
    warningDim: Color(0xFFFFF3CC),
    cardShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );

  static TapFocusColors of(BuildContext context) {
    return Theme.of(context).extension<TapFocusColors>() ?? night;
  }

  @override
  TapFocusColors copyWith({
    Color? voidBlack,
    Color? graphite,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentDeep,
    Color? accentDim,
    Color? onAccent,
    Color? danger,
    Color? warning,
    Color? warningDeep,
    Color? dangerDim,
    Color? warningDim,
    List<BoxShadow>? cardShadow,
  }) {
    return TapFocusColors(
      voidBlack: voidBlack ?? this.voidBlack,
      graphite: graphite ?? this.graphite,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentDeep: accentDeep ?? this.accentDeep,
      accentDim: accentDim ?? this.accentDim,
      onAccent: onAccent ?? this.onAccent,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      warningDeep: warningDeep ?? this.warningDeep,
      dangerDim: dangerDim ?? this.dangerDim,
      warningDim: warningDim ?? this.warningDim,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  TapFocusColors lerp(ThemeExtension<TapFocusColors>? other, double t) {
    if (other is! TapFocusColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return TapFocusColors(
      voidBlack: l(voidBlack, other.voidBlack),
      graphite: l(graphite, other.graphite),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      surfaceBorder: l(surfaceBorder, other.surfaceBorder),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      accentDeep: l(accentDeep, other.accentDeep),
      accentDim: l(accentDim, other.accentDim),
      onAccent: l(onAccent, other.onAccent),
      danger: l(danger, other.danger),
      warning: l(warning, other.warning),
      warningDeep: l(warningDeep, other.warningDeep),
      dangerDim: l(dangerDim, other.dangerDim),
      warningDim: l(warningDim, other.warningDim),
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

extension TapFocusThemeX on BuildContext {
  TapFocusColors get colors => TapFocusColors.of(this);
}

ThemeData buildTapFocusTheme(TapFocusColors palette, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: palette.accent,
    onPrimary: palette.onAccent,
    primaryContainer: palette.accentDim,
    onPrimaryContainer: palette.accent,
    secondary: palette.warning,
    onSecondary: palette.onAccent,
    secondaryContainer: palette.warningDim,
    onSecondaryContainer: palette.warning,
    tertiary: palette.danger,
    onTertiary: Colors.white,
    error: palette.danger,
    onError: Colors.white,
    surface: palette.surface,
    onSurface: palette.textPrimary,
    onSurfaceVariant: palette.textSecondary,
    outline: palette.surfaceBorder,
    outlineVariant: palette.surfaceBorder,
    surfaceContainerHighest: palette.surfaceElevated,
    surfaceContainerHigh: palette.surface,
    surfaceContainer: palette.graphite,
    surfaceContainerLow: palette.voidBlack,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.voidBlack,
    canvasColor: palette.voidBlack,
    cardColor: palette.surface,
    dividerColor: palette.surfaceBorder,
    splashFactory: InkSparkle.splashFactory,
    extensions: <ThemeExtension<dynamic>>[palette],
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: palette.voidBlack,
      foregroundColor: palette.textPrimary,
      titleTextStyle: TextStyle(
        color: palette.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      iconTheme: IconThemeData(color: palette.textPrimary),
      actionsIconTheme: IconThemeData(color: palette.textPrimary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.graphite,
      indicatorColor: palette.accentDim,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? palette.accent : palette.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? palette.accent : palette.textSecondary,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: brightness == Brightness.light ? 1 : 0,
      shadowColor: const Color(0x14000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.surfaceBorder),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        color: palette.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: palette.textSecondary,
        fontSize: 14,
        height: 1.4,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surfaceElevated,
      contentTextStyle: TextStyle(color: palette.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.accentDeep,
        foregroundColor: palette.onAccent,
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.textPrimary,
        side: BorderSide(color: palette.surfaceBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: palette.accent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.accent;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(palette.onAccent),
      side: BorderSide(color: palette.textSecondary),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.accent),
    dividerTheme: DividerThemeData(
      color: palette.surfaceBorder,
      thickness: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: palette.textSecondary,
      textColor: palette.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.surfaceBorder),
      ),
    ),
    textTheme: base.textTheme
        .apply(
          bodyColor: palette.textPrimary,
          displayColor: palette.textPrimary,
        )
        .copyWith(
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            color: palette.textSecondary,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            color: palette.textMuted,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            color: palette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
  );
}

ThemeData buildTapFocusDarkTheme() =>
    buildTapFocusTheme(TapFocusColors.night, Brightness.dark);

ThemeData buildTapFocusLightTheme() =>
    buildTapFocusTheme(TapFocusColors.day, Brightness.light);
