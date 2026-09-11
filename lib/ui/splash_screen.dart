/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/config/navigation/app_routes.dart';
import 'package:comrade/core/extensions/ext_build_context.dart';
import 'package:comrade/core/extensions/ext_num.dart';
import 'package:comrade/core/services/auth_service.dart';
import 'package:comrade/config/navigation/navigation_service.dart';
import 'package:comrade/core/services/method_channel_service.dart';
import 'package:comrade/core/utils/platform_features.dart';
import 'package:comrade/providers/system/comrade_settings_provider.dart';
import 'package:comrade/providers/system/parental_controls_provider.dart';
import 'package:comrade/providers/system/permissions_provider.dart';
import 'package:comrade/ui/common/breathing_widget.dart';
import 'package:comrade/ui/common/rounded_container.dart';
import 'package:comrade/ui/common/styled_text.dart';
import 'package:comrade/ui/transitions/default_effects.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _haveAllEssentialPermissions = false;
  bool _isOnboardingDone = false;
  bool _isAccessProtected = false;
  bool _isAppUpdated = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();

    try {
      final perms =
          await ref.read(permissionProvider.notifier).fetchPermissionsStatus();
      final settings = await ref.read(comradeSettingsProvider.notifier).init();
      final parental =
          await ref.read(parentalControlsProvider.notifier).init();

      _isOnboardingDone = settings.isOnboardingDone;
      _isAppUpdated = settings.appVersion !=
          MethodChannelService.instance.deviceInfo.comradeVersion;
      _isAccessProtected = parental.protectedAccess;
      _haveAllEssentialPermissions =
          PlatformFeatures.haveEssentialPermissions(perms);
    } catch (e) {
      debugPrint('SplashScreen._bootstrap(): $e');
      // Fail closed for first-launch: show onboarding rather than home.
      _isOnboardingDone = false;
      _haveAllEssentialPermissions = false;
    }

    // Always show the logo/animation for a readable beat on both platforms.
    // iOS needs a longer pause so the first-launch sequence is not skipped.
    final minSplash = PlatformFeatures.isIOS ? 1800.ms : 250.ms;
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < minSplash) {
      await Future.delayed(minSplash - elapsed);
    }

    if (!mounted) return;
    setState(() => _isReady = true);

    if (_isAccessProtected) {
      _authenticate();
    } else {
      _goToNextScreen();
    }
  }

  void _goToNextScreen() {
    if (!mounted) return;

    // Fresh installs always go through onboarding/setup until Finish Setup.
    final canEnterApp =
        _isOnboardingDone && _haveAllEssentialPermissions;

    if (canEnterApp) {
      NavigationService.instance.init(showChangeLogsToo: _isAppUpdated);
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.onboardingPath,
      arguments: {"isOnboardingDone": _isOnboardingDone},
    );
  }

  void _authenticate() async {
    final isAuthenticated = await AuthService.instance.authenticate();

    if (!mounted) return;

    if (isAuthenticated == null) {
      context.showSnackAlert(
        context.locale.protected_access_removed_lock_snack_alert,
        icon: FluentIcons.fingerprint_20_filled,
      );
      return;
    }

    if (!isAuthenticated) {
      context.showSnackAlert(
        context.locale.protected_access_failed_lock_snack_alert,
        icon: FluentIcons.fingerprint_20_filled,
      );
      return;
    }

    _goToNextScreen();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoSide = min(320.0, size.width * 0.72);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) => SystemNavigator.pop(),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                BreathingWidget(
                  dimension: logoSide + 20,
                  child: RoundedContainer(
                    circularRadius: logoSide,
                    color: Colors.transparent,
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/comradelogo.png',
                      width: logoSide,
                      height: logoSide,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Column(
                  children: [
                    StyledText(
                      "Comrade",
                      fontSize: size.width < 360 ? 36 : 48,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    StyledText(
                      context.locale.comrade_tagline,
                      fontSize: 16,
                      isSubtitle: true,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (_isAccessProtected && _isReady)
                  FilledButton.icon(
                    icon: const Icon(FluentIcons.fingerprint_20_regular),
                    label: Text(context.locale.unlock_button_label),
                    onPressed: _authenticate,
                  )
                else
                  0.vBox,
                const StyledText(
                  "Made with ♥️ in 🇮🇳",
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ].animate(
                effects: DefaultEffects.transitionIn,
                delay: 100.ms,
                interval: 100.ms,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
