/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/material.dart';
import 'package:comrade/core/extensions/ext_build_context.dart';
import 'package:comrade/core/extensions/ext_num.dart';
import 'package:comrade/core/services/method_channel_service.dart';
import 'package:comrade/core/utils/platform_features.dart';
import 'package:comrade/ui/onboarding/onboarding_page.dart';
import 'package:comrade/ui/permissions/alarm_permission_tile.dart';
import 'package:comrade/ui/permissions/battery_permission_tile.dart';
import 'package:comrade/ui/permissions/display_overlay_permission_tile.dart';
import 'package:comrade/ui/permissions/notification_permission_tile.dart';
import 'package:comrade/ui/permissions/usage_access_permission_tile.dart';

class PermissionsPage extends StatelessWidget {
  const PermissionsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 24 is min sdk
    final sdkVersion = MethodChannelService.instance.deviceInfo.sdkVersion;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          OnboardingPage(
            bottomPadding: 0,
            title: context.locale.onboarding_page_permissions_title,
            imgArtPath: "assets/illustrations/onboarding_4.png",
            description: context.locale.onboarding_page_permissions_info,
          ),

          12.vBox,

          /// Permission tiles
          const NotificationPermissionTile(),

          if (PlatformFeatures.isAndroid) ...[
            const BatteryPermissionTile(),
            // Only SDK version Android(S [31]) and above need this permission
            if (sdkVersion >= 31) const AlarmPermissionTile(),
            const UsageAccessPermissionTile(),
            if (PlatformFeatures.hasDisplayOverlay)
              const DisplayOverlayPermissionTile(),
          ],

          SizedBox(height: 108 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
