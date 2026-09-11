import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:comrade/core/enums/app_theme_mode.dart';
import 'package:comrade/core/services/chat/chat_agent.dart';
import 'package:comrade/core/services/chat/chat_tool_base.dart';
import 'package:comrade/core/utils/platform_features.dart';
import 'package:comrade/models/app_info.dart';
import 'package:comrade/providers/apps/apps_info_provider.dart';
import 'package:comrade/providers/focus/focus_mode_provider.dart';
import 'package:comrade/providers/restrictions/apps_restrictions_provider.dart';
import 'package:comrade/providers/system/comrade_settings_provider.dart';
import 'package:comrade/providers/system/permissions_provider.dart';

class TabChat extends ConsumerStatefulWidget {
  const TabChat({super.key});

  @override
  ConsumerState<TabChat> createState() => _TabChatState();
}

class _TabChatState extends ConsumerState<TabChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatAgent _agent = ChatAgent();

  bool _isBusy = false;
  String? _statusLabel;
  bool _historyLoaded = false;

  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final userId = await _agent.memory.resolveUserId();
      final rows =
          await _agent.memory.loadRecentMessages(userId: userId, limit: 50);
      if (!mounted) return;
      setState(() {
        if (rows.isEmpty) {
          _messages.add(
            ChatMessage(
              text:
                  "Hello! I'm Comrade. I remember our chats and can change themes or limit apps when you ask.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          _messages.addAll(rows.map((r) => ChatMessage(
                text: r.content,
                isUser: r.role == 'user',
                timestamp: r.createdAt,
              )));
        }
        _historyLoaded = true;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Hello! I'm Comrade. How can I help you?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _historyLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ChatToolContext _buildToolContext() {
    return ChatToolContext(
      changeThemeMode: (AppThemeMode mode) async {
        ref.read(comradeSettingsProvider.notifier).changeThemeMode(mode);
      },
      currentThemeMode: () => ref.read(comradeSettingsProvider).themeMode,
      updateAppTimer: (package, timerSec) async {
        await ref
            .read(appsRestrictionsProvider.notifier)
            .updateAppTimer(package, timerSec);
      },
      resolveInstalledApps: () async {
        final async = ref.read(appsInfoProvider);
        return async.value ?? <String, AppInfo>{};
      },
      isAndroid: PlatformFeatures.isAndroid,
      openSystemSettings: () async {
        await openAppSettings();
      },
      hasUsagePermission: () async {
        final perm = ref.read(permissionProvider);
        return perm.haveUsageAccessPermission;
      },
      getAppTimer: (package) {
        final restrictions = ref.read(appsRestrictionsProvider);
        return restrictions[package]?.timerSec ?? 0;
      },
      startFocusSession: () async {
        await ref.read(focusModeProvider.notifier).startNewSession();
      },
      stopFocusSession: () async {
        await ref.read(focusModeProvider.notifier).giveUpOrFinishFocusSession(
              isTheSessionSuccessful: true,
              isFiniteSession: false,
            );
      },
      isFocusSessionActive: () {
        return ref.read(focusModeProvider).activeSession.value != null;
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isBusy) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isBusy = true;
      _statusLabel = 'Understanding…';
    });

    _messageController.clear();
    _scrollToBottom();

    final response = await _agent.handle(
      message: text,
      toolContext: _buildToolContext(),
      onProgress: (p) {
        if (!mounted) return;
        setState(() => _statusLabel = p.label ?? _statusLabel);
      },
    );

    if (!mounted) return;

    setState(() {
      _isBusy = false;
      _statusLabel = null;
      _messages.add(ChatMessage(
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        actionSucceeded: response.actionSucceeded,
        toolName: response.toolName,
      ));
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            if (!_historyLoaded)
              const LinearProgressIndicator(minHeight: 2)
            else
              const SizedBox(height: 2),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _messages.length + (_isBusy ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return _ChatBubble(message: _messages[index]);
                  }
                  return _TypingIndicator(label: _statusLabel ?? 'Working…');
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: _ChatInput(
                controller: _messageController,
                onSend: _sendMessage,
                isEnabled: !_isBusy && _historyLoaded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool? actionSucceeded;
  final String? toolName;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionSucceeded,
    this.toolName,
  });
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAction = message.actionSucceeded != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: message.isUser
                ? theme.colorScheme.primary
                : isAction
                    ? (message.actionSucceeded == true
                        ? theme.colorScheme.tertiaryContainer
                        : theme.colorScheme.errorContainer)
                    : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAction && message.toolName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        message.actionSucceeded == true
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 14,
                        color: message.actionSucceeded == true
                            ? theme.colorScheme.onTertiaryContainer
                            : theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        message.actionSucceeded == true
                            ? 'Action completed'
                            : 'Action failed',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: message.actionSucceeded == true
                              ? theme.colorScheme.onTertiaryContainer
                              : theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? theme.colorScheme.onPrimary
                      : isAction && message.actionSucceeded == false
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
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
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: controller,
              enabled: isEnabled,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Message Comrade...",
                border: InputBorder.none,
              ),
              onSubmitted: (_) {
                if (isEnabled) onSend();
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: isEnabled ? onSend : null,
          ),
        ),
      ],
    );
  }
}
