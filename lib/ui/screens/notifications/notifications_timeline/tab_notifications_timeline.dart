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
import 'package:comrade/core/extensions/ext_date_time.dart';
import 'package:comrade/core/extensions/ext_num.dart';
import 'package:comrade/core/extensions/ext_widget.dart';
import 'package:comrade/core/utils/date_time_utils.dart';
import 'package:comrade/providers/notifications/dated_notifications_provider.dart';
import 'package:comrade/providers/notifications/monthly_notifications_count_provider.dart';
import 'package:comrade/ui/common/default_refresh_indicator.dart';
import 'package:comrade/ui/common/content_section_header.dart';
import 'package:comrade/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:comrade/ui/common/styled_text.dart';
import 'package:comrade/ui/common/usage_glance_card.dart';
import 'package:comrade/ui/screens/focus/focus_timeline/sliver_heatmap_calender.dart';
import 'package:comrade/ui/screens/notifications/sliver_notifications_list.dart';

class TabNotificationTimeline extends ConsumerStatefulWidget {
  const TabNotificationTimeline({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TabNotificationTimelineState();
}

class _TabNotificationTimelineState
    extends ConsumerState<TabNotificationTimeline> {
  DateTimeRange _monthRange = dateToday.monthRange;
  DateTime _selectedDay = dateToday;

  @override
  Widget build(BuildContext context) {
    final monthlyNotificationsMap =
        ref.watch(monthlyNotificationsCountProvider(_monthRange));

    final monthlyNotifications =
        monthlyNotificationsMap.values.fold(0, (a, b) => a + b);

    return DefaultRefreshIndicator(
      onRefresh: () async {
        await ref
            .read(monthlyNotificationsCountProvider(_monthRange).notifier)
            .refreshTimeline();

        await ref
            .read(datedNotificationsProvider(_selectedDay.dayRange).notifier)
            .refreshNotifications();
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          StyledText(context.locale.notification_timeline_tab_info).sliver,

          24.vSliverBox,

          Row(
            children: [
              /// Monthly notifications
              Expanded(
                child: UsageGlanceCard(
                  isPrimary: true,
                  position: ItemPosition.left,
                  icon: FluentIcons.channel_alert_20_regular,
                  title: context.locale.monthly_label,
                  info: monthlyNotifications.toString(),
                ),
              ),
              4.hBox,

              /// Daily
              Expanded(
                child: UsageGlanceCard(
                  isPrimary: true,
                  position: ItemPosition.right,
                  icon: FluentIcons.alert_on_20_regular,
                  title: context.locale.daily_label,
                  info: (monthlyNotificationsMap[_selectedDay] ?? 0).toString(),
                ),
              ),
            ],
          ).sliver,

          /// Calender
          ContentSectionHeader(title: context.locale.calender_heading).sliver,
          SliverHeatMapCalendar(
            heatmapData: monthlyNotificationsMap,
            onDayChanged: (day) => setState(() => _selectedDay = day),
            onMonthChanged: (date) =>
                setState(() => _monthRange = date.monthRange),
          ),

          8.vSliverBox,

          SliverNotificationsList(
            timeRange: _selectedDay.dayRange,
            header: context.locale.notifications_tab_title,
          ),

          const SliverTabsBottomPadding(),
        ],
      ),
    );
  }
}
