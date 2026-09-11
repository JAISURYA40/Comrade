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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:comrade/config/app_constants.dart';
import 'package:comrade/core/extensions/ext_num.dart';
import 'package:comrade/core/extensions/ext_widget.dart';
import 'package:comrade/core/services/method_channel_service.dart';
import 'package:comrade/ui/common/rounded_container.dart';
import 'package:comrade/ui/common/styled_text.dart';

class SliverTabsBottomPadding extends StatelessWidget {
  /// Padded "Made with ♥️ in 🇮🇳" text
  const SliverTabsBottomPadding({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 140,
        bottom: 120 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Center(
        child: Column(
          children: [
            /// Made with
            const StyledText(
              "Made with ♥️ in 🇮🇳",
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),

            6.vBox,

            /// Socials
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Github
                RoundedContainer(
                  height: 30,
                  width: 30,
                  circularRadius: 30,
                  padding: const EdgeInsets.all(6),
                  child: SvgPicture.asset(
                    "assets/vectors/github.svg",
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => MethodChannelService.instance
                      .launchUrl(AppConstants.githubUrl),
                ),

                /// BMC
                4.hBox,
                RoundedContainer(
                  height: 30,
                  width: 30,
                  circularRadius: 30,
                  padding: const EdgeInsets.all(6),
                  child: SvgPicture.asset(
                    "assets/vectors/bmc.svg",
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => MethodChannelService.instance
                      .launchUrl(AppConstants.bmcUrl),
                ),

                /// Instagram
                4.hBox,
                RoundedContainer(
                  height: 30,
                  width: 30,
                  circularRadius: 30,
                  padding: const EdgeInsets.all(6),
                  child: SvgPicture.asset(
                    "assets/vectors/instagram.svg",
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => MethodChannelService.instance
                      .launchUrl(AppConstants.instagramUrl),
                ),

                /// Telegram
                4.hBox,
                RoundedContainer(
                  height: 30,
                  width: 30,
                  circularRadius: 30,
                  padding: const EdgeInsets.all(6),
                  child: SvgPicture.asset(
                    "assets/vectors/telegram.svg",
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => MethodChannelService.instance
                      .launchUrl(AppConstants.telegramUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    ).sliver;
  }
}
