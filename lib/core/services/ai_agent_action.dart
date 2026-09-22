/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

/// Represents an action requested by the AI agent to be performed in the app.
class AgentAction {
  final String toolName;
  final Map<String, dynamic> arguments;

  const AgentAction({
    required this.toolName,
    required this.arguments,
  });

  factory AgentAction.fromJson(Map<String, dynamic> json) {
    return AgentAction(
      toolName: json['toolName'] ?? json['tool_name'] ?? json['action'] ?? '',
      arguments: Map<String, dynamic>.from(json['arguments'] ?? json['params'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'toolName': toolName,
        'arguments': arguments,
      };
}

/// The result of executing an [AgentAction].
class AgentActionResult {
  final String toolName;
  final bool success;
  final String message;
  final DateTime executedAt;

  AgentActionResult({
    required this.toolName,
    required this.success,
    required this.message,
    DateTime? executedAt,
  }) : executedAt = executedAt ?? DateTime.now();
}

/// Tool definitions in OpenAI / Groq compatible format.
class AiAgentTools {
  static const List<Map<String, dynamic>> toolsDefinition = [
    {
      "type": "function",
      "function": {
        "name": "start_focus_session",
        "description":
            "Starts a new focus mode session with a specified duration in minutes, with optional DND or strict enforcement.",
        "parameters": {
          "type": "object",
          "properties": {
            "duration_minutes": {
              "type": "integer",
              "description": "The focus duration in minutes (e.g. 10, 25, 45, 60)."
            },
            "enable_dnd": {
              "type": "boolean",
              "description": "Whether to turn on Do Not Disturb during focus."
            },
            "enforce": {
              "type": "boolean",
              "description": "Whether to enable strict enforced focus mode."
            }
          },
          "required": ["duration_minutes"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "stop_focus_session",
        "description": "Stops or finishes the currently active focus session.",
        "parameters": {
          "type": "object",
          "properties": {
            "give_up": {
              "type": "boolean",
              "description": "True if the user is giving up prematurely, false if naturally finishing."
            }
          }
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "block_app_in_focus",
        "description":
            "Adds or removes an app from the distracting/blocked apps list during focus sessions. The app will be blocked while focus mode is active.",
        "parameters": {
          "type": "object",
          "properties": {
            "app_name": {
              "type": "string",
              "description": "The name of the app (e.g. 'WhatsApp', 'Instagram', 'YouTube', 'Chrome')."
            },
            "should_block": {
              "type": "boolean",
              "description": "True to block/restrict the app in focus mode, false to unblock/remove."
            }
          },
          "required": ["app_name", "should_block"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "set_app_timer",
        "description": "Sets a daily screen time usage limit/timer for a specific app.",
        "parameters": {
          "type": "object",
          "properties": {
            "app_name": {
              "type": "string",
              "description": "The name of the app (e.g. 'WhatsApp', 'Instagram', 'YouTube')."
            },
            "timer_minutes": {
              "type": "integer",
              "description": "The daily limit allowed for this app in minutes (e.g. 30, 60)."
            }
          },
          "required": ["app_name", "timer_minutes"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_productivity_status",
        "description": "Fetches real-time status of today's screen time, focus history, and active session details.",
        "parameters": {
          "type": "object",
          "properties": {}
        }
      }
    }
  ];
}
