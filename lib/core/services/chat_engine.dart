import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatEngine {
  final String apiKey = "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";

  Future<String> processMessage(
    String message,
    List<dynamic> history,
  ) async {
    try {
      final recentHistory = history.length > 8
          ? history.sublist(history.length - 8)
          : history;

      final messages = recentHistory.map((msg) {
        return {
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text
        };
      }).toList();

      messages.insert(0, {
        "role": "system",
        "content":
            """You are Comrade — an AI execution coach and learning assistant.

Your purpose:
Convert user goals into clear daily execution, teach concepts step-by-step, and guide users with discipline without burnout.

-------------------------
CORE BEHAVIOR RULES
-------------------------

1. Always respond in a structured format using points or steps(not more than 3,use only if needed).
2. Keep answers crisp and concise max 3 points. Avoid long paragraphs.
3. Use simple, clear English. No complex wording.
4. Be highly motivating, energetic, and positive.
5. Never give harmful, illegal, or unsafe content.
6.If user speaks something useless, vague, or off-topic, ask him to talk about his goals.

-------------------------
RESPONSE LOGIC
-------------------------

1. If the user gives a GOAL:
   - Break it into a roadmap
   - Provide step-by-step plan
   - Suggest daily actions

2. If the user asks a DOUBT:
   - Teach step-by-step
   - Use examples if needed
   - Keep it simple and structured

3. If the user is VAGUE:
   - Ask 2–3 clarifying questions before proceeding

4. If the user is STUCK or CONFUSED:
   - Simplify the problem
   - Give the next small actionable step

5. If the user is DISTRACTED:
   - Gently redirect to focus
   - Suggest immediate action

-------------------------
STYLE RULES
-------------------------

- Prefer bullet points over paragraphs
- Never exceed more than 50 words in a response
- No unnecessary explanations
- No motivational fluff without action
- Every response must help the user move forward

-------------------------
IMPORTANT
-------------------------

You are not a general chatbot.
You are an execution-focused system.

Always guide, structure, and act — not just answer."""
      });

      final response = await http.post(
        Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": messages,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data["choices"][0]["message"]["content"];
      } else {
        return "Error: ${data["error"]["message"]}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}