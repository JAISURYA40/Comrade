/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:comrade/config/youtube_config.dart';
import 'package:comrade/core/services/youtube/youtube_learning_filter.dart';
import 'package:comrade/models/learning_video_model.dart';

class MissingApiKeyException implements Exception {
  final String message;
  const MissingApiKeyException([
    this.message =
        'No YouTube API Key found. Provide one via --dart-define=YOUTUBE_API_KEY=your_key or configure it in settings.',
  ]);

  @override
  String toString() => message;
}

class YouTubeApiException implements Exception {
  final int statusCode;
  final String message;

  const YouTubeApiException(this.statusCode, this.message);

  @override
  String toString() => 'YouTube API Error ($statusCode): $message';
}

class YoutubeService {
  final http.Client _client;

  YoutubeService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3/search';

  /// Searches YouTube Data API v3 and applies learning filters.
  Future<List<LearningVideoModel>> searchLearningVideos(
    String query, {
    String? apiKey,
    int maxResults = 25,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final key = apiKey ?? YouTubeConfig.activeApiKey;

    if (key.isEmpty) {
      throw const MissingApiKeyException();
    }

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'part': 'snippet',
        'type': 'video',
        'maxResults': maxResults.toString(),
        'q': cleanQuery,
        'key': key,
      },
    );

    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      String errorMessage = 'Failed to fetch videos from YouTube';
      try {
        final errorJson = jsonDecode(response.body);
        if (errorJson is Map && errorJson['error'] is Map) {
          errorMessage = errorJson['error']['message']?.toString() ?? errorMessage;
        }
      } catch (_) {}

      throw YouTubeApiException(response.statusCode, errorMessage);
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final items = (data['items'] as List<dynamic>?) ?? [];

    final rawVideos = items
        .whereType<Map<String, dynamic>>()
        .map((item) => LearningVideoModel.fromJson(item))
        .where((v) => v.id.isNotEmpty)
        .toList();

    // Curate and filter for educational relevance
    return YoutubeLearningFilter.filterAndRank(
      rawVideos,
      query: cleanQuery,
    );
  }
}
