/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import 'package:comrade/models/learning_video_model.dart';

class YoutubeLearningFilter {
  static const Map<String, String> educationalSignalsMap = {
    'tutorial': 'Tutorial',
    'course': 'Course',
    'lecture': 'Lecture',
    'explained': 'Explained',
    'programming': 'Programming',
    'learn': 'Learn',
    'education': 'Education',
    'guide': 'Guide',
    'how to': 'How-To',
    'documentation': 'Documentation',
    'crash course': 'Crash Course',
    'full course': 'Full Course',
    'coding': 'Coding',
    'concepts': 'Concepts',
    'architecture': 'Architecture',
    'roadmap': 'Roadmap',
    'deep dive': 'Deep Dive',
    'masterclass': 'Masterclass',
    'algorithm': 'Algorithms',
    'data structure': 'Data Structures',
  };

  static const List<String> entertainmentSignals = [
    'prank',
    'vlog',
    'reaction',
    'gameplay',
    'playthrough',
    'funny moments',
    'comedy',
    'meme',
    'memes',
    'trailer',
    'teaser',
    'official music video',
    'music video',
    'roast',
    'drama',
    'gossip',
    'challenge',
    'parody',
    'try not to laugh',
    'bloopers',
    'asmr',
  ];

  static const String disclaimer =
      'Educational curation is heuristic-based and aims to reduce distractions. Some non-learning content may occasionally appear.';

  /// Filters out entertainment videos and scores/ranks educational content.
  static List<LearningVideoModel> filterAndRank(
    List<LearningVideoModel> videos, {
    String? query,
  }) {
    final queryTokens = (query ?? '')
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .toList();

    final List<LearningVideoModel> scoredVideos = [];

    for (final video in videos) {
      final titleLower = video.title.toLowerCase();
      final descLower = video.description.toLowerCase();
      final channelLower = video.channelTitle.toLowerCase();
      final combined = '$titleLower $descLower $channelLower';

      // Check entertainment signals
      int entertainmentMatches = 0;
      for (final badSignal in entertainmentSignals) {
        if (_containsPhrase(combined, badSignal)) {
          entertainmentMatches++;
        }
      }

      // Check educational signals
      final List<String> detectedSignals = [];
      double score = 0.0;

      educationalSignalsMap.forEach((keyword, label) {
        final inTitle = _containsPhrase(titleLower, keyword);
        final inDesc = _containsPhrase(descLower, keyword);

        if (inTitle || inDesc) {
          if (!detectedSignals.contains(label)) {
            detectedSignals.add(label);
          }
          if (inTitle) score += 6.0;
          if (inDesc) score += 2.0;
        }
      });

      // Channel credibility hints (academic or tech channel indicators)
      if (channelLower.contains('academy') ||
          channelLower.contains('university') ||
          channelLower.contains('school') ||
          channelLower.contains('code') ||
          channelLower.contains('dev') ||
          channelLower.contains('cs') ||
          channelLower.contains('education') ||
          channelLower.contains('institute')) {
        score += 3.0;
        if (!detectedSignals.contains('Verified Educator')) {
          detectedSignals.add('Verified Educator');
        }
      }

      // Relevance to user search query
      for (final token in queryTokens) {
        if (_containsPhrase(titleLower, token)) {
          score += 4.0;
        } else if (_containsPhrase(descLower, token)) {
          score += 1.0;
        }
      }

      // If strong entertainment cues are present, heavily penalize or drop
      if (entertainmentMatches > 0) {
        score -= (entertainmentMatches * 15.0);
      }

      // If entertainment signals outweigh educational signals, exclude
      if (entertainmentMatches >= 1 && detectedSignals.isEmpty) {
        continue;
      }
      if (score < 0) {
        continue;
      }

      // Retain video with computed signals and score
      scoredVideos.add(
        video.copyWith(
          educationalSignals: detectedSignals,
          score: score,
        ),
      );
    }

    // Sort descending by educational score
    scoredVideos.sort((a, b) => b.score.compareTo(a.score));

    return scoredVideos;
  }

  static bool _containsPhrase(String text, String phrase) {
    if (phrase.contains(' ')) {
      return text.contains(phrase);
    }
    // Word boundary check for single words to avoid false partial matches
    final pattern = RegExp(r'\b' + RegExp.escape(phrase) + r'\b');
    return pattern.hasMatch(text);
  }
}
