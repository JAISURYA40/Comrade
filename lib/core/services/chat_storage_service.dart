/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:comrade/models/chat_conversation.dart';

class ChatStorageData {
  final String? activeConversationId;
  final Map<String, ChatConversation> conversations;

  const ChatStorageData({
    this.activeConversationId,
    this.conversations = const {},
  });
}

class ChatStorageService {
  final File? _overrideFile;

  ChatStorageService({File? customFile}) : _overrideFile = customFile;

  Future<File> _getFile() async {
    final override = _overrideFile;
    if (override != null) return override;
    final docsDir = await getApplicationDocumentsDirectory();
    return File(path.join(docsDir.path, 'comrade_chat_history.json'));
  }

  Future<ChatStorageData> loadData() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return const ChatStorageData();
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return const ChatStorageData();
      }

      final Map<String, dynamic> json = jsonDecode(content);
      final activeId = json['activeConversationId'] as String?;
      final rawConversations = json['conversations'] as Map<String, dynamic>? ?? {};

      final Map<String, ChatConversation> conversations = {};
      rawConversations.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          conversations[key] = ChatConversation.fromJson(val);
        }
      });

      return ChatStorageData(
        activeConversationId: activeId,
        conversations: conversations,
      );
    } catch (e) {
      debugPrint("Error loading chat storage: $e");
      return const ChatStorageData();
    }
  }

  Future<void> saveConversation(
    ChatConversation conversation, {
    bool setActive = true,
  }) async {
    try {
      final currentData = await loadData();
      final updatedMap = Map<String, ChatConversation>.from(currentData.conversations);
      updatedMap[conversation.id] = conversation;

      final activeId = setActive ? conversation.id : (currentData.activeConversationId ?? conversation.id);

      final payload = {
        'activeConversationId': activeId,
        'conversations': updatedMap.map((key, val) => MapEntry(key, val.toJson())),
      };

      final file = await _getFile();
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsString(jsonEncode(payload), flush: true);
    } catch (e) {
      debugPrint("Error saving conversation: $e");
    }
  }

  Future<void> setActiveConversationId(String id) async {
    try {
      final currentData = await loadData();
      final payload = {
        'activeConversationId': id,
        'conversations': currentData.conversations.map((key, val) => MapEntry(key, val.toJson())),
      };

      final file = await _getFile();
      await file.writeAsString(jsonEncode(payload), flush: true);
    } catch (e) {
      debugPrint("Error setting active conversation id: $e");
    }
  }

  Future<void> clearAll() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Error clearing chat storage: $e");
    }
  }
}
