import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/club_module_store.dart';
import '../../../core/network/supabase_service.dart';
import '../../attendance/attendance_repository.dart';
import '../../tournament/models/tournament_model.dart';
import '../models/court_session_model.dart';

String courtDay() => DateFormat('yyyy-MM-dd').format(DateTime.now());

class CourtQueueNotifier extends ClubModuleStore<CourtQueueData> {
  CourtQueueNotifier(SupabaseClient client)
      : super(client, 'court_queue', () => CourtQueueData(date: courtDay()));
  @override
  CourtQueueData decode(Map<String, dynamic> json) => json.isEmpty
      ? CourtQueueData(date: courtDay())
      : CourtQueueData.fromJson(json);
  @override
  Map<String, dynamic> encode(CourtQueueData data) => data.toJson();
  Future<void> importAttendance(
          List<AttendanceRecord> logs, List<ClubPlayer> players) =>
      change((d) {
        final now = DateTime.now();
        if (d.date != courtDay()) {
          if (d.courts.isNotEmpty) {
            throw StateError(
                'Finish yesterday’s court sessions before starting today.');
          }
          d.members.clear();
          d.date = courtDay();
          d.manualOrder = false;
        }
        final present = {
          for (final log in logs
              .where((l) => l.sessionDate == courtDay() && l.verifiedByAdmin))
            log.playerId: log
        };
        for (final p in players.where((p) => present.containsKey(p.id))) {
          if (!d.members.any((q) => q.player.id == p.id)) {
            d.members.add(QueuePlayer(
                player: p, waitingSince: present[p.id]?.checkInTime ?? now));
          }
        }
      });
  Future<void> configure(int count) => change((d) {
        if (count < 1 || count > 3) throw ArgumentError('Choose 1–3 courts.');
        if (d.courts.any((c) => c.court > count)) {
          throw StateError('Finish active sessions before removing a court.');
        }
        d.courtCount = count;
      });
  Future<void> allocate(int court, List<String> a, List<String> b) =>
      change((d) {
        if (d.date != courtDay()) {
          throw StateError('Refresh today’s attendance first.');
        }
        if (court < 1 ||
            court > d.courtCount ||
            d.courts.any((c) => c.court == court)) {
          throw StateError('That court is no longer empty.');
        }
        final ids = [...a, ...b];
        final available =
            d.waiting(DateTime.now()).map((p) => p.player.id).toSet();
        if (a.length != b.length ||
            ![1, 2].contains(a.length) ||
            ids.toSet().length != ids.length ||
            !ids.every(available.contains)) {
          throw StateError(
              'Players changed availability. Generate a fresh match.');
        }
        d.courts.add(CourtSession(
            id: const Uuid().v4(), court: court, teamA: a, teamB: b));
      });
  Future<void> start(String id) => change((d) {
        final c = d.courts.firstWhere((c) => c.id == id);
        c.startedAt ??= DateTime.now();
      });
  Future<void> finish(String id) => change((d) {
        final c = d.courts.where((c) => c.id == id).firstOrNull;
        if (c == null) return;
        final now = DateTime.now();
        for (final p
            in d.members.where((p) => c.players.contains(p.player.id))) {
          if (c.startedAt != null) p.played++;
          p.cooldownUntil =
              c.startedAt == null ? null : now.add(const Duration(minutes: 5));
          p.waitingSince = p.cooldownUntil ?? now;
        }
        d.courts.removeWhere((c) => c.id == id);
      });
  Future<void> reorder(List<String> ids) => change((d) {
        final waiting =
            d.waiting(DateTime.now()).map((p) => p.player.id).toSet();
        if (ids.toSet().length != ids.length ||
            !waiting.containsAll(ids) ||
            ids.length != waiting.length) {
          throw StateError('The queue changed. Try dragging again.');
        }
        d.members.sort((a, b) {
          final x = ids.indexOf(a.player.id), y = ids.indexOf(b.player.id);
          return (x < 0 ? 999 : x).compareTo(y < 0 ? 999 : y);
        });
        d.manualOrder = true;
      });
  Future<void> resetFairness() => change((d) => d.manualOrder = false);
}

final courtQueueProvider =
    StateNotifierProvider<CourtQueueNotifier, AsyncValue<CourtQueueData>>(
        (ref) => CourtQueueNotifier(ref.watch(supabaseClientProvider)));
