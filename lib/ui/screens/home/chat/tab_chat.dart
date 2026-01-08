/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/services/chat_engine.dart';
import 'package:mindful/ui/common/rounded_container.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:mindful/ui/common/sliver_tabs_bottom_padding.dart';

class TabChat extends StatefulWidget {
  const TabChat({super.key});

  @override
  State<TabChat> createState() => _TabChatState();
}

class _TabChatState extends State<TabChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatEngine _chatEngine = ChatEngine();
  bool _isTyping = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello! I'm Comrade, your learning assistant. I can help you create personalized roadmaps, provide productivity tips, and guide your learning journey. How can I assist you today?",
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    // Show typing indicator
    setState(() {
      _isTyping = true;
    });

    // Simulate thinking delay (varies based on message length)
    final delay = Duration(milliseconds: 500 + (text.length * 10).clamp(300, 1500));
    await Future.delayed(delay);

    if (!mounted) return;

    // Process message through chat engine
    final response = await _chatEngine.processMessage(text);

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        isRoadmap: _isRoadmapMessage(response),
      ));
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isRoadmapMessage(String text) {
    return text.contains('ROADMAP OVERVIEW') || 
           text.contains('PHASE 1:') ||
           text.contains('PHASE 2:') ||
           text.contains('PHASE 3:');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ..._messages.map((message) => SliverToBoxAdapter(
                      child: _ChatBubble(message: message),
                    )),
                if (_isTyping)
                  const SliverToBoxAdapter(
                    child: _TypingIndicator(),
                  ),
                const SliverTabsBottomPadding(),
              ],
            ),
          ),
          _ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            isEnabled: !_isTyping,
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isRoadmap;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isRoadmap = false,
  });
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                FluentIcons.sparkle_20_filled,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            12.hBox,
          ],
          Flexible(
            child: RoundedContainer(
              color: isUser
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : message.isRoadmap
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerHighest,
              padding: EdgeInsets.all(message.isRoadmap ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isRoadmap)
                    _RoadmapContent(text: message.text)
                  else
                    StyledText(
                      message.text,
                      fontSize: 15,
                      color: isUser
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  4.vBox,
                  StyledText(
                    _formatTime(message.timestamp),
                    fontSize: 11,
                    isSubtitle: true,
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            12.hBox,
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                FluentIcons.person_20_filled,
                size: 18,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

/// Widget to display roadmap content with proper formatting
class _RoadmapContent extends StatelessWidget {
  const _RoadmapContent({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      if (line.startsWith('ROADMAP OVERVIEW') ||
          line.startsWith('PHASE 1:') ||
          line.startsWith('PHASE 2:') ||
          line.startsWith('PHASE 3:') ||
          line.startsWith('Final Outcome:')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: StyledText(
              line,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 15,
                  ),
                ),
                Expanded(
                  child: StyledText(
                    line.substring(2),
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.contains('Objective:') ||
                 line.contains('Tasks:') ||
                 line.contains('Outcome:')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: StyledText(
              line,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: StyledText(
              line,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

/// Typing indicator widget
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              FluentIcons.sparkle_20_filled,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          12.hBox,
          RoundedContainer(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                4.hBox,
                _TypingDot(delay: 200),
                4.hBox,
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.delay});

  final int delay;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.onSend,
    this.isEnabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: RoundedContainer(
                color: theme.colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  enabled: isEnabled,
                  onSubmitted: isEnabled ? (_) => onSend() : null,
                ),
              ),
            ),
            12.hBox,
            RoundedContainer(
              color: isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(12),
              onPressed: isEnabled ? onSend : null,
              child: Icon(
                FluentIcons.send_20_filled,
                color: isEnabled ? Colors.white : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
