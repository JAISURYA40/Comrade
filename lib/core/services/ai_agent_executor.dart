/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/core/services/ai_agent_action.dart';
import 'package:comrade/core/services/method_channel_service.dart';
import 'package:comrade/models/app_info.dart';
import 'package:comrade/providers/apps/apps_info_provider.dart';
import 'package:comrade/providers/focus/focus_mode_provider.dart';
import 'package:comrade/providers/restrictions/apps_restrictions_provider.dart';

class AiAgentExecutor {
  /// Executes a single [AgentAction] against Comrade's Riverpod state.
  static Future<AgentActionResult> execute(
    AgentAction action,
    WidgetRef ref,
  ) async {
    try {
      switch (action.toolName) {
        case 'start_focus_session':
          return await _startFocusSession(action.arguments, ref);

        case 'stop_focus_session':
          return await _stopFocusSession(action.arguments, ref);

        case 'block_app_in_focus':
          return await _blockAppInFocus(action.arguments, ref);

        case 'set_app_timer':
          return await _setAppTimer(action.arguments, ref);

        case 'get_productivity_status':
          return await _getProductivityStatus(ref);

        default:
          return AgentActionResult(
            toolName: action.toolName,
            success: false,
            message: "Unknown action: ${action.toolName}",
          );
      }
    } catch (e, stack) {
      debugPrint("Error executing AI action ${action.toolName}: $e\n$stack");
      return AgentActionResult(
        toolName: action.toolName,
        success: false,
        message: "Failed to execute ${action.toolName}: $e",
      );
    }
  }

  /// Starts a new focus session.
  static Future<AgentActionResult> _startFocusSession(
    Map<String, dynamic> args,
    WidgetRef ref,
  ) async {
    final rawDuration = args['duration_minutes'] ?? args['duration'] ?? 25;
    final durationMinutes = (rawDuration is num)
        ? rawDuration.toInt()
        : int.tryParse(rawDuration.toString()) ?? 25;

    final durationSec = durationMinutes * 60;
    final notifier = ref.read(focusModeProvider.notifier);

    if (args['enforce'] is bool) {
      notifier.setEnforceFocus(args['enforce'] as bool);
    }

    if (args['enable_dnd'] is bool) {
      notifier.setShouldStartDnd(args['enable_dnd'] as bool);
    }

    // Set duration and start
    notifier.setSessionDuration(durationSec);
    await notifier.startNewSession();

    return AgentActionResult(
      toolName: 'start_focus_session',
      success: true,
      message: "Started $durationMinutes-minute focus session.",
    );
  }

  /// Stops or finishes the active focus session.
  static Future<AgentActionResult> _stopFocusSession(
    Map<String, dynamic> args,
    WidgetRef ref,
  ) async {
    final focusState = ref.read(focusModeProvider);
    if (focusState.activeSession.value == null) {
      return AgentActionResult(
        toolName: 'stop_focus_session',
        success: false,
        message: "No active focus session is currently running.",
      );
    }

    final isGivingUp = args['give_up'] == true;
    final isFinite = (focusState.activeSession.value?.durationSecs ?? 0) > 0;

    await ref.read(focusModeProvider.notifier).giveUpOrFinishFocusSession(
          isTheSessionSuccessful: !isGivingUp,
          isFiniteSession: isFinite,
        );

    return AgentActionResult(
      toolName: 'stop_focus_session',
      success: true,
      message: isGivingUp
          ? "Focus session cancelled."
          : "Focus session completed successfully!",
    );
  }

  /// Adds or removes an app from the distracting apps list during focus mode.
  static Future<AgentActionResult> _blockAppInFocus(
    Map<String, dynamic> args,
    WidgetRef ref,
  ) async {
    final appName = args['app_name']?.toString() ?? '';
    final shouldBlock = args['should_block'] != false;

    if (appName.isEmpty) {
      return AgentActionResult(
        toolName: 'block_app_in_focus',
        success: false,
        message: "No app name was specified.",
      );
    }

    final appInfo = await _resolveApp(appName, ref);
    if (appInfo == null) {
      return AgentActionResult(
        toolName: 'block_app_in_focus',
        success: false,
        message: "Could not find app matching '$appName' on your device.",
      );
    }

    ref
        .read(focusModeProvider.notifier)
        .insertRemoveDistractingApp(appInfo.packageName, shouldBlock);

    return AgentActionResult(
      toolName: 'block_app_in_focus',
      success: true,
      message: shouldBlock
          ? "Added ${appInfo.name} to focus blocklist."
          : "Removed ${appInfo.name} from focus blocklist.",
    );
  }

