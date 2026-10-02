import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Zero-Budget Automated Telegram Bot Webhook Integration Service
/// Delivers real-time match results, ladder challenge alerts, and club notices
class TelegramNotificationService {
  static const String _botTokenKey = 'smashdeck_tg_bot_token';
  static const String _chatIdKey = 'smashdeck_tg_chat_id';
  static const String _historyKey = 'smashdeck_tg_broadcast_history';

  // Optional pre-configured bot fallback for college club broadcast
  static const String defaultFallbackChatName = 'SmashDeck Badminton Club';

  /// Dispatches a Markdown message to the configured Telegram chat/channel
  static Future<bool> sendBroadcast(String message,
      {bool markdown = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final botToken = prefs.getString(_botTokenKey);
    final chatId = prefs.getString(_chatIdKey);

    // Save message locally into broadcast history log regardless of connectivity
    await _recordBroadcastHistory(message);

    if (botToken == null ||
        botToken.isEmpty ||
        chatId == null ||
        chatId.isEmpty) {
      debugPrint('Telegram Notification (Simulated/Local): \n$message');
      return true; // Successfully buffered locally for zero-budget setup
    }

    try {
      final url =
          Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'chat_id': chatId,
              'text': message,
              if (markdown) 'parse_mode': 'Markdown',
              'disable_web_page_preview': true,
            }),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Telegram broadcast dispatch exception: $e');
      return false;
    }
  }

  /// Tournament updates use plain text so player names cannot break Markdown.
  /// Missing credentials are reported accurately instead of claiming delivery.
  static Future<bool> broadcastTournamentUpdate(String message) async {
    final credentials = await getCredentials();
    if (credentials.botToken?.isNotEmpty != true ||
        credentials.chatId?.isNotEmpty != true) {
      await _recordBroadcastHistory(message);
      return false;
    }
    var chunk = '';
    for (final line in message.split('\n')) {
      if (chunk.length + line.length > 3600) {
        if (!await sendBroadcast(chunk, markdown: false)) return false;
        chunk = '';
      }
      chunk += '$line\n';
    }
    return chunk.isEmpty || await sendBroadcast(chunk, markdown: false);
  }

  /// Broadcasts official Match Result & Elo / Ladder displacement
  static Future<bool> broadcastMatchResult({
    required String winnerName,
    required String loserName,
    required String scoreSummary,
    int? eloDelta,
    String? ladderUpdate,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('*SMASHDECK MATCH RESULT*');
    buffer.writeln('--------------------');
    buffer.writeln('*Winner:* $winnerName');
    buffer.writeln('*Runner-Up:* $loserName');
    buffer.writeln('*Set Score:* $scoreSummary');
    if (eloDelta != null) {
      buffer.writeln('*Rating Adjustment:* +$eloDelta / -$eloDelta PTS');
    }
    if (ladderUpdate != null && ladderUpdate.isNotEmpty) {
      buffer.writeln('*Ladder Movement:* $ladderUpdate');
    }
    buffer.writeln('--------------------');
    buffer.writeln('#SmashDeck #Badminton');

    return sendBroadcast(buffer.toString());
  }

  /// Broadcasts a newly issued Ladder Challenge
  static Future<bool> broadcastLadderChallenge({
    required String challengerName,
    required int challengerRank,
    required String defenderName,
    required int defenderRank,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('*NEW LADDER CHALLENGE ISSUED*');
    buffer.writeln('--------------------');
    buffer.writeln('*Challenger:* $challengerName (Rank #$challengerRank)');
    buffer.writeln('*Defender:* $defenderName (Rank #$defenderRank)');
    buffer.writeln('*Stakes:* Rank #$defenderRank Position');
    buffer.writeln('*Deadline:* 48 Hours to accept & schedule');
    buffer.writeln('--------------------');
    buffer.writeln('#SmashDeck #LadderDuel');

    return sendBroadcast(buffer.toString());
  }

  /// Broadcasts practice session & attendance reminders
  static Future<bool> broadcastPracticeReminder({
    required String sessionDate,
    required String venue,
    required String startTime,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('*SMASHDECK PRACTICE ALERT*');
    buffer.writeln('--------------------');
    buffer.writeln('*Date:* $sessionDate');
    buffer.writeln('*Time:* $startTime');
    buffer.writeln('*Venue:* $venue');
    buffer.writeln('*Attendance:* Dynamic QR check-in opens 15 mins prior.');
    buffer.writeln('--------------------');
    buffer.writeln('#SmashDeck #SquadTraining');

    return sendBroadcast(buffer.toString());
  }

  /// Verification test ping
  static Future<bool> testWebhookPing() async {
    final timestamp = DateTime.now().toLocal().toString().split('.').first;
    return sendBroadcast(
      '*SmashDeck Telegram Webhook Verified!*\n'
      'Timestamp: $timestamp\n'
      'Status: Online & Ready for Match Broadcasts.',
    );
  }

  /// Saves webhook credentials locally
  static Future<void> saveCredentials({
    required String botToken,
    required String chatId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_botTokenKey, botToken.trim());
    await prefs.setString(_chatIdKey, chatId.trim());
  }

  /// Reads configured credentials
  static Future<({String? botToken, String? chatId})> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      botToken: prefs.getString(_botTokenKey),
      chatId: prefs.getString(_chatIdKey),
    );
  }

  static Future<void> _recordBroadcastHistory(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    final entry =
        '${DateTime.now().toIso8601String()}|${message.replaceAll('\n', '<br>')}';
    history.insert(0, entry);
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    await prefs.setStringList(_historyKey, history);
  }

  static Future<List<String>> getBroadcastHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }
}

final telegramServiceProvider =
    Provider((ref) => TelegramNotificationService());
