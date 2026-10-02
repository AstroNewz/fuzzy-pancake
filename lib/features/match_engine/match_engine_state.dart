import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/bwf_scoring_rules.dart';

/// Point Commentary Event Model
class PointCommentaryEvent {
  final int pointIndex;
  final int setIndex;
  final String scoringTeam; // 'A' or 'B'
  final String scorerName;
  final int scoreA;
  final int scoreB;
  final String? tag; // e.g. 'Smash Winner', 'Deceptive Drop', 'Net Kill'
  final String? comment;
  final DateTime timestamp;

  const PointCommentaryEvent({
    required this.pointIndex,
    required this.setIndex,
    required this.scoringTeam,
    required this.scorerName,
    required this.scoreA,
    required this.scoreB,
    this.tag,
    this.comment,
    required this.timestamp,
  });

  PointCommentaryEvent copyWith({
    String? tag,
    String? comment,
  }) {
    return PointCommentaryEvent(
      pointIndex: pointIndex,
      setIndex: setIndex,
      scoringTeam: scoringTeam,
      scorerName: scorerName,
      scoreA: scoreA,
      scoreB: scoreB,
      tag: tag ?? this.tag,
      comment: comment ?? this.comment,
      timestamp: timestamp,
    );
  }
}

/// Snapshot for Score Undo stack
class ScoreSnapshot {
  final DoublesServicePositions doublesPositions;
  final int currentSet;
  final int teamAScore;
  final int teamBScore;
  final String servingTeam;
  final List<Map<String, int>> completedSets;
  final bool hasIntervalTriggered;
  final List<PointCommentaryEvent> pointEvents;

  const ScoreSnapshot({
    this.doublesPositions = const DoublesServicePositions(),
    required this.currentSet,
    required this.teamAScore,
    required this.teamBScore,
    required this.servingTeam,
    required this.completedSets,
    required this.hasIntervalTriggered,
    required this.pointEvents,
  });
}

/// Live Match State for Umpire Scoring UI
class LiveMatchState {
  final DoublesServicePositions doublesPositions;
  final String? matchId;
  final String matchType; // 'singles' or 'doubles'
  final String category; // 'ladder', 'tournament', 'practice'
  final bool isRatingEligible;
  final int targetPoints; // Default 21, customizable to 11, 15, 21, 30, etc.
  final int bestOfSets; // Default 3, customizable to 1, 3, 5

  final String teamA1Id;
  final String teamAPlayer1Name;
  final String? teamA2Id;
  final String? teamAPlayer2Name;

  final String teamB1Id;
  final String teamBPlayer1Name;
  final String? teamB2Id;
  final String? teamBPlayer2Name;

  final int currentSet; // 1, 2, 3
  final int teamAScore;
  final int teamBScore;
  final List<Map<String, int>> completedSets;
  final String servingTeam; // 'A' or 'B'
  final bool hasIntervalTriggered;
  final bool isPaused;
  final bool isMatchCompleted;
  final String? matchWinner;
  final List<ScoreSnapshot> undoStack;
  final List<PointCommentaryEvent> pointEvents;

  const LiveMatchState({
    this.doublesPositions = const DoublesServicePositions(),
    this.matchId,
    this.matchType = 'singles',
    this.category = 'ladder',
    this.isRatingEligible = true,
    this.targetPoints = 21,
    this.bestOfSets = 3,
    this.teamA1Id = 'p-01',
    required this.teamAPlayer1Name,
    this.teamA2Id,
    this.teamAPlayer2Name,
    this.teamB1Id = 'p-04',
    required this.teamBPlayer1Name,
    this.teamB2Id,
    this.teamBPlayer2Name,
    this.currentSet = 1,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.completedSets = const [],
    this.servingTeam = 'A',
    this.hasIntervalTriggered = false,
    this.isPaused = false,
    this.isMatchCompleted = false,
    this.matchWinner,
    this.undoStack = const [],
    this.pointEvents = const [],
  });

  bool get isDoubles => matchType == 'doubles';
  int get servingScore => servingTeam == 'A' ? teamAScore : teamBScore;
  String playerAt(String team, int index) => team == 'A'
      ? (index == 0 ? teamAPlayer1Name : teamAPlayer2Name ?? teamAPlayer1Name)
      : (index == 0 ? teamBPlayer1Name : teamBPlayer2Name ?? teamBPlayer1Name);
  String get serverName => playerAt(servingTeam,
      isDoubles ? doublesPositions.playerIndex(servingTeam, servingScore) : 0);
  String get receiverName => playerAt(
      servingTeam == 'A' ? 'B' : 'A',
      isDoubles
          ? doublesPositions.playerIndex(
              servingTeam == 'A' ? 'B' : 'A', servingScore)
          : 0);

