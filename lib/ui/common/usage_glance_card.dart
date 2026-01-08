/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/material.dart';
import 'package:mindful/core/enums/item_position.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/utils/widget_utils.dart';
import 'package:mindful/ui/common/rounded_container.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UsageGlanceCard extends StatelessWidget {
  const UsageGlanceCard({
    super.key,
    required this.title,
    required this.info,
    this.icon,
    this.onTap,
    this.badge,
    this.isPrimary = false,
    this.position = ItemPosition.mid,
  });

  final IconData? icon;
  final bool isPrimary;
  final String title;
  final String info;
  final VoidCallback? onTap;
  final ItemPosition position;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final mini = icon == null;
    final theme = Theme.of(context);
    final isPrimaryColor = isPrimary 
        ? theme.colorScheme.primary.withValues(alpha: 0.15)
        : theme.colorScheme.surfaceContainerHighest;

    return RoundedContainer(
      circularRadius: 20,
      borderRadius: getBorderRadiusFromPosition(position),
      padding: const EdgeInsets.all(20),
      color: isPrimaryColor,
      onPressed: onTap,
      child: Stack(
        children: [
          /// Usage
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mini) 
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              mini ? 0.vBox : 16.vBox,
              StyledText(
                title,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                isSubtitle: true,
              ),
              8.vBox,
              Skeleton.leaf(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  child: StyledText(
                    info.isEmpty ? " " : info,
                    fontSize: 28,
                    maxLines: 1,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          /// Badge
          Align(
            alignment: Alignment.topRight,
            child: badge ?? 0.hBox,
          )
        ],
      ),
    );
  }
}
