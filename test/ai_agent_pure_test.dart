// ignore_for_file: avoid_print
import 'package:comrade/core/services/ai_agent_action.dart';

void main() {
  print('Running pure Dart AI Agent verification...');

  // Test 1: AgentAction parsing
  final json = {
    'toolName': 'start_focus_session',
    'arguments': {'duration_minutes': 10, 'enable_dnd': true},
  };
  final action = AgentAction.fromJson(json);
  assert(action.toolName == 'start_focus_session', 'Tool name should match');
  assert(action.arguments['duration_minutes'] == 10, 'Duration should be 10');
  assert(action.arguments['enable_dnd'] == true, 'DND should be true');
  print('✓ Test 1 Passed: AgentAction JSON deserialization');

  // Test 2: Tools Definition
  assert(AiAgentTools.toolsDefinition.length == 4, 'Should have 4 action tools');
  final toolNames = AiAgentTools.toolsDefinition
      .map((t) => (t['function'] as Map<String, dynamic>)['name'])
      .toSet();
  assert(toolNames.contains('start_focus_session'), 'Should contain start_focus_session');
  assert(toolNames.contains('stop_focus_session'), 'Should contain stop_focus_session');
  assert(toolNames.contains('block_app_in_focus'), 'Should contain block_app_in_focus');
  assert(toolNames.contains('set_app_timer'), 'Should contain set_app_timer');
  print('✓ Test 2 Passed: AiAgentTools specifications');

  // Test 3: AgentActionResult
  final result = AgentActionResult(
    toolName: 'start_focus_session',
    success: true,
    message: 'Started 10-minute focus session.',
  );
  assert(result.success == true, 'Result success should be true');
  assert(result.message.contains('10-minute'), 'Message should contain 10-minute');
  print('✓ Test 3 Passed: AgentActionResult model');

  print('\nALL AI AGENT TESTS PASSED SUCCESSFULLY! 🎉');
}
