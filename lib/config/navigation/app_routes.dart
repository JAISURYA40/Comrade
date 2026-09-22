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
import 'package:comrade/core/enums/usage_type.dart';
import 'package:comrade/core/extensions/ext_build_context.dart';
import 'package:comrade/ui/onboarding/onboarding_screen.dart';
import 'package:comrade/ui/screens/active_session/active_session_screen.dart';
import 'package:comrade/ui/screens/app_dashboard/app_dashboard_screen.dart';
import 'package:comrade/ui/screens/change_logs/change_logs_screen.dart';
import 'package:comrade/ui/screens/focus/focus_screen.dart';
import 'package:comrade/ui/screens/home/home_screen.dart';
import 'package:comrade/ui/screens/parental_controls/parental_controls_screen.dart';
import 'package:comrade/ui/screens/restriction_groups/restriction_groups_screen.dart';
import 'package:comrade/ui/screens/settings/settings_screen.dart';
import 'package:comrade/ui/screens/shorts_blocking/shorts_blocking_screen.dart';
import 'package:comrade/ui/screens/notifications/notifications_screen.dart';
import 'package:comrade/ui/screens/websites_blocking/websites_blocking_screen.dart';
import 'package:comrade/ui/screens/roadmap/roadmap_screen.dart';
import 'package:comrade/ui/screens/learning_youtube/learning_youtube_screen.dart';
import 'package:comrade/ui/splash_screen.dart';

class AppRoutes {
  static const String rootSplashPath = '/';
  static const String onboardingPath = '/onboarding';
  static const String changeLogsPath = '/changeLogs';
  static const String settingsPath = '/settings';

  static const String homePath = '/home';
  static const String activeSessionPath = '/activeSession';
  static const String focusModePath = '/focus';

  static const String parentalControlsPath = '/parentalControls';
  static const String restrictionGroupsPath = '/restrictionGroups';
  static const String shortsBlockingPath = '/shortsBlocking';
  static const String websitesBlockingPath = '/websitesBlocking';

  static const String appDashboardPath = '/appDashboard';
  static const String notificationsPath = '/notifications';
  static const String roadmapPath = '/roadmap';
  static const String learningYoutubePath = '/learningYoutube';

  static final Map<String, Widget Function(BuildContext)> routes = {
    /// Root
    rootSplashPath: (context) => const SplashScreen(),

    /// Onboarding screen
    onboardingPath: (context) => OnboardingScreen(
          isOnboardingDone:
              context.resolveParam<bool>("isOnboardingDone") ?? false,
        ),

    /// Change logs screen
    changeLogsPath: (context) => const ChangeLogsScreen(),

    /// Settings screen
    settingsPath: (context) => SettingsScreen(
          initialTabIndex: context.resolveParam<int>("tab"),
        ),

    /// Home screen
    homePath: (context) => HomeScreen(
          initialTabIndex: context.resolveParam<int>("tab"),
        ),

    /// Parental controls screen
    parentalControlsPath: (context) => const ParentalControlsScreen(),

    /// Restriction groups screen
    restrictionGroupsPath: (context) => const RestrictionGroupsScreen(),

    /// Shorts blocking screen
    shortsBlockingPath: (context) => const ShortsBlockingScreen(),

    /// Websites blocking screen
    websitesBlockingPath: (context) => const WebsitesBlockingScreen(),

    /// Notifications list screen
    notificationsPath: (context) => NotificationsScreen(
          initialTabIndex: context.resolveParam<int>("tab"),
        ),

    /// Focus mode screen
    focusModePath: (context) => FocusScreen(
          initialTabIndex: context.resolveParam<int>("tab"),
        ),

    /// Active focus session screen
    activeSessionPath: (context) => const ActiveSessionScreen(),

    /// App dashboard screen
    appDashboardPath: (context) => AppDashboardScreen(
          packageName: context.resolveParam<String>("package") ?? "",
          initialUsageType:
              UsageType.values[(context.resolveParam<int>("usageType") ?? 0) % 2],
          selectedDay: context.resolveParam<DateTime>("day"),
        ),

    /// Roadmap screen
    roadmapPath: (context) => const RoadmapScreen(),

    /// Learning YouTube screen
    learningYoutubePath: (context) => const LearningYoutubeScreen(),
  };
}
