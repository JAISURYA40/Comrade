import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:comrade/core/enums/app_theme_mode.dart';
import 'package:comrade/core/services/chat/chat_tool_base.dart';
import 'package:comrade/core/services/chat/chat_tools.dart';
import 'package:comrade/models/app_info.dart';

void main() {
  group('ChangeThemeTool', () {
    final tool = ChangeThemeTool();

    test('explicit theme commands plan accurately', () {
      final blastPlan = tool.plan('change my theme to Blast');
      expect(blastPlan, isNotNull);
      expect(blastPlan!.args['mode'], equals('blast'));
      expect(blastPlan.confidence, greaterThanOrEqualTo(0.9));

      final focusPlan = tool.plan('make my theme Focus');
      expect(focusPlan, isNotNull);
      expect(focusPlan!.args['mode'], equals('focus'));

      final calmPlan = tool.plan('switch theme to calm');
      expect(calmPlan, isNotNull);
      expect(calmPlan!.args['mode'], equals('calm'));

      final darkPlan = tool.plan('turn on dark theme');
      expect(darkPlan, isNotNull);
      expect(darkPlan!.args['mode'], equals('dark'));

      final lightPlan = tool.plan('switch to light theme');
      expect(lightPlan, isNotNull);
      expect(lightPlan!.args['mode'], equals('light'));

      final sysPlan = tool.plan('use system theme mode');
      expect(sysPlan, isNotNull);
      expect(sysPlan!.args['mode'], equals('system'));
    });

    test('mood-based language plans to the correct theme', () {
      // Motivated / on fire -> Blast
      final motivated = tool.plan(
          "I'm feeling extremely motivated and on fire, change my theme");
      expect(motivated, isNotNull);
      expect(motivated!.args['mode'], equals('blast'));

      // Studying / concentration / deep-work -> Focus
      final study = tool.plan(
          'I am studying for my calculus midterm and need deep work concentration, set theme');
      expect(study, isNotNull);
      expect(study!.args['mode'], equals('focus'));

      // Peaceful / relaxed / calm / stressed / disturbed -> Calm
      final stressed = tool.plan(
          'I am feeling stressed and disturbed, change my theme to something peaceful');
      expect(stressed, isNotNull);
      expect(stressed!.args['mode'], equals('calm'));
    });

    test('execution verifies theme change and fails if not updated', () async {
      var current = AppThemeMode.light;

      // Successful verification
      final ctxOk = ChatToolContext(
        changeThemeMode: (m) async => current = m,
        currentThemeMode: () => current,
        updateAppTimer: (_, __) async {},
        resolveInstalledApps: () async => {},
        isAndroid: true,
        openSystemSettings: () async {},
      );

      final plan = tool.plan('change my theme to Blast')!;
      final resOk = await tool.execute(plan, ctxOk);
      expect(resOk.success, isTrue);
      expect(resOk.message, contains('Blast'));
      expect(current, equals(AppThemeMode.blast));

      // Failed verification: changeThemeMode fails to update state
      final ctxFail = ChatToolContext(
        changeThemeMode: (m) async {}, // doesn't update current
        currentThemeMode: () => AppThemeMode.light,
        updateAppTimer: (_, __) async {},
        resolveInstalledApps: () async => {},
        isAndroid: true,
        openSystemSettings: () async {},
      );

      final resFail = await tool.execute(plan, ctxFail);
      expect(resFail.success, isFalse);
      expect(resFail.message, contains('Verification failed'));
    });
  });

  group('BlockAppTool & UnblockAppTool', () {
    final blockTool = BlockAppTool();
    final unblockTool = UnblockAppTool();

    final Map<String, AppInfo> mockApps = {
      'com.instagram.android': AppInfo(
        name: 'Instagram',
        packageName: 'com.instagram.android',
        isImpSysApp: false,
        icon: Uint8List(0),
      ),
      'com.google.android.youtube': AppInfo(
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        isImpSysApp: false,
        icon: Uint8List(0),
      ),
    };

    test('plans app blocking from user utterances', () {
      final p1 = blockTool.plan('block Instagram');
      expect(p1, isNotNull);
      expect(p1!.args['appQuery'], equals('Instagram'));

      final p2 = blockTool.plan('restrict youtube please');
      expect(p2, isNotNull);
      expect(p2!.args['appQuery'], equals('youtube'));
    });

    test('on iOS, does not claim success and explains limitations', () async {
      final iosCtx = ChatToolContext(
        changeThemeMode: (_) async {},
        currentThemeMode: () => AppThemeMode.light,
        updateAppTimer: (_, __) async {},
        resolveInstalledApps: () async => mockApps,
        isAndroid: false, // iOS
        openSystemSettings: () async {},
      );

      final plan = blockTool.plan('block Instagram')!;
      final result = await blockTool.execute(plan, iosCtx);

      expect(result.success, isFalse);
      expect(result.message, contains('iOS'));
      expect(result.message, contains('Screen Time'));
      expect(result.message, contains('No block was claimed'));
    });

    test('on Android, checks permissions, updates timer and verifies', () async {
      final timers = <String, int>{};
      var usagePermissionGranted = true;

      final androidCtx = ChatToolContext(
        changeThemeMode: (_) async {},
        currentThemeMode: () => AppThemeMode.light,
        updateAppTimer: (pkg, sec) async => timers[pkg] = sec,
        resolveInstalledApps: () async => mockApps,
        isAndroid: true,
        openSystemSettings: () async {},
        hasUsagePermission: () async => usagePermissionGranted,
        getAppTimer: (pkg) => timers[pkg] ?? 0,
      );

      final plan = blockTool.plan('block Instagram')!;
      final result = await blockTool.execute(plan, androidCtx);

      expect(result.success, isTrue);
      expect(result.message, contains('Blocked Instagram'));
      expect(timers['com.instagram.android'], equals(1));

      // With missing usage permission, warns user in response
      usagePermissionGranted = false;
      final resultWithWarning = await blockTool.execute(plan, androidCtx);
      expect(resultWithWarning.success, isTrue);
      expect(resultWithWarning.message, contains('Usage Access'));
    });

    test('unblock app clears restrictions and verifies', () async {
      final timers = <String, int>{'com.instagram.android': 1};

      final androidCtx = ChatToolContext(
        changeThemeMode: (_) async {},
        currentThemeMode: () => AppThemeMode.light,
        updateAppTimer: (pkg, sec) async => timers[pkg] = sec,
        resolveInstalledApps: () async => mockApps,
        isAndroid: true,
        openSystemSettings: () async {},
        getAppTimer: (pkg) => timers[pkg] ?? 0,
      );

      final plan = unblockTool.plan('unblock Instagram')!;
      expect(plan, isNotNull);
      final result = await unblockTool.execute(plan, androidCtx);

      expect(result.success, isTrue);
      expect(result.message, contains('Unblocked Instagram'));
      expect(timers['com.instagram.android'], equals(0));
    });
  });

  group('FocusSessionTool', () {
    final tool = FocusSessionTool();

    test('plans starting and stopping focus sessions', () {
      final startPlan = tool.plan('start a focus session');
      expect(startPlan, isNotNull);
      expect(startPlan!.args['action'], equals('start'));

      final stopPlan = tool.plan('stop focus session');
      expect(stopPlan, isNotNull);
      expect(stopPlan!.args['action'], equals('stop'));
    });

    test('executes and verifies focus session state', () async {
      var isActive = false;

      final ctx = ChatToolContext(
        changeThemeMode: (_) async {},
        currentThemeMode: () => AppThemeMode.light,
        updateAppTimer: (_, __) async {},
        resolveInstalledApps: () async => {},
        isAndroid: true,
        openSystemSettings: () async {},
        startFocusSession: () async => isActive = true,
        stopFocusSession: () async => isActive = false,
        isFocusSessionActive: () => isActive,
      );

      final startResult =
          await tool.execute(tool.plan('start focus mode')!, ctx);
      expect(startResult.success, isTrue);
      expect(isActive, isTrue);

      final stopResult =
          await tool.execute(tool.plan('end focus session')!, ctx);
      expect(stopResult.success, isTrue);
      expect(isActive, isFalse);
    });
  });

  group('ChatToolRegistry', () {
    final registry = buildDefaultChatTools();

    test('resolves highest confidence plan for supported actions', () {
      expect(
        registry.resolveBestPlan('change theme to blast')?.toolName,
        equals('change_theme'),
      );
      expect(
        registry.resolveBestPlan('block youtube')?.toolName,
        equals('block_app'),
      );
      expect(
        registry.resolveBestPlan('unblock youtube')?.toolName,
        equals('unblock_app'),
      );
      expect(
        registry.resolveBestPlan('start a focus session')?.toolName,
        equals('focus_session'),
      );
      expect(
        registry.resolveBestPlan('open settings')?.toolName,
        equals('open_settings'),
      );
    });

    test('returns null for standard conversational queries', () {
      expect(
        registry.resolveBestPlan('what did I tell you yesterday?'),
        isNull,
      );
      expect(
        registry.resolveBestPlan('how can I stay disciplined with coding?'),
        isNull,
      );
    });
  });
}
