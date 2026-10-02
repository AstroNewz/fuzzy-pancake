import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingRecord {
  const TrainingRecord(
      {required this.id,
      required this.name,
      required this.completedAt,
      required this.seconds,
      required this.rounds});
  final String id;
  final String name;
  final DateTime completedAt;
  final int seconds;
  final int rounds;
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'completedAt': completedAt.toIso8601String(),
        'seconds': seconds,
        'rounds': rounds
      };
  factory TrainingRecord.fromJson(Map<String, dynamic> map) => TrainingRecord(
      id: map['id'] as String,
      name: map['name'] as String,
      completedAt: DateTime.parse(map['completedAt'] as String),
      seconds: map['seconds'] as int,
      rounds: map['rounds'] as int);
}

final trainingHistoryRepositoryProvider =
    Provider((ref) => TrainingHistoryRepository());
final trainingHistoryProvider =
    FutureProvider.family<List<TrainingRecord>, String>((ref, playerId) =>
        ref.watch(trainingHistoryRepositoryProvider).read(playerId));

class TrainingHistoryRepository {
  Future<void> _writes = Future.value();
  String _key(String playerId) => 'training.history.$playerId';
  Future<List<TrainingRecord>> read(String playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(playerId));
    if (raw == null) return [];
    final records = (jsonDecode(raw) as List)
        .map(
            (e) => TrainingRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return records;
  }

  Future<void> save(String playerId, TrainingRecord record) {
    final write = _writes.then((_) async {
      final records = await read(playerId);
      if (records.any((item) => item.id == record.id)) return;
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(
          _key(playerId),
          jsonEncode(
              [record, ...records].map((item) => item.toJson()).toList()));
      if (!saved) throw StateError('Could not save this workout.');
    });
    _writes = write.catchError((Object _) {});
    return write;
  }
}
