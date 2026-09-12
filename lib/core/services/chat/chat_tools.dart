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
import 'package:comrade/core/services/chat/chat_tool_base.dart';
import 'package:comrade/core/utils/platform_features.dart';
import 'package:comrade/models/app_info.dart';

/// Theme / mood theme tool — Blast, Focus, Calm (+ classic modes).
class ChangeThemeTool implements ChatTool {
  @override
  String get name => 'change_theme';

  @override
  String get description =>
      'Change Comrade global theme (system/light/dark/blast/focus/calm).';

  @override
  ChatToolPlan? plan(String message) {
    final q = message.toLowerCase().trim();
    final wantsTheme = RegExp(
      r'\b(theme|appearance|look|mode|color\s*scheme)\b',
    ).hasMatch(q);
    final moodCue = _scoreMood(q);

    AppThemeMode? mode;
    var confidence = 0.0;
    var reason = '';

    // Explicit name wins.
    if (RegExp(r'\bblast\b').hasMatch(q)) {
      mode = AppThemeMode.blast;
      confidence = wantsTheme ? 0.95 : 0.7;
      reason = 'explicit Blast';
    } else if (RegExp(r'\bfocus\b').hasMatch(q) &&
        (wantsTheme || moodCue.$1 == AppThemeMode.focus)) {
      mode = AppThemeMode.focus;
      confidence = wantsTheme ? 0.95 : 0.72;
      reason = 'explicit Focus';
    } else if (RegExp(r'\bcalm\b').hasMatch(q)) {
      mode = AppThemeMode.calm;
      confidence = wantsTheme ? 0.95 : 0.7;
      reason = 'explicit Calm';
    } else if (RegExp(r'\b(system|auto)\b').hasMatch(q) && wantsTheme) {
      mode = AppThemeMode.system;
      confidence = 0.9;
      reason = 'system theme';
    } else if (RegExp(r'\blight\b').hasMatch(q) && wantsTheme) {
      mode = AppThemeMode.light;
      confidence = 0.9;
      reason = 'light theme';
    } else if (RegExp(r'\bdark\b').hasMatch(q) && wantsTheme) {
      mode = AppThemeMode.dark;
      confidence = 0.9;
      reason = 'dark theme';
    } else if (wantsTheme && moodCue.$1 != null) {
      mode = moodCue.$1;
      confidence = moodCue.$2;
      reason = 'mood → ${mode!.name}';
    } else if (!wantsTheme && moodCue.$2 >= 0.8) {
      // Strong mood + change request without saying "theme"
      final changeVerb = RegExp(
        r'\b(change|switch|set|make|activate|enable|use)\b',
      ).hasMatch(q);
      if (changeVerb) {
        mode = moodCue.$1;
        confidence = moodCue.$2;
        reason = 'mood+change → ${mode!.name}';
      }
    }

    if (mode == null) return null;

    return ChatToolPlan(
      toolName: name,
      args: {'mode': mode.name, 'reason': reason},
      confidence: confidence.clamp(0.0, 1.0),
      summary: 'Set theme to ${mode.name}',
    );
  }

  (AppThemeMode?, double) _scoreMood(String q) {
    var blast = 0.0;
    var focus = 0.0;
    var calm = 0.0;

    void add(List<String> words, void Function(double) bump) {
      for (final w in words) {
        if (q.contains(w)) bump(w.length > 6 ? 0.35 : 0.28);
      }
    }

    add(
      [
        'motivated',
        'on fire',
        'energetic',
        'energy',
        'pumped',
        'hype',
        'fired up',
        'unstoppable',
        'amber',
        'flame',
        'orange',
        'burn',
        'crush it',
      ],
      (v) => blast += v,
    );
    add(
      [
        'studying',
        'study',
        'concentration',
        'concentrate',
        'deep work',
        'deep-work',
        'focus mode',
        'productive',
        'productivity',
        'reading',
        'prep',
        'revision',
        'sky blue',
        'sky-blue',
      ],
      (v) => focus += v,
    );
    add(
      [
        'peaceful',
        'relaxed',
        'relax',
        'calm',
        'stressed',
        'stress',
        'disturbed',
        'anxious',
        'anxiety',
        'overwhelmed',
        'chill',
        'serene',
        'restless',
        'unwind',
        'tranquility',
      ],
      (v) => calm += v,
    );

    final scores = {
      AppThemeMode.blast: blast,
      AppThemeMode.focus: focus,
      AppThemeMode.calm: calm,
    };
    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (best.value < 0.28) return (null, 0);
    // Map raw score → confidence
    final conf = (0.55 + best.value).clamp(0.55, 0.95);
    return (best.key, conf);
  }