  /// Sets daily usage timer for an app.
  static Future<AgentActionResult> _setAppTimer(
    Map<String, dynamic> args,
    WidgetRef ref,
  ) async {
    final appName = args['app_name']?.toString() ?? '';
    final rawTimer = args['timer_minutes'] ?? 0;
    final timerMinutes = (rawTimer is num)
        ? rawTimer.toInt()
        : int.tryParse(rawTimer.toString()) ?? 0;

    if (appName.isEmpty) {
      return AgentActionResult(
        toolName: 'set_app_timer',
        success: false,
        message: "No app name was specified.",
      );
    }

    final appInfo = await _resolveApp(appName, ref);
    if (appInfo == null) {
      return AgentActionResult(
        toolName: 'set_app_timer',
        success: false,
        message: "Could not find app matching '$appName' on your device.",
      );
    }

    final timerSec = timerMinutes * 60;
    await ref
        .read(appsRestrictionsProvider.notifier)
        .updateAppTimer(appInfo.packageName, timerSec);

    return AgentActionResult(
      toolName: 'set_app_timer',
      success: true,
      message: timerMinutes > 0
          ? "Set daily limit for ${appInfo.name} to $timerMinutes minutes."
          : "Removed daily limit for ${appInfo.name}.",
    );
  }

  /// Fetches productivity status.
  static Future<AgentActionResult> _getProductivityStatus(WidgetRef ref) async {
    final focusState = ref.read(focusModeProvider);
    final hasActiveSession = focusState.activeSession.value != null;
    final distractingCount = focusState.focusProfile.distractingApps.length;

    return AgentActionResult(
      toolName: 'get_productivity_status',
      success: true,
      message: hasActiveSession
          ? "Active focus session running. $distractingCount apps blocked."
          : "No active session right now. $distractingCount apps configured in blocklist.",
    );
  }

  /// Resolves user natural language query to an installed [AppInfo].
  static Future<AppInfo?> _resolveApp(String query, WidgetRef ref) async {
    final cleanQuery = query.trim().toLowerCase();

    // 1. Try reading from Riverpod state
    Map<String, AppInfo>? installedMap = ref.read(appsInfoProvider).value;

    // 2. Fallback to method channel if state isn't ready
    if (installedMap == null || installedMap.isEmpty) {
      final list = await MethodChannelService.instance.fetchDeviceAppsInfo();
      installedMap = {for (final app in list) app.packageName: app};
    }

    final apps = installedMap.values.toList();

    // Exact name match (case-insensitive)
    for (final app in apps) {
      if (app.name.toLowerCase() == cleanQuery) {
        return app;
      }
    }

    // Common app aliases / normalization
    final aliasMap = {
      'whatsapp': ['whatsapp', 'wa'],
      'instagram': ['instagram', 'insta', 'ig'],
      'youtube': ['youtube', 'yt'],
      'facebook': ['facebook', 'fb'],
      'twitter': ['twitter', 'x'],
      'telegram': ['telegram', 'tg'],
      'chrome': ['chrome', 'google chrome'],
      'gmail': ['gmail', 'google mail'],
      'tiktok': ['tiktok'],
      'reddit': ['reddit'],
      'snapchat': ['snapchat', 'snap'],
      'netflix': ['netflix'],
      'spotify': ['spotify'],
    };

    for (final entry in aliasMap.entries) {
      if (entry.value.contains(cleanQuery) || cleanQuery.contains(entry.key)) {
        for (final app in apps) {
          final lowerName = app.name.toLowerCase();
          final lowerPkg = app.packageName.toLowerCase();
          if (lowerName.contains(entry.key) || lowerPkg.contains(entry.key)) {
            return app;
          }
        }
      }
    }

    // Name contains query
    for (final app in apps) {
      if (app.name.toLowerCase().contains(cleanQuery)) {
        return app;
      }
    }

    // Package contains query
    for (final app in apps) {
      if (app.packageName.toLowerCase().contains(cleanQuery)) {
        return app;
      }
    }

    return null;
  }
}
