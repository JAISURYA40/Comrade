import 'package:comrade/core/services/drift_db_service.dart';
import 'package:comrade/core/services/method_channel_service.dart';
import 'package:comrade/models/ai_user_context.dart';

class AiContextBuilder {
  final DriftDbService _dbService = DriftDbService.instance;
  final MethodChannelService _methodChannel =
      MethodChannelService.instance;

  Future<AiUserContext> build() async {
    final now = DateTime.now();

    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final weekStart = todayStart.subtract(const Duration(days: 6));

    // Today's app usage.
    final todayApps = await _methodChannel.fetchAppsUsageForInterval(
      start: todayStart,
      end: now,
    );

    // Installed app information.
    final appsInfo = await _methodChannel.fetchDeviceAppsInfo();

    final appNames = {
      for (final app in appsInfo) app.packageName: app.name,
    };

    // Today's focus time.
    final todayFocusTime = await _dbService.driftDb.dynamicRecordsDao
        .fetchSessionsDurationForInterval(
      todayStart,
      tomorrowStart,
    );

    // Last 7 days' focus time.
    final weeklyFocusTime = await _dbService.driftDb.dynamicRecordsDao
        .fetchSessionsDurationForInterval(
      weekStart,
      tomorrowStart,
    );

    // Active focus session.
    final activeSession = await _dbService.driftDb.dynamicRecordsDao
        .fetchLastActiveFocusSession();

    // Convert package names into real app names.
    final appUsage = <String, int>{};

    for (final entry in todayApps.entries) {
      final appName = appNames[entry.key] ?? entry.key;

      appUsage[appName] = entry.value.screenTime;
    }

    return AiUserContext(
      todayScreenTime: todayApps.values.fold(
        0,
        (total, usage) => total + usage.screenTime,
      ),
      appUsage: appUsage,
      todayFocusTime: todayFocusTime,
      weeklyFocusTime: weeklyFocusTime,
      hasActiveFocusSession: activeSession != null,
      focusSessionDuration: activeSession?.durationSecs ?? 0,
    );
  }
}