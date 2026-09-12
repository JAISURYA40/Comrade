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
import 'package:comrade/config/app_themes.dart';
import 'package:comrade/config/app_theme_tokens.dart';
import 'package:comrade/core/enums/app_theme_mode.dart';
import 'package:comrade/core/enums/default_home_tab.dart';
import 'package:comrade/core/enums/item_position.dart';
import 'package:comrade/core/extensions/ext_build_context.dart';
import 'package:comrade/core/extensions/ext_num.dart';
import 'package:comrade/core/extensions/ext_widget.dart';
import 'package:comrade/config/locales.dart';
import 'package:comrade/core/services/method_channel_service.dart';
import 'package:comrade/l10n/generated/app_localizations.dart';
import 'package:comrade/providers/system/comrade_settings_provider.dart';
import 'package:comrade/ui/common/default_list_tile.dart';
import 'package:comrade/ui/common/rounded_container.dart';
import 'package:comrade/ui/common/content_section_header.dart';
import 'package:comrade/ui/common/default_dropdown_tile.dart';
import 'package:comrade/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:comrade/ui/common/styled_text.dart';
import 'package:comrade/ui/permissions/battery_permission_tile.dart';
import 'package:comrade/core/utils/platform_features.dart';

class TabGeneral extends ConsumerWidget {
  const TabGeneral({super.key});

  void _openAutoStartSettings(BuildContext context) async {
    final success = await MethodChannelService.instance.openAutoStartSettings();

    if (!success && context.mounted) {
      context.showSnackAlert(
        context.locale.whitelist_app_unsupported_snack_alert,
      );
    }
  }

