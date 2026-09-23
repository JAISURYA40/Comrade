import 'package:flutter_test/flutter_test.dart';
import 'package:comrade/core/services/ai_intent_classifier.dart';
import 'package:comrade/models/ai_intent_decision.dart';
import 'package:comrade/models/chat_message.dart';

void main() {
  group('AI Intent Classifier Tests', () {
    group('1. Normal Conversation (Must NEVER trigger Focus Mode)', () {
      final casualMessages = [
        'Hey',
        'How are you?',
        'Hey, how are you?',
        "I'm bored",
        "I'm bored today",
        'Tell me something interesting',
        'Tell me a joke',
        "What is today's weather?",
        'I finished my assignment',
        'Good morning',
        'Hello there',
      ];

      for (final msg in casualMessages) {
        test('Casual message: "$msg" -> generalChat, action: none', () {
          final decision = AiIntentClassifier.classify(msg);
          expect(decision.intent, equals(UserIntentType.generalChat),
              reason: 'Message "$msg" should be generalChat');
          expect(decision.action, equals('none'));
          expect(decision.requiresConfirmation, isFalse);
        });
      }
    });

    group('2. Learning & Educational Questions (Must NEVER trigger Focus Mode)',
        () {
      final learningMessages = [
        'Explain DBMS normalization',
        'What is recursion?',
        'Teach me Java HashMap',
        'Explain microservices',
        'Explain recursion in Java',
        'What is the capital of France?',
        "What's the difference between Java and Python?",
        'Can you explain this code?',
        'What should I learn today?',
        'What is focus mode?',
        'How does focus mode work in Comrade?',
        'Explain focus mode',
      ];

      for (final msg in learningMessages) {
        test('Learning question: "$msg" -> learningQuestion, action: none', () {
          final decision = AiIntentClassifier.classify(msg);
          expect(decision.intent, equals(UserIntentType.learningQuestion),
              reason: 'Message "$msg" should be learningQuestion');
          expect(decision.action, equals('none'));
          expect(decision.requiresConfirmation, isFalse);
        });
      }
    });

    group('3. Explicit Negative Intent (Must NEVER trigger Focus Mode)', () {
      final negativeMessages = [
        "Don't start Focus Mode",
        'I just want to chat',
        "Explain focus mode, don't start it",
        'Do not start focus mode',
        'Without starting focus mode, tell me about it',
        'Only want to chat',
      ];

      for (final msg in negativeMessages) {
        test('Negative intent: "$msg" -> negativeIntent, action: none', () {
          final decision = AiIntentClassifier.classify(msg);
          expect(decision.intent, equals(UserIntentType.negativeIntent),
              reason: 'Message "$msg" should be negativeIntent');
          expect(decision.action, equals('none'));
          expect(decision.requiresConfirmation, isFalse);
        });
      }
    });

    group('4. Ambiguous Requests (Must NOT automatically activate Focus Mode)',
        () {
      final ambiguousMessages = [
        'I really need to focus',
        'I should probably study',
        'I am having trouble focusing today',
      ];

      for (final msg in ambiguousMessages) {
        test('Ambiguous request: "$msg" -> requires confirmation before action',
            () {
          final decision = AiIntentClassifier.classify(msg);
          expect(decision.intent, equals(UserIntentType.ambiguousFocus));
          expect(decision.requiresConfirmation, isTrue);
          expect(decision.action, equals('ask_confirmation'));
        });
      }
    });

    group('5. Explicit Focus Action Requests (SHOULD trigger Focus Mode)', () {
      test('Start Focus Mode', () {
        final decision = AiIntentClassifier.classify('Start Focus Mode');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('start_focus_session'));
        expect(decision.requiresConfirmation, isFalse);
      });

      test('Start a 25 minute study session', () {
        final decision =
            AiIntentClassifier.classify('Start a 25 minute study session');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('start_focus_session'));
        expect(decision.suggestedDurationMinutes, equals(25));
      });

      test('Help me focus on Java', () {
        final decision = AiIntentClassifier.classify('Help me focus on Java');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('start_focus_session'));
        expect(decision.focusTopic, equals('JAVA'));
      });

      test('Start a Pomodoro for 45 minutes', () {
        final decision =
            AiIntentClassifier.classify('Start a Pomodoro for 45 minutes');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('start_focus_session'));
        expect(decision.suggestedDurationMinutes, equals(45));
      });

      test('Help me focus for the next 30 minutes', () {
        final decision = AiIntentClassifier.classify(
            'Help me focus for the next 30 minutes');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('start_focus_session'));
        expect(decision.suggestedDurationMinutes, equals(30));
      });

      test('I need to study DBMS now', () {
        final decision =
            AiIntentClassifier.classify('I need to study DBMS now');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('start_focus_session'));
        expect(decision.focusTopic, equals('DBMS'));
      });

      test('I want to study for 45 minutes', () {
        final decision =
            AiIntentClassifier.classify('I want to study for 45 minutes');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('start_focus_session'));
        expect(decision.suggestedDurationMinutes, equals(45));
      });

      test('Start a Pomodoro', () {
        final decision = AiIntentClassifier.classify('Start a Pomodoro');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('start_focus_session'));
      });

      test('I need a focused study session', () {
        final decision =
            AiIntentClassifier.classify('I need a focused study session');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('start_focus_session'));
      });

      test('Block distractions while I study', () {
        final decision =
            AiIntentClassifier.classify('Block distractions while I study');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('start_focus_session'));
      });

      test('Start a 45-minute DBMS focus session', () {
        final decision =
            AiIntentClassifier.classify('Start a 45-minute DBMS focus session');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('start_focus_session'));
        expect(decision.suggestedDurationMinutes, equals(45));
      });
    });

    group('6. Other Comrade Device Control Tools', () {
      test('Stop focus mode', () {
        final decision = AiIntentClassifier.classify('Stop focus mode');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('stop_focus_session'));
      });

      test('Block Instagram during focus', () {
        final decision =
            AiIntentClassifier.classify('Block Instagram during focus');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('block_app_in_focus'));
      });

      test('Set Instagram timer to 30 mins', () {
        final decision =
            AiIntentClassifier.classify('Set Instagram timer to 30 mins');
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('set_app_timer'));
        expect(decision.suggestedDurationMinutes, equals(30));
      });
    });

    group('7. Affirmative confirmation flow', () {
      test('User says "Yes please" after assistant prompted to start focus',
          () {
        final history = [
          ChatMessage(
            text: 'I really need to focus',
            isUser: true,
            timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
          ChatMessage(
            text:
                'I understand! Would you like me to start a focus session for you?',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ];

        final decision =
            AiIntentClassifier.classify('Yes please', recentMessages: history);
        expect(decision.intent, equals(UserIntentType.explicitAction));
        expect(decision.action, equals('start_focus_session'));
      });
    });
  });
}