  @override
  Future<ChatToolResult> execute(ChatToolPlan plan, ChatToolContext ctx) async {
    final modeName = plan.args['mode'] as String? ?? '';
    AppThemeMode? mode;
    for (final m in AppThemeMode.values) {
      if (m.name == modeName) {
        mode = m;
        break;
      }
    }
    if (mode == null) {
      return ChatToolResult.fail('Unknown theme "$modeName".');
    }

    try {
      await ctx.changeThemeMode(mode);
      // Verify
      final current = ctx.currentThemeMode();
      if (current != mode) {
        return ChatToolResult.fail(
          'Verification failed: tried to switch to ${mode.name}, but theme is still ${current.name}.',
        );
      }
      final label = _label(mode);
      return ChatToolResult.ok('Theme set to $label.');
    } catch (e) {
      return ChatToolResult.fail('Could not change theme: $e');
    }
  }

  String _label(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.blast:
        return 'Blast';
      case AppThemeMode.focus:
        return 'Focus';
      case AppThemeMode.calm:
        return 'Calm';
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }
}

/// Block / heavily limit an installed app via existing Android restrictions.
class BlockAppTool implements ChatTool {
  @override
  String get name => 'block_app';

  @override
  String get description =>
      'Block or heavily limit an app (Android app timer). iOS explains limits.';

