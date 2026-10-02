import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dynamic Attendance QR Token (Issue-003 Proxy Mitigation)
class AttendanceToken {
  final String dateString;
  final String totp;
  final DateTime expiresAt;

  AttendanceToken({
    required this.dateString,
    required this.totp,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get payload => 'SMASHDECK:$dateString:$totp';

  static AttendanceToken generate() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final randomInt = Random().nextInt(900000) + 100000;
    return AttendanceToken(
      dateString: dateStr,
      totp: randomInt.toString(),
      expiresAt: now.add(const Duration(seconds: 15)), // 15s refresh
    );
  }
}

/// Dynamic QR Token State Notifier for Admin screen
class AdminAttendanceTokenNotifier extends StateNotifier<AttendanceToken> {
  AdminAttendanceTokenNotifier() : super(AttendanceToken.generate());

  void refresh() {
    state = AttendanceToken.generate();
  }
}

final adminAttendanceTokenProvider =
    StateNotifierProvider<AdminAttendanceTokenNotifier, AttendanceToken>((ref) {
  return AdminAttendanceTokenNotifier();
});
