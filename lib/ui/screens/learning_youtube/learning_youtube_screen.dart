/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/config/youtube_config.dart';
import 'package:comrade/core/extensions/ext_build_context.dart';
import 'package:comrade/core/extensions/ext_num.dart';
import 'package:comrade/core/services/method_channel_service.dart';
import 'package:comrade/core/services/youtube/youtube_learning_filter.dart';
import 'package:comrade/core/services/youtube/youtube_service.dart';
import 'package:comrade/models/learning_video_model.dart';
import 'package:comrade/providers/learning_youtube/learning_youtube_provider.dart';
import 'package:comrade/ui/common/rounded_container.dart';
import 'package:comrade/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:comrade/ui/common/styled_text.dart';

class LearningYoutubeScreen extends ConsumerStatefulWidget {
  const LearningYoutubeScreen({super.key});

  @override
  ConsumerState<LearningYoutubeScreen> createState() =>
      _LearningYoutubeScreenState();
}

class _LearningYoutubeScreenState extends ConsumerState<LearningYoutubeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;
    _searchFocusNode.unfocus();
    ref.read(learningYoutubeProvider.notifier).search(clean);
  }

  void _onTopicSelected(String topic) {
    _searchController.text = topic;
    _performSearch(topic);
  }

  void _showApiKeyDialog() {
    final keyController =
        TextEditingController(text: YouTubeConfig.activeApiKey);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(FluentIcons.key_20_regular),
              SizedBox(width: 8),
              Text("YouTube API Key"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter your YouTube Data API v3 key to enable curated search.",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: "API Key",
                  hintText: "AIzaSy...",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Or launch the app with:\n--dart-define=YOUTUBE_API_KEY=YOUR_KEY",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final newKey = keyController.text.trim();
                ref
                    .read(learningYoutubeProvider.notifier)
                    .setCustomApiKey(newKey);
                Navigator.of(dialogContext).pop();
                context.showSnackAlert(
                  newKey.isNotEmpty
                      ? "API Key updated successfully"
                      : "API Key cleared",
                  icon: FluentIcons.checkmark_circle_20_regular,
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningYoutubeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text("🎓 ", style: TextStyle(fontSize: 20)),
            StyledText(
              "Learning YouTube",
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            FluentIcons.chevron_left_24_filled,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: "API Key Settings",
            icon: Icon(
              state.hasApiKey
                  ? FluentIcons.key_20_filled
                  : FluentIcons.key_20_regular,
              color: state.hasApiKey
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          /// API Key Warning Banner if missing
          if (!state.hasApiKey)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RoundedContainer(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.warning_20_filled,
                        color: theme.colorScheme.error,
                      ),
                      12.hBox,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "YouTube API Key required",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Configure via --dart-define=YOUTUBE_API_KEY or tap to enter.",
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      8.hBox,
                      TextButton(
                        onPressed: _showApiKeyDialog,
                        child: const Text("Enter Key"),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!state.hasApiKey) 12.vSliverBox,

          /// Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RoundedContainer(
                color: theme.colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.search_20_regular,
                      color: theme.colorScheme.primary,
                    ),
                    10.hBox,
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _performSearch,
                        decoration: const InputDecoration(
                          hintText: "Search what you want (e.g. Java Collections)",
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(FluentIcons.dismiss_16_regular, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: const Icon(FluentIcons.arrow_right_20_filled),
                      color: theme.colorScheme.primary,
                      onPressed: () => _performSearch(_searchController.text),
                    ),
                  ],
                ),
              ),
            ),
          ),

          12.vSliverBox,

          /// Topic Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.popularTopics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final topic = state.popularTopics[index];
                  final isSelected = state.query.toLowerCase() == topic.toLowerCase();

                  return ActionChip(
                    label: Text(topic),
                    avatar: const Icon(
                      FluentIcons.book_open_20_regular,
                      size: 16,
                    ),
                    backgroundColor: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerLow,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                    onPressed: () => _onTopicSelected(topic),
                  );
                },
              ),
            ),
          ),

          8.vSliverBox,

          /// Disclaimer Note
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.info_16_regular,
                    size: 14,
                    color: theme.hintColor,
                  ),
                  6.hBox,
                  Expanded(
                    child: Text(
                      YoutubeLearningFilter.disclaimer,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          16.vSliverBox,

          /// Results State
          ..._buildResultsSlivers(context, state),

          const SliverTabsBottomPadding(),
        ],
      ),
    );
  }

  List<Widget> _buildResultsSlivers(
    BuildContext context,
    LearningYoutubeState state,
  ) {
    final theme = Theme.of(context);

    // Initial state before search
    if (!state.hasSearched) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FluentIcons.video_clip_24_regular,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                16.vBox,
                const StyledText(
                  "Discover Educational Content",
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.center,
                ),
                8.vBox,
                StyledText(
                  "Search any subject or tap a topic chip to find distraction-free tutorials, lectures, and courses.",
                  fontSize: 13,
                  color: theme.hintColor,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // Results handler
    return state.results.when(
      data: (videos) {
        if (videos.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  children: [
                    Icon(
                      FluentIcons.filter_dismiss_24_regular,
                      size: 40,
                      color: theme.hintColor,
                    ),
                    12.vBox,
                    StyledText(
                      "No learning videos found for \"${state.query}\"",
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                    ),
                    8.vBox,
                    StyledText(
                      "Try refining your search terms or picking another topic.",
                      fontSize: 13,
                      color: theme.hintColor,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ];
        }

        return [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final video = videos[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _VideoCard(video: video),
                  );
                },
                childCount: videos.length,
              ),
            ),
          ),
        ];
      },
      loading: () => [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
      error: (error, _) {
        final isMissingKey = error is MissingApiKeyException;
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                children: [
                  Icon(
                    FluentIcons.error_circle_24_regular,
                    size: 44,
                    color: theme.colorScheme.error,
                  ),
                  12.vBox,
                  StyledText(
                    isMissingKey
                        ? "API Key Required"
                        : "Unable to load videos",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                  ),
                  8.vBox,
                  StyledText(
                    error.toString(),
                    fontSize: 12,
                    color: theme.hintColor,
                    textAlign: TextAlign.center,
                  ),
                  16.vBox,
                  ElevatedButton.icon(
                    icon: Icon(
                      isMissingKey
                          ? FluentIcons.key_20_regular
                          : FluentIcons.arrow_clockwise_20_regular,
                      size: 18,
                    ),
                    label: Text(isMissingKey ? "Configure API Key" : "Try Again"),
                    onPressed: isMissingKey
                        ? _showApiKeyDialog
                        : () => _performSearch(state.query),
                  ),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});

  final LearningVideoModel video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RoundedContainer(
      color: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.all(12),
      onPressed: () {
        HapticFeedback.lightImpact();
        MethodChannelService.instance.launchUrl(video.videoUrl);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Thumbnail & Play Icon
          if (video.thumbnailUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(FluentIcons.video_clip_24_regular),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      FluentIcons.play_20_filled,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

          10.vBox,

          /// Title
          StyledText(
            video.title,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          6.vBox,

          /// Channel Name
          Row(
            children: [
              Icon(
                FluentIcons.person_board_20_regular,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              6.hBox,
              Expanded(
                child: Text(
                  video.channelTitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          /// Educational Signal Badges
          if (video.educationalSignals.isNotEmpty) ...[
            8.vBox,
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: video.educationalSignals.take(3).map((signal) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "🎓 $signal",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
