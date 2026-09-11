/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/config/navigation/app_routes.dart';
import 'package:comrade/config/app_themes.dart';
import 'package:comrade/config/navigation/app_routes_observer.dart';
import 'package:comrade/config/navigation/navigation_service.dart';
import 'package:comrade/core/enums/app_theme_mode.dart';
import 'package:comrade/l10n/generated/app_localizations.dart';
import 'package:comrade/providers/system/comrade_settings_provider.dart';

class ComradeApp extends ConsumerWidget {
  const ComradeApp({super.key});

  ThemeMode _toFlutterThemeMode(AppThemeMode mode) {
    switch (mode.materialBinding) {
      case ThemeModeBinding.system:
        return ThemeMode.system;
      case ThemeModeBinding.light:
        return ThemeMode.light;
      case ThemeModeBinding.dark:
        return ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode =
        ref.watch(comradeSettingsProvider.select((v) => v.themeMode));
    final accentColor =
        ref.watch(comradeSettingsProvider.select((v) => v.accentColor));
    final localeCode =
        ref.watch(comradeSettingsProvider.select((v) => v.localeCode));
    final useAmoledDark =
        ref.watch(comradeSettingsProvider.select((v) => v.useAmoledDark));
    final useDynamicColors =
        ref.watch(comradeSettingsProvider.select((v) => v.useDynamicColors));

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              systemNavigationBarContrastEnforced: true,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
          ),
        );

        final accent = AppTheme.materialColors[accentColor];
        final ThemeData lightTheme;
        final ThemeData darkTheme;
        final ThemeMode flutterMode;

        if (appThemeMode.isMoodTheme) {
          // Mood themes are full ThemeData packs applied to both slots so
          // the entire app (and platform brightness flips) stay consistent.
          final mood = AppTheme.resolve(
            mode: appThemeMode,
            platformBrightness: Brightness.dark,
            isAmoled: false,
          );
          lightTheme = mood;
          darkTheme = mood;
          flutterMode = ThemeMode.dark;
        } else {
          lightTheme = AppTheme.lightTheme(
            seedColor: useDynamicColors ? lightDynamic?.primary : accent,
          );
          darkTheme = AppTheme.darkTheme(
            isAmoled: useAmoledDark,
            seedColor: useDynamicColors ? darkDynamic?.primary : accent,
          );
          flutterMode = _toFlutterThemeMode(appThemeMode);
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final scaled = media.copyWith(
              textScaler: media.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.25,
              ),
            );
            Widget content = MediaQuery(
              data: scaled,
              child: child ?? const SizedBox.shrink(),
            );
            if (Platform.isIOS) {
              content = GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.translucent,
                child: content,
              );
            }
            return content;
          },
          themeAnimationCurve: Curves.easeInOut,
          themeAnimationDuration: const Duration(milliseconds: 280),
          themeMode: flutterMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          locale: Locale(localeCode),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: AppRoutes.rootSplashPath,
          routes: AppRoutes.routes,
          navigatorKey: NavigationService.navigatorKey,
          navigatorObservers: [AppRoutesObserver.instance],
        );
      },
    );
  }
}
