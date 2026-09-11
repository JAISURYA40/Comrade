import 'package:flutter/foundation.dart';

@immutable
class AiUserContext {
  /// Today's total screen time in seconds.
  final int todayScreenTime;

  /// App-wise screen time.
  /// Key = human-readable app name, Value = seconds.
  final Map<String, int> appUsage;

  /// Today's total focus time in seconds.
  final int todayFocusTime;

  /// Focus time for the last 7 days in seconds.
  final int weeklyFocusTime;

  /// Currently active focus session, if any.
  final bool hasActiveFocusSession;

  /// Configured focus session duration in seconds.
  final int focusSessionDuration;

  /// Apps configured as distracting apps.
  final List<String> distractingApps;

  const AiUserContext({
    this.todayScreenTime = 0,
    this.appUsage = const {},
    this.todayFocusTime = 0,
    this.weeklyFocusTime = 0,
    this.hasActiveFocusSession = false,
    this.focusSessionDuration = 0,
    this.distractingApps = const [],
  });
}