  Color _swatchFor(AppThemeMode? mode) {
    switch (mode) {
      case AppThemeMode.blast:
        return AppThemeTokens.blast.primary;
      case AppThemeMode.focus:
        return AppThemeTokens.focus.primary;
      case AppThemeMode.calm:
        return AppThemeTokens.calm.primary;
      case AppThemeMode.light:
        return AppThemeTokens.classicLight.primary;
      case AppThemeMode.dark:
      case AppThemeMode.system:
      case null:
        return AppThemeTokens.classicDark.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comradeSettings = ref.watch(comradeSettingsProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        /// Appearance
        ContentSectionHeader(
          title: context.locale.appearance_heading,
        ).sliver,

        /// Theme mode (System / Light / Dark + mood themes)
        DefaultDropdownTile<AppThemeMode>(
          position: ItemPosition.top,
          value: comradeSettings.themeMode,
          dialogIcon: FluentIcons.dark_theme_20_filled,
          titleText: context.locale.theme_mode_tile_title,
          onSelected:
              ref.read(comradeSettingsProvider.notifier).changeThemeMode,
          trailingBuilder: (mode) => RoundedContainer(
            height: 18,
            width: 18,
            circularRadius: 18,
            color: _swatchFor(mode),
          ),
          items: [
            DefaultDropdownItem(
              label: context.locale.theme_mode_system_label,
              value: AppThemeMode.system,
            ),
            DefaultDropdownItem(
              label: context.locale.theme_mode_light_label,
              value: AppThemeMode.light,
            ),
            DefaultDropdownItem(
              label: context.locale.theme_mode_dark_label,
              value: AppThemeMode.dark,
            ),
            DefaultDropdownItem(
              label: context.locale.theme_mode_blast_label,
              value: AppThemeMode.blast,
            ),
            DefaultDropdownItem(
              label: context.locale.theme_mode_focus_label,
              value: AppThemeMode.focus,
            ),
            DefaultDropdownItem(
              label: context.locale.theme_mode_calm_label,
              value: AppThemeMode.calm,
            ),
          ],
        ).sliver,

        if (comradeSettings.themeMode.isMoodTheme)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: StyledText(
              context.locale.theme_mode_mood_section_hint,
              fontSize: 12,
              isSubtitle: true,
            ),
          ).sliver,

        /// Material Color (classic themes only)
        DefaultDropdownTile<String>(
          position: ItemPosition.mid,
          enabled: !comradeSettings.themeMode.isMoodTheme,
          titleText: context.locale.material_color_tile_title,
          dialogIcon: FluentIcons.color_20_filled,
          value: comradeSettings.accentColor,
          onSelected: ref.read(comradeSettingsProvider.notifier).changeColor,
          trailingBuilder: (item) => RoundedContainer(
            height: 18,
            width: 18,
            circularRadius: 18,
            color: AppTheme.materialColors[item],
          ),
          items: AppTheme.materialColors.entries
              .map((e) => DefaultDropdownItem(
                    label: e.key,
                    value: e.key,
                  ))
              .toList(),
        ).sliver,

        /// Amoled dark
        DefaultListTile(
          position: ItemPosition.mid,
          enabled: !comradeSettings.themeMode.isMoodTheme &&
              comradeSettings.themeMode != AppThemeMode.light,
          switchValue: comradeSettings.useAmoledDark,
          titleText: context.locale.amoled_dark_tile_title,
          subtitleText: context.locale.amoled_dark_tile_subtitle,
          onPressed:
              ref.read(comradeSettingsProvider.notifier).switchAmoledDark,
        ).sliver,

        /// Dynamic colors
        DefaultListTile(
          position: ItemPosition.bottom,
          enabled: !comradeSettings.themeMode.isMoodTheme,
          switchValue: comradeSettings.useDynamicColors,
          titleText: context.locale.dynamic_colors_tile_title,
          subtitleText: context.locale.dynamic_colors_tile_subtitle,
          onPressed:
              ref.read(comradeSettingsProvider.notifier).switchDynamicColor,
        ).sliver,

        /// Default settings
        12.vSliverBox,
        ContentSectionHeader(title: context.locale.defaults_heading).sliver,

        /// App Language
        DefaultDropdownTile<String>(
          position: ItemPosition.top,
          titleText: context.locale.app_language_tile_title,
          dialogIcon: FluentIcons.color_20_filled,
          value: comradeSettings.localeCode,
          onSelected: ref.read(comradeSettingsProvider.notifier).changeLocale,
          items: AppLocalizations.supportedLocales
              .map((e) => DefaultDropdownItem(
                    value: e.languageCode,
                    label:
                        Locales.knownLocales[e.languageCode] ?? e.languageCode,
                  ))
              .toList(),
        ).sliver,

        /// Default home tab
        DefaultDropdownTile<DefaultHomeTab>(
          position: ItemPosition.mid,
          titleText: context.locale.default_home_tab_tile_title,
          dialogIcon: FluentIcons.color_20_filled,
          value: comradeSettings.defaultHomeTab,
          onSelected: ref.read(comradeSettingsProvider.notifier).changeHomeTab,
          items: [
            DefaultDropdownItem(
              label: context.locale.dashboard_tab_title,
              value: DefaultHomeTab.dashboard,
            ),
            DefaultDropdownItem(
              label: context.locale.statistics_tab_title,
              value: DefaultHomeTab.statistics,
            ),
            DefaultDropdownItem(
              label: context.locale.notifications_tab_title,
              value: DefaultHomeTab.notifications,
            ),
            DefaultDropdownItem(
              label: context.locale.bedtime_tab_title,
              value: DefaultHomeTab.bedtime,
            ),
          ],
        ).sliver,

        /// Usage history in weeks
        DefaultDropdownTile<int>(
          position: ItemPosition.bottom,
          titleText: context.locale.usage_history_tile_title,
          dialogIcon: FluentIcons.history_20_filled,
          value: comradeSettings.usageHistoryWeeks,
          onSelected: ref
              .read(comradeSettingsProvider.notifier)
              .changeUsageHistoryWeeks,
          items: [
            // 15 days = 2 weeks
            DefaultDropdownItem(
              label: context.locale.usage_history_15_days,
              value: 2,
            ),

            // 1 month = 4 weeks
            DefaultDropdownItem(
              label: context.locale.usage_history_1_month,
              value: 4,
            ),

            // 3 months = 13 weeks
            DefaultDropdownItem(
              label: context.locale.usage_history_3_month,
              value: 13,
            ),

            // 6 months = 26 weeks
            DefaultDropdownItem(
              label: context.locale.usage_history_6_month,
              value: 26,
            ),

            // 1 year = 52 weeks
            DefaultDropdownItem(
              label: context.locale.usage_history_1_year,
              value: 52,
            ),
          ],
        ).sliver,

        /// Service
        if (PlatformFeatures.hasBatteryOptimization) ...[
          ContentSectionHeader(title: context.locale.service_heading).sliver,

          /// Battery permission
          StyledText(context.locale.service_stopping_warning).sliver,
          6.vSliverBox,
          const SliverBatteryPermissionSwitchTile(),
          DefaultListTile(
            position: ItemPosition.bottom,
            leadingIcon: FluentIcons.leaf_three_20_regular,
            titleText: context.locale.whitelist_app_tile_title,
            subtitleText: context.locale.whitelist_app_tile_subtitle,
            trailing: const Icon(FluentIcons.chevron_right_20_regular),
            onPressed: () => _openAutoStartSettings(context),
          ).sliver,
        ],

        const SliverTabsBottomPadding(),
      ],
    );
  }
}
