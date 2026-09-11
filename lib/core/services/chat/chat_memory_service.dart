/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:comrade/core/database/app_database.dart';
import 'package:comrade/core/database/daos/chat_records_dao.dart';
import 'package:comrade/core/services/drift_db_service.dart';

/// Persistent chat history + selective long-term memories (Drift DB).
class ChatMemoryService {
  ChatMemoryService({ChatRecordsDao? dao})
      : _dao = dao ?? DriftDbService.instance.driftDb.chatRecordsDao;

  final ChatRecordsDao _dao;

  static final _sensitive = RegExp(
    r'(password|api[_\s-]?key|gsk_|sk-|token|secret|otp|pin\b|credit\s*card|cvv|ssn|passcode)',
    caseSensitive: false,
  );

  static final _transientOrCommands = RegExp(
    r'^(hi|hello|hey|good\s*(morning|afternoon|evening|night)|thanks?(\s*you)?|ok(ay)?|cool|sure|yes|no|fine|bye|cya)\b|'
    r'\b(change\s+(my\s+)?theme|set\s+theme|switch\s+theme|block\s+|unblock\s+|open\s+settings)\b',
    caseSensitive: false,
  );

  static final _memoryHints = RegExp(
    r"\b(remember|my goal|i want to|i am studying|i'm studying|my name is|"
    r"i work|call me|don't forget|do not forget|i told you|preference|"
    r"favorite|i prefer|i like|i hate|i always|i never|my schedule)\b",
    caseSensitive: false,
  );

  Future<String> resolveUserId() async {
    try {
      final settings =
          await DriftDbService.instance.driftDb.uniqueRecordsDao
              .loadComradeSettings();
      final name = settings.username.trim();
      if (name.isNotEmpty) return name.toLowerCase();
    } catch (_) {}
    return 'local';
  }

  Future<List<ChatMessageRow>> loadRecentMessages({
    required String userId,
    int limit = 30,
  }) =>
      _dao.fetchRecentMessages(userId: userId, limit: limit);

  Future<void> saveTurn({
    required String userId,
    required String userText,
    required String assistantText,
  }) async {
    final now = DateTime.now();
    await _dao.insertMessage(
      userId: userId,
      role: 'user',
      content: userText,
      createdAt: now,
    );
    await _dao.insertMessage(
      userId: userId,
      role: 'assistant',
      content: assistantText,
      createdAt: now.add(const Duration(milliseconds: 1)),
    );
    await _dao.trimMessages(userId: userId, keep: 250);
    await maybeStoreMemory(userId: userId, userText: userText);
  }

  Future<void> maybeStoreMemory({
    required String userId,
    required String userText,
  }) async {
    final text = userText.trim();
    if (text.length < 8 || text.length > 300) return;
    if (_sensitive.hasMatch(text)) return;
    if (_transientOrCommands.hasMatch(text)) return;
    if (!_memoryHints.hasMatch(text) && !_looksLikeDurableFact(text)) {
      return;
    }

    final tags = _tokenize(text).take(8).join(',');
    await _dao.upsertMemory(userId: userId, content: text, tags: tags);
  }

