import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/offline_sync_service.dart';
import '../../core/network/supabase_service.dart';

/// Attendance Check-in Result
class CheckInResult {
  final bool isSuccess;
  final bool isDuplicate;
  final bool isOffline;
  final String message;
  final String? playerId;
  final DateTime? checkInTime;

  const CheckInResult({
    required this.isSuccess,
    this.isDuplicate = false,
    this.isOffline = false,
    required this.message,
    this.playerId,
    this.checkInTime,
  });
}

/// Daily Attendance Log Entry
class AttendanceRecord {
  final String id;
  final String playerId;
  final String sessionDate;
  final DateTime checkInTime;
  final String? totpToken;
  final bool verifiedByAdmin;

  const AttendanceRecord({
    required this.id,
    required this.playerId,
    required this.sessionDate,
    required this.checkInTime,
    this.totpToken,
    this.verifiedByAdmin = true,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id']?.toString() ?? '',
      playerId: map['player_id']?.toString() ?? '',
      sessionDate: map['session_date']?.toString() ?? '',
      checkInTime: map['check_in_time'] != null
          ? DateTime.tryParse(map['check_in_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totpToken: map['totp_token']?.toString(),
      verifiedByAdmin: map['verified_by_admin'] as bool? ?? true,
    );
  }
}

/// Attendance Engine Repository
class AttendanceRepository {
  final SupabaseClient _client;
  final OfflineSyncService _offlineSync;

  AttendanceRepository(this._client, this._offlineSync);

  /// Parse and validate QR Token Payload (SMASHDECK:YYYY-MM-DD:XXXXXX)
  static Map<String, String>? parseQrPayload(String rawPayload) {
    final parts = rawPayload.trim().split(':');
    if (parts.length != 3 || parts[0] != 'SMASHDECK') {
      return null;
    }
    final date = DateTime.tryParse(parts[1]);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(parts[1]) ||
        date == null ||
        date.toIso8601String().split('T').first != parts[1] ||
        !RegExp(r'^\d{6}$').hasMatch(parts[2])) {
      return null;
    }
    return {
      'prefix': parts[0],
      'date': parts[1],
      'totp': parts[2],
    };
  }

  /// Check if player has already checked in for a specific date
  Future<bool> hasCheckedInToday(String playerId, String dateStr) async {
    try {
      final response = await _client
          .from(AppConstants.tableAttendanceLogs)
          .select('id')
          .eq('player_id', playerId)
          .eq('session_date', dateStr)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('[AttendanceRepo] Check duplicate error: $e');
      return false;
    }
  }

  /// Process QR code scan for a player
  Future<CheckInResult> processQrCheckIn({
    required String playerId,
    required String qrPayload,
  }) async {
    final parsed = parseQrPayload(qrPayload);
    if (parsed == null) {
      return const CheckInResult(
        isSuccess: false,
        message:
            'Invalid QR Code. Please scan the official SmashDeck Admin code.',
      );
    }

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tokenDate = parsed['date']!;
    final totpToken = parsed['totp']!;

    // Anti-proxy check: Token date must match today's date
    if (tokenDate != todayStr) {
      return CheckInResult(
        isSuccess: false,
        message:
            'QR Code is from a different date ($tokenDate). Please scan today\'s live code.',
      );
    }

    // Check duplicate
    final isAlreadyCheckedIn = await hasCheckedInToday(playerId, todayStr);
    if (isAlreadyCheckedIn) {
      return const CheckInResult(
        isSuccess: false,
        isDuplicate: true,
        message: 'You have already checked in for today\'s session!',
      );
    }

    // Attempt Supabase insert
    try {
      final checkInTime = DateTime.now();
      await _client.from(AppConstants.tableAttendanceLogs).insert({
        'player_id': playerId,
        'session_date': todayStr,
        'totp_token': totpToken,
        'check_in_time': checkInTime.toIso8601String(),
        'verified_by_admin': false,
      });

      return CheckInResult(
        isSuccess: true,
        playerId: playerId,
        checkInTime: checkInTime,
        message: 'Check-in recorded. Awaiting captain verification.',
      );
    } catch (e) {
      debugPrint(
          '[AttendanceRepo] Online check-in failed, buffering offline: $e');

      // Offline-First Fallback (ISSUE-002)
      final checkInTime = DateTime.now();
      await _offlineSync.queueAttendanceCheckIn(
        playerId: playerId,
        sessionDate: todayStr,
        totpToken: totpToken,
        checkInTime: checkInTime,
      );

      return CheckInResult(
        isSuccess: true,
        isOffline: true,
        playerId: playerId,
        checkInTime: checkInTime,
        message:
            'Saved locally (Offline Mode). Will sync when connection is restored.',
      );
    }
  }

  /// Bulk manual attendance marking for Admin/Captain
  Future<int> markBulkAttendance({
    required List<String> playerIds,
    required DateTime sessionDate,
  }) async {
    final dateStr =
        '${sessionDate.year}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}';
    int savedCount = 0;

    for (final playerId in playerIds) {
      try {
        String targetId = playerId;
        if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(targetId)) {
          try {
            final pRow = await _client
                .from('players')
                .select('id')
                .eq('roll_number', playerId)
                .maybeSingle();
            if (pRow != null && pRow['id'] != null) {
              targetId = pRow['id'] as String;
            }
          } catch (_) {}
        }

        await _client.from(AppConstants.tableAttendanceLogs).upsert({
          'player_id': targetId,
          'session_date': dateStr,
          'check_in_time': DateTime.now().toIso8601String(),
          'totp_token': 'MANUAL_ADMIN',
          'verified_by_admin': true,
        }, onConflict: 'player_id,session_date');
        savedCount++;
      } catch (e) {
        // Queue offline
        await _offlineSync.queueAttendanceCheckIn(
          playerId: playerId,
          sessionDate: dateStr,
          totpToken: 'MANUAL_ADMIN',
          checkInTime: DateTime.now(),
        );
        savedCount++;
      }
    }
    return savedCount;
  }

  /// Fetch attendance records for a specific session date
  Future<List<AttendanceRecord>> getAttendanceForDate(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final response = await _client
          .from(AppConstants.tableAttendanceLogs)
          .select()
          .eq('session_date', dateStr);

      final list = (response as List)
          .map((item) => AttendanceRecord.fromMap(item as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      debugPrint('[AttendanceRepo] Fetch attendance error: $e');
      return [];
    }
  }
}

/// Attendance Repository Provider
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final offlineSync = ref.watch(offlineSyncServiceProvider);
  return AttendanceRepository(client, offlineSync);
});

/// Attendance records for today provider
final todayAttendanceRecordsProvider =
    FutureProvider.autoDispose<List<AttendanceRecord>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return await repo.getAttendanceForDate(DateTime.now());
});
