import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comrade/core/database/app_database.dart';
import 'package:comrade/core/enums/app_theme_mode.dart';
import 'package:comrade/core/services/chat/chat_agent.dart';
import 'package:comrade/core/services/chat/chat_memory_service.dart';
import 'package:comrade/core/services/chat/chat_tool_base.dart';
import 'package:comrade/core/services/chat/chat_tools.dart';
import 'package:comrade/core/services/chat_engine.dart';

class MockChatEngine extends ChatEngine {
  MockChatEngine({this.onProcess});

  final Future<String> Function(String message, List<dynamic> history, List<String> memories)? onProcess;

  @override
  Future<String> processMessage(
    String message,
    List<dynamic> history, {
    List<String> memoryContext = const [],
  }) async {
    if (onProcess != null) {
      return onProcess!(message, history, memoryContext);
    }
    return 'Mock assistant response';
  }
}

void main() {
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

  group('ChatAgent - Intent -> Tool -> Execution -> Verification -> Response', () {
    test('executes theme change, verifies, and returns response', () async {
      var current = AppThemeMode.light;

      final agent = ChatAgent(
        engine: MockChatEngine(),
        memory: memoryService,
        tools: tools,
      );

      final ctx = ChatToolContext(
        changeThemeMode: (m) async => current = m,
        currentThemeMode: () => current,
        updateAppTimer: (_, __) async {},
        resolveInstalledApps: () async => {},
        isAndroid: true,
        openSystemSettings: () async {},
      );

      final progressPhases = <ChatAgentPhase>[];
      final res = await agent.handle(
        message: 'change my theme to Blast',
        toolContext: ctx,
        onProgress: (p) => progressPhases.add(p.phase),
      );

      expect(res.actionSucceeded, isTrue);
      expect(res.toolName, equals('change_theme'));
      expect(res.text, contains('✓ Theme set to Blast'));
      expect(current, equals(AppThemeMode.blast));
      expect(progressPhases, contains(ChatAgentPhase.understanding));
      expect(progressPhases, contains(ChatAgentPhase.executing));
      expect(progressPhases, contains(ChatAgentPhase.verifying));

      // Check that history was persisted in the database
      final history = await db.chatRecordsDao.fetchRecentMessages(userId: 'local');
      expect(history.length, equals(2));
      expect(history.first.content, equals('change my theme to Blast'));
      expect(history.last.content, contains('✓ Theme set to Blast'));
    });

    test('iOS app blocking safely refuses without faking success', () async {
      final agent = ChatAgent(
        engine: MockChatEngine(),
        memory: memoryService,
        tools: tools,
      );

      final ctx = ChatToolContext(
        changeThemeMode: (_) async {},
        currentThemeMode: () => AppThemeMode.light,
        updateAppTimer: (_, __) async {},
        resolveInstalledApps: () async => {},
        isAndroid: false, // iOS
        openSystemSettings: () async {},
      );

      final res = await agent.handle(
        message: 'block Instagram',
        toolContext: ctx,
      );

      expect(res.actionSucceeded, isFalse);
      expect(res.text, contains('✗'));
      expect(res.text, contains('iOS'));
      expect(res.text, contains('No block was claimed or applied on iOS'));
    });

    test('retrieves relevant memory when answering recall questions', () async {
      // Store past turns in DB
      await db.chatRecordsDao.insertMessage(
        userId: 'local',
        role: 'user',
        content: 'I told you my target is reading 15 pages of philosophy daily',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      );

      List<String> capturedMemories = [];

      final engine = MockChatEngine(
        onProcess: (msg, hist, mems) async {
          capturedMemories = mems;
          return 'You told me that your target is reading 15 pages of philosophy daily.';
        },
      );

      final agent = ChatAgent(
        engine: engine,
        memory: memoryService,
        tools: tools,
      );

      final ctx = ChatToolContext(
        changeThemeMode: (_) async {},
        currentThemeMode: () => AppThemeMode.light,
        updateAppTimer: (_, __) async {},
        resolveInstalledApps: () async => {},
        isAndroid: true,
        openSystemSettings: () async {},
      );

      final res = await agent.handle(
        message: 'what did I tell you a few days ago?',
        toolContext: ctx,
      );

      expect(capturedMemories, isNotEmpty);
      expect(
        capturedMemories.any((m) => m.contains('reading 15 pages of philosophy')),
        isTrue,
      );
      expect(res.text, contains('reading 15 pages of philosophy'));
    });

    test('offline fallback synthesizes answer from local memories if LLM fails', () async {
      // Store durable memory
      await memoryService.maybeStoreMemory(
        userId: 'local',
        userText: 'My goal is to learn Rust and systems programming',
      );

      // Failing engine (network error)
      final failingEngine = MockChatEngine(
        onProcess: (msg, hist, mems) async => 'Error: SocketException: Failed host lookup',
      );

      final agent = ChatAgent(
        engine: failingEngine,
        memory: memoryService,
        tools: tools,
      );

      final ctx = ChatToolContext(
        changeThemeMode: (_) async {},
        currentThemeMode: () => AppThemeMode.light,
        updateAppTimer: (_, __) async {},
        resolveInstalledApps: () async => {},
        isAndroid: true,
        openSystemSettings: () async {},
      );

      final res = await agent.handle(
        message: 'what was my goal for Rust?',
        toolContext: ctx,
      );

      expect(res.text, contains('Here is what I remember'));
      expect(res.text, contains('Rust and systems programming'));
    });
  });
}