  LiveMatchState copyWith({
    DoublesServicePositions? doublesPositions,
    String? matchId,
    String? matchType,
    String? category,
    bool? isRatingEligible,
    int? targetPoints,
    int? bestOfSets,
    String? teamA1Id,
    String? teamAPlayer1Name,
    String? teamA2Id,
    String? teamAPlayer2Name,
    String? teamB1Id,
    String? teamBPlayer1Name,
    String? teamB2Id,
    String? teamBPlayer2Name,
    int? currentSet,
    int? teamAScore,
    int? teamBScore,
    List<Map<String, int>>? completedSets,
    String? servingTeam,
    bool? hasIntervalTriggered,
    bool? isPaused,
    bool? isMatchCompleted,
    String? matchWinner,
    List<ScoreSnapshot>? undoStack,
    List<PointCommentaryEvent>? pointEvents,
  }) {
    return LiveMatchState(
      doublesPositions: doublesPositions ?? this.doublesPositions,
      matchId: matchId ?? this.matchId,
      matchType: matchType ?? this.matchType,
      category: category ?? this.category,
      isRatingEligible: isRatingEligible ?? this.isRatingEligible,
      targetPoints: targetPoints ?? this.targetPoints,
      bestOfSets: bestOfSets ?? this.bestOfSets,
      teamA1Id: teamA1Id ?? this.teamA1Id,
      teamAPlayer1Name: teamAPlayer1Name ?? this.teamAPlayer1Name,
      teamA2Id: teamA2Id ?? this.teamA2Id,
      teamAPlayer2Name: teamAPlayer2Name ?? this.teamAPlayer2Name,
      teamB1Id: teamB1Id ?? this.teamB1Id,
      teamBPlayer1Name: teamBPlayer1Name ?? this.teamBPlayer1Name,
      teamB2Id: teamB2Id ?? this.teamB2Id,
      teamBPlayer2Name: teamBPlayer2Name ?? this.teamBPlayer2Name,
      currentSet: currentSet ?? this.currentSet,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      completedSets: completedSets ?? this.completedSets,
      servingTeam: servingTeam ?? this.servingTeam,
      hasIntervalTriggered: hasIntervalTriggered ?? this.hasIntervalTriggered,
      isPaused: isPaused ?? this.isPaused,
      isMatchCompleted: isMatchCompleted ?? this.isMatchCompleted,
      matchWinner:
          isMatchCompleted == false ? null : matchWinner ?? this.matchWinner,
      undoStack: undoStack ?? this.undoStack,
      pointEvents: pointEvents ?? this.pointEvents,
    );
  }
}

/// Live Umpire Match StateNotifier with undo history, BWF scoring, and commentary
class LiveMatchNotifier extends StateNotifier<LiveMatchState> {
  void restoreMatch(LiveMatchState saved) => state = saved;
  LiveMatchNotifier()
      : super(const LiveMatchState(
          teamA1Id: 'SD-0001',
          teamAPlayer1Name: 'Sachin Jyani',
          teamB1Id: 'SD-0002',
          teamBPlayer1Name: 'Ishan Narayan Shukla',
        ));

  void initMatch({
    String? matchId,
    String matchType = 'singles',
    String category = 'ladder',
    bool isRatingEligible = true,
    int targetPoints = 21,
    int bestOfSets = 3,
    required String teamA1Id,
    required String teamA1Name,
    String? teamA2Id,
    String? teamA2Name,
    required String teamB1Id,
    required String teamB1Name,
    String? teamB2Id,
    String? teamB2Name,
  }) {
    state = LiveMatchState(
      matchId: matchId ?? const Uuid().v4(),
      matchType: matchType,
      category: category,
      isRatingEligible: isRatingEligible,
      targetPoints: targetPoints,
      bestOfSets: bestOfSets,
      teamA1Id: teamA1Id,
      teamAPlayer1Name: teamA1Name,
      teamA2Id: teamA2Id,
      teamAPlayer2Name: teamA2Name,
      teamB1Id: teamB1Id,
      teamBPlayer1Name: teamB1Name,
      teamB2Id: teamB2Id,
      teamBPlayer2Name: teamB2Name,
    );
  }

  void setTargetPoints(int points) {
    if (points <= 0 || state.undoStack.isNotEmpty) return;
    state = state.copyWith(targetPoints: points);
  }

  void setBestOfSets(int sets) {
    if (sets <= 0 || sets.isEven || state.undoStack.isNotEmpty) return;
    state = state.copyWith(bestOfSets: sets);
  }

  void togglePause() => state = state.copyWith(isPaused: !state.isPaused);

  void _pushSnapshot() {
    final snapshot = ScoreSnapshot(
      doublesPositions: state.doublesPositions,
      currentSet: state.currentSet,
      teamAScore: state.teamAScore,
      teamBScore: state.teamBScore,
      servingTeam: state.servingTeam,
      completedSets: List.from(state.completedSets),
      hasIntervalTriggered: state.hasIntervalTriggered,
      pointEvents: List.from(state.pointEvents),
    );
    final newStack = List<ScoreSnapshot>.from(state.undoStack)..add(snapshot);
    state = state.copyWith(undoStack: newStack);
  }

