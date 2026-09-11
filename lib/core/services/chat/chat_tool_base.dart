/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:comrade/core/enums/app_theme_mode.dart';
import 'package:comrade/models/app_info.dart';

/// Result of a tool execution — never claim success unless [success] is true.
class ChatToolResult {
  const ChatToolResult({
    required this.success,
    required this.message,
    this.needsConfirmation = false,
    this.pendingActionId,
  });

  final bool success;
  final String message;
  final bool needsConfirmation;
  final String? pendingActionId;

  factory ChatToolResult.ok(String message) =>
      ChatToolResult(success: true, message: message);

  factory ChatToolResult.fail(String message) =>
      ChatToolResult(success: false, message: message);

  factory ChatToolResult.confirm({
    required String message,
    required String actionId,
  }) =>
      ChatToolResult(
        success: false,
        message: message,
        needsConfirmation: true,
        pendingActionId: actionId,
      );
}

class ChatToolContext {
  ChatToolContext({
    required this.changeThemeMode,
    required this.currentThemeMode,
    required this.updateAppTimer,
    required this.resolveInstalledApps,
    required this.isAndroid,
    required this.openSystemSettings,
    this.hasUsagePermission,
    this.getAppTimer,
    this.startFocusSession,
    this.stopFocusSession,
    this.isFocusSessionActive,
  });

  final Future<void> Function(AppThemeMode mode) changeThemeMode;
  final AppThemeMode Function() currentThemeMode;
  final Future<void> Function(String packageName, int timerSec) updateAppTimer;
  final Future<Map<String, AppInfo>> Function() resolveInstalledApps;
  final bool isAndroid;
  final Future<void> Function() openSystemSettings;
  final Future<bool> Function()? hasUsagePermission;
  final int Function(String packageName)? getAppTimer;
  final Future<void> Function()? startFocusSession;
  final Future<void> Function()? stopFocusSession;
  final bool Function()? isFocusSessionActive;
}

abstract class ChatTool {
  String get name;
  String get description;

  /// Returns null when this tool cannot handle [message].
  ChatToolPlan? plan(String message);

  Future<ChatToolResult> execute(ChatToolPlan plan, ChatToolContext ctx);
}

class ChatToolPlan {
  const ChatToolPlan({
    required this.toolName,
    required this.args,
    required this.confidence,
    this.summary = '',
  });

  final String toolName;
  final Map<String, dynamic> args;
  final double confidence;
  final String summary;
}

/// Registry so new Comrade actions can be added without rewriting the agent.
class ChatToolRegistry {
  ChatToolRegistry(List<ChatTool> tools) : _tools = List.unmodifiable(tools);

  final List<ChatTool> _tools;

  List<ChatTool> get tools => _tools;

  ChatTool? byName(String name) {
    for (final t in _tools) {
      if (t.name == name) return t;
    }
    return null;
  }

  /// Intent → best tool plan (scored matchers, not naive single keywords).
  ChatToolPlan? resolveBestPlan(String message) {
    ChatToolPlan? best;
    for (final tool in _tools) {
      final plan = tool.plan(message);
      if (plan == null) continue;
      if (best == null || plan.confidence > best.confidence) {
        best = plan;
      }
    }
    if (best == null || best.confidence < 0.55) return null;
    return best;
  }
}
