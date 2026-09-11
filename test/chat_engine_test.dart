import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:comrade/core/database/app_database.dart';
import 'package:comrade/core/enums/app_theme_mode.dart';
import 'package:comrade/core/services/chat/chat_agent.dart';
import 'package:comrade/core/services/chat/chat_memory_service.dart';
import 'package:comrade/core/services/chat/chat_tool_base.dart';
import 'package:comrade/core/services/chat/chat_tools.dart';
import 'package:comrade/core/services/chat_engine.dart';

void main() {
  group('ChatEngine - Secure Configuration & Graceful Missing Key', () {
    test('defaults to environment key or empty string if not defined', () {
      final engine = ChatEngine(apiKey: '');
      expect(engine.hasApiKey, isFalse);
      expect(engine.apiKey, isEmpty);
    });

    test('accepts explicit apiKey in constructor', () {
      final engine = ChatEngine(apiKey: 'custom_test_key');
      expect(engine.hasApiKey, isTrue);
      expect(engine.apiKey, 'custom_test_key');
    });

    test('returns clear error without making HTTP calls when apiKey is missing', () async {
      var httpCalled = false;
      final mockClient = MockClient((request) async {
        httpCalled = true;
        return http.Response('{}', 200);
      });

      final engine = ChatEngine(apiKey: '', client: mockClient);
      final result = await engine.processMessage('Hello Comrade', []);

      expect(httpCalled, isFalse);
      expect(result, startsWith('Error: GROQ_API_KEY is not configured'));
    });

    test('makes HTTP request to Groq endpoint when key is configured', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'https://api.groq.com/openai/v1/chat/completions');
        expect(request.headers['Authorization'], 'Bearer test_key_123');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'openai/gpt-oss-20b');

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'Comrade response test'}
              }
            ]
          }),
          200,
        );
      });

      final engine = ChatEngine(apiKey: 'test_key_123', client: mockClient);
      final result = await engine.processMessage('Stay focused', []);

      expect(result, 'Comrade response test');
    });
  });

  group('ChatAgent - Graceful handling when GROQ_API_KEY is missing', () {
    late AppDatabase db;
    late ChatMemoryService memoryService;
    late ChatToolRegistry tools;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      memoryService = ChatMemoryService(dao: db.chatRecordsDao);
      tools = buildDefaultChatTools();
    });

    tearDown(() async {
      await db.close();
    });

    ChatToolContext buildContext() {
      return ChatToolContext(
        changeThemeMode: (_) async {},
        currentThemeMode: () => AppThemeMode.light,
        updateAppTimer: (_, __) async {},
        resolveInstalledApps: () async => {},
        isAndroid: true,
        openSystemSettings: () async {},
      );
    }

    test('informs user how to configure GROQ_API_KEY when no memories exist', () async {
      final agent = ChatAgent(
        engine: ChatEngine(apiKey: ''),
        memory: memoryService,
        tools: tools,
      );

      final res = await agent.handle(
        message: 'Tell me how to stay productive',
        toolContext: buildContext(),
      );

      expect(res.text, contains('Comrade AI Assistant is running in offline mode'));
      expect(res.text, contains('--dart-define=GROQ_API_KEY=your_key'));
    });

    test('synthesizes saved memories even when GROQ_API_KEY is missing', () async {
      await memoryService.maybeStoreMemory(
        userId: 'local',
        userText: 'My main goal is to finish the Comrade clean-up today',
      );

      final agent = ChatAgent(
        engine: ChatEngine(apiKey: ''),
        memory: memoryService,
        tools: tools,
      );

      final res = await agent.handle(
        message: 'What was my goal for Comrade?',
        toolContext: buildContext(),
      );

      expect(res.text, contains('Here is what I remember'));
      expect(res.text, contains('Comrade clean-up today'));
    });
  });
}
