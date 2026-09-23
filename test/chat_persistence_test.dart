import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comrade/core/services/ai_agent_action.dart';
import 'package:comrade/core/services/chat_storage_service.dart';
import 'package:comrade/models/chat_conversation.dart';
import 'package:comrade/models/chat_message.dart';
import 'package:comrade/providers/chat/chat_provider.dart';

void main() {
  group('ChatMessage & Action Serialization Tests', () {
    test('AgentActionResult serialization round-trip', () {
      final actionResult = AgentActionResult(
        toolName: 'start_focus_session',
        success: true,
        message: 'Started 25-minute focus session.',
        executedAt: DateTime.parse('2026-03-23T10:00:00.000Z'),
      );

      final json = actionResult.toJson();
      final restored = AgentActionResult.fromJson(json);

      expect(restored.toolName, equals('start_focus_session'));
      expect(restored.success, isTrue);
      expect(restored.message, equals('Started 25-minute focus session.'));
      expect(restored.executedAt, equals(actionResult.executedAt));
    });

    test('ChatMessage serialization round-trip with action results', () {
      final message = ChatMessage(
        id: 'msg_123',
        text: 'Started focus session for you!',
        isUser: false,
        timestamp: DateTime.parse('2026-03-23T10:05:00.000Z'),
        actionResults: [
          AgentActionResult(
            toolName: 'start_focus_session',
            success: true,
            message: 'Started 15-minute session',
            executedAt: DateTime.parse('2026-03-23T10:05:00.000Z'),
          ),
        ],
      );

      final json = message.toJson();
      final restored = ChatMessage.fromJson(json);

      expect(restored.id, equals('msg_123'));
      expect(restored.text, equals('Started focus session for you!'));
      expect(restored.isUser, isFalse);
      expect(restored.timestamp, equals(message.timestamp));
      expect(restored.actionResults.length, equals(1));
      expect(restored.actionResults.first.toolName, equals('start_focus_session'));
    });
  });

  group('ChatStorageService Tests', () {
    late Directory tempDir;
    late File tempFile;
    late ChatStorageService storageService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('comrade_chat_test_');
      tempFile = File('${tempDir.path}/test_chat.json');
      storageService = ChatStorageService(customFile: tempFile);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Loads empty data when file does not exist', () async {
      final data = await storageService.loadData();
      expect(data.activeConversationId, isNull);
      expect(data.conversations, isEmpty);
    });

    test('Saves and restores conversation correctly', () async {
      final conversation = ChatConversation(
        id: 'conv_test_1',
        title: 'Focus test',
        createdAt: DateTime.parse('2026-03-23T08:00:00.000Z'),
        updatedAt: DateTime.parse('2026-03-23T08:05:00.000Z'),
        messages: [
          ChatMessage(
            id: 'm1',
            text: 'Hello assistant',
            isUser: true,
            timestamp: DateTime.parse('2026-03-23T08:00:00.000Z'),
          ),
          ChatMessage(
            id: 'm2',
            text: 'Hello user!',
            isUser: false,
            timestamp: DateTime.parse('2026-03-23T08:01:00.000Z'),
          ),
        ],
      );

      await storageService.saveConversation(conversation, setActive: true);

      final loaded = await storageService.loadData();
      expect(loaded.activeConversationId, equals('conv_test_1'));
      expect(loaded.conversations.containsKey('conv_test_1'), isTrue);

      final restoredConv = loaded.conversations['conv_test_1']!;
      expect(restoredConv.id, equals('conv_test_1'));
      expect(restoredConv.title, equals('Focus test'));
      expect(restoredConv.messages.length, equals(2));
      expect(restoredConv.messages.first.text, equals('Hello assistant'));
      expect(restoredConv.messages.last.text, equals('Hello user!'));
    });
  });

  group('ChatNotifier Persistence & Navigation Lifecycle Tests', () {
    late Directory tempDir;
    late File tempFile;
    late ChatStorageService storageService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('comrade_notifier_test_');
      tempFile = File('${tempDir.path}/test_chat_notifier.json');
      storageService = ChatStorageService(customFile: tempFile);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Active conversation survives screen disposal and recreation', () async {
      final container1 = ProviderContainer(
        overrides: [
          chatStorageServiceProvider.overrideWithValue(storageService),
        ],
      );

      container1.read(chatNotifierProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      final activeId = container1.read(chatNotifierProvider).activeConversationId;
      expect(activeId, isNotEmpty);

      // Simulate sending messages
      final userMsg = ChatMessage(
        id: 'msg_u1',
        text: 'How much screen time did I use today?',
        isUser: true,
        timestamp: DateTime.now(),
      );
      final aiMsg = ChatMessage(
        id: 'msg_a1',
        text: 'You used 2 hours and 15 minutes today.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      final conv = ChatConversation(
        id: activeId,
        title: 'Screen time query',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [
          ChatState.defaultInitialMessage,
          userMsg,
          aiMsg,
        ],
      );
      await storageService.saveConversation(conv, setActive: true);

      // Simulate navigating away by disposing the first container/screen
      container1.dispose();

      // Simulate returning to the screen by creating a new container with the same storage
      final container2 = ProviderContainer(
        overrides: [
          chatStorageServiceProvider.overrideWithValue(storageService),
        ],
      );

      container2.read(chatNotifierProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      final state2 = container2.read(chatNotifierProvider);

      // Verify conversation was restored exactly as before
      expect(state2.activeConversationId, equals(activeId));
      expect(state2.messages.length, equals(3));
      expect(state2.messages[1].text, equals('How much screen time did I use today?'));
      expect(state2.messages[2].text, equals('You used 2 hours and 15 minutes today.'));

      container2.dispose();
    });

    test('startNewConversation preserves old conversation without overwriting', () async {
      final container = ProviderContainer(
        overrides: [
          chatStorageServiceProvider.overrideWithValue(storageService),
        ],
      );

      final notifier = container.read(chatNotifierProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      final firstId = container.read(chatNotifierProvider).activeConversationId;

      // Add a message to the first conversation and save
      final conv1 = ChatConversation(
        id: firstId,
        title: 'Conversation 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [
          ChatState.defaultInitialMessage,
          ChatMessage(text: 'Message in chat 1', isUser: true, timestamp: DateTime.now()),
        ],
      );
      await storageService.saveConversation(conv1, setActive: true);

      // Start a genuinely new conversation
      await notifier.startNewConversation();
      final secondId = container.read(chatNotifierProvider).activeConversationId;

      expect(secondId, isNot(equals(firstId)));
      expect(container.read(chatNotifierProvider).messages.length, equals(1));

      // Check storage has both conversations preserved
      final storedData = await storageService.loadData();
      expect(storedData.activeConversationId, equals(secondId));
      expect(storedData.conversations.containsKey(firstId), isTrue);
      expect(storedData.conversations.containsKey(secondId), isTrue);

      final preservedOldConv = storedData.conversations[firstId]!;
      expect(preservedOldConv.messages.length, equals(2));
      expect(preservedOldConv.messages[1].text, equals('Message in chat 1'));

      container.dispose();
    });
  });
}
