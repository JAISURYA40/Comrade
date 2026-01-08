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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mindful/config/app_constants.dart';
import 'package:mindful/ui/transitions/default_hero.dart';

class DefaultFabButton extends StatelessWidget {
  const DefaultFabButton({
    super.key,
    this.heroTag,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final Object? heroTag;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return DefaultHero(
      tag: heroTag ?? "defaultScaffoldFabButton",
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ButtonStyle(
          elevation: WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    ).animate().scale(
          duration: AppConstants.defaultAnimDuration,
          curve: Curves.easeOutBack,
        );
  }
}
