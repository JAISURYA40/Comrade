/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/core/services/ai_agent_action.dart';
import 'package:comrade/core/services/ai_agent_executor.dart';
import 'package:comrade/core/services/ai_context_builder.dart';
import 'package:comrade/core/services/chat_engine.dart';

class TabChat extends ConsumerStatefulWidget {
  const TabChat({super.key});

  @override
  ConsumerState<TabChat> createState() => _TabChatState();
}

class _TabChatState extends ConsumerState<TabChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ChatEngine _chatEngine = ChatEngine();
  final AiContextBuilder _contextBuilder = AiContextBuilder();

  bool _isTyping = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hey! I'm your Comrade AI Agent. ⚡\n\nYou can talk to me, or ask me to control Comrade for you:\n- *\"Set my focus time 10 mins now and start\"*\n- *\"Block WhatsApp during focus\"*\n- *\"Stop current focus session\"*\n- *\"How much screen time did I use today?\"*",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? customPrompt]) async {
    final text = (customPrompt ?? _messageController.text).trim();

    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );

      _isTyping = true;
    });

    if (customPrompt == null) {
      _messageController.clear();
    }
    _scrollToBottom();

    try {
      // Build the user's current Comrade context.
      final context = await _contextBuilder.build();

      final response = await _chatEngine.processMessage(
        text,
        _messages,
        context,
      );

      // Execute any tool/action requests returned by the AI Agent
      final List<AgentActionResult> executedActions = [];
      if (response.actions.isNotEmpty) {
        for (final action in response.actions) {
          final result = await AiAgentExecutor.execute(action, ref);
          executedActions.add(result);
        }
        HapticFeedback.mediumImpact();
      }

      if (!mounted) return;

      setState(() {
        _isTyping = false;

        _messages.add(
          ChatMessage(
            text: response.replyText,
            isUser: false,
            timestamp: DateTime.now(),
            actionResults: executedActions,
          ),
        );
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isTyping = false;

        _messages.add(
          ChatMessage(
            text: "I couldn't process that right now. Please try again. ($e)",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    }
  }

  Future<void> _regenerateResponse() async {
    if (_isTyping || _messages.length < 2) return;

    final lastAssistantIndex = _messages.lastIndexWhere(
      (message) => !message.isUser,
    );

    if (lastAssistantIndex == -1) return;

    int userIndex = lastAssistantIndex - 1;

    while (userIndex >= 0 && !_messages[userIndex].isUser) {
      userIndex--;
    }

    if (userIndex < 0) return;

    final userMessage = _messages[userIndex].text;

    setState(() {
      _messages.removeAt(lastAssistantIndex);
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final context = await _contextBuilder.build();

      final response = await _chatEngine.processMessage(
        userMessage,
        _messages,
        context,
      );

      final List<AgentActionResult> executedActions = [];
      if (response.actions.isNotEmpty) {
        for (final action in response.actions) {
          final result = await AiAgentExecutor.execute(action, ref);
          executedActions.add(result);
        }
        HapticFeedback.mediumImpact();
      }

      if (!mounted) return;

      setState(() {
        _isTyping = false;

        _messages.add(
          ChatMessage(
            text: response.replyText,
            isUser: false,
            timestamp: DateTime.now(),
            actionResults: executedActions,
          ),
        );
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isTyping = false;

        _messages.add(
          ChatMessage(
            text: "I couldn't regenerate the response. Please try again.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    }
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(
                  top: 16,
                  bottom: 20,
                ),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    final message = _messages[index];

                    final isLastAssistantMessage =
                        !message.isUser &&
                        index == _messages.lastIndexWhere(
                          (item) => !item.isUser,
                        );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ChatMessageView(
                          message: message,
                          showActions: isLastAssistantMessage,
                          onCopy: () => _copyMessage(message.text),
                          onRegenerate: _regenerateResponse,
                        ),
                        // Quick Action suggestions on first load
                        if (index == 0 && _messages.length == 1)
                          _QuickActionSuggestions(
                            onSelect: (prompt) => _sendMessage(prompt),
                          ),
                      ],
                    );
                  }

                  return const _TypingIndicator();
                },
              ),
            ),
            _ChatComposer(
              controller: _messageController,
              onSend: () => _sendMessage(),
              isEnabled: !_isTyping,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CHAT MESSAGE MODEL
// ============================================================

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<AgentActionResult> actionResults;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionResults = const [],
  });
}

// ============================================================
// QUICK ACTION SUGGESTIONS
// ============================================================

class _QuickActionSuggestions extends StatelessWidget {
  const _QuickActionSuggestions({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final suggestions = [
      "Set my focus time 10 mins now and start",
      "Block the WhatsApp app",
      "How much screen time did I use today?",
      "Stop my focus session",
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 16, top: 4, bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((prompt) {
          return ActionChip(
            label: Text(
              prompt,
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.primary,
              ),
            ),
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: () => onSelect(prompt),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// MESSAGE VIEW
// ============================================================

class _ChatMessageView extends StatelessWidget {
  const _ChatMessageView({
    required this.message,
    required this.showActions,
    required this.onCopy,
    required this.onRegenerate,
  });

  final ChatMessage message;
  final bool showActions;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _UserMessage(
        message: message,
      );
    }

    return _AssistantMessage(
      message: message,
      showActions: showActions,
      onCopy: onCopy,
      onRegenerate: onRegenerate,
    );
  }
}

// ============================================================
// USER MESSAGE
// ============================================================

class _UserMessage extends StatelessWidget {
  const _UserMessage({
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: 48,
        right: 16,
        top: 8,
        bottom: 8,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 360,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: 15.5,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ASSISTANT MESSAGE
// ============================================================

class _AssistantMessage extends StatelessWidget {
  const _AssistantMessage({
    required this.message,
    required this.showActions,
    required this.onCopy,
    required this.onRegenerate,
  });

  final ChatMessage message;
  final bool showActions;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Agent Actions Executed Badges
                    if (message.actionResults.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: message.actionResults.map((result) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: result.success
                                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                  : theme.colorScheme.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: result.success
                                    ? theme.colorScheme.primary.withValues(alpha: 0.35)
                                    : theme.colorScheme.error.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  result.success
                                      ? Icons.check_circle_rounded
                                      : Icons.error_outline_rounded,
                                  size: 14,
                                  color: result.success
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.error,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    result.message,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: result.success
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],

                    MarkdownBody(
                      data: message.text,
                      selectable: true,
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                        h1: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        h2: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        h3: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                        strong: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        em: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontStyle: FontStyle.italic,
                        ),
                        listBullet: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 15,
                        ),
                        code: TextStyle(
                          color: theme.colorScheme.onSurface,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          fontSize: 13.5,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        tableHead: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        tableBody: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                        tableBorder: TableBorder.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.25,
                          ),
                        ),
                        a: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onTapLink: (
                        text,
                        href,
                        title,
                      ) {
                        if (href == null) return;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showActions)
            Padding(
              padding: const EdgeInsets.only(
                left: 42,
                top: 4,
              ),
              child: Row(
                children: [
                  _MessageActionButton(
                    icon: Icons.copy_outlined,
                    tooltip: "Copy",
                    onPressed: onCopy,
                  ),
                  const SizedBox(width: 4),
                  _MessageActionButton(
                    icon: Icons.refresh_rounded,
                    tooltip: "Regenerate",
                    onPressed: onRegenerate,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// MESSAGE ACTION BUTTON
// ============================================================

class _MessageActionButton extends StatelessWidget {
  const _MessageActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 18,
      ),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
    );
  }
}

// ============================================================
// TYPING INDICATOR
// ============================================================

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 19,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value;

              return Row(
                children: List.generate(
                  3,
                  (index) {
                    final delay = index * 0.2;

                    final animationValue =
                        ((value - delay) % 1.0);

                    final opacity =
                        0.3 +
                        (animationValue < 0.5
                            ? animationValue * 1.4
                            : (1 - animationValue) * 1.4);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                      ),
                      child: Opacity(
                        opacity: opacity.clamp(0.3, 1.0),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHAT COMPOSER
// ============================================================

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.onSend,
    required this.isEnabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(
              alpha: 0.12,
            ),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isEnabled,
              minLines: 1,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: "Ask Comrade AI to take action...",
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(
                      alpha: 0.45,
                    ),
                  ),
                ),
              ),
              onSubmitted: (_) {
                if (isEnabled) {
                  onSend();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: "Send",
              onPressed: isEnabled ? onSend : null,
              icon: Icon(
                Icons.arrow_upward_rounded,
                color: isEnabled
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}