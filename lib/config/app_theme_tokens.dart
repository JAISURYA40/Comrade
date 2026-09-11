/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/material.dart';
import 'package:comrade/core/enums/app_theme_mode.dart';

/// Centralized design tokens for Comrade themes.
/// UI should prefer [ColorScheme] / [ThemeData]; tokens feed those builders.
@immutable
class AppThemeTokens {
  const AppThemeTokens({
    required this.brightness,
    required this.background,
    required this.card,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.accent,
    required this.foreground,
    required this.mutedForeground,
    required this.destructive,
    required this.inputBackground,
    required this.outline,
  });

  final Brightness brightness;
  final Color background;
  final Color card;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color accent;
  final Color foreground;
  final Color mutedForeground;
  final Color destructive;
  final Color inputBackground;
  final Color outline;

  /// Primary brand gradient for glowing CTAs (derived from tokens).
  List<Color> get primaryGradient => [
        primary,
        Color.lerp(primary, accent, 0.45) ?? primary,
        Color.lerp(primary, secondary, 0.65) ?? secondary,
      ];

  /// Classic Comrade dark (System/Dark baseline).
  static const classicDark = AppThemeTokens(
    brightness: Brightness.dark,
    background: Color(0xFF0A0E27),
    card: Color(0xFF0F1433),
    primary: Color(0xFF5B7FFF),
    onPrimary: Colors.white,
    secondary: Color(0xFF1A2047),
    accent: Color(0xFF2D3A6E),
    foreground: Color(0xFFE8EAF2),
    mutedForeground: Color(0xFF8D92B3),
    destructive: Color(0xFFFF6B9D),
    inputBackground: Color(0xFF131837),
    outline: Color(0x265B7FFF),
  );