  @override
  ChatToolPlan? plan(String message) {
    final q = message.toLowerCase().trim();
    if (q.contains('unblock') || q.contains('remove restriction')) return null;

    final blockVerb = RegExp(
      r'\b(block|restrict|limit|lock|ban|disable)\b',
    ).hasMatch(q);
    if (!blockVerb) return null;

    // "block Instagram", "restrict youtube", etc.
    final match = RegExp(
      r'\b(?:block|restrict|limit|lock|ban|disable)\s+(?:the\s+)?([a-z0-9 .+-]{2,40})',
      caseSensitive: false,
    ).firstMatch(message);
    var appQuery = match?.group(1)?.trim() ?? '';
    appQuery = appQuery
        .replaceAll(RegExp(r'\b(please|app|for\s+me|now|right\s+now)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .trim();
    if (appQuery.isEmpty) {
      // "instagram block please"
      final soft = RegExp(
        r'\b(instagram|youtube|tiktok|twitter|x|facebook|snapchat|reddit|whatsapp|netflix)\b',
        caseSensitive: false,
      ).firstMatch(q);
      appQuery = soft?.group(1) ?? '';
    }
    if (appQuery.isEmpty) return null;

    return ChatToolPlan(
      toolName: name,
      args: {'appQuery': appQuery},
      confidence: 0.88,
      summary: 'Block $appQuery',
    );
  }

  @override
  Future<ChatToolResult> execute(ChatToolPlan plan, ChatToolContext ctx) async {
    final query = (plan.args['appQuery'] as String? ?? '').trim();
    if (query.isEmpty) {
      return ChatToolResult.fail('Which app should I block?');
    }

    if (!ctx.isAndroid && !PlatformFeatures.isAndroid) {
      return ChatToolResult.fail(
        'System-level app blocking is not permitted by iOS for third-party apps '
        'without Apple Family Controls / Screen Time entitlement. '
        'Closest option: use iOS Screen Time in Settings, or start a Comrade Focus session '
        'to build discipline. No block was claimed or applied on iOS.',
      );
    }

    try {
      final apps = await ctx.resolveInstalledApps();
      final resolved = _resolvePackage(apps, query);
      if (resolved == null) {
        return ChatToolResult.fail(
          'Could not find an installed app matching "$query".',
        );
      }

      // Check Android usage access permission
      var permNotice = '';
      if (ctx.hasUsagePermission != null) {
        final hasUsage = await ctx.hasUsagePermission!();
        if (!hasUsage) {
          permNotice =
              ' (Note: Please grant Usage Access permission in settings so Android can intercept this app).';
        }
      }

      // 1 second daily timer ≈ effective block via existing tracker service.
      const timerSec = 1;
      await ctx.updateAppTimer(resolved.packageName, timerSec);

      // Verify restriction state
      if (ctx.getAppTimer != null) {
        final currentTimer = ctx.getAppTimer!(resolved.packageName);
        if (currentTimer != timerSec) {
          return ChatToolResult.fail(
            'Verification failed: app timer could not be verified in Comrade storage.',
          );
        }
      }

      final appDisplayName =
          resolved.name.isEmpty ? query : resolved.name;
      return ChatToolResult.ok(
        'Blocked $appDisplayName (daily limit set to 1s via Comrade restrictions)$permNotice.',
      );
    } catch (e) {
      return ChatToolResult.fail('Block failed: $e');
    }
  }

  AppInfo? _resolvePackage(Map<String, AppInfo> apps, String query) {
    final q = query.toLowerCase();
    // Known package shortcuts
    const aliases = {
      'instagram': 'com.instagram.android',
      'youtube': 'com.google.android.youtube',
      'tiktok': 'com.zhiliaoapp.musically',
      'facebook': 'com.facebook.katana',
      'snapchat': 'com.snapchat.android',
      'reddit': 'com.reddit.frontpage',
      'whatsapp': 'com.whatsapp',
      'netflix': 'com.netflix.mediaclient',
      'twitter': 'com.twitter.android',
      'x': 'com.twitter.android',
    };
    final aliasPkg = aliases[q];
    if (aliasPkg != null && apps.containsKey(aliasPkg)) {
      return apps[aliasPkg];
    }

    AppInfo? best;
    var bestScore = 0;
    for (final app in apps.values) {
      final name = app.name.toLowerCase();
      final pkg = app.packageName.toLowerCase();
      var score = 0;
      if (name == q) {
        score = 100;
      } else if (name.contains(q)) {
        score = 80;
      } else if (pkg.contains(q.replaceAll(' ', ''))) {
        score = 60;
      }
      if (score > bestScore) {
        bestScore = score;
        best = app;
      }
    }
    return bestScore >= 60 ? best : null;
  }
}

/// Unblock / remove limits on an installed app.
class UnblockAppTool implements ChatTool {
  @override
  String get name => 'unblock_app';

  @override
  String get description => 'Unblock or remove timer restrictions on an app.';

  @override
  ChatToolPlan? plan(String message) {
    final q = message.toLowerCase().trim();
    final isUnblock = RegExp(
      r'\b(unblock|remove\s+restriction|remove\s+limit|clear\s+limit|allow|enable)\b',
    ).hasMatch(q);
    if (!isUnblock) return null;

    final match = RegExp(
      r'\b(?:unblock|remove\s+restriction\s+(?:on|for)?|remove\s+limit\s+(?:on|for)?|clear\s+limit\s+(?:on|for)?|allow|enable)\s+(?:the\s+)?([a-z0-9 .+-]{2,40})',
      caseSensitive: false,
    ).firstMatch(message);

    var appQuery = match?.group(1)?.trim() ?? '';
    appQuery = appQuery
        .replaceAll(RegExp(r'\b(please|app|for\s+me|now|right\s+now)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .trim();
    if (appQuery.isEmpty) {
      final soft = RegExp(
        r'\b(instagram|youtube|tiktok|twitter|x|facebook|snapchat|reddit|whatsapp|netflix)\b',
        caseSensitive: false,
      ).firstMatch(q);
      appQuery = soft?.group(1) ?? '';
    }
    if (appQuery.isEmpty) return null;

    return ChatToolPlan(
      toolName: name,
      args: {'appQuery': appQuery},
      confidence: 0.88,
      summary: 'Unblock $appQuery',
    );
  }

  @override
  Future<ChatToolResult> execute(ChatToolPlan plan, ChatToolContext ctx) async {
    final query = (plan.args['appQuery'] as String? ?? '').trim();
    if (query.isEmpty) {
      return ChatToolResult.fail('Which app should I unblock?');
    }

    if (!ctx.isAndroid && !PlatformFeatures.isAndroid) {
      return ChatToolResult.fail(
        'App restrictions are managed on Android. On iOS, adjust limits directly in iOS Screen Time.',
      );
    }

    try {
      final apps = await ctx.resolveInstalledApps();
      final resolved = _resolvePackage(apps, query);
      if (resolved == null) {
        return ChatToolResult.fail(
          'Could not find an installed app matching "$query".',
        );
      }

      await ctx.updateAppTimer(resolved.packageName, 0);

      // Verify restriction state
      if (ctx.getAppTimer != null) {
        final currentTimer = ctx.getAppTimer!(resolved.packageName);
        if (currentTimer != 0) {
          return ChatToolResult.fail(
            'Verification failed: restriction could not be cleared.',
          );
        }
      }

      final appDisplayName =
          resolved.name.isEmpty ? query : resolved.name;
      return ChatToolResult.ok('Unblocked $appDisplayName (restriction removed).');
    } catch (e) {
      return ChatToolResult.fail('Unblock failed: $e');
    }
  }

  AppInfo? _resolvePackage(Map<String, AppInfo> apps, String query) {
    final q = query.toLowerCase();
    for (final app in apps.values) {
      if (app.name.toLowerCase() == q ||
          app.packageName.toLowerCase().contains(q)) {
        return app;
      }
    }
    return null;
  }
}

/// Control Focus sessions (start/stop focus sessions).
class FocusSessionTool implements ChatTool {
  @override
  String get name => 'focus_session';

  @override
  String get description => 'Start or stop a Comrade focus session.';

  @override
  ChatToolPlan? plan(String message) {
    final q = message.toLowerCase().trim();
    final isStart = RegExp(
      r'\b(start|begin|launch|activate)\b.*\b(focus|study|session|deep work)\b',
    ).hasMatch(q);
    final isStop = RegExp(
      r'\b(stop|end|finish|quit|cancel|give up)\b.*\b(focus|session)\b',
    ).hasMatch(q);

    if (isStart) {
      return const ChatToolPlan(
        toolName: 'focus_session',
        args: {'action': 'start'},
        confidence: 0.88,
        summary: 'Start focus session',
      );
    } else if (isStop) {
      return const ChatToolPlan(
        toolName: 'focus_session',
        args: {'action': 'stop'},
        confidence: 0.88,
        summary: 'End focus session',
      );
    }
    return null;
  }

  @override
  Future<ChatToolResult> execute(ChatToolPlan plan, ChatToolContext ctx) async {
    final action = plan.args['action'] as String? ?? 'start';
    if (action == 'start') {
      if (ctx.startFocusSession == null) {
        return ChatToolResult.fail('Focus session service unavailable.');
      }
      try {
        await ctx.startFocusSession!();
        if (ctx.isFocusSessionActive != null &&
            !ctx.isFocusSessionActive!()) {
          return ChatToolResult.fail('Could not verify that focus session started.');
        }
        return ChatToolResult.ok('Focus session started. Stay locked in!');
      } catch (e) {
        return ChatToolResult.fail('Could not start focus session: $e');
      }
    } else {
      if (ctx.stopFocusSession == null) {
        return ChatToolResult.fail('Focus session service unavailable.');
      }
      try {
        await ctx.stopFocusSession!();
        if (ctx.isFocusSessionActive != null &&
            ctx.isFocusSessionActive!()) {
          return ChatToolResult.fail('Focus session is still active.');
        }
        return ChatToolResult.ok('Focus session completed.');
      } catch (e) {
        return ChatToolResult.fail('Could not stop focus session: $e');
      }
    }
  }
}

/// Open system settings (permission / Screen Time hint on iOS).
class OpenSettingsTool implements ChatTool {
  @override
  String get name => 'open_settings';

  @override
  String get description => 'Open system settings for permissions.';

  @override
  ChatToolPlan? plan(String message) {
    final q = message.toLowerCase();
    if (RegExp(r'\b(open|go to|launch)\b.*\bsettings\b').hasMatch(q) ||
        q.contains('open settings')) {
      return const ChatToolPlan(
        toolName: 'open_settings',
        args: {},
        confidence: 0.85,
        summary: 'Open settings',
      );
    }
    return null;
  }

  @override
  Future<ChatToolResult> execute(ChatToolPlan plan, ChatToolContext ctx) async {
    try {
      await ctx.openSystemSettings();
      return ChatToolResult.ok('Opened system settings.');
    } catch (e) {
      return ChatToolResult.fail('Could not open settings: $e');
    }
  }
}

ChatToolRegistry buildDefaultChatTools() => ChatToolRegistry([
      ChangeThemeTool(),
      BlockAppTool(),
      UnblockAppTool(),
      FocusSessionTool(),
      OpenSettingsTool(),
    ]);
