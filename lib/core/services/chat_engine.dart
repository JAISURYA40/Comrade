import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:comrade/models/ai_user_context.dart';

class ChatEngine {
  // Keep the API key out of source code.
  // Run with:
  // flutter run --dart-define=GROQ_API_KEY=your_key
  final String apiKey = const String.fromEnvironment('GROQ_API_KEY');

  Future<String> processMessage(
    String message,
    List<dynamic> history,
    AiUserContext context,
  ) async {
    try {
      if (apiKey.isEmpty) {
        return "Error: GROQ_API_KEY is not configured.";
      }

      print("===== COMRADE AI CONTEXT =====");
      print("Screen time: ${context.todayScreenTime}");
      print("App usage: ${context.appUsage}");
      print("Focus today: ${context.todayFocusTime}");
      print("Focus this week: ${context.weeklyFocusTime}");
      print("Active focus: ${context.hasActiveFocusSession}");
      print("Focus duration: ${context.focusSessionDuration}");
      print("==============================");

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
You are Comrade — an AI execution coach and learning assistant.

Your purpose:
Convert user goals into clear daily execution, teach concepts step-by-step, and guide users with discipline without burnout.

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

-------------------------
RESPONSE LOGIC
-------------------------

0. If the user asks about their personal Comrade data:
   - Answer directly using the USER CONTEXT provided below.
   - Do NOT ask clarifying questions.
   - Examples:
     - "What do you know about my activity today?"
     - "Where did I spend most of my time?"
     - "Which app do I use the most?"
     - "How much screen time did I have?"
     - "How much did I focus today?"
   - Calculate the answer from the provided data.
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

      final response = await http.post(
        Uri.parse(
          "https://api.groq.com/openai/v1/chat/completions",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "openai/gpt-oss-20b",
          "messages": messages,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data["choices"][0]["message"]["content"] as String;
      } else {
        return "Error: ${data["error"]?["message"] ?? "Unknown API error"}";
      }
    } catch (e) {
      return "Error: $e";
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
          (entry) =>
              "${entry.key}: ${_formatDuration(entry.value)}",
        )
        .join("\n");
  }
}