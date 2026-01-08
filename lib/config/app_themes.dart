/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/material.dart';
import 'package:mindful/config/app_colors.dart';
import 'package:mindful/ui/transitions/default_page_transition_builder.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AppTheme {
  static const _kSeedColor = Colors.indigo;

  static final _kShimmerEffect = ShimmerEffect(
    highlightColor: Colors.white.withValues(alpha: 0.6),
    baseColor: Colors.grey.withValues(alpha: 0.3),
  );

  /// Custom transition for page routes
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

  static ThemeData darkTheme({Color? seedColor, required bool isAmoled}) {
    // Use custom color scheme with premium navy/indigo palette
    final colorScheme = ColorScheme.dark(
      surface: isAmoled ? Colors.black : AppColors.background,
      onSurface: AppColors.foreground,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.secondary,
      onPrimaryContainer: AppColors.foreground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.foreground,
      secondaryContainer: AppColors.accent,
      onSecondaryContainer: AppColors.foreground,
      tertiary: AppColors.accent,
      onTertiary: AppColors.foreground,
      error: AppColors.destructive,
      onError: Colors.white,
      errorContainer: AppColors.destructive.withValues(alpha: 0.2),
      onErrorContainer: AppColors.destructive,
      outline: AppColors.primary.withValues(alpha: 0.15),
      outlineVariant: AppColors.primary.withValues(alpha: 0.1),
      surfaceContainerHighest: AppColors.card,
      surfaceContainerHigh: AppColors.secondary,
      surfaceContainer: AppColors.accent,
      surfaceVariant: AppColors.secondary,
      onSurfaceVariant: AppColors.mutedForeground,
      scrim: Colors.black,
      shadow: Colors.black,
      inverseSurface: AppColors.foreground,
      onInverseSurface: AppColors.background,
      inversePrimary: AppColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isAmoled ? Colors.black : AppColors.background,
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),

      // Typography (Base Layer)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.foreground,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.foreground,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedForeground,
        ),
      ).apply(bodyColor: AppColors.foreground, displayColor: AppColors.foreground),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Input Decoration (Input Layer)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.destructive.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.destructive,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 16,
        ),
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.foreground,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
          letterSpacing: -0.3,
        ),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.mutedForeground,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: 24,
            );
          }
          return IconThemeData(
            color: AppColors.mutedForeground,
            size: 24,
          );
        }),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedForeground,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.foreground,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.primary.withValues(alpha: 0.1),
        thickness: 1,
        space: 1,
      ),

      pageTransitionsTheme: _kPageTransitionTheme,
      extensions: [SkeletonizerConfigData.dark(effect: _kShimmerEffect)],
    );
  }

  static ThemeData lightTheme({Color? seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? _kSeedColor,
      brightness: Brightness.light,
    );

    return ThemeData.from(
      useMaterial3: true,
      colorScheme: colorScheme,
    ).copyWith(
      pageTransitionsTheme: _kPageTransitionTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: colorScheme.surfaceContainerHighest,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      extensions: [SkeletonizerConfigData(effect: _kShimmerEffect)],
    );
  }
}
