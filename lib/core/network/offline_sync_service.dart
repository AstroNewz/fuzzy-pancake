import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';

/// Serializes local queue changes so a flush cannot erase newly queued records.
class OfflineSyncService {
  static const _keyPendingAttendance = 'smashdeck_pending_attendance';
  static const _keyPendingMatches = 'smashdeck_pending_matches';
  final SupabaseClient _client;
  Future<void> _tail = Future.value();
  Future<SyncResult>? _activeFlush;
  OfflineSyncService(this._client);

  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _store(
      SharedPreferences prefs, String key, List<String> values) async {
    if (!await prefs.setStringList(key, values)) {
      throw StateError('Device storage is unavailable.');
    }
  }

  Future<void> queueAttendanceCheckIn(
          {required String playerId,
          required String sessionDate,
          required String totpToken,
          required DateTime checkInTime}) =>
      _locked(() async {
        final prefs = await SharedPreferences.getInstance();
        final items = prefs.getStringList(_keyPendingAttendance) ?? [];
        items.removeWhere((raw) {
          try {
            final item = jsonDecode(raw);
            return item['player_id'] == playerId &&
                item['session_date'] == sessionDate;
          } catch (_) {
            return false;
          }
        });
        items.add(jsonEncode({
          'player_id': playerId,
          'session_date': sessionDate,
          'totp_token': totpToken,
          'check_in_time': checkInTime.toIso8601String(),
          'verified_by_admin': false
        }));
        await _store(prefs, _keyPendingAttendance, items);
      });

  Future<void> queueMatchResult(
          {required Map<String, dynamic> matchData,
          required List<Map<String, dynamic>> setsData}) =>
      _locked(() async {
        final prefs = await SharedPreferences.getInstance();
        final items = prefs.getStringList(_keyPendingMatches) ?? [];
        items.removeWhere((raw) {
          try {
            return jsonDecode(raw)['match']['id'] == matchData['id'];
          } catch (_) {
            return false;
          }
        });
        items.add(jsonEncode({'match': matchData, 'sets': setsData}));
        await _store(prefs, _keyPendingMatches, items);
      });

  Future<void> removeQueuedMatch(String id) => _locked(() async {
        final prefs = await SharedPreferences.getInstance();
        final items = prefs.getStringList(_keyPendingMatches) ?? [];
        items.removeWhere((raw) {
          try {
            return jsonDecode(raw)['match']['id'] == id;
          } catch (_) {
            return false;
          }
        });
        await _store(prefs, _keyPendingMatches, items);
      });

  Future<int> getPendingRecordsCount() => _locked(() async {
        final prefs = await SharedPreferences.getInstance();
        return (prefs.getStringList(_keyPendingAttendance) ?? []).length +
            (prefs.getStringList(_keyPendingMatches) ?? []).length;
      });

  /// Stage once, write every set, then complete once. Rating triggers run only
  /// after all sets exist; retries never revert an already completed match.
  Future<void> persistMatch(
      Map<String, dynamic> match, List<Map<String, dynamic>> sets) async {
    await _client.from(AppConstants.tableMatches).upsert({
      ...match,
      'status': 'in_progress',
      'winner_team': null,
      'completed_at': null
    },
        onConflict: 'id',
        ignoreDuplicates: true).timeout(const Duration(seconds: 10));
    await _client
        .from(AppConstants.tableMatchSets)
        .upsert(sets, onConflict: 'match_id,set_number')
        .timeout(const Duration(seconds: 10));
    await _client
        .from(AppConstants.tableMatches)
        .update({
          'status': 'completed',
          'winner_team': match['winner_team'],
          'completed_at': match['completed_at'],
        })
        .eq('id', match['id'])
        .neq('status', 'completed')
        .timeout(const Duration(seconds: 10));
  }

  Future<SyncResult> flushPendingData() {
    return _activeFlush ??=
        _locked(_flush).whenComplete(() => _activeFlush = null);
  }

  Future<SyncResult> _flush() async {
    final prefs = await SharedPreferences.getInstance();
    var attendanceCount = 0;
    var matchCount = 0;
    final errors = <String>[];
    final attendance = prefs.getStringList(_keyPendingAttendance) ?? [];
    final remainingAttendance = <String>[];
    for (final raw in attendance) {
      try {
        final item = Map<String, dynamic>.from(jsonDecode(raw));
        item.remove('queued_at');
        await _client
            .from(AppConstants.tableAttendanceLogs)
            .upsert(item,
                onConflict: 'player_id,session_date', ignoreDuplicates: true)
            .timeout(const Duration(seconds: 10));
        attendanceCount++;
      } catch (e) {
        remainingAttendance.add(raw);
        errors.add(e.toString());
      }
    }
    await _store(prefs, _keyPendingAttendance, remainingAttendance);
    final matches = prefs.getStringList(_keyPendingMatches) ?? [];
    final remainingMatches = <String>[];
    for (final raw in matches) {
      try {
        final item = jsonDecode(raw);
        await persistMatch(
            Map<String, dynamic>.from(item['match']),
            (item['sets'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList());
        matchCount++;
      } catch (e) {
        remainingMatches.add(raw);
        errors.add(e.toString());
      }
    }
    await _store(prefs, _keyPendingMatches, remainingMatches);
    return SyncResult(
        syncedAttendance: attendanceCount,
        syncedMatches: matchCount,
        remainingPending: remainingAttendance.length + remainingMatches.length,
        errors: errors);
  }
}

class SyncResult {
  final int syncedAttendance;
  final int syncedMatches;
  final int remainingPending;
  final List<String> errors;
  const SyncResult(
      {required this.syncedAttendance,
      required this.syncedMatches,
      required this.remainingPending,
      required this.errors});
  bool get isSuccess => errors.isEmpty;
  int get totalSynced => syncedAttendance + syncedMatches;
}

final offlineSyncServiceProvider = Provider<OfflineSyncService>(
    (ref) => OfflineSyncService(ref.watch(supabaseClientProvider)));

final pendingOfflineCountProvider = FutureProvider.autoDispose<int>(
    (ref) => ref.watch(offlineSyncServiceProvider).getPendingRecordsCount());
