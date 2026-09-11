/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/config/navigation/navigation_service.dart';
import 'package:comrade/core/extensions/ext_build_context.dart';
import 'package:comrade/core/extensions/ext_num.dart';
import 'package:comrade/config/app_constants.dart';
import 'package:comrade/core/utils/platform_features.dart';
import 'package:comrade/models/permissions_model.dart';
import 'package:comrade/providers/system/comrade_settings_provider.dart';
import 'package:comrade/providers/system/permissions_provider.dart';
import 'package:comrade/ui/onboarding/onboarding_page.dart';
import 'package:comrade/ui/onboarding/permission_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    required this.isOnboardingDone,
    super.key,
  });

  final bool isOnboardingDone;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  int _currentPage = 0;
  ProviderSubscription? _subscription;
  bool _isFinishing = false;
  final PageController _controller = PageController();
  final _animCurve = Curves.easeInOut;
  final _animDuration = AppConstants.defaultAnimDuration;
  late final List<Widget> _pages = [
    OnboardingPage(
      title: context.locale.onboarding_page_one_title,
      imgArtPath: "assets/illustrations/onboarding_1.png",
      description: context.locale.onboarding_page_one_info,
    ),
    OnboardingPage(
      title: context.locale.onboarding_page_two_title,
      imgArtPath: "assets/illustrations/onboarding_2.png",
      description: context.locale.onboarding_page_two_info,
    ),
    OnboardingPage(
      title: context.locale.onboarding_page_three_title,
      imgArtPath: "assets/illustrations/onboarding_3.png",
      description: context.locale.onboarding_page_three_info,
    ),
    const PermissionsPage(),
  ];

  @override
  void initState() {
    super.initState();

    // Android: auto-finish when all essential permissions are granted.
    // iOS: require explicit Finish Setup so the setup flow is never skipped.
    if (PlatformFeatures.isAndroid) {
      _subscription = ref.listenManual<PermissionsModel>(
        permissionProvider,
        (_, perms) {
          if (!PlatformFeatures.haveEssentialPermissions(perms)) return;
          _finishOnboarding();
          _subscription?.close();
        },
      );
    }

    if (widget.isOnboardingDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _skipToLastPage();
      });
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    _controller.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    if (!mounted || _isFinishing) return;
    _isFinishing = true;

    ref.read(comradeSettingsProvider.notifier).markOnboardingDone();

    await Future.delayed(200.ms);
    if (!mounted) return;
    NavigationService.instance
        .init(showChangeLogsToo: !widget.isOnboardingDone);
  }

  void _skipToLastPage() {
    if (!mounted) return;
    _controller.animateToPage(
      _pages.length - 1,
      duration: _animDuration,
      curve: _animCurve,
    );
  }

  bool _canFinishSetup(PermissionsModel perms) {
    if (PlatformFeatures.isIOS) {
      // iOS: user can finish after reviewing permissions; notification is
      // encouraged via the tile but may be skipped.
      return true;
    }
    return PlatformFeatures.haveEssentialPermissions(perms);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final perms = ref.watch(permissionProvider);
    final canFinish = _canFinishSetup(perms);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) => SystemNavigator.pop(),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _pages[index],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _skipToLastPage,
                      child: Text(context.locale.onboarding_skip_btn_label),
                    )
                        .animate(target: isLastPage ? 0 : 1)
                        .scale(duration: 100.ms),
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: EdgeInsets.only(
                        bottom: math.max(16.0, bottomInset),
                        top: 4,
                      ),
                      child: Row(
                        children: [
                          SmoothPageIndicator(
                            controller: _controller,
                            count: _pages.length,
                            effect: ExpandingDotsEffect(
                              dotWidth: 10,
                              dotHeight: 10,
                              spacing: 6,
                              expansionFactor: 2.5,
                              dotColor: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              activeDotColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          IconButton.filledTonal(
                            onPressed: () => _controller.previousPage(
                              curve: _animCurve,
                              duration: _animDuration,
                            ),
                            padding: const EdgeInsets.all(10),
                            icon: const Icon(FluentIcons.caret_left_20_filled),
                          )
                              .animate(
                                target: _currentPage > 0 && !isLastPage ? 1 : 0,
                              )
                              .scale(duration: 150.ms),
                          4.hBox,
                          isLastPage
                              ? FilledButton(
                                  onPressed: canFinish && !_isFinishing
                                      ? () => _finishOnboarding()
                                      : null,
                                  child: Text(
                                    context.locale
                                        .onboarding_finish_setup_btn_label,
                                  ),
                                ).animate(target: isLastPage ? 1 : 0).scale(
                                    duration: 250.ms,
                                    alignment: Alignment.centerRight,
                                  )
                              : IconButton.filled(
                                  padding: const EdgeInsets.all(10),
                                  onPressed: () => _controller.nextPage(
                                    curve: _animCurve,
                                    duration: _animDuration,
                                  ),
                                  icon: const Icon(
                                    FluentIcons.caret_right_20_filled,
                                  ),
                                )
                                  .animate(target: isLastPage ? 0 : 1)
                                  .scale(duration: 150.ms),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
