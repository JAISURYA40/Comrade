/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/core/services/method_channel_service.dart';

/// Short content's screen time in SECONDS provider
final shortsScreenTimeProvider = StreamProvider.autoDispose<int>(
  (ref) async* {
    yield await MethodChannelService.instance.getShortsScreenTimeSec();
    await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
      yield await MethodChannelService.instance.getShortsScreenTimeSec();
    }
  },
);
