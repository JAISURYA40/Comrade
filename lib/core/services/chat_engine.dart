import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:comrade/core/database/app_database.dart';

class ChatEngine {
  final String apiKey;
  final http.Client? client;

  ChatEngine({
    String? apiKey,
    this.client,
  }) : apiKey = apiKey ?? const String.fromEnvironment('GROQ_API_KEY');

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  static const _systemPrompt = """You are Comrade — an AI execution coach and learning assistant.

Your purpose:
Convert user goals into clear daily execution, teach concepts step-by-step, and guide users with discipline without burnout.

You may receive RELEVANT MEMORIES from past conversations. Use them when the user asks what they told you earlier. Do not invent memories. If no memory fits, say you don't have that saved.

You can also trigger device actions via the agent layer (theme, app limits). If the user asks you to change theme or block an app, prefer confirming you can do it — the agent may already handle it. For coaching answers, stay concise.

-------------------------
CORE BEHAVIOR RULES
-------------------------

1. Always respond in a structured format using points or steps(not more than 3,use only if needed).
2. Keep answers crisp and concise max 3 points. Avoid long paragraphs.
3. Use simple, clear English. No complex wording.
4. Be highly motivating, energetic, and positive.
5. Never give harmful, illegal, or unsafe content.
6.If user speaks something useless, vague, or off-topic, ask him to talk about his goals.
7. Never claim you changed settings unless an ACTION RESULT is provided.

-------------------------
STYLE RULES
-------------------------

- Prefer bullet points over paragraphs
- Never exceed more than 50 words in a response
- No unnecessary explanations
- Every response must help the user move forward
""";

  Future<String> processMessage(
    String message,
    List<dynamic> history, {
    List<String> memoryContext = const [],
  }) async {
    try {
      if (!hasApiKey) {
        return "Error: GROQ_API_KEY is not configured. Please supply your Groq API key (e.g. using --dart-define=GROQ_API_KEY=your_key).";
      }

      final recentHistory = history.length > 8
          ? history.sublist(history.length - 8)
          : history;

      final messages = <Map<String, String>>[
        {"role": "system", "content": _systemPrompt},
      ];

      if (memoryContext.isNotEmpty) {
        messages.add({
          "role": "system",
          "content":
              "RELEVANT MEMORIES (use only if relevant; do not invent):\n"
                  "${memoryContext.map((e) => '- $e').join('\n')}",
        });
      }

      for (final msg in recentHistory) {
        if (msg is ChatMessageRow) {
          messages.add({
            "role": msg.role == 'user' ? 'user' : 'assistant',
            "content": msg.content,
          });
        } else {
          // UI ChatMessage duck-typing
          final isUser = (msg as dynamic).isUser == true;
          final text = (msg as dynamic).text as String? ?? '';
          if (text.isEmpty) continue;
          messages.add({
            "role": isUser ? "user" : "assistant",
            "content": text,
          });
        }
      }

      // Ensure latest user message is present (history may already include it).
      final last = messages.isNotEmpty ? messages.last : null;
      if (last == null ||
          last['role'] != 'user' ||
          last['content'] != message) {
        messages.add({"role": "user", "content": message});
      }

      final response = client != null
          ? await client!.post(
              Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $apiKey",
              },
              body: jsonEncode({
                "model": "openai/gpt-oss-20b",
                "messages": messages,
              }),
            )
          : await http.post(
              Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
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
        return "Error: ${data["error"]["message"]}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
