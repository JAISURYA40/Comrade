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
import 'package:mindful/config/navigation/app_routes.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_num.dart';
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
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello! I'm your AI Companion. I can help you with focus, productivity, and creating roadmaps. How can I assist you today?",
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    // Check for keywords to navigate to roadmap
    final lowerText = text.toLowerCase();
    if (lowerText.contains('roadmap') || 
        lowerText.contains('give roadmap') ||
        lowerText.contains('show roadmap') ||
        lowerText.contains('create roadmap')) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushNamed(AppRoutes.roadmapPath);
        }
      });
    } else {
      // Mock AI response
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              text: _getMockResponse(text),
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
          _scrollToBottom();
        }
      });
    }
  }

  String _getMockResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (lower.contains('help') || lower.contains('what can you do')) {
      return "I can help you:\n• Create personalized roadmaps for your goals\n• Provide focus and productivity tips\n• Track your progress\n• Answer questions about the app\n\nTry asking for a roadmap!";
    } else if (lower.contains('focus') || lower.contains('productivity')) {
      return "Great question! Here are some tips:\n• Use focus mode to block distractions\n• Set specific time blocks for tasks\n• Take regular breaks\n• Track your screen time\n\nWould you like me to create a roadmap for improving your focus?";
    } else {
      return "I understand. Would you like me to create a roadmap to help you achieve your goals? Just ask for a roadmap!";
    }
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
                const SliverTabsBottomPadding(),
              ],
            ),
          ),
          _ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
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

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
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
                  : theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

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
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            12.hBox,
            RoundedContainer(
              color: theme.colorScheme.primary,
              padding: const EdgeInsets.all(12),
              onPressed: onSend,
              child: Icon(
                FluentIcons.send_20_filled,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
