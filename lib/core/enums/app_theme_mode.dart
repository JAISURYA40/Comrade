/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

/// App appearance. Indices are persisted via Drift EnumIndexConverter —
/// append new values only; never reorder existing ones.
enum AppThemeMode {
  system,
  light,
  dark,

  /// Motivated / energetic flame orange-amber mood.
  blast,

  /// Study / concentration sky-blue mood.
  focus,

  /// Peaceful / balanced sage-mint mood.
  calm,
}

extension AppThemeModeX on AppThemeMode {
  bool get isMoodTheme =>
      this == AppThemeMode.blast ||
      this == AppThemeMode.focus ||
      this == AppThemeMode.calm;

  /// MaterialApp [ThemeMode] mapping. Mood themes lock to dark slot
  /// (ThemeData is applied to both light and dark slots in ComradeApp).
  ThemeModeBinding get materialBinding {
    switch (this) {
      case AppThemeMode.system:
        return ThemeModeBinding.system;
      case AppThemeMode.light:
        return ThemeModeBinding.light;
      case AppThemeMode.dark:
      case AppThemeMode.blast:
      case AppThemeMode.focus:
      case AppThemeMode.calm:
        return ThemeModeBinding.dark;
    }
  }
}

enum ThemeModeBinding { system, light, dark }
