/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

class LearningVideoModel {
  final String id;
  final String title;
  final String channelTitle;
  final String description;
  final String thumbnailUrl;
  final DateTime? publishedAt;
  final List<String> educationalSignals;
  final double score;

  const LearningVideoModel({
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.description,
    required this.thumbnailUrl,
    this.publishedAt,
    this.educationalSignals = const [],
    this.score = 0.0,
  });

  String get videoUrl => 'https://www.youtube.com/watch?v=$id';

  LearningVideoModel copyWith({
    String? id,
    String? title,
    String? channelTitle,
    String? description,
    String? thumbnailUrl,
    DateTime? publishedAt,
    List<String>? educationalSignals,
    double? score,
  }) {
    return LearningVideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      channelTitle: channelTitle ?? this.channelTitle,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      educationalSignals: educationalSignals ?? this.educationalSignals,
      score: score ?? this.score,
    );
  }

  factory LearningVideoModel.fromJson(Map<String, dynamic> json) {
    // ID can be an object with videoId (YouTube search API) or direct String
    String videoId = '';
    if (json['id'] is Map<String, dynamic>) {
      videoId = json['id']['videoId']?.toString() ?? '';
    } else if (json['id'] is String) {
      videoId = json['id'] as String;
    }

    final snippet = (json['snippet'] as Map<String, dynamic>?) ?? {};

    // Thumbnail preference: high -> medium -> default
    String thumb = '';
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>?;
    if (thumbnails != null) {
      if (thumbnails['high'] is Map<String, dynamic>) {
        thumb = thumbnails['high']['url']?.toString() ?? '';
      } else if (thumbnails['medium'] is Map<String, dynamic>) {
        thumb = thumbnails['medium']['url']?.toString() ?? '';
      } else if (thumbnails['default'] is Map<String, dynamic>) {
        thumb = thumbnails['default']['url']?.toString() ?? '';
      }
    }

    DateTime? published;
    if (snippet['publishedAt'] != null) {
      published = DateTime.tryParse(snippet['publishedAt'].toString());
    }

    return LearningVideoModel(
      id: videoId,
      title: _decodeHtml(snippet['title']?.toString() ?? ''),
      channelTitle: _decodeHtml(snippet['channelTitle']?.toString() ?? ''),
      description: _decodeHtml(snippet['description']?.toString() ?? ''),
      thumbnailUrl: thumb,
      publishedAt: published,
    );
  }

  static String _decodeHtml(String input) {
    return input
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'channelTitle': channelTitle,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'publishedAt': publishedAt?.toIso8601String(),
        'educationalSignals': educationalSignals,
        'score': score,
      };
}
