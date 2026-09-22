import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:comrade/config/youtube_config.dart';
import 'package:comrade/core/services/youtube/youtube_learning_filter.dart';
import 'package:comrade/core/services/youtube/youtube_service.dart';
import 'package:comrade/models/learning_video_model.dart';

void main() {
  group('LearningVideoModel Tests', () {
    test('Correctly parses YouTube API search item json', () {
      final json = {
        'id': {'videoId': 'test1234'},
        'snippet': {
          'title': 'Java Collections &amp; Framework Tutorial',
          'description': 'A complete guide &amp; deep dive into Java Collections.',
          'channelTitle': 'Tech Academy',
          'publishedAt': '2024-03-15T10:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://i.ytimg.com/vi/test1234/hqdefault.jpg'},
          },
        },
      };

      final model = LearningVideoModel.fromJson(json);

      expect(model.id, equals('test1234'));
      expect(model.title, equals('Java Collections & Framework Tutorial'));
      expect(model.channelTitle, equals('Tech Academy'));
      expect(model.thumbnailUrl, equals('https://i.ytimg.com/vi/test1234/hqdefault.jpg'));
      expect(model.videoUrl, equals('https://www.youtube.com/watch?v=test1234'));
      expect(model.publishedAt, isNotNull);
    });

    test('Correctly decodes HTML entities in titles and descriptions', () {
      final json = {
        'id': 'abc987',
        'snippet': {
          'title': '&quot;Hello World&quot; &#39;DSA&#39; &amp; Algorithms',
          'description': 'Guide &lt;Beginner&gt; to &quot;Advanced&quot;',
          'channelTitle': 'Dev Channel',
        },
      };

      final model = LearningVideoModel.fromJson(json);
      expect(model.id, equals('abc987'));
      expect(model.title, equals('"Hello World" \'DSA\' & Algorithms'));
      expect(model.description, equals('Guide <Beginner> to "Advanced"'));
    });
  });

  group('YoutubeLearningFilter Tests', () {
    test('Keeps educational videos and assigns educational signals', () {
      final videos = [
        const LearningVideoModel(
          id: 'v1',
          title: 'Java Collections Framework Tutorial - Full Course',
          channelTitle: 'Coding University',
          description: 'Learn ArrayList, HashMap, and HashSet with clear examples.',
          thumbnailUrl: 'https://example.com/1.jpg',
        ),
        const LearningVideoModel(
          id: 'v2',
          title: 'System Design Architecture Explained',
          channelTitle: 'System Architect',
          description: 'Deep dive into microservices and load balancers lecture.',
          thumbnailUrl: 'https://example.com/2.jpg',
        ),
      ];

      final filtered = YoutubeLearningFilter.filterAndRank(videos, query: 'Java Collections');

      expect(filtered.length, equals(2));
      expect(filtered[0].educationalSignals, contains('Tutorial'));
      expect(filtered[0].educationalSignals, contains('Course'));
      expect(filtered[0].educationalSignals, contains('Learn'));
      expect(filtered[1].educationalSignals, contains('Explained'));
      expect(filtered[1].educationalSignals, contains('Architecture'));
      expect(filtered[0].score, greaterThan(0.0));
    });

    test('Filters out entertainment, pranks, vlogs, and meme videos', () {
      final videos = [
        const LearningVideoModel(
          id: 'edu1',
          title: 'Python Programming Course for Beginners',
          channelTitle: 'FreeCodeDev',
          description: 'Complete tutorial on Python basics and data structures.',
          thumbnailUrl: 'https://example.com/edu.jpg',
        ),
        const LearningVideoModel(
          id: 'ent1',
          title: 'I PRANKED My Roommate While He Was Coding (Hilarious Vlog)',
          channelTitle: 'Comedy Bros',
          description: 'Watch this funny prank challenge and meme video.',
          thumbnailUrl: 'https://example.com/prank.jpg',
        ),
        const LearningVideoModel(
          id: 'ent2',
          title: 'Reaction to worst programmer tiktok memes',
          channelTitle: 'Funny Clips',
          description: 'Try not to laugh challenge gameplay roast',
          thumbnailUrl: 'https://example.com/meme.jpg',
        ),
      ];

      final filtered = YoutubeLearningFilter.filterAndRank(videos, query: 'Python');

      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('edu1'));
      expect(filtered.first.educationalSignals, contains('Course'));
      expect(filtered.first.educationalSignals, contains('Programming'));
    });

    test('Ranks highly relevant educational videos above less relevant ones', () {
      final videos = [
        const LearningVideoModel(
          id: 'low',
          title: 'General Overview of Tech Topics',
          channelTitle: 'Random Creator',
          description: 'Just some thoughts.',
          thumbnailUrl: 'https://example.com/low.jpg',
        ),
        const LearningVideoModel(
          id: 'high',
          title: 'DSA Complete Tutorial & Data Structures Course',
          channelTitle: 'Algorithms Academy',
          description: 'Full course and documentation on algorithms and data structures.',
          thumbnailUrl: 'https://example.com/high.jpg',
        ),
      ];

      final filtered = YoutubeLearningFilter.filterAndRank(videos, query: 'DSA Tutorial');

      expect(filtered.first.id, equals('high'));
      expect(filtered.first.score, greaterThan(15.0));
    });
  });

  group('YouTubeConfig Tests', () {
    tearDown(() {
      YouTubeConfig.runtimeApiKey = '';
    });

    test('Allows runtime API key setting and retrieval', () {
      expect(YouTubeConfig.runtimeApiKey, isEmpty);

      YouTubeConfig.runtimeApiKey = 'test_api_key_123';
      expect(YouTubeConfig.runtimeApiKey, equals('test_api_key_123'));
      expect(YouTubeConfig.activeApiKey, equals('test_api_key_123'));
      expect(YouTubeConfig.hasApiKey, isTrue);

      YouTubeConfig.runtimeApiKey = '';
      expect(YouTubeConfig.runtimeApiKey, isEmpty);
    });
  });

  group('YoutubeService Tests', () {
    tearDown(() {
      YouTubeConfig.runtimeApiKey = '';
    });

    test('Throws MissingApiKeyException when no key is set', () async {
      YouTubeConfig.runtimeApiKey = '';
      final service = YoutubeService();

      expect(
        () => service.searchLearningVideos('Java', apiKey: ''),
        throwsA(isA<MissingApiKeyException>()),
      );
    });

    test('Queries API and filters results with mock client', () async {
      final mockResponse = jsonEncode({
        'items': [
          {
            'id': {'videoId': 'java1'},
            'snippet': {
              'title': 'Java Collections Explained: Tutorial for Developers',
              'description': 'In-depth guide on List, Set, and Map interfaces in Java.',
              'channelTitle': 'Dev Academy',
              'thumbnails': {
                'high': {'url': 'https://example.com/java1.jpg'},
              },
            },
          },
          {
            'id': {'videoId': 'prank1'},
            'snippet': {
              'title': 'Java Programmer PRANK in Public Library (Gone Wrong)',
              'description': 'Comedy prank challenge reaction funny.',
              'channelTitle': 'Prankster Central',
              'thumbnails': {
                'high': {'url': 'https://example.com/prank.jpg'},
              },
            },
          },
        ],
      });

      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['q'], equals('Java Collections'));
        expect(request.url.queryParameters['key'], equals('test_mock_key'));
        return http.Response(mockResponse, 200);
      });

      final service = YoutubeService(client: mockClient);
      final results = await service.searchLearningVideos(
        'Java Collections',
        apiKey: 'test_mock_key',
      );

      expect(results.length, equals(1));
      expect(results.first.id, equals('java1'));
      expect(results.first.title, contains('Java Collections Explained'));
      expect(results.first.educationalSignals, contains('Tutorial'));
      expect(results.first.educationalSignals, contains('Explained'));
    });

    test('Handles API error status correctly', () async {
      final errorResponse = jsonEncode({
        'error': {
          'code': 403,
          'message': 'The request cannot be completed because you have exceeded your quota.',
        },
      });

      final mockClient = MockClient((request) async {
        return http.Response(errorResponse, 403);
      });

      final service = YoutubeService(client: mockClient);

      expect(
        () => service.searchLearningVideos('React', apiKey: 'valid_looking_key'),
        throwsA(
          predicate((e) =>
              e is YouTubeApiException &&
              e.statusCode == 403 &&
              e.message.contains('exceeded your quota')),
        ),
      );
    });
  });
}
