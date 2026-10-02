import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/club_module_store.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/services/telegram_notification_service.dart';
import '../models/tournament_model.dart';

class TournamentCollection {
  TournamentCollection(this.cups);
  final List<Tournament> cups;
}

class TournamentNotifier extends ClubModuleStore<TournamentCollection> {
  TournamentNotifier(SupabaseClient client)
      : super(client, 'tournaments', () => TournamentCollection([]));
  @override
  TournamentCollection decode(Map<String, dynamic> json) =>
      TournamentCollection((json['cups'] as List? ?? [])
          .map((c) => Tournament.fromJson(Map<String, dynamic>.from(c)))
          .toList());
  @override
  Map<String, dynamic> encode(TournamentCollection value) =>
      {'cups': value.cups.map((t) => t.toJson()).toList()};
  Future<void> create(Tournament cup) =>
      change((draft) => draft.cups.insert(0, cup));
  Future<void> markLive(String cupId, String matchId) => change((draft) {
        final match = draft.cups
            .firstWhere((t) => t.id == cupId)
            .matches
            .firstWhere((m) => m.id == matchId);
        if (!match.playable) throw StateError('This match is not ready.');
        match.status = 'live';
      });
  Future<void> complete(
      String cupId, String matchId, List<Map<String, int>> sets) async {
    var changed = false;
    await change((draft) {
      final cup = draft.cups.firstWhere((t) => t.id == cupId);
      changed = !cup.matches.firstWhere((m) => m.id == matchId).finished;
      cup.completeMatch(matchId, sets);
    });
    if (!mounted || !changed || hasConflict) return;
    final cup = state.requireValue.cups.firstWhere((t) => t.id == cupId);
    final round =
        cup.rounds.firstWhere((r) => r.matches.any((m) => m.id == matchId));
    if (round.matches.every((m) => m.finished)) {
      final update =
          StringBuffer('SmashDeck — ${cup.name}\n${round.name} results\n');
      for (final m in round.matches.where((m) => m.status == 'completed')) {
        update.writeln(
            '${cup.side(m.sideA)?.name} vs ${cup.side(m.sideB)?.name}: ${m.sets.map((s) => "${s['a']}-${s['b']}").join(', ')}');
      }
      if (cup.champion != null)
        update.writeln('Champion: ${cup.champion!.name} 🏆');
      await TelegramNotificationService.broadcastTournamentUpdate(
          update.toString());
    }
  }

  Future<bool> broadcast(String cupId) async {
    final cup = state.requireValue.cups.firstWhere((t) => t.id == cupId);
    final text = StringBuffer('SmashDeck — ${cup.name}\n');
    for (final round in cup.rounds) {
      final completed = round.matches.where((m) => m.status == 'completed');
      if (completed.isEmpty) continue;
      text.writeln('\n${round.name}');
      for (final m in completed) {
        text.writeln(
            '${cup.side(m.sideA)?.name} vs ${cup.side(m.sideB)?.name}: ${m.sets.map((s) => "${s['a']}-${s['b']}").join(', ')}');
      }
    }
    if (cup.champion != null) {
      text.writeln('\nChampion: ${cup.champion!.name} 🏆');
    }
    return TelegramNotificationService.broadcastTournamentUpdate(
        text.toString());
  }
}

final tournamentProvider =
    StateNotifierProvider<TournamentNotifier, AsyncValue<TournamentCollection>>(
        (ref) => TournamentNotifier(ref.watch(supabaseClientProvider)));
