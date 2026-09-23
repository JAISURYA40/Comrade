/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

/// Represents the categorized user intent.
enum UserIntentType {
  /// Casual conversation, greetings, humor, boredom, trivia.
  generalChat,

  /// Technical, conceptual, programming, or Comrade informational questions.
  learningQuestion,

  /// Requests for roadmaps, study planning, exam strategy, guidance.
  planning,

  /// Inquiries about Comrade personal data, screen time, or device stats.
  comradeQuery,

  /// Ambiguous or passive expressions ("I really need to focus", "I should study")
  /// that require confirmation before any action is taken.
  ambiguousFocus,

  /// Explicit negative intent ("Don't start focus mode", "I just want to chat").
  negativeIntent,

  /// Clear, unambiguous command to perform an action (e.g. "Start focus mode for 30m").
  explicitAction,
}

/// Structured decision produced by the agentic intent classifier.
class UserIntentDecision {
  final UserIntentType intent;
  final String action;
  final double confidence;
  final bool requiresConfirmation;
  final int? suggestedDurationMinutes;
  final String? focusTopic;
  final String reasoning;

  const UserIntentDecision({
    required this.intent,
    required this.action,
    required this.confidence,
    this.requiresConfirmation = false,
    this.suggestedDurationMinutes,
    this.focusTopic,
    this.reasoning = '',
  });

  /// Factory for a general chat decision with no actions.
  factory UserIntentDecision.generalChat({
    double confidence = 0.98,
    String reasoning = 'Casual chat or greeting',
  }) {
    return UserIntentDecision(
      intent: UserIntentType.generalChat,
      action: 'none',
      confidence: confidence,
      requiresConfirmation: false,
      reasoning: reasoning,
    );
  }

  /// Factory for a learning/technical question decision with no actions.
  factory UserIntentDecision.learningQuestion({
    double confidence = 0.98,
    String reasoning = 'Educational or informational question',
  }) {
    return UserIntentDecision(
      intent: UserIntentType.learningQuestion,
      action: 'none',
      confidence: confidence,
      requiresConfirmation: false,
      reasoning: reasoning,
    );
  }

  /// Factory for planning/roadmap request with no actions.
  factory UserIntentDecision.planning({
    double confidence = 0.95,
    String reasoning = 'Planning or study strategy request',
  }) {
    return UserIntentDecision(
      intent: UserIntentType.planning,
      action: 'none',
      confidence: confidence,
      requiresConfirmation: false,
      reasoning: reasoning,
    );
  }

  /// Factory for Comrade stats query with no action.
  factory UserIntentDecision.comradeQuery({
    double confidence = 0.98,
    String reasoning = 'Personal stats or Comrade query',
  }) {
    return UserIntentDecision(
      intent: UserIntentType.comradeQuery,
      action: 'none',
      confidence: confidence,
      requiresConfirmation: false,
      reasoning: reasoning,
    );
  }

  /// Factory for ambiguous intent where confirmation is recommended.
  factory UserIntentDecision.ambiguousFocus({
    double confidence = 0.70,
    int? suggestedDurationMinutes,
    String? focusTopic,
    String reasoning =
        'Passive expression of focus or study without direct command',
  }) {
    return UserIntentDecision(
      intent: UserIntentType.ambiguousFocus,
      action: 'ask_confirmation',
      confidence: confidence,
      requiresConfirmation: true,
      suggestedDurationMinutes: suggestedDurationMinutes,
      focusTopic: focusTopic,
      reasoning: reasoning,
    );
  }

  /// Factory for explicit negative intent (user expressly said not to start/act).
  factory UserIntentDecision.negativeIntent({
    double confidence = 1.0,
    String reasoning = 'Explicit negative intent or opt-out from action',
  }) {
    return UserIntentDecision(
      intent: UserIntentType.negativeIntent,
      action: 'none',
      confidence: confidence,
      requiresConfirmation: false,
      reasoning: reasoning,
    );
  }

  /// Factory for explicit action request.
  factory UserIntentDecision.explicitAction({
    required String action,
    double confidence = 0.95,
    int? suggestedDurationMinutes,
    String? focusTopic,
    String reasoning = 'Explicit command to perform an application action',
  }) {
    return UserIntentDecision(
      intent: UserIntentType.explicitAction,
      action: action,
      confidence: confidence,
      requiresConfirmation: false,
      suggestedDurationMinutes: suggestedDurationMinutes,
      focusTopic: focusTopic,
      reasoning: reasoning,
    );
  }

  Map<String, dynamic> toJson() => {
        'intent': intent.name,
        'action': action,
        'confidence': confidence,
        'requires_confirmation': requiresConfirmation,
        if (suggestedDurationMinutes != null)
          'suggested_duration_minutes': suggestedDurationMinutes,
        if (focusTopic != null) 'focus_topic': focusTopic,
        'reasoning': reasoning,
      };

  @override
  String toString() =>
      'UserIntentDecision(intent: $intent, action: $action, confidence: $confidence, requiresConfirmation: $requiresConfirmation)';
}
