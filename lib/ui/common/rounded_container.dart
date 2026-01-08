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

class RoundedContainer extends StatelessWidget {
  /// A decorated container with the provided properties
  ///
  /// If [onPressed] is not null then it build a inkwell widget, otherwise build a normal container with the decorations
  const RoundedContainer({
    super.key,
    this.height,
    this.width,
    this.color,
    this.borderRadius,
    this.child,
    this.onPressed,
    this.circularRadius = 18,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.center,
  });

  final double? height;
  final double? width;
  final Color? color;
  final double circularRadius;
  final BorderRadius? borderRadius;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Widget? child;
  final VoidCallback? onPressed;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = color ?? theme.colorScheme.surfaceContainerHighest;
    final radius = borderRadius ?? BorderRadius.circular(circularRadius);
    final isDark = theme.brightness == Brightness.dark;
    
    return onPressed == null

        /// Static container
        ? Container(
            width: width,
            height: height,
            margin: margin,
            padding: padding,
            alignment: alignment,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          )

        /// Interactive container
        : Container(
            height: height,
            width: width,
            margin: margin,
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: bgColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
              ),
              child: InkWell(
                onTap: onPressed,
                splashFactory: InkSparkle.splashFactory,
                splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                highlightColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: radius,
                child: Padding(
                  padding: padding,
                  child: Align(
                    alignment: alignment,
                    child: child,
                  ),
                ),
              ),
            ),
          );
  }
}
