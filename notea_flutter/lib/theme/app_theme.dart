import 'package:flutter/material.dart';

/// Notea v2 design tokens — mirror the "Notea v2 / Color" variables in the
/// Figma page "Redesign v2".
class NC {
  static const cream = Color(0xFFFFF8EE);
  static const surface = Color(0xFFFFFFFF);
  static const sand = Color(0xFFFBF0E1);
  static const line = Color(0xFFEFE4D3);
  static const ink = Color(0xFF2F2A3A);
  static const muted = Color(0xFF77707F);
  static const onPrimary = Color(0xFFFFFFFF);

  static const plum = Color(0xFF7C5CBF);
  static const plumSoft = Color(0xFFECE4FF);
  static const pink = Color(0xFFF27A99);
  static const pinkSoft = Color(0xFFFFE3EA);
  static const peach = Color(0xFFF59A6B);
  static const peachSoft = Color(0xFFFFE9DC);
  static const mint = Color(0xFF3FB68F);
  static const mintSoft = Color(0xFFDCF4EA);
  static const butter = Color(0xFFE9B23E);
  static const butterSoft = Color(0xFFFFF2CC);
  static const sky = Color(0xFF4E9BEA);
  static const skySoft = Color(0xFFDEEDFF);

  static const red = Color(0xFFE5484D);
}

/// Accent pairs used for chips, icon bubbles and tiles.
class Accent {
  final Color strong;
  final Color soft;
  const Accent(this.strong, this.soft);

  static const plum = Accent(NC.plum, NC.plumSoft);
  static const pink = Accent(NC.pink, NC.pinkSoft);
  static const peach = Accent(NC.peach, NC.peachSoft);
  static const mint = Accent(NC.mint, NC.mintSoft);
  static const butter = Accent(NC.butter, NC.butterSoft);
  static const sky = Accent(NC.sky, NC.skySoft);
  static const all = [plum, pink, peach, mint, butter, sky];
}

/// Type scale: Fredoka for titles, Nunito for UI text.
class NText {
  static const display = TextStyle(
      fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 30, height: 1.2, color: NC.ink);
  static const title = TextStyle(
      fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 22, height: 1.27, color: NC.ink);
  static const headline = TextStyle(
      fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 17, height: 1.3, color: NC.ink);
  static const body = TextStyle(
      fontFamily: 'Nunito', fontWeight: FontWeight.w600, fontSize: 15, height: 1.4, color: NC.ink);
  static const muted = TextStyle(
      fontFamily: 'Nunito', fontWeight: FontWeight.w500, fontSize: 14, height: 1.43, color: NC.muted);
  static const caption = TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      fontSize: 12,
      height: 1.33,
      letterSpacing: 0.24,
      color: NC.muted);
  static const number = TextStyle(
      fontFamily: 'Fredoka',
      fontWeight: FontWeight.w600,
      fontSize: 56,
      height: 1.07,
      color: NC.ink,
      fontFeatures: [FontFeature.tabularFigures()]);
}

/// Create a Color from a hex string like "#RRGGBB" (kept from Color+Hex.swift).
Color hexColor(String hex) {
  var h = hex.trim().toUpperCase();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 3) h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
  if (h.length == 6) h = 'FF$h';
  final value = int.tryParse(h, radix: 16);
  return value == null || h.length != 8 ? const Color(0xFF808080) : Color(value);
}

/// Equivalent of SwiftUI `Color.opacity(x)`.
Color fade(Color c, double opacity) => c.withAlpha((opacity * 255).round().clamp(0, 255));

/// Equivalent of SwiftUI `Color(red:green:blue:)` with 0...1 components.
Color rgb(double r, double g, double b) =>
    Color.fromARGB(255, (r * 255).round(), (g * 255).round(), (b * 255).round());

/// Kept for the screens that still use iOS system colours.
class IOSColors {
  static const pink = NC.pink;
  static const mint = NC.mint;
  static const teal = Color(0xFF30B0C7);
  static const cyan = Color(0xFF32ADE6);
  static const blue = NC.sky;
  static const indigo = Color(0xFF5856D6);
  static const purple = NC.plum;
  static const red = NC.red;
  static const orange = NC.peach;
  static const yellow = NC.butter;
  static const green = NC.mint;
  static const brown = Color(0xFFA2845E);
  static const gray = NC.muted;
  static const systemGray5 = NC.line;
  static const systemGray6 = NC.sand;
  static const groupedBackground = NC.cream;
  static const secondaryLabel = NC.muted;
}

/// App themes (picked in Profile). Each one tints the background and accent.
enum AppTheme {
  defaultTheme('Cozy cream', NC.cream, NC.plum, NC.plumSoft),
  lavender('Lavender dream', Color(0xFFF7F3FF), Color(0xFF7457C4), Color(0xFFE9E1FF)),
  matcha('Matcha latte', Color(0xFFF3F8F0), Color(0xFF3A9A78), Color(0xFFD9F1E5)),
  peach('Peach soda', Color(0xFFFFF4EC), Color(0xFFDF6F4C), Color(0xFFFFE4D6));

  final String rawValue;
  final Color background;
  final Color primary;
  final Color primarySoft;
  const AppTheme(this.rawValue, this.background, this.primary, this.primarySoft);

  Color get primaryColor => primary;
  Color get backgroundColor => background;
  Color get secondaryColor => primarySoft;

  static AppTheme fromRaw(String? raw) {
    for (final t in AppTheme.values) {
      if (t.rawValue == raw || t.name == raw) return t;
    }
    return AppTheme.defaultTheme;
  }
}

/// Palette that follows the selected theme. Read with `context.pal`.
class NoteaPalette extends ThemeExtension<NoteaPalette> {
  final Color bg;
  final Color primary;
  final Color primarySoft;
  const NoteaPalette({required this.bg, required this.primary, required this.primarySoft});

  factory NoteaPalette.of(AppTheme t) =>
      NoteaPalette(bg: t.background, primary: t.primary, primarySoft: t.primarySoft);

  @override
  NoteaPalette copyWith({Color? bg, Color? primary, Color? primarySoft}) => NoteaPalette(
      bg: bg ?? this.bg, primary: primary ?? this.primary, primarySoft: primarySoft ?? this.primarySoft);

  @override
  NoteaPalette lerp(covariant ThemeExtension<NoteaPalette>? other, double t) {
    if (other is! NoteaPalette) return this;
    return NoteaPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
    );
  }
}

extension PaletteX on BuildContext {
  NoteaPalette get pal =>
      Theme.of(this).extension<NoteaPalette>() ?? NoteaPalette.of(AppTheme.defaultTheme);
}

ThemeData buildNoteaTheme(AppTheme theme) {
  final pal = NoteaPalette.of(theme);
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    colorScheme: ColorScheme.fromSeed(
      seedColor: pal.primary,
      primary: pal.primary,
      surface: NC.surface,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: pal.bg,
    extensions: [pal],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: NC.ink, displayColor: NC.ink),
    textSelectionTheme: TextSelectionThemeData(
        cursorColor: pal.primary, selectionColor: fade(pal.primary, 0.25), selectionHandleColor: pal.primary),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: NC.ink,
      contentTextStyle: NText.body.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: NC.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: NC.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
