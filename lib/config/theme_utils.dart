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

/// Utility class for theme-related helper methods
class ThemeUtils {
  /// Creates a BoxDecoration with gradient and glow effect
  /// Perfect for premium buttons and highlighted cards
  static BoxDecoration gradientGlowDecoration({
    double borderRadius = 16,
    List<Color>? gradient,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        colors: gradient ?? AppColors.primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.4), // --glow-primary
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Creates a gradient widget decoration
  static Decoration gradientDecoration({
    double borderRadius = 16,
    List<Color>? gradient,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        colors: gradient ?? AppColors.primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}