  /// Ranked relevant memories + dated snippets for “what did I tell you…”.
  Future<List<String>> retrieveRelevantContext({
    required String userId,
    required String query,
    int maxMemories = 5,
    int maxHistorySnippets = 5,
  }) async {
    final tokens = _tokenize(query);
    final memories = await _dao.fetchAllMemories(userId: userId);
    final scored = <({ChatMemoryRow row, double score})>[];
    final isOpenRecall = _isOpenRecallQuery(query);

    for (final m in memories) {
      final hay = '${m.content} ${m.tags}'.toLowerCase();
      var score = 0.0;
      for (final t in tokens) {
        if (hay.contains(t)) score += 1.0;
      }
      final ageDays = DateTime.now().difference(m.updatedAt).inDays;
      if (isOpenRecall) {
        // In open recall, boost recent facts even if query had no content tokens
        if (ageDays <= 21) {
          score += ((21 - ageDays) / 10.0) + 0.5;
        }
      } else {
        // Soft recency boost
        if (ageDays <= 7) {
          score += 0.8;
        } else if (ageDays <= 30) {
          score += 0.4;
        }
      }
      if (score > 0) scored.add((row: m, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));

    final out = <String>[];
    for (final s in scored.take(maxMemories)) {
      out.add(
        'Memory (${_fmtDay(s.row.updatedAt)}): ${s.row.content}',
      );
    }

    // Time-based recall (“few days ago”, “yesterday”, “last week”, “3 days ago”).
    final window = _recallWindow(query);
    if (window != null) {
      final history = await _dao.fetchRecentMessages(userId: userId, limit: 100);
      final hits = history.where((m) {
        if (m.role != 'user') return false;
        final d = m.createdAt;
        return !d.isBefore(window.start) && !d.isAfter(window.end);
      }).toList();

      final ranked = hits.map((m) {
        final hay = m.content.toLowerCase();
        var score = 0.0;
        for (final t in tokens) {
          if (hay.contains(t)) score += 1;
        }
        if (isOpenRecall) score += 0.8;
        return (row: m, score: score);
      }).where((e) => e.score > 0).toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      for (final h in ranked.take(maxHistorySnippets)) {
        out.add(
          'Past message (${_fmtDay(h.row.createdAt)}): ${h.row.content}',
        );
      }
    }

    return out;
  }

  bool _looksLikeDurableFact(String text) {
    final lower = text.toLowerCase();
    return (lower.startsWith('i ') || lower.startsWith("i'm ") || lower.startsWith('my ')) &&
        (lower.contains(' goal') ||
            lower.contains(' study') ||
            lower.contains(' learn') ||
            lower.contains(' prefer') ||
            lower.contains(' always') ||
            lower.contains(' never') ||
            lower.contains(' prepare') ||
            lower.contains(' exam') ||
            lower.contains(' habit') ||
            lower.contains(' routine'));
  }

  bool _isOpenRecallQuery(String query) {
    final q = query.toLowerCase();
    return q.contains('what did i') ||
        q.contains('remember') ||
        q.contains('told you') ||
        q.contains('say') ||
        q.contains('said') ||
        q.contains('mention') ||
        q.contains('few days') ||
        q.contains('yesterday') ||
        q.contains('last week') ||
        q.contains('days ago') ||
        q.contains('earlier');
  }

  ({DateTime start, DateTime end})? _recallWindow(String query) {
    final q = query.toLowerCase();
    final now = DateTime.now();
    final end = now;

    // "X days ago"
    final dayNumMatch = RegExp(r'(\d+)\s*days?\s*ago').firstMatch(q);
    if (dayNumMatch != null) {
      final days = int.tryParse(dayNumMatch.group(1)!) ?? 3;
      return (
        start: now.subtract(Duration(days: days + 1)),
        end: now.subtract(Duration(days: days - 1 > 0 ? days - 1 : 0)),
      );
    }

    if (q.contains('yesterday')) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
      return (start: day, end: day.add(const Duration(days: 1)));
    }
    if (q.contains('few days') || q.contains('couple of days')) {
      return (
        start: now.subtract(const Duration(days: 5)),
        end: end,
      );
    }
    if (q.contains('last week') || q.contains('past week')) {
      return (
        start: now.subtract(const Duration(days: 9)),
        end: end,
      );
    }
    if (q.contains('days ago') ||
        q.contains('told you') ||
        q.contains('what did i') ||
        q.contains('earlier') ||
        q.contains('previously')) {
      return (
        start: now.subtract(const Duration(days: 21)),
        end: end,
      );
    }
    return null;
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .where((t) => !_stop.contains(t))
        .toList();
  }

  String _fmtDay(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _stop = {
    'the',
    'and',
    'for',
    'you',
    'your',
    'that',
    'this',
    'with',
    'have',
    'was',
    'are',
    'did',
    'what',
    'when',
    'how',
    'can',
    'please',
    'tell',
    'about',
    'from',
    'few',
    'ago',
    'days',
    'week',
    'last',
    'past',
    'earlier',
    'something',
  };
}
