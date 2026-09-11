import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comrade/core/database/app_database.dart';
import 'package:comrade/core/services/chat/chat_memory_service.dart';

void main() {
  late AppDatabase db;
  late ChatMemoryService memoryService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    memoryService = ChatMemoryService(dao: db.chatRecordsDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('ChatMemoryService - Storage & Sensitivity Filtering', () {
    const userId = 'tester';

    test('never stores sensitive information (passwords, tokens, keys)', () async {
      final sensitiveInputs = [
        'My password is superSecretPassword123!',
        'Here is my api_key: TEST_KEY_PLACEHOLDER',
        'Use sk-1234567890abcdef for the auth token',
        'My credit card number is 4111 2222 3333 4444',
        'The OTP is 592811 for login',
        'My secret pin is 9988',
      ];

      for (final text in sensitiveInputs) {
        await memoryService.maybeStoreMemory(userId: userId, userText: text);
      }

      final memories = await db.chatRecordsDao.fetchAllMemories(userId: userId);
      expect(memories, isEmpty);
    });

    test('ignores trivial greetings and commands from permanent memory', () async {
      final trivialInputs = [
        'hi',
        'hello',
        'good morning',
        'thanks',
        'ok',
        'change my theme to blast',
        'block instagram',
        'open settings',
      ];

      for (final text in trivialInputs) {
        await memoryService.maybeStoreMemory(userId: userId, userText: text);
      }

      final memories = await db.chatRecordsDao.fetchAllMemories(userId: userId);
      expect(memories, isEmpty);
    });

    test('stores durable user facts and goals', () async {
      await memoryService.maybeStoreMemory(
        userId: userId,
        userText: 'My goal is to read 30 pages every morning before work',
      );
      await memoryService.maybeStoreMemory(
        userId: userId,
        userText: 'Remember that I am preparing for the UPSC civil services exam',
      );
      await memoryService.maybeStoreMemory(
        userId: userId,
        userText: 'I always study best when listening to low-tempo lofi music',
      );

      final memories = await db.chatRecordsDao.fetchAllMemories(userId: userId);
      expect(memories.length, equals(3));
      expect(memories.any((m) => m.content.contains('UPSC')), isTrue);
      expect(memories.any((m) => m.content.contains('30 pages')), isTrue);
    });
  });

  group('ChatMemoryService - Relevant Memory Retrieval', () {
    const userId = 'tester';

    setUp(() async {
      final now = DateTime.now();

      // Store a durable memory
      await memoryService.maybeStoreMemory(
        userId: userId,
        userText: 'My goal is to build a Flutter application for productivity',
      );

      // Store conversation history turns from previous days
      // 3 days ago
      await db.chatRecordsDao.insertMessage(
        userId: userId,
        role: 'user',
        content: 'I decided to start learning Dart and Flutter 3 days ago',
        createdAt: now.subtract(const Duration(days: 3, hours: 2)),
      );
      await db.chatRecordsDao.insertMessage(
        userId: userId,
        role: 'assistant',
        content: 'That is a fantastic journey! Stay consistent.',
        createdAt: now.subtract(const Duration(days: 3, hours: 2)),
      );

      // Yesterday
      await db.chatRecordsDao.insertMessage(
        userId: userId,
        role: 'user',
        content: 'Yesterday I finished reading the state management documentation',
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
      );
      await db.chatRecordsDao.insertMessage(
        userId: userId,
        role: 'assistant',
        content: 'Great progress!',
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
      );
    });

    test('retrieves relevant memories for "what did I tell you a few days ago?"', () async {
      final context = await memoryService.retrieveRelevantContext(
        userId: userId,
        query: 'what did I tell you a few days ago?',
      );

      expect(context, isNotEmpty);
      expect(
        context.any((s) => s.contains('Dart and Flutter') || s.contains('productivity')),
        isTrue,
      );
    });

    test('retrieves relevant messages for "yesterday"', () async {
      final context = await memoryService.retrieveRelevantContext(
        userId: userId,
        query: 'what did I tell you yesterday?',
      );

      expect(context, isNotEmpty);
      expect(
        context.any((s) => s.contains('state management')),
        isTrue,
      );
    });

    test('retrieves topical memories on specific keywords', () async {
      final context = await memoryService.retrieveRelevantContext(
        userId: userId,
        query: 'what was my goal for productivity?',
      );

      expect(context, isNotEmpty);
      expect(
        context.any((s) => s.contains('Flutter application for productivity')),
        isTrue,
      );
    });
  });
}
