/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:comrade/core/services/ai_agent_action.dart';
import 'package:comrade/models/ai_user_context.dart';

class ChatEngineResult {
  final String replyText;
  final List<AgentAction> actions;

  const ChatEngineResult({
    required this.replyText,
    this.actions = const [],
  });
}

class ChatEngine {
  final String apiKey = "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";
  final String modelName = "openai/gpt-oss-20b";

  Future<ChatEngineResult> processMessage(
    String message,
    List<dynamic> history,
    AiUserContext context,
  ) async {
    try {
      debugPrint("===== COMRADE AI AGENT CONTEXT =====");
      debugPrint("Screen time: ${context.todayScreenTime}");
      debugPrint("App usage: ${context.appUsage}");
      debugPrint("Focus today: ${context.todayFocusTime}");
      debugPrint("Focus this week: ${context.weeklyFocusTime}");
      debugPrint("Active focus: ${context.hasActiveFocusSession}");
      debugPrint("Focus duration: ${context.focusSessionDuration}");
      debugPrint("=====================================");

      final recentHistory = history.length > 8
          ? history.sublist(history.length - 8)
          : history;

      final messages = recentHistory.map((msg) {
        return {
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text,
        };
      }).toList();

      messages.insert(0, {
        "role": "system",
        "content": """
You are Comrade — an autonomous AI execution coach, productivity assistant, and companion.

Your purpose:
You don't just talk; you take ACTION in the app on behalf of the user. When the user asks you to start focus, stop focus, block apps, set limits, or manage sessions, USE YOUR TOOLS IMMEDIATELY.

-------------------------
CORE AGENT CAPABILITIES
-------------------------
1. Focus Mode Control:
   - Start focus sessions (e.g. "set focus time 10 mins and start", "start 25 min pomodoro").
   - Stop or finish active focus sessions.
2. App Restrictions:
   - Block distracting apps in focus mode (e.g. "block whatsapp", "restrict instagram").
   - Unblock apps from focus mode.
   - Set daily screen time limits/timers for apps.
3. Personal Data & Stats:
   - Read screen time, top apps, focus streaks, and active session status from the context below.

-------------------------
RESPONSE RULES
-------------------------
1. Always call the relevant tool when the user asks for an action.
2. Keep textual responses concise, energetic, motivating, and clear.
3. When taking an action, confirm what you did in 1 short sentence.
4. If the user asks general questions, teach or assist them step-by-step with no more than 3 bullet points.

-------------------------
USER CONTEXT
-------------------------
Today's total screen time: ${_formatDuration(context.todayScreenTime)}
Today's app usage:
${_formatAppUsage(context.appUsage)}
Today's focus time: ${_formatDuration(context.todayFocusTime)}
Focus time during the last 7 days: ${_formatDuration(context.weeklyFocusTime)}
Active focus session: ${context.hasActiveFocusSession ? "Yes" : "No"}
Configured focus session duration: ${_formatDuration(context.focusSessionDuration)}
Distracting apps: ${context.distractingApps.isEmpty ? "None configured" : context.distractingApps.join(", ")}
""",
      });

      final requestPayload = {
        "model": modelName,
        "messages": messages,
        "tools": AiAgentTools.toolsDefinition,
        "tool_choice": "auto",
      };

      final response = await http.post(
        Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode(requestPayload),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        final errorMsg = data["error"]?["message"] ?? "Unknown API error";
        return ChatEngineResult(
          replyText: "Error communicating with AI agent: $errorMsg",
        );
      }

      final choice = data["choices"]?[0];
      final responseMessage = choice?["message"];
      final rawContent = responseMessage?["content"] as String?;
      final toolCalls = responseMessage?["tool_calls"] as List<dynamic>?;

      final List<AgentAction> extractedActions = [];

      // 1. Parse native tool calls
      if (toolCalls != null && toolCalls.isNotEmpty) {
        for (final call in toolCalls) {
          try {
            final func = call["function"];
            final funcName = func["name"]?.toString() ?? "";
            final argsString = func["arguments"]?.toString() ?? "{}";
            final Map<String, dynamic> args = jsonDecode(argsString);
            extractedActions.add(AgentAction(
              toolName: funcName,
              arguments: args,
            ));
          } catch (e) {
            debugPrint("Failed to parse tool call: $e");
          }
        }
      }

      // 2. Parse text content fallback (if actions were written inside code blocks)
      String replyText = rawContent?.trim() ?? "";
      if (replyText.contains('"toolName"') || replyText.contains('"tool_name"')) {
        try {
          final regex = RegExp(r'\{[^{}]*(?:"toolName"|"tool_name")[^{}]*\}');
          for (final match in regex.allMatches(replyText)) {
            final jsonStr = match.group(0);
            if (jsonStr != null) {
              final parsed = jsonDecode(jsonStr);
              extractedActions.add(AgentAction.fromJson(parsed));
            }
          }
        } catch (_) {}
      }

      // 3. Fallback confirmation text if content is empty but tool was called
      if (replyText.isEmpty && extractedActions.isNotEmpty) {
        replyText = _generateFallbackActionConfirmation(extractedActions.first);
      } else if (replyText.isEmpty) {
        replyText = "I'm on it!";
      }

      return ChatEngineResult(
        replyText: replyText,
        actions: extractedActions,
      );
    } catch (e) {
      debugPrint("ChatEngine Exception: $e");
      return ChatEngineResult(
        replyText: "Sorry, I ran into an error: $e",
      );
    }
  }

  String _generateFallbackActionConfirmation(AgentAction action) {
    switch (action.toolName) {
      case 'start_focus_session':
        final mins = action.arguments['duration_minutes'] ?? 25;
        return "🚀 Starting your $mins-minute focus session now. Stay focused!";
      case 'stop_focus_session':
        return "⏹️ Stopping your current focus session.";
      case 'block_app_in_focus':
        final app = action.arguments['app_name'] ?? 'app';
        final block = action.arguments['should_block'] != false;
        return block
            ? "🚫 Added $app to your focus blocklist."
            : "✅ Removed $app from your focus blocklist.";
      case 'set_app_timer':
        final app = action.arguments['app_name'] ?? 'app';
        final mins = action.arguments['timer_minutes'] ?? 0;
        return "⏳ Set daily screen time limit for $app to $mins minutes.";
      case 'get_productivity_status':
        return "📊 Here is your productivity status for today.";
      default:
        return "⚡ Executing ${action.toolName}...";
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    }
    return "${minutes}m";
  }

  String _formatAppUsage(Map<String, int> appUsage) {
    if (appUsage.isEmpty) {
      return "No app usage data available.";
    }

    final sortedApps = appUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topApps = sortedApps.take(5);

    return topApps
        .map(
          (entry) => "${entry.key}: ${_formatDuration(entry.value)}",
        )
        .join("\n");
  }
}