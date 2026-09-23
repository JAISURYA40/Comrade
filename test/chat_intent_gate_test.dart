import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comrade/core/services/ai_agent_action.dart';
import 'package:comrade/core/services/ai_context_builder.dart';
import 'package:comrade/core/services/ai_intent_classifier.dart';
import 'package:comrade/core/services/chat_engine.dart';
import 'package:comrade/core/services/chat_storage_service.dart';
import 'package:comrade/models/ai_user_context.dart';
import 'package:comrade/providers/chat/chat_provider.dart';

class FakeContextBuilder extends AiContextBuilder {
  @override
  Future<AiUserContext> build() async {
    return const AiUserContext(
      todayScreenTime: 1200,
      appUsage: {},
      todayFocusTime: 600,
      weeklyFocusTime: 3600,
      hasActiveFocusSession: false,
      focusSessionDuration: 1500,
      distractingApps: [],
    );
  }
}

class TestChatEngine extends ChatEngine {
  final List<AgentAction> injectedActions;

  TestChatEngine({this.injectedActions = const []});

  @override
  Future<ChatEngineResult> processMessage(
    String message,
    List<dynamic> history,
    AiUserContext context,
  ) async {
    final intentDecision =
        AiIntentClassifier.classify(message, recentMessages: history);
    return ChatEngineResult(
      replyText: "Response to: $message",
      actions: injectedActions,
      intentDecision: intentDecision,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatNotifier Intent Gate Tests', () {
    late Directory tempDir;
    late File tempFile;
    late ChatStorageService storageService;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('comrade_intent_gate_test_');
      tempFile = File('${tempDir.path}/test_chat.json');
      storageService = ChatStorageService(customFile: tempFile);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final dummyRefProvider = Provider<Ref>((ref) => ref);

    test(
        'Blocks start_focus_session when user message is casual greeting ("Hey, how are you?")',
        () async {
      final container = ProviderContainer();
      final ref = container.read(dummyRefProvider);
      final chatEngine = TestChatEngine(
        injectedActions: [
          const AgentAction(
            toolName: 'start_focus_session',
            arguments: {'duration_minutes': 25},
          ),
        ],
      );

      final notifier = ChatNotifier(
        storage: storageService,
        ref: ref,
        chatEngine: chatEngine,
        contextBuilder: FakeContextBuilder(),
      );

      await notifier.sendMessage('Hey, how are you?');

      expect(notifier.state.messages.length, equals(3));
      final lastMsg = notifier.state.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.actionResults, isEmpty,
          reason:
              'Casual message must NEVER execute start_focus_session even if returned by model');
    });

    test(
        'Blocks start_focus_session when user message is learning question ("Explain recursion in Java")',
        () async {
      final container = ProviderContainer();
      final ref = container.read(dummyRefProvider);
      final chatEngine = TestChatEngine(
        injectedActions: [
          const AgentAction(
            toolName: 'start_focus_session',
            arguments: {'duration_minutes': 25},
          ),
        ],
      );

      final notifier = ChatNotifier(
        storage: storageService,
        ref: ref,
        chatEngine: chatEngine,
        contextBuilder: FakeContextBuilder(),
      );

      await notifier.sendMessage('Explain recursion in Java');

      expect(notifier.state.messages.length, equals(3));
      final lastMsg = notifier.state.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.actionResults, isEmpty,
          reason: 'Educational doubt must NEVER execute start_focus_session');
    });

    test(
        'Blocks start_focus_session when user message has explicit negative intent ("Don\'t start Focus Mode")',
        () async {
      final container = ProviderContainer();
      final ref = container.read(dummyRefProvider);
      final chatEngine = TestChatEngine(
        injectedActions: [
          const AgentAction(
            toolName: 'start_focus_session',
            arguments: {'duration_minutes': 25},
          ),
        ],
      );

      final notifier = ChatNotifier(
        storage: storageService,
        ref: ref,
        chatEngine: chatEngine,
        contextBuilder: FakeContextBuilder(),
      );

      await notifier.sendMessage("Don't start Focus Mode");

      expect(notifier.state.messages.length, equals(3));
      final lastMsg = notifier.state.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.actionResults, isEmpty,
          reason: 'Negative intent must strictly block start_focus_session');
    });

    test(
        'Does NOT activate focus mode for ambiguous desire ("I really need to focus"), offers confirmation instead',
        () async {
      final container = ProviderContainer();
      final ref = container.read(dummyRefProvider);
      final chatEngine = TestChatEngine(
        injectedActions: [
          const AgentAction(
            toolName: 'start_focus_session',
            arguments: {'duration_minutes': 25},
          ),
        ],
      );

      final notifier = ChatNotifier(
        storage: storageService,
        ref: ref,
        chatEngine: chatEngine,
        contextBuilder: FakeContextBuilder(),
      );

      await notifier.sendMessage('I really need to focus');

      expect(notifier.state.messages.length, equals(3));
      final lastMsg = notifier.state.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.actionResults, isEmpty,
          reason:
              'Ambiguous desire without explicit command must NOT automatically start focus session');
      expect(lastMsg.text.toLowerCase(), contains('focus mode'),
          reason: 'Must prompt user with confirmation question');
    });
  });
}
