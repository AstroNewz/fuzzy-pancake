import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/supabase_service.dart';
import '../../core/theme/app_theme.dart';

/// Gear / Racket Stringing Log with Physics-Based Tension Loss Engine
class GearLog {
  final String id;
  final String playerId;
  final String racketBrandModel;
  final String stringModel;
  final double tensionLbs;
  final DateTime stringingDate;
  final DateTime? expectedRestringDate;
  final String? notes;

  const GearLog({
    required this.id,
    required this.playerId,
    required this.racketBrandModel,
    required this.stringModel,
    required this.tensionLbs,
    required this.stringingDate,
    this.expectedRestringDate,
    this.notes,
  });

  factory GearLog.fromMap(Map<String, dynamic> map) {
    return GearLog(
      id: map['id'] as String,
      playerId: map['player_id'] as String,
      racketBrandModel: map['racket_brand_model'] as String,
      stringModel: map['string_model'] as String,
      tensionLbs: (map['tension_lbs'] as num).toDouble(),
      stringingDate: DateTime.parse(map['stringing_date'] as String),
      expectedRestringDate: map['expected_restring_date'] != null
          ? DateTime.parse(map['expected_restring_date'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'player_id': playerId,
      'racket_brand_model': racketBrandModel,
      'string_model': stringModel,
      'tension_lbs': tensionLbs,
      'stringing_date': stringingDate.toIso8601String().split('T').first,
      'expected_restring_date':
          expectedRestringDate?.toIso8601String().split('T').first,
      'notes': notes,
    };
  }

  /// Days elapsed since stringing
  int get daysSinceStringing =>
      DateTime.now().difference(stringingDate).inDays.clamp(0, 365);

  /// Estimated current tension based on badminton string relaxation curve:
  /// - First 24-48 hours: rapid elastic settling (~8% loss)
  /// - Weeks 1-2: gradual viscoelastic creep (~12-14% total loss)
  /// - Weeks 3-5: progressive degradation (~18-22% total loss)
  /// - Beyond 35 days: >25% loss (dead stringbed)
  double get estimatedCurrentTensionLbs {
    final days = daysSinceStringing;
    double factor;

    if (days <= 1) {
      factor = 0.92;
    } else if (days <= 14) {
      factor = 0.92 - ((days - 1) * 0.005); // ~0.855 at day 14
    } else if (days <= 35) {
      factor = 0.855 - ((days - 14) * 0.004); // ~0.771 at day 35
    } else {
      factor = (0.771 - ((days - 35) * 0.002)).clamp(0.70, 1.0);
    }

    return double.parse((tensionLbs * factor).toStringAsFixed(1));
  }

  /// Percentage drop from initial tension
  double get tensionDropPct {
    final drop = ((tensionLbs - estimatedCurrentTensionLbs) / tensionLbs) * 100;
    return double.parse(drop.toStringAsFixed(1));
  }

  /// Tension health factor (1.0 = brand new, 0.0 = completely dead)
  double get tensionHealthPct {
    return (1.0 - (tensionDropPct / 26.0)).clamp(0.0, 1.0);
  }

  /// Urgency boolean flag
  bool get needsRestringing =>
      daysSinceStringing > 35 ||
      tensionDropPct >= 22.0 ||
      (expectedRestringDate != null &&
          DateTime.now().isAfter(expectedRestringDate!));

  /// Human-readable status label
  String get statusLabel {
    if (needsRestringing) return 'Needs Restringing';
    if (tensionDropPct >= 14.0) return 'Aging Tension';
    return 'Optimal Tension';
  }

  /// Status theme color
  Color get statusColor {
    if (needsRestringing) return AppTheme.errorRed;
    if (tensionDropPct >= 14.0) return AppTheme.gold;
    return AppTheme.primaryEmerald;
  }
}

/// Player Gear Logs Provider
final playerGearLogsProvider =
    FutureProvider.family<List<GearLog>, String>((ref, playerId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('gear_logs')
      .select()
      .eq('player_id', playerId)
      .order('stringing_date', ascending: false);

  return (response as List<dynamic>)
      .map((item) => GearLog.fromMap(item as Map<String, dynamic>))
      .toList();
});
