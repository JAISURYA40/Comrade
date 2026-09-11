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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/core/enums/item_position.dart';
import 'package:comrade/core/extensions/ext_build_context.dart';
import 'package:comrade/core/services/method_channel_service.dart';
import 'package:comrade/core/utils/platform_features.dart';
import 'package:comrade/providers/system/permissions_provider.dart';
import 'package:comrade/ui/common/default_list_tile.dart';
import 'package:comrade/ui/permissions/permission_sheet.dart';

class NotificationPermissionTile extends ConsumerWidget {
  const NotificationPermissionTile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final havePermission = ref
        .watch(permissionProvider.select((v) => v.haveNotificationPermission));

    return DefaultListTile(
      position: PlatformFeatures.isIOS ? ItemPosition.none : ItemPosition.top,
      titleText: context.locale.permission_notification_title,
      accent: havePermission ? null : Theme.of(context).colorScheme.error,
      subtitleText: havePermission
          ? context.locale.permission_status_allowed
          : context.locale.permission_status_not_allowed,
      isSelected: havePermission,
      onPressed: havePermission
          ? null
          : () {
              if (PlatformFeatures.isIOS) {
                _showIosSheet(context, ref);
              } else {
                ref
                    .read(permissionProvider.notifier)
                    .askNotificationPermission();
              }
            },
    );
  }

  void _showIosSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => PermissionSheet(
        icon: FluentIcons.alert_20_filled,
        title: context.locale.permission_notification_title,
        description:
            'Allow notifications so Comrade can remind you about focus, bedtime, and timers. If permission was denied earlier, this opens Settings.',
        onTapGrantPermission: () async {
          Navigator.of(sheetContext).maybePop();
          final granted = await MethodChannelService.instance
              .getAndAskNotificationPermission(askPermissionToo: true);
          await ref.read(permissionProvider.notifier).fetchPermissionsStatus();
          if (!granted) {
            await MethodChannelService.instance.openAppSettingsForPackage('');
          }
        },
      ),
    );
  }
}
