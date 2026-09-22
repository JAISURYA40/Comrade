import 'package:flutter_test/flutter_test.dart';
import 'package:comrade/core/services/ai_agent_action.dart';

void main() {
  group('AI Agent Unit Tests', () {
    test('AgentAction JSON deserialization', () {
      final json = {
        'toolName': 'start_focus_session',
        'arguments': {'duration_minutes': 10, 'enable_dnd': true},
      };
      final action = AgentAction.fromJson(json);
      expect(action.toolName, equals('start_focus_session'));
      expect(action.arguments['duration_minutes'], equals(10));
      expect(action.arguments['enable_dnd'], equals(true));
    });

    test('AiAgentTools specifications', () {
      expect(AiAgentTools.toolsDefinition.length, equals(4));
      final toolNames = AiAgentTools.toolsDefinition
          .map((t) => (t['function'] as Map<String, dynamic>)['name'])
          .toSet();
      expect(toolNames, contains('start_focus_session'));
      expect(toolNames, contains('stop_focus_session'));
      expect(toolNames, contains('block_app_in_focus'));
      expect(toolNames, contains('set_app_timer'));
    });

    test('AgentActionResult model', () {
      final result = AgentActionResult(
        toolName: 'start_focus_session',
        success: true,
        message: 'Started 10-minute focus session.',
      );
      expect(result.success, isTrue);
      expect(result.message, contains('10-minute'));
    });
  });
}