  void addPointTeamA({String? tag, String? comment}) {
    if (state.isMatchCompleted || state.isPaused) return;
    _pushSnapshot();
    final newScoreA = state.teamAScore + 1;
    final event = PointCommentaryEvent(
      pointIndex: state.pointEvents.length + 1,
      setIndex: state.currentSet,
      scoringTeam: 'A',
      scorerName: state.teamAPlayer1Name,
      scoreA: newScoreA,
      scoreB: state.teamBScore,
      tag: tag ?? 'Point Scored',
      comment: comment,
      timestamp: DateTime.now(),
    );
    final newEvents = List<PointCommentaryEvent>.from(state.pointEvents)
      ..add(event);
    state = state.copyWith(pointEvents: newEvents);
    _evaluateSetProgress(newScoreA, state.teamBScore, 'A');
  }

  void addPointTeamB({String? tag, String? comment}) {
    if (state.isMatchCompleted || state.isPaused) return;
    _pushSnapshot();
    final newScoreB = state.teamBScore + 1;
    final event = PointCommentaryEvent(
      pointIndex: state.pointEvents.length + 1,
      setIndex: state.currentSet,
      scoringTeam: 'B',
      scorerName: state.teamBPlayer1Name,
      scoreA: state.teamAScore,
      scoreB: newScoreB,
      tag: tag ?? 'Point Scored',
      comment: comment,
      timestamp: DateTime.now(),
    );
    final newEvents = List<PointCommentaryEvent>.from(state.pointEvents)
      ..add(event);
    state = state.copyWith(pointEvents: newEvents);
    _evaluateSetProgress(state.teamAScore, newScoreB, 'B');
  }

  void updateLastPointComment(String comment, {String? tag}) {
    if (state.pointEvents.isEmpty) return;
    final lastEvent = state.pointEvents.last;
    final updated = lastEvent.copyWith(
      comment: comment,
      tag: tag ?? lastEvent.tag,
    );
    final newEvents = List<PointCommentaryEvent>.from(state.pointEvents);
    newEvents[newEvents.length - 1] = updated;
    state = state.copyWith(pointEvents: newEvents);
  }

  void undoLastPoint() {
    if (state.undoStack.isEmpty) return;
    final lastSnapshot = state.undoStack.last;
    final newStack = List<ScoreSnapshot>.from(state.undoStack)..removeLast();

    state = state.copyWith(
      currentSet: lastSnapshot.currentSet,
      doublesPositions: lastSnapshot.doublesPositions,
      teamAScore: lastSnapshot.teamAScore,
      teamBScore: lastSnapshot.teamBScore,
      servingTeam: lastSnapshot.servingTeam,
      completedSets: lastSnapshot.completedSets,
      hasIntervalTriggered: lastSnapshot.hasIntervalTriggered,
      pointEvents: lastSnapshot.pointEvents,
      isMatchCompleted: false,
      matchWinner: null,
      undoStack: newStack,
    );
  }

  void markIntervalAcknowledged() {
    state = state.copyWith(hasIntervalTriggered: true);
  }

  void _evaluateSetProgress(int scoreA, int scoreB, String lastScorer) {
    if (state.isDoubles) {
      state = state.copyWith(
          doublesPositions: BwfScoringRules.rotateDoubles(
              state.doublesPositions,
              servingTeam: state.servingTeam,
              rallyWinner: lastScorer));
    }
    // Check interval based on targetPoints

    if (BwfScoringRules.isSetWon(scoreA, scoreB,
        targetPoints: state.targetPoints)) {
      final updatedSets = List<Map<String, int>>.from(state.completedSets)
        ..add({'a': scoreA, 'b': scoreB});

      final matchWinner = BwfScoringRules.getMatchWinner(
        updatedSets,
        bestOfSets: state.bestOfSets,
        targetPoints: state.targetPoints,
      );

      final setsNeeded = (state.bestOfSets / 2).ceil();
      if (matchWinner != null ||
          state.currentSet >= state.bestOfSets ||
          updatedSets.length >= setsNeeded * 2 - 1) {
        state = state.copyWith(
          teamAScore: scoreA,
          teamBScore: scoreB,
          completedSets: updatedSets,
          isMatchCompleted: true,
          servingTeam: lastScorer,
          matchWinner: matchWinner ?? (scoreA > scoreB ? 'A' : 'B'),
        );
      } else {
        // Advance to next set
        state = state.copyWith(
          doublesPositions: const DoublesServicePositions(),
          teamAScore: 0,
          teamBScore: 0,
          currentSet: state.currentSet + 1,
          completedSets: updatedSets,
          servingTeam: lastScorer,
          hasIntervalTriggered: false,
        );
      }
    } else {
      state = state.copyWith(
        teamAScore: scoreA,
        teamBScore: scoreB,
        servingTeam: lastScorer,
        hasIntervalTriggered: state.hasIntervalTriggered,
      );
    }
  }
}

final liveMatchProvider =
    StateNotifierProvider<LiveMatchNotifier, LiveMatchState>((ref) {
  return LiveMatchNotifier();
});
