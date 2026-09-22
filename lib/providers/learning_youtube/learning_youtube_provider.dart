/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/config/youtube_config.dart';
import 'package:comrade/core/services/youtube/youtube_service.dart';
import 'package:comrade/models/learning_video_model.dart';

class LearningYoutubeState {
  final String query;
  final AsyncValue<List<LearningVideoModel>> results;
  final bool hasSearched;
  final List<String> popularTopics;

  const LearningYoutubeState({
    this.query = '',
    this.results = const AsyncData([]),
    this.hasSearched = false,
    this.popularTopics = const [
      'Java',
      'Python',
      'React',
      'DSA',
      'System Design',
      'Mathematics',
    ],
  });

  bool get hasApiKey => YouTubeConfig.hasApiKey;

  LearningYoutubeState copyWith({
    String? query,
    AsyncValue<List<LearningVideoModel>>? results,
    bool? hasSearched,
    List<String>? popularTopics,
  }) {
    return LearningYoutubeState(
      query: query ?? this.query,
      results: results ?? this.results,
      hasSearched: hasSearched ?? this.hasSearched,
      popularTopics: popularTopics ?? this.popularTopics,
    );
  }
}

class LearningYoutubeNotifier extends StateNotifier<LearningYoutubeState> {
  final YoutubeService _service;

  LearningYoutubeNotifier({YoutubeService? service})
      : _service = service ?? YoutubeService(),
        super(const LearningYoutubeState());

  void setCustomApiKey(String key) {
    YouTubeConfig.runtimeApiKey = key;
    // Refresh state to trigger UI updates for key availability
    state = state.copyWith();
    if (state.query.trim().isNotEmpty) {
      search(state.query);
    }
  }

  Future<void> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    state = state.copyWith(
      query: cleanQuery,
      hasSearched: true,
      results: const AsyncLoading(),
    );

    try {
      final videos = await _service.searchLearningVideos(cleanQuery);
      state = state.copyWith(
        results: AsyncData(videos),
      );
    } catch (e, st) {
      state = state.copyWith(
        results: AsyncError(e, st),
      );
    }
  }

  void clearResults() {
    state = state.copyWith(
      query: '',
      hasSearched: false,
      results: const AsyncData([]),
    );
  }
}

final youtubeServiceProvider = Provider<YoutubeService>((ref) {
  return YoutubeService();
});

final learningYoutubeProvider =
    StateNotifierProvider<LearningYoutubeNotifier, LearningYoutubeState>((ref) {
  final service = ref.watch(youtubeServiceProvider);
  return LearningYoutubeNotifier(service: service);
});
