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
import 'package:comrade/config/app_theme_tokens.dart';
import 'package:comrade/core/enums/app_theme_mode.dart';
import 'package:comrade/ui/transitions/default_page_transition_builder.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AppTheme {
  static final _kShimmerEffect = ShimmerEffect(
    highlightColor: Colors.white.withValues(alpha: 0.6),
    baseColor: Colors.grey.withValues(alpha: 0.3),
  );

  static const _kPageTransitionTheme = PageTransitionsTheme(
    builders: {TargetPlatform.android: DefaultPageTransitionsBuilder()},
  );

  static final materialColors = <String, MaterialColor>{
    'Amber': Colors.amber,
    'Blue': Colors.blue,
    'Blue Grey': Colors.blueGrey,
    'Brown': Colors.brown,
    'Cyan': Colors.cyan,
    'Deep Orange': Colors.deepOrange,
    'Deep Purple': Colors.deepPurple,
    'Green': Colors.green,
    'Grey': Colors.grey,
    'Indigo': Colors.indigo,
    'Light Blue': Colors.lightBlue,
    'Light Green': Colors.lightGreen,
    'Lime': Colors.lime,
    'Orange': Colors.orange,
    'Pink': Colors.pink,
    'Purple': Colors.purple,
    'Red': Colors.red,
    'Teal': Colors.teal,
    'Yellow': Colors.yellow,
  };

  /// Resolve the active [ThemeData] for the selected app theme mode.
  static ThemeData resolve({
    required AppThemeMode mode,
    required Brightness platformBrightness,
    required bool isAmoled,
    Color? seedColor,
    bool useDynamicColors = false,
  }) {
    final tokens = AppThemeTokens.forMode(
      mode,
      platformBrightness: platformBrightness,
      amoledDark: isAmoled && !mode.isMoodTheme,
    );

    // Accent / dynamic color only applies to classic system/light/dark.
    final seed = mode.isMoodTheme
        ? null
        : (useDynamicColors ? seedColor : seedColor);

    return fromTokens(
      tokens: tokens,
      mode: mode,
      seedOverride: mode.isMoodTheme ? null : seed,
    );
  }

  static ThemeData darkTheme({Color? seedColor, required bool isAmoled}) {
    final tokens = isAmoled
        ? AppThemeTokens.classicDark
            .copyWith(background: Colors.black, card: const Color(0xFF0A0A0A))
        : AppThemeTokens.classicDark;
    return fromTokens(
      tokens: tokens,
      mode: AppThemeMode.dark,
      seedOverride: seedColor,
    );
  }

  static ThemeData lightTheme({Color? seedColor}) {
    if (seedColor != null) {
      final scheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      );
      return _themeFromScheme(
        scheme: scheme,
        tokens: AppThemeTokens.classicLight.copyWith(
          primary: scheme.primary,
          background: scheme.surface,
          card: scheme.surfaceContainerHighest,
          foreground: scheme.onSurface,
          mutedForeground: scheme.onSurfaceVariant,
          secondary: scheme.secondaryContainer,
          accent: scheme.tertiaryContainer,
          inputBackground: scheme.surfaceContainerHighest,
        ),
        mode: AppThemeMode.light,
      );
    }
    return fromTokens(
      tokens: AppThemeTokens.classicLight,
      mode: AppThemeMode.light,
    );
  }

  static ThemeData fromTokens({
    required AppThemeTokens tokens,
    required AppThemeMode mode,
    Color? seedOverride,
  }) {
    final scheme = tokens.toColorScheme(seedOverride: seedOverride);
    return _themeFromScheme(scheme: scheme, tokens: tokens, mode: mode);
  }

  static ThemeData _themeFromScheme({
    required ColorScheme scheme,
    required AppThemeTokens tokens,
    required AppThemeMode mode,
  }) {
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.background,
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: tokens.foreground,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: tokens.foreground,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: tokens.foreground,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: tokens.foreground,
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: tokens.foreground,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: tokens.foreground,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: tokens.foreground,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: tokens.mutedForeground,
        ),
      ).apply(
        bodyColor: tokens.foreground,
        displayColor: tokens.foreground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: tokens.primary.withValues(alpha: 0.7),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: tokens.destructive.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.destructive, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(
          color: tokens.mutedForeground,
          fontSize: 16,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: tokens.foreground,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: tokens.foreground,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: tokens.card,
        indicatorColor: tokens.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: tokens.mutedForeground,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: tokens.primary, size: 24);
          }
          return IconThemeData(color: tokens.mutedForeground, size: 24);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: tokens.card,
        selectedItemColor: tokens.primary,
        unselectedItemColor: tokens.mutedForeground,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: tokens.mutedForeground,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: tokens.foreground,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: tokens.foreground,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.card,
        modalBackgroundColor: tokens.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.outline,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.primary,
        linearTrackColor: tokens.secondary,
        circularTrackColor: tokens.secondary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.secondary,
        contentTextStyle: TextStyle(color: tokens.foreground),
        actionTextColor: tokens.primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.secondary,
        selectedColor: tokens.primary.withValues(alpha: 0.25),
        labelStyle: TextStyle(color: tokens.foreground),
        secondaryLabelStyle: TextStyle(color: tokens.onPrimary),
        side: BorderSide(color: tokens.outline),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.onPrimary;
          return tokens.mutedForeground;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return tokens.secondary;
        }),
      ),
      iconTheme: IconThemeData(color: tokens.foreground),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
      ),
      pageTransitionsTheme: _kPageTransitionTheme,
      extensions: [
        isDark
            ? SkeletonizerConfigData.dark(effect: _kShimmerEffect)
            : SkeletonizerConfigData(effect: _kShimmerEffect),
        ComradeThemeExtension(tokens: tokens, mode: mode),
      ],
    );
  }
}
