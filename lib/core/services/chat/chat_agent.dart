/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:comrade/core/services/chat/chat_memory_service.dart';
import 'package:comrade/core/services/chat/chat_tool_base.dart';
import 'package:comrade/core/services/chat/chat_tools.dart';
import 'package:comrade/core/services/chat_engine.dart';

enum ChatAgentPhase {
  idle,
  understanding,
  retrievingMemory,
  selectingTool,
  executing,
  verifying,
  generating,
  done,
  error,
}

class ChatAgentProgress {
  const ChatAgentProgress(this.phase, [this.label]);
  final ChatAgentPhase phase;
  final String? label;
}

class ChatAgentResponse {
  const ChatAgentResponse({
    required this.text,
    this.actionSucceeded,
    this.toolName,
    this.phase = ChatAgentPhase.done,
  });

  final String text;
  final bool? actionSucceeded;
  final String? toolName;
  final ChatAgentPhase phase;
}

/// Orchestrates: intent → tool → execute → verify → respond,
/// with relevant memory retrieval for LLM turns.
class ChatAgent {
  ChatAgent({
    ChatEngine? engine,
    ChatMemoryService? memory,
    ChatToolRegistry? tools,
  })  : _engine = engine ?? ChatEngine(),
        _memory = memory ?? ChatMemoryService(),
        _tools = tools ?? buildDefaultChatTools();

  final ChatEngine _engine;
  final ChatMemoryService _memory;
  final ChatToolRegistry _tools;

  ChatToolPlan? _pendingPlan;

  ChatMemoryService get memory => _memory;
  ChatToolRegistry get tools => _tools;

  Future<ChatAgentResponse> handle({
    required String message,
    required ChatToolContext toolContext,
    void Function(ChatAgentProgress progress)? onProgress,
  }) async {
    void progress(ChatAgentPhase phase, [String? label]) {
      onProgress?.call(ChatAgentProgress(phase, label));
    }

    try {
      progress(ChatAgentPhase.understanding, 'Understanding…');
      final userId = await _memory.resolveUserId();

      // Check if user is confirming or cancelling a pending action
      final cleanText = message.trim().toLowerCase();
      if (_pendingPlan != null) {
        if (RegExp(r'^(yes|confirm|proceed|do it|sure|ok)\b').hasMatch(cleanText)) {
          final plan = _pendingPlan!;
          _pendingPlan = null;
          final tool = _tools.byName(plan.toolName);
          if (tool != null) {
            progress(ChatAgentPhase.executing, plan.summary);
            final result = await tool.execute(plan, toolContext);
            progress(ChatAgentPhase.verifying, 'Verifying…');
            final text = result.success
                ? '✓ ${result.message}'
                : '✗ ${result.message}';

            await _memory.saveTurn(
              userId: userId,
              userText: message,
              assistantText: text,
            );

            return ChatAgentResponse(
              text: text,
              actionSucceeded: result.success,
              toolName: plan.toolName,
            );
          }
        } else if (RegExp(r'^(no|cancel|stop|nevermind|abort)\b').hasMatch(cleanText)) {
          _pendingPlan = null;
          const text = 'Action cancelled.';
          await _memory.saveTurn(
            userId: userId,
            userText: message,
            assistantText: text,
          );
          return const ChatAgentResponse(
            text: text,
            actionSucceeded: false,
          );
        }
      }

      progress(ChatAgentPhase.selectingTool, 'Checking actions…');
      final plan = _tools.resolveBestPlan(message);

      if (plan != null) {
        final tool = _tools.byName(plan.toolName);
        if (tool != null) {
          progress(ChatAgentPhase.executing, plan.summary);
          final result = await tool.execute(plan, toolContext);
          progress(ChatAgentPhase.verifying, 'Verifying…');

          if (result.needsConfirmation) {
            _pendingPlan = plan;
            final text = '${result.message}\nPlease reply "yes" to confirm or "no" to cancel.';
            await _memory.saveTurn(
              userId: userId,
              userText: message,
              assistantText: text,
            );
            return ChatAgentResponse(
              text: text,
              toolName: plan.toolName,
            );
          }

          final text = result.success
              ? '✓ ${result.message}'
              : '✗ ${result.message}';

          await _memory.saveTurn(
            userId: userId,
            userText: message,
            assistantText: text,
          );

          return ChatAgentResponse(
            text: text,
            actionSucceeded: result.success,
            toolName: plan.toolName,
          );
        }
      }

      progress(ChatAgentPhase.retrievingMemory, 'Recalling…');
      final memories = await _memory.retrieveRelevantContext(
        userId: userId,
        query: message,
      );

      final recent = await _memory.loadRecentMessages(
        userId: userId,
        limit: 12,
      );

      progress(ChatAgentPhase.generating, 'Thinking…');
      var reply = await _engine.processMessage(
        message,
        recent,
        memoryContext: memories,
      );

      // Graceful offline fallback: if network failed but we have local memories
      if (reply.startsWith('Error:') && memories.isNotEmpty) {
        final bullets = memories.map((m) => '• $m').join('\n');
        reply = 'Here is what I remember from your past conversations:\n$bullets';
      } else if (reply.startsWith('Error: GROQ_API_KEY')) {
        reply =
            'Comrade AI Assistant is running in offline mode because no Groq API key is configured.\n\n'
            '• Run with: flutter run --dart-define=GROQ_API_KEY=your_key\n'
            '• Or ask me to manage timers, start a focus session, or switch themes!';
      }

      await _memory.saveTurn(
        userId: userId,
        userText: message,
        assistantText: reply,
      );

      return ChatAgentResponse(text: reply);
    } catch (e) {
      progress(ChatAgentPhase.error, 'Error');
      return ChatAgentResponse(
        text: 'Something went wrong: $e',
        phase: ChatAgentPhase.error,
        actionSucceeded: false,
      );
    }
  }
}
