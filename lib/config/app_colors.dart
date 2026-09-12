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

/// Backward-compatible aliases for classic dark palette.
/// Prefer [Theme.of(context).colorScheme] or [context.themeTokens] in new code.
class AppColors {
  static Color get background => AppThemeTokens.classicDark.background;
  static Color get card => AppThemeTokens.classicDark.card;
  static Color get primary => AppThemeTokens.classicDark.primary;
  static Color get secondary => AppThemeTokens.classicDark.secondary;
  static Color get accent => AppThemeTokens.classicDark.accent;
  static Color get foreground => AppThemeTokens.classicDark.foreground;
  static Color get mutedForeground => AppThemeTokens.classicDark.mutedForeground;
  static Color get destructive => AppThemeTokens.classicDark.destructive;
  static Color get inputBackground => AppThemeTokens.classicDark.inputBackground;

  /// Prefer [AppThemeTokens.primaryGradient] via context when possible.
  static List<Color> get primaryGradient =>
      AppThemeTokens.classicDark.primaryGradient;
}
