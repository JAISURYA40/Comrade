/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/core/services/ai_agent_action.dart';
import 'package:comrade/core/services/ai_agent_executor.dart';
import 'package:comrade/core/services/ai_context_builder.dart';
import 'package:comrade/core/services/chat_engine.dart';
import 'package:comrade/core/services/chat_storage_service.dart';
import 'package:comrade/models/chat_conversation.dart';
import 'package:comrade/models/chat_message.dart';

class ChatState {
  final String activeConversationId;
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? error;
  final bool isInitialized;

  const ChatState({
    required this.activeConversationId,
    required this.messages,
    this.isTyping = false,
    this.error,
    this.isInitialized = false,
  });

  static ChatMessage get defaultInitialMessage => ChatMessage(
        text:
            "Hey! I'm your Comrade AI Agent. ⚡\n\nYou can talk to me, or ask me to control Comrade for you:\n- *\"Set my focus time 10 mins now and start\"*\n- *\"Block WhatsApp during focus\"*\n- *\"Stop current focus session\"*\n- *\"How much screen time did I use today?\"*",
        isUser: false,
        timestamp: DateTime.now(),
      );

  ChatState copyWith({
    String? activeConversationId,
    List<ChatMessage>? messages,
    bool? isTyping,
    String? error,
    bool? isInitialized,
  }) {
    return ChatState(
      activeConversationId: activeConversationId ?? this.activeConversationId,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatStorageService _storage;
  final Ref _ref;
  final ChatEngine _chatEngine;
  final AiContextBuilder _contextBuilder;

  ChatNotifier({
    required ChatStorageService storage,
    required Ref ref,
    ChatEngine? chatEngine,
    AiContextBuilder? contextBuilder,
  })  : _storage = storage,
        _ref = ref,
        _chatEngine = chatEngine ?? ChatEngine(),
        _contextBuilder = contextBuilder ?? AiContextBuilder(),
        super(
          ChatState(
            activeConversationId: 'conv_${DateTime.now().millisecondsSinceEpoch}',
            messages: [ChatState.defaultInitialMessage],
          ),
        ) {
    _init();
  }

  Future<void> _init() async {
    final data = await _storage.loadData();
    if (data.activeConversationId != null &&
        data.conversations.containsKey(data.activeConversationId)) {
      final activeConv = data.conversations[data.activeConversationId]!;
      state = state.copyWith(
        activeConversationId: activeConv.id,
        messages: activeConv.messages.isNotEmpty
            ? activeConv.messages
            : [ChatState.defaultInitialMessage],
        isInitialized: true,
      );
    } else {
      await _persistActiveConversation();
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> _persistActiveConversation() async {
    final conv = ChatConversation(
      id: state.activeConversationId,
      title: state.messages.isNotEmpty && state.messages.any((m) => m.isUser)
          ? state.messages.firstWhere((m) => m.isUser).text
          : 'Conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: state.messages,
    );
    await _storage.saveConversation(conv, setActive: true);
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || state.isTyping) return;

    final userMessage = ChatMessage(
      text: cleanText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];

    state = state.copyWith(
      messages: updatedMessages,
      isTyping: true,
      error: null,
    );

    await _persistActiveConversation();

    try {
      final context = await _contextBuilder.build();
      final response = await _chatEngine.processMessage(
        cleanText,
        state.messages,
        context,
      );

      final List<AgentActionResult> executedActions = [];
      if (response.actions.isNotEmpty) {
        for (final action in response.actions) {
          final result = await AiAgentExecutor.execute(action, _ref);
          executedActions.add(result);
        }
        HapticFeedback.mediumImpact();
      }

      final assistantMessage = ChatMessage(
        text: response.replyText,
        isUser: false,
        timestamp: DateTime.now(),
        actionResults: executedActions,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isTyping: false,
      );

      await _persistActiveConversation();
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "I couldn't process that right now. Please try again. ($e)",
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isTyping: false,
        error: e.toString(),
      );

      await _persistActiveConversation();
    }
  }

  Future<void> regenerateResponse() async {
    if (state.isTyping || state.messages.length < 2) return;

    final lastAssistantIndex = state.messages.lastIndexWhere((m) => !m.isUser);
    if (lastAssistantIndex == -1) return;

    int userIndex = lastAssistantIndex - 1;
    while (userIndex >= 0 && !state.messages[userIndex].isUser) {
      userIndex--;
    }
    if (userIndex < 0) return;

    final userMessageText = state.messages[userIndex].text;
    final trimmedMessages = List<ChatMessage>.from(state.messages)..removeAt(lastAssistantIndex);

    state = state.copyWith(
      messages: trimmedMessages,
      isTyping: true,
      error: null,
    );

    await _persistActiveConversation();

    try {
      final context = await _contextBuilder.build();
      final response = await _chatEngine.processMessage(
        userMessageText,
        state.messages,
        context,
      );

      final List<AgentActionResult> executedActions = [];
      if (response.actions.isNotEmpty) {
        for (final action in response.actions) {
          final result = await AiAgentExecutor.execute(action, _ref);
          executedActions.add(result);
        }
        HapticFeedback.mediumImpact();
      }

      final assistantMessage = ChatMessage(
        text: response.replyText,
        isUser: false,
        timestamp: DateTime.now(),
        actionResults: executedActions,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isTyping: false,
      );

      await _persistActiveConversation();
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "I couldn't regenerate the response. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isTyping: false,
        error: e.toString(),
      );

      await _persistActiveConversation();
    }
  }

  Future<void> startNewConversation() async {
    final newId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(
      activeConversationId: newId,
      messages: [ChatState.defaultInitialMessage],
      isTyping: false,
      error: null,
    );

    await _persistActiveConversation();
  }

  Future<void> clearHistory() async {
    await _storage.clearAll();
    await startNewConversation();
  }
}

final chatStorageServiceProvider = Provider<ChatStorageService>((ref) {
  return ChatStorageService();
});

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final storage = ref.watch(chatStorageServiceProvider);
  return ChatNotifier(storage: storage, ref: ref);
});
