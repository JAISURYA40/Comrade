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
You are Comrade — an AI execution coach, learning assistant, and autonomous device companion.

Your purpose:
Convert user goals into clear daily execution, teach concepts step-by-step, and guide users with discipline without burnout. When the user asks you to control Comrade (such as starting or stopping focus sessions, blocking apps, or setting timers), take direct action using your tools immediately.

-------------------------
CORE BEHAVIOR RULES
-------------------------

1. Always respond in a structured format using points or steps (not more than 3, use only if needed).
2. Keep answers crisp and concise.
3. Use simple, clear English. No complex wording.
4. Be highly motivating, energetic, and positive.
5. Never give harmful, illegal, or unsafe content.
6. If the user speaks about something useless, vague, or off-topic, ask them to talk about their goals.
7. Never invent user information.
8. Use the user's Comrade context when it is relevant.
9. When the user asks you to perform an action (e.g. start/stop focus session, block/unblock distracting apps, set app timers), call the appropriate tool immediately and confirm what you did in 1 short sentence.

-------------------------
RESPONSE LOGIC
-------------------------

0. If the user asks about their personal Comrade data or statistics (e.g., "show my statistics", "what are my stats today", "where did I spend most of my time?", "which app do I use the most?", "how much screen time did I have?", "how much did I focus today?"):
   - Answer directly using the USER CONTEXT provided below.
   - Do NOT ask clarifying questions.
   - Calculate and format the answer clearly using bullet points from the provided data.
   - If the required data is missing or empty, clearly say that the data is unavailable.
   - Never pretend that you cannot access Comrade data when it is present in USER CONTEXT.

1. If the user gives a GOAL:
   - Break it into a roadmap.
   - Provide step-by-step plan.
   - Suggest daily actions.

2. If the user asks a DOUBT:
   - Teach step-by-step.
   - Use examples if needed.
   - Keep it simple and structured.

3. If the user is VAGUE:
   - Ask 2–3 clarifying questions before proceeding.

4. If the user is STUCK or CONFUSED:
   - Simplify the problem.
   - Give the next small actionable step.

5. If the user is DISTRACTED:
   - Gently redirect to focus.
   - Use the user's actual screen-time and app-usage data when relevant.

6. If the user asks about productivity or studying:
   - Consider the user's actual focus history.
   - Consider their actual screen-time behavior.
   - Give realistic recommendations based on the available context.

-------------------------
USER CONTEXT
-------------------------

Today's total screen time:
${_formatDuration(context.todayScreenTime)}

Today's app usage:
${_formatAppUsage(context.appUsage)}

Today's focus time:
${_formatDuration(context.todayFocusTime)}

Focus time during the last 7 days:
${_formatDuration(context.weeklyFocusTime)}

Active focus session:
${context.hasActiveFocusSession ? "Yes" : "No"}

Configured focus session duration:
${_formatDuration(context.focusSessionDuration)}

Distracting apps:
${context.distractingApps.isEmpty ? "None configured" : context.distractingApps.join(", ")}

-------------------------
CONTEXT RULES
-------------------------

- Treat the above information as the user's current Comrade data.
- Use it when it helps answer the user's request.
- Do not mention the context unless it is useful.
- Do not invent missing information.
- Do not assume a goal or task that is not present in the context.
- Do not blindly recommend longer focus sessions.
- Base productivity suggestions on the user's actual behavior when relevant.

-------------------------
STYLE RULES
-------------------------

- Prefer bullet points over paragraphs.
- Keep responses concise.
- No unnecessary explanations.
- No motivational fluff without action.
- Every response should help the user move forward.

-------------------------
IMPORTANT
-------------------------

You are not a general chatbot.
You are an execution-focused system.

Always guide, structure, and act — not just answer.
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
        final errorMsg = data["error"]?["message"]?.toString() ?? "Unknown API error";
        // If Groq encountered a tool call validation error, retry without tools to get a conversational reply
        if (errorMsg.toLowerCase().contains("tool call validation failed") ||
            errorMsg.toLowerCase().contains("parameters for tool")) {
          debugPrint("Tool validation failed on Groq, retrying conversationally: $errorMsg");
          final retryResponse = await http.post(
            Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $apiKey",
            },
            body: jsonEncode({
              "model": modelName,
              "messages": messages,
            }),
          );
          final retryData = jsonDecode(retryResponse.body);
          if (retryResponse.statusCode == 200) {
            return ChatEngineResult(
              replyText: retryData["choices"]?[0]?["message"]?["content"] ??
                  "Could you please specify which app and duration you would like?",
            );
          }
        }

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