/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

/// Conversation state tracking for the Comrade chat assistant.
/// Tracks where we are in the conversation flow to provide contextual responses.
enum ChatState {
  /// Initial idle state - ready for user input
  idle,

  /// User asked for roadmap - asking what topic/subject
  askingTopic,

  /// User provided topic - asking about daily time commitment
  askingDailyTime,

  /// User provided daily time - asking about current skill level
  askingLevel,

  /// User provided level - asking about final goal/purpose
  askingGoal,

  /// All information collected - generating roadmap
  generatingRoadmap,

  /// Roadmap generated - conversation complete, back to idle
  roadmapComplete,

  /// User asked for help or general questions
  providingHelp,

  /// User asked about productivity/focus tips
  providingTips,

  /// Casual conversation mode
  casualChat,
}
