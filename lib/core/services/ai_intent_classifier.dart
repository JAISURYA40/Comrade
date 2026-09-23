/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import 'package:comrade/models/ai_intent_decision.dart';

/// Intelligent intent classifier for Comrade's agentic chat assistant.
///
/// Discerningly separates:
/// 1. Explicit negative intent ("Don't start focus mode", "I just want to chat")
/// 2. Device control tools ("Stop focus", "Block Instagram", "Set timer")
/// 3. Explicit action requests ("Start focus mode", "Start a 25 min study session")
/// 4. Questions ABOUT Focus Mode ("What is focus mode?", "How does it work?")
/// 5. Casual conversational banter ("Hey", "How are you?", "I'm bored", "Weather")
/// 6. Comrade data queries ("Show my screen time today")
/// 7. Planning & study roadmaps ("What should I study for DBMS exam?")
/// 8. Informational & learning doubts ("Explain recursion", "What is 3NF?")
/// 9. Ambiguous focus desires ("I really need to focus" -> requires confirmation)
class AiIntentClassifier {
  /// Analyzes a user's [message] and optional conversation context to classify
  /// intent and decide whether an application action is justified.
  static UserIntentDecision classify(
    String message, {
    List<dynamic>? recentMessages,
  }) {
    final raw = message.trim();
    if (raw.isEmpty) {
      return UserIntentDecision.generalChat(reasoning: 'Empty message');
    }

    final lower = raw.toLowerCase();
    final clean = lower
        .replaceAll(RegExp(r'[^\w\s\?]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final duration = _extractDurationMinutes(lower);
    final topic = _extractFocusTopic(lower);

    // 1. Explicit Negative Intent Check
    if (_isExplicitNegative(lower, clean)) {
      return UserIntentDecision.negativeIntent(
        reasoning:
            'User explicitly requested no focus mode or opted for chat only',
      );
    }

    // 2. Previous Confirmation Context Check
    // If assistant recently asked if the user wants to start focus mode, and user agrees:
    if (_isAffirmativeResponse(clean) &&
        _wasRecentAssistantMessageAConfirmationPrompt(recentMessages)) {
      return UserIntentDecision.explicitAction(
        action: 'start_focus_session',
        confidence: 0.96,
        suggestedDurationMinutes: duration ?? 25,
        reasoning: 'User confirmed assistant prompt to start focus mode',
      );
    }

    // 3. Other Comrade Tool Actions (Stop focus, Block app, Set timer)
    final deviceControlAction =
        _detectDeviceControlAction(lower, clean, duration);
    if (deviceControlAction != null) {
      return deviceControlAction;
    }

    // 4. Questions ABOUT Focus Mode or Comrade Features (Informational)
    // E.g. "What is focus mode?", "How does focus mode work?", "Explain focus mode"
    if (_isQuestionAboutFocusMode(lower, clean)) {
      return UserIntentDecision.learningQuestion(
        reasoning: 'Informational question about Focus Mode feature',
      );
    }

    // 5. Explicit Action Requests to Start Focus Mode / Study Session
    // E.g. "Start focus mode", "Start a 25 min study session", "Help me focus for 30m"
    if (_isExplicitFocusAction(lower, clean)) {
      return UserIntentDecision.explicitAction(
        action: 'start_focus_session',
        confidence: 0.95,
        suggestedDurationMinutes: duration ?? 25,
        focusTopic: topic,
        reasoning: 'Explicit user command to initiate a focus or study session',
      );
    }

    // 6. Casual Chat, Greetings, Humor, Boredom, Weather
    // Checked BEFORE general learning questions so "How are you?" or "What's the weather?" aren't categorized as learning
    if (_isCasualConversation(lower, clean)) {
      return UserIntentDecision.generalChat(
        reasoning:
            'Casual greeting, emotion, humor, weather, or general chit-chat',
      );
    }

    // 7. Comrade Statistics Queries
    // E.g. "Show my screen time today", "What are my stats?"
    if (_isComradeStatsQuery(lower, clean)) {
      return UserIntentDecision.comradeQuery(
        reasoning: 'User requested Comrade usage or focus statistics',
      );
    }

    // 8. Planning & Study Roadmap Queries
    // E.g. "I have DBMS exam tomorrow. What should I study?", "Give me a study plan for DSA"
    if (_isPlanningQuery(lower, clean)) {
      return UserIntentDecision.planning(
        reasoning: 'User asked for study guidance, advice, or a roadmap',
      );
    }

    // 9. Educational, Technical & General Learning Questions
    // E.g. "Explain recursion in Java", "What is the capital of France?", "Teach me HashMap"
    if (_isLearningOrConceptualQuestion(lower, clean)) {
      return UserIntentDecision.learningQuestion(
        reasoning: 'Conceptual, coding, or factual question',
      );
    }

    // 10. Ambiguous Focus Expressions (Soft desire, no direct command)
    // E.g. "I really need to focus", "I should probably study", "I have an exam tomorrow"
    if (_isAmbiguousFocusDesire(lower, clean)) {
      return UserIntentDecision.ambiguousFocus(
        suggestedDurationMinutes: duration,
        focusTopic: topic,
        reasoning:
            'Passive intention or concern about focus; requires confirmation',
      );
    }

    // 11. Safe Default: Treat unknown messages as conversation/learning, NEVER auto-activate
    return UserIntentDecision.generalChat(
      confidence: 0.80,
      reasoning: 'Default safe fallback without action',
    );
  }

  // ---------------------------------------------------------------------------
  // Detection Helpers
  // ---------------------------------------------------------------------------

  static bool _isExplicitNegative(String lower, String clean) {
    // Negation phrases forbidding focus mode or opting into pure chat
    final negations = [
      "don't start focus",
      "dont start focus",
      "do not start focus",
      "don't start it",
      "dont start it",
      "do not start it",
      "don't enable focus",
      "dont enable focus",
      "don't turn on focus",
      "dont turn on focus",
      "don't activate focus",
      "dont activate focus",
      "without starting focus",
      "without starting",
      "don't start",
      "dont start",
      "just want to chat",
      "just want to talk",
      "only want to chat",
      "only want to talk",
      "just chatting",
      "only chatting",
      "no focus mode",
      "no focus",
      "don't lock",
      "dont lock",
    ];

    for (final phrase in negations) {
      if (lower.contains(phrase)) return true;
    }

    // "Explain focus mode, don't start it"
    if (lower.contains('focus') &&
        (lower.contains("don't start") ||
            lower.contains("dont start") ||
            lower.contains("do not start") ||
            lower.contains("just chat"))) {
      return true;
    }

    return false;
  }

  static bool _isAffirmativeResponse(String clean) {
    final affirmations = [
      'yes',
      'yeah',
      'yep',
      'yup',
      'sure',
      'please',
      'please do',
      'start it',
      'do it',
      'go ahead',
      'yes please',
      'start focus',
      'start focus mode',
      'ok',
      'okay',
      'lets do it',
      "let's do it",
    ];

    final trimmed = clean.replaceAll('?', '').trim();
    return affirmations.contains(trimmed);
  }

  static bool _wasRecentAssistantMessageAConfirmationPrompt(
      List<dynamic>? recentMessages) {
    if (recentMessages == null || recentMessages.isEmpty) return false;
    // Check the last assistant message
    for (int i = recentMessages.length - 1; i >= 0; i--) {
      final msg = recentMessages[i];
      final isUser = msg.isUser ?? false;
      if (!isUser) {
        final text = (msg.text as String? ?? '').toLowerCase();
        if (text.contains('start focus mode') ||
            text.contains('start a focus session') ||
            text.contains('want me to start focus') ||
            text.contains('would you like me to start') ||
            text.contains('shall i start')) {
          return true;
        }
        break;
      }
    }
    return false;
  }

  static UserIntentDecision? _detectDeviceControlAction(
    String lower,
    String clean,
    int? duration,
  ) {
    // 1. Stop focus session
    if (lower.contains('stop focus') ||
        lower.contains('end focus') ||
        lower.contains('cancel focus') ||
        lower.contains('stop the focus') ||
        lower.contains('finish focus session') ||
        lower.contains('turn off focus')) {
      return UserIntentDecision.explicitAction(
        action: 'stop_focus_session',
        reasoning: 'Explicit command to stop active focus session',
      );
    }

    // 2. Block app in focus
    if ((lower.contains('block') || lower.contains('unblock')) &&
        (lower.contains('app') ||
            lower.contains('during focus') ||
            lower.contains('in focus') ||
            lower.contains('instagram') ||
            lower.contains('youtube') ||
            lower.contains('whatsapp') ||
            lower.contains('facebook') ||
            lower.contains('twitter') ||
            lower.contains('x') ||
            lower.contains('reddit') ||
            lower.contains('snapchat') ||
            lower.contains('tiktok'))) {
      // Check if it's not "block distractions while I study" (which means start focus mode)
      if (!lower.contains('block distraction') &&
          !lower.contains('block distractions while')) {
        return UserIntentDecision.explicitAction(
          action: 'block_app_in_focus',
          reasoning: 'Explicit command to configure app blocklist',
        );
      }
    }

    // 3. Set app timer
    if ((lower.contains('timer') || lower.contains('limit')) &&
        (lower.contains('set') || lower.contains('put')) &&
        (lower.contains('minute') ||
            lower.contains('min') ||
            lower.contains('hour') ||
            lower.contains('mins')) &&
        (lower.contains('app') ||
            lower.contains('instagram') ||
            lower.contains('youtube') ||
            lower.contains('whatsapp') ||
            lower.contains('facebook') ||
            lower.contains('reddit'))) {
      return UserIntentDecision.explicitAction(
        action: 'set_app_timer',
        suggestedDurationMinutes: duration,
        reasoning: 'Explicit command to set application time limit',
      );
    }

    return null;
  }

  static bool _isQuestionAboutFocusMode(String lower, String clean) {
    if (!lower.contains('focus mode')) return false;

    // Direct questions about the focus mode concept/feature
    final informationalPatterns = [
      RegExp(
          r'^(what is|what are|what does|whats|how does|how do|how to use|explain|tell me about|describe)\b.*focus mode'),
      RegExp(r'focus mode\b.*\?$'),
      RegExp(r'meaning of focus mode'),
      RegExp(r'definition of focus mode'),
      RegExp(r'how focus mode works'),
    ];

    for (final pattern in informationalPatterns) {
      if (pattern.hasMatch(lower)) return true;
    }

    if (lower == 'what is focus mode' ||
        lower == 'what is focus mode?' ||
        lower == 'explain focus mode' ||
        lower == 'how does focus mode work' ||
        lower == 'how does focus mode work?' ||
        lower == 'tell me about focus mode') {
      return true;
    }

    return false;
  }

  static bool _isExplicitFocusAction(String lower, String clean) {
    // 1. Direct explicit phrases
    final explicitPhrases = [
      'start focus mode',
      'start focus session',
      'start focus',
      'turn on focus mode',
      'turn on focus',
      'activate focus mode',
      'activate focus',
      'enable focus mode',
      'enable focus',
      'enter focus mode',
      'launch focus mode',
      'start a pomodoro',
      'start pomodoro',
      'run a pomodoro',
      'i need a focused study session',
      'need a focused study session',
      'block distractions while i study',
      'block distractions while studying',
    ];

    for (final phrase in explicitPhrases) {
      if (lower.contains(phrase)) return true;
    }

    // 2. Action verb combined with focus session or study session
    if ((lower.contains('focus session') || lower.contains('study session')) &&
        (lower.contains('start') ||
            lower.contains('begin') ||
            lower.contains('launch') ||
            lower.contains('activate') ||
            lower.contains('enter') ||
            lower.contains('run') ||
            lower.contains('setup') ||
            lower.contains('set up'))) {
      return true;
    }

    // 3. "Start a [X minute] ... focus/study session"
    if (RegExp(
            r'start\s+(?:a\s+)?(?:\d+\s*-?\s*(?:minute|min|hour|m|mins)\s*-?\s*)?(?:[\w\-]+\s+)*(?:study|focus)\s+session')
        .hasMatch(lower)) {
      return true;
    }

    // 4. "Help me focus for [duration]" or "Help me focus on [topic]"
    if (RegExp(r'help me focus (?:for|on)\b').hasMatch(lower)) {
      return true;
    }

    // 5. "I need to study [topic] now" (with imperative "now")
    if (RegExp(r'i need to study\b.*\bnow\b').hasMatch(lower)) {
      return true;
    }

    // 6. "I want to study for [duration]"
    if (RegExp(r'i want to study for\s+\d+').hasMatch(lower)) {
      return true;
    }

    // 7. "Start a [X] minute focus/study"
    if (RegExp(
            r'start\s+(?:a\s+)?\d+\s*-?\s*(?:minute|min|hour|mins)\s+(?:[\w\-]+\s+)*(?:focus|study)')
        .hasMatch(lower)) {
      return true;
    }

    // 8. "Set focus timer for [X] and start"
    if (lower.contains('focus timer') && lower.contains('start')) {
      return true;
    }

    return false;
  }

  static bool _isCasualConversation(String lower, String clean) {
    // Greetings & pleasantries
    final casualPhrases = [
      'hi',
      'hey',
      'hello',
      'hey how are you',
      'how are you',
      'how are you today',
      'how are you doing',
      'good morning',
      'good afternoon',
      'good evening',
      'good night',
      'sup',
      'yo',
    ];

    if (casualPhrases.contains(clean)) return true;
    if (clean.startsWith('hey ') ||
        clean.startsWith('hi ') ||
        clean.startsWith('hello ')) {
      final rest = clean
          .replaceFirst(RegExp(r'^(hey|hi|hello)\s+'), '')
          .replaceAll('?', '')
          .trim();
      if (rest.isEmpty || rest == 'there' || rest.contains('how are you')) {
        return true;
      }
    }

    if (clean.contains('how are you')) {
      return true;
    }

    // Feelings & Boredom
    if (lower.contains('bored') ||
        lower.contains('feeling tired') ||
        lower.contains('feeling sleepy') ||
        lower.contains('im tired')) {
      return true;
    }

    // Humor & Weather & Trivia
    if (lower.contains('tell me a joke') ||
        lower.contains('tell me something interesting') ||
        lower.contains('tell me a fun fact') ||
        lower.contains('weather')) {
      return true;
    }

    // Pleasantries & Check-ins
    if (clean == 'thanks' ||
        clean == 'thank you' ||
        clean == 'cool' ||
        clean == 'nice' ||
        clean == 'awesome' ||
        clean == 'bye' ||
        clean == 'see you' ||
        clean == 'i finished my assignment' ||
        clean == 'finished my homework') {
      return true;
    }

    return false;
  }

  static bool _isComradeStatsQuery(String lower, String clean) {
    return lower.contains('screen time') ||
        lower.contains('my stats') ||
        lower.contains('my statistics') ||
        lower.contains('app usage') ||
        lower.contains('how much did i focus') ||
        lower.contains('where did i spend most') ||
        lower.contains('which app do i use');
  }

  static bool _isPlanningQuery(String lower, String clean) {
    // "I have DBMS exam tomorrow. What should I study?"
    // "Create a study plan for DSA", "Roadmap for Flutter"
    if (lower.contains('exam tomorrow') ||
        lower.contains('exam next') ||
        lower.contains('exam soon') ||
        lower.contains('study plan') ||
        lower.contains('study roadmap') ||
        lower.contains('what should i study') ||
        lower.contains('how should i prepare') ||
        lower.contains('how to prepare for') ||
        lower.contains('how to study for')) {
      return true;
    }

    return false;
  }

  static bool _isLearningOrConceptualQuestion(String lower, String clean) {
    // Check for clear question starters
    final questionStarters = [
      'what is ',
      'what are ',
      "what's ",
      'whats ',
      'how does ',
      'how do ',
      'how can ',
      'how to ',
      'why is ',
      'why does ',
      'why do ',
      'why should ',
      'can you explain ',
      'explain ',
      'teach me ',
      'describe ',
      'tell me about ',
      'difference between ',
      'compare ',
      'meaning of ',
      'definition of ',
    ];

    for (final starter in questionStarters) {
      if (lower.startsWith(starter) || clean.startsWith(starter)) {
        return true;
      }
    }

    // Check specific educational questions:
    // "Explain recursion in Java", "Teach me Java HashMap", "Explain microservices",
    // "What is the capital of France?", "Can you explain this code?", "What should I learn today?"
    if (lower.contains('recursion') ||
        lower.contains('normalization') ||
        lower.contains('3nf') ||
        lower.contains('2nf') ||
        lower.contains('bcnf') ||
        lower.contains('hashmap') ||
        lower.contains('microservices') ||
        lower.contains('capital of') ||
        lower.contains('explain this code') ||
        lower.contains('what should i learn')) {
      return true;
    }

    // If it ends with a question mark and does NOT contain an imperative action command
    if (lower.endsWith('?') &&
        !lower.contains('start') &&
        !lower.contains('activate') &&
        !lower.contains('enable') &&
        !lower.contains('turn on')) {
      return true;
    }

    return false;
  }

  static bool _isAmbiguousFocusDesire(String lower, String clean) {
    // Expressions like "I really need to focus", "I should probably study", "I have an exam tomorrow"
    final ambiguousPhrases = [
      'need to focus',
      'really need to focus',
      'should focus',
      'should study',
      'should probably study',
      'have to focus',
      'have to study',
      'need to study',
      'want to focus',
      'want to study',
      'trouble focusing',
      'cant focus',
      "can't focus",
      'struggling to focus',
      'exam tomorrow',
      'distracted today',
      'get to work',
      'get some work done',
    ];

    for (final phrase in ambiguousPhrases) {
      if (lower.contains(phrase)) return true;
    }

    return false;
  }

  static int? _extractDurationMinutes(String lower) {
    // E.g. "for 25 minutes", "25 minute", "25 mins", "45 min", "45-minute", "for 30m"
    final minMatch = RegExp(r'(\d+)\s*-?\s*(?:minutes|minute|mins|min|m)\b')
        .firstMatch(lower);
    if (minMatch != null) {
      return int.tryParse(minMatch.group(1)!);
    }

    // E.g. "for 1 hour", "for 2 hours", "1.5 hours"
    final hourMatch =
        RegExp(r'(\d+(?:\.\d+)?)\s*-?\s*(?:hours|hour|hrs|hr|h)\b')
            .firstMatch(lower);
    if (hourMatch != null) {
      final hours = double.tryParse(hourMatch.group(1)!);
      if (hours != null) {
        return (hours * 60).round();
      }
    }

    // E.g. "for an hour"
    if (lower.contains('an hour')) {
      return 60;
    }

    return null;
  }

  static String? _extractFocusTopic(String lower) {
    // "Help me focus on DBMS", "study DBMS now", "45-minute DBMS focus"
    final onMatch =
        RegExp(r'(?:focus on|study for|study)\s+([a-zA-Z0-9#\+\.\-]+)')
            .firstMatch(lower);
    if (onMatch != null) {
      final match = onMatch.group(1)!.trim();
      if (match != 'now' &&
          match != 'for' &&
          match != 'a' &&
          match != 'the' &&
          match != 'today') {
        return match.toUpperCase();
      }
    }
    return null;
  }
}
