/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/core/enums/item_position.dart';
import 'package:comrade/core/extensions/ext_build_context.dart';
import 'package:comrade/core/extensions/ext_duration.dart';
import 'package:comrade/config/hero_tags.dart';
import 'package:comrade/models/app_info.dart';
import 'package:comrade/providers/system/parental_controls_provider.dart';
import 'package:comrade/providers/restrictions/apps_restrictions_provider.dart';
import 'package:comrade/ui/common/default_list_tile.dart';
import 'package:comrade/ui/common/time_text_short.dart';
import 'package:comrade/ui/dialogs/timer_picker_dialog.dart';
import 'package:comrade/ui/transitions/default_hero.dart';

class AppTimerTile extends ConsumerWidget {
  const AppTimerTile({
    required this.appInfo,
    required this.appTimer,
    required this.isPurged,
    this.isIconButton = false,
    super.key,
  });

  final AppInfo appInfo;
  final int appTimer;
  final bool isPurged;
  final bool isIconButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isIconButton
        ? IconButton(
            icon: appTimer > 0
                ? TimeTextShort(timeDuration: appTimer.seconds)
                : const Icon(FluentIcons.timer_20_regular),
            onPressed: () => _pickAppTimer(context, ref),
          )
        : DefaultHero(
            tag: HeroTags.appTimerTileTag(appInfo.packageName),
            child: DefaultListTile(
              position: ItemPosition.top,
              titleText: context.locale.app_timer_tile_title,
              enabled: !appInfo.isImpSysApp,
              subtitleText: appTimer > 0
                  ? appTimer.seconds.toTimeFull(context)
                  : context.locale.app_limit_status_not_set,
              leadingIcon: FluentIcons.timer_20_regular,
              accent: isPurged ? Theme.of(context).colorScheme.error : null,
              trailing:
                  isPurged ? Text(context.locale.timer_status_paused) : null,
              onPressed: () => _pickAppTimer(context, ref),
            ),
          );
  }

  void _pickAppTimer(
    BuildContext context,
    WidgetRef ref,
  ) async {
    /// If restricted by invincible mode
    final isInvincibleRestricted = ref.read(parentalControlsProvider
            .select((v) => v.isInvincibleModeOn && v.includeAppsTimer)) &&
        !ref.read(parentalControlsProvider.notifier).isBetweenInvincibleWindow;

    if (isInvincibleRestricted && appTimer > 0) {
      context.showSnackAlert(
        context.locale.invincible_mode_snack_alert,
      );
      return;
    }

    final newTimer = await showAppTimerPicker(
      appInfo: appInfo,
      heroTag: isIconButton
          ? HeroTags.applicationTileTag(appInfo.packageName)
          : HeroTags.appTimerTileTag(appInfo.packageName),
      context: context,
      initialTime: appTimer,
    );

    if (newTimer == null || newTimer == appTimer) return;
    ref
        .read(appsRestrictionsProvider.notifier)
        .updateAppTimer(appInfo.packageName, newTimer);
  }
}
