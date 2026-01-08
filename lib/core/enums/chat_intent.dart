/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

/// User intent classification for the chat engine.
/// Determines what the user wants to accomplish.
enum ChatIntent {
  /// User wants a roadmap
  roadmap,

  /// User is confused and needs help
  confusion,

  /// User needs motivation
  motivation,

  /// User wants productivity/focus tips
  productivity,

  /// User wants learning advice
  learningAdvice,

  /// Casual conversation/greeting
  casual,

  /// User needs general help
  help,

  /// Unknown intent - needs clarification
  unknown,
}
