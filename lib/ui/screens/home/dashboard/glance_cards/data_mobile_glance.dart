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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/core/extensions/ext_build_context.dart';
import 'package:comrade/core/extensions/ext_date_time.dart';
import 'package:comrade/core/extensions/ext_int.dart';
import 'package:comrade/core/utils/date_time_utils.dart';
import 'package:comrade/providers/usage/weekly_device_usage_provider.dart';
import 'package:comrade/ui/common/usage_glance_card.dart';

class DataMobileGlance extends ConsumerWidget {
  const DataMobileGlance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(
      weeklyDeviceUsageProvider(dateToday.weekRange).select(
        (v) => v[dateToday]?.mobileData ?? 0,
      ),
    );

    return UsageGlanceCard(
      title: context.locale.mobile_data_label,
      info: today.toData(),
    );
  }
}
