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
import 'package:comrade/core/extensions/ext_num.dart';
import 'package:comrade/ui/common/styled_text.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.imgArtPath,
    required this.title,
    required this.description,
    this.bottomPadding = 148,
  });

  final String imgArtPath;
  final String title;
  final String description;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortScreen = size.height < 700;
    final titleSize = shortScreen ? 26.0 : 32.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxArt = shortScreen
              ? constraints.maxHeight * 0.42
              : constraints.maxHeight * 0.55;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              0.vBox,
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxArt.clamp(160.0, 420.0),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(
                    imgArtPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StyledText(
                    title,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                    color: Theme.of(context).colorScheme.primary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  4.vBox,
                  StyledText(
                    description,
                    fontSize: shortScreen ? 14 : 16,
                    color: Theme.of(context).hintColor,
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