  /// Classic light baseline.
  static const classicLight = AppThemeTokens(
    brightness: Brightness.light,
    background: Color(0xFFF7F8FC),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF3F51B5),
    onPrimary: Colors.white,
    secondary: Color(0xFFE8EAF6),
    accent: Color(0xFFC5CAE9),
    foreground: Color(0xFF1A1C2C),
    mutedForeground: Color(0xFF5C6078),
    destructive: Color(0xFFB3261E),
    inputBackground: Color(0xFFF0F1F7),
    outline: Color(0x333F51B5),
  );

  /// Blast — Flame Orange / Amber (motivated, energetic).
  static const blast = AppThemeTokens(
    brightness: Brightness.dark,
    background: Color(0xFF1A0F0A),
    card: Color(0xFF26160F),
    primary: Color(0xFFFF6B1A),
    onPrimary: Color(0xFF1A0A00),
    secondary: Color(0xFF3A1F12),
    accent: Color(0xFF5C2E14),
    foreground: Color(0xFFFFF3E8),
    mutedForeground: Color(0xFFC9A992),
    destructive: Color(0xFFFF4D6D),
    inputBackground: Color(0xFF2A160F),
    outline: Color(0x40FF8A3D),
  );

  /// Focus — Focus Blue / Sky Blue (study, concentration).
  static const focus = AppThemeTokens(
    brightness: Brightness.dark,
    background: Color(0xFF07121F),
    card: Color(0xFF0C1B2E),
    primary: Color(0xFF38BDF8),
    onPrimary: Color(0xFF001018),
    secondary: Color(0xFF123049),
    accent: Color(0xFF1A4060),
    foreground: Color(0xFFE8F4FF),
    mutedForeground: Color(0xFF8BAFC8),
    destructive: Color(0xFFFF6B9D),
    inputBackground: Color(0xFF0F2236),
    outline: Color(0x4038BDF8),
  );

  /// Calm — Sage / Mint (peaceful, balanced, reduce stress).
  static const calm = AppThemeTokens(
    brightness: Brightness.dark,
    background: Color(0xFF0C1412),
    card: Color(0xFF121C19),
    primary: Color(0xFF6FCFB0),
    onPrimary: Color(0xFF04140E),
    secondary: Color(0xFF1A2E28),
    accent: Color(0xFF254038),
    foreground: Color(0xFFE7F5EF),
    mutedForeground: Color(0xFF95B3A8),
    destructive: Color(0xFFE57373),
    inputBackground: Color(0xFF15241F),
    outline: Color(0x406FCFB0),
  );

  static AppThemeTokens forMode(
    AppThemeMode mode, {
    required Brightness platformBrightness,
    bool amoledDark = false,
  }) {
    switch (mode) {
      case AppThemeMode.blast:
        return blast;
      case AppThemeMode.focus:
        return focus;
      case AppThemeMode.calm:
        return calm;
      case AppThemeMode.light:
        return classicLight;
      case AppThemeMode.dark:
        return amoledDark
            ? classicDark.copyWith(background: Colors.black, card: const Color(0xFF0A0A0A))
            : classicDark;
      case AppThemeMode.system:
        if (platformBrightness == Brightness.light) return classicLight;
        return amoledDark
            ? classicDark.copyWith(background: Colors.black, card: const Color(0xFF0A0A0A))
            : classicDark;
    }
  }

  AppThemeTokens copyWith({
    Brightness? brightness,
    Color? background,
    Color? card,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? accent,
    Color? foreground,
    Color? mutedForeground,
    Color? destructive,
    Color? inputBackground,
    Color? outline,
  }) {
    return AppThemeTokens(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      foreground: foreground ?? this.foreground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      destructive: destructive ?? this.destructive,
      inputBackground: inputBackground ?? this.inputBackground,
      outline: outline ?? this.outline,
    );
  }

  ColorScheme toColorScheme({Color? seedOverride}) {
    final primaryColor = seedOverride ?? primary;
    return ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: onPrimary,
      primaryContainer: secondary,
      onPrimaryContainer: foreground,
      secondary: secondary,
      onSecondary: foreground,
      secondaryContainer: accent,
      onSecondaryContainer: foreground,
      tertiary: accent,
      onTertiary: foreground,
      error: destructive,
      onError: Colors.white,
      errorContainer: destructive.withValues(alpha: 0.2),
      onErrorContainer: destructive,
      surface: background,
      onSurface: foreground,
      surfaceContainerHighest: card,
      surfaceContainerHigh: secondary,
      surfaceContainer: accent,
      surfaceContainerLow: secondary,
      onSurfaceVariant: mutedForeground,
      outline: outline,
      outlineVariant: outline.withValues(alpha: 0.5),
      scrim: Colors.black,
      shadow: Colors.black,
      inverseSurface: foreground,
      onInverseSurface: background,
      inversePrimary: primaryColor,
    );
  }
}

/// Theme extension so widgets can read mood tokens without hardcoding colors.
@immutable
class ComradeThemeExtension extends ThemeExtension<ComradeThemeExtension> {
  const ComradeThemeExtension({
    required this.tokens,
    required this.mode,
  });

  final AppThemeTokens tokens;
  final AppThemeMode mode;

  @override
  ComradeThemeExtension copyWith({
    AppThemeTokens? tokens,
    AppThemeMode? mode,
  }) {
    return ComradeThemeExtension(
      tokens: tokens ?? this.tokens,
      mode: mode ?? this.mode,
    );
  }

  @override
  ComradeThemeExtension lerp(ThemeExtension<ComradeThemeExtension>? other, double t) {
    if (other is! ComradeThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}

extension ComradeThemeContext on BuildContext {
  ComradeThemeExtension get comradeTheme =>
      Theme.of(this).extension<ComradeThemeExtension>() ??
      const ComradeThemeExtension(
        tokens: AppThemeTokens.classicDark,
        mode: AppThemeMode.dark,
      );

  AppThemeTokens get themeTokens => comradeTheme.tokens;
}
