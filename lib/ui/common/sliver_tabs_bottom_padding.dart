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
import 'package:comrade/core/extensions/ext_widget.dart';

class SliverTabsBottomPadding extends StatelessWidget {
  /// Padded bottom space
  const SliverTabsBottomPadding({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 140).sliver;
  }
}
