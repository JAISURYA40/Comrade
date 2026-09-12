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

/// Theme-aware decoration helpers. Prefer passing [BuildContext] so moods apply.
class ThemeUtils {
  static BoxDecoration gradientGlowDecoration({
    required BuildContext context,
    double borderRadius = 16,
    List<Color>? gradient,
  }) {
    final tokens = context.themeTokens;
    final colors = gradient ?? tokens.primaryGradient;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: tokens.primary.withValues(alpha: 0.4),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration gradientDecoration({
    required BuildContext context,
    double borderRadius = 16,
    List<Color>? gradient,
  }) {
    final tokens = context.themeTokens;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        colors: gradient ?? tokens.primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}
