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
import 'package:comrade/core/extensions/ext_widget.dart';
import 'package:comrade/providers/restrictions/bedtime_provider.dart';
import 'package:comrade/ui/common/default_list_tile.dart';
import 'package:comrade/ui/common/device_dnd_tile.dart';
import 'package:comrade/ui/common/content_section_header.dart';
import 'package:comrade/ui/dialogs/modal_bottom_sheet.dart';
import 'package:comrade/ui/permissions/dnd_switch_tile.dart';
import 'package:comrade/ui/screens/home/bedtime/bedtime_distracting_apps_list.dart';
import 'package:sliver_tools/sliver_tools.dart';

class BedtimeQuickActions extends ConsumerWidget {
  const BedtimeQuickActions({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldStartDnd =
        ref.watch(bedtimeScheduleProvider.select((v) => v.shouldStartDnd));

    final isScheduleOn =
        ref.watch(bedtimeScheduleProvider.select((v) => v.isScheduleOn));

    return MultiSliver(
      children: [
        /// Bedtime actions
        ContentSectionHeader(title: context.locale.quick_actions_heading)
            .sliver,

        /// Should start dnd
        DndSwitchTile(
          position: ItemPosition.top,
          enabled: !isScheduleOn,
          switchValue: shouldStartDnd,
          onPressed: () => ref
              .read(bedtimeScheduleProvider.notifier)
              .setShouldStartDnd(!shouldStartDnd),
        ),

        /// Manage Dnd settings
        const DeviceDndTile(
          position: ItemPosition.mid,
        ),

        /// Manage distracting apps
        DefaultListTile(
          position: ItemPosition.bottom,
          leading: const Icon(FluentIcons.weather_moon_20_regular),
          titleText: context.locale.distracting_apps_tile_title,
          subtitleText: context.locale.distracting_apps_tile_subtitle,
          trailing: const Icon(FluentIcons.arrow_up_right_20_filled),
          onPressed: () => showDefaultBottomSheet(
            context: context,
            sliverBody: const BedtimeDistractingAppsList(),
          ),
        ),
      ],
    );
  }
}
