import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/bwf_scoring_rules.dart';
import 'match_engine_state.dart';

class LiveMatchDraftRepository {
  Future<void> _writes = Future.value();
  Future<LiveMatchState?> load(String id) async {
    final raw =
        (await SharedPreferences.getInstance()).getString('live.draft.$id');
    if (raw == null) return null;
    return decode(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(LiveMatchState match) {
    final data = jsonEncode(encode(match));
    final next = _writes.then((_) async {
      if (!await (await SharedPreferences.getInstance())
          .setString('live.draft.${match.matchId}', data))
        throw StateError('Could not save live score.');
    });
    _writes = next.catchError((Object _) {});
    return next;
  }

  Future<void> remove(String id) async {
    await _writes;
    await (await SharedPreferences.getInstance()).remove('live.draft.$id');
  }

  static Map<String, dynamic> _event(PointCommentaryEvent e) => {
        'pointIndex': e.pointIndex,
        'setIndex': e.setIndex,
        'scoringTeam': e.scoringTeam,
        'scorerName': e.scorerName,
        'scoreA': e.scoreA,
        'scoreB': e.scoreB,
        'tag': e.tag,
        'comment': e.comment,
        'timestamp': e.timestamp.toIso8601String()
      };
  static PointCommentaryEvent _readEvent(Map<String, dynamic> e) =>
      PointCommentaryEvent(
          pointIndex: e['pointIndex'],
          setIndex: e['setIndex'],
          scoringTeam: e['scoringTeam'],
          scorerName: e['scorerName'],
          scoreA: e['scoreA'],
          scoreB: e['scoreB'],
          tag: e['tag'],
          comment: e['comment'],
          timestamp: DateTime.parse(e['timestamp']));
  static List<Map<String, int>> _sets(dynamic s) =>
      (s as List).map((e) => Map<String, int>.from(e)).toList();
  static List<PointCommentaryEvent> _events(dynamic s) =>
      (s as List).map((e) => _readEvent(Map<String, dynamic>.from(e))).toList();
  static Map<String, dynamic> encode(LiveMatchState m) => {
        'matchId': m.matchId,
        'matchType': m.matchType,
        'category': m.category,
        'isRatingEligible': m.isRatingEligible,
        'targetPoints': m.targetPoints,
        'bestOfSets': m.bestOfSets,
        'teamA1Id': m.teamA1Id,
        'teamAPlayer1Name': m.teamAPlayer1Name,
        'teamA2Id': m.teamA2Id,
        'teamAPlayer2Name': m.teamAPlayer2Name,
        'teamB1Id': m.teamB1Id,
        'teamBPlayer1Name': m.teamBPlayer1Name,
        'teamB2Id': m.teamB2Id,
        'teamBPlayer2Name': m.teamBPlayer2Name,
        'currentSet': m.currentSet,
        'teamAScore': m.teamAScore,
        'teamBScore': m.teamBScore,
        'completedSets': m.completedSets,
        'servingTeam': m.servingTeam,
        'aFirstRight': m.doublesPositions.aFirstRight,
        'bFirstRight': m.doublesPositions.bFirstRight,
        'hasIntervalTriggered': m.hasIntervalTriggered,
        'isPaused': m.isPaused,
        'isMatchCompleted': m.isMatchCompleted,
        'matchWinner': m.matchWinner,
        'pointEvents': m.pointEvents.map(_event).toList(),
        'undoStack': m.undoStack
            .map((s) => {
                  'currentSet': s.currentSet,
                  'teamAScore': s.teamAScore,
                  'teamBScore': s.teamBScore,
                  'servingTeam': s.servingTeam,
                  'completedSets': s.completedSets,
                  'hasIntervalTriggered': s.hasIntervalTriggered,
                  'aFirstRight': s.doublesPositions.aFirstRight,
                  'bFirstRight': s.doublesPositions.bFirstRight,
                  'pointEvents': s.pointEvents.map(_event).toList()
                })
            .toList(),
      };
  static LiveMatchState decode(Map<String, dynamic> j) => LiveMatchState(
        matchId: j['matchId'],
        matchType: j['matchType'],
        category: j['category'],
        isRatingEligible: j['isRatingEligible'],
        targetPoints: j['targetPoints'],
        bestOfSets: j['bestOfSets'],
        teamA1Id: j['teamA1Id'],
        teamAPlayer1Name: j['teamAPlayer1Name'],
        teamA2Id: j['teamA2Id'],
        teamAPlayer2Name: j['teamAPlayer2Name'],
        teamB1Id: j['teamB1Id'],
        teamBPlayer1Name: j['teamBPlayer1Name'],
        teamB2Id: j['teamB2Id'],
        teamBPlayer2Name: j['teamBPlayer2Name'],
        currentSet: j['currentSet'],
        teamAScore: j['teamAScore'],
        teamBScore: j['teamBScore'],
        completedSets: _sets(j['completedSets']),
        servingTeam: j['servingTeam'],
        doublesPositions: DoublesServicePositions(
            aFirstRight: j['aFirstRight'], bFirstRight: j['bFirstRight']),
        hasIntervalTriggered: j['hasIntervalTriggered'],
        isPaused: j['isPaused'],
        isMatchCompleted: j['isMatchCompleted'],
        matchWinner: j['matchWinner'],
        pointEvents: _events(j['pointEvents']),
        undoStack: (j['undoStack'] as List)
            .map((s) => ScoreSnapshot(
                currentSet: s['currentSet'],
                teamAScore: s['teamAScore'],
                teamBScore: s['teamBScore'],
                servingTeam: s['servingTeam'],
                completedSets: _sets(s['completedSets']),
                hasIntervalTriggered: s['hasIntervalTriggered'],
                doublesPositions: DoublesServicePositions(
                    aFirstRight: s['aFirstRight'],
                    bFirstRight: s['bFirstRight']),
                pointEvents: _events(s['pointEvents'])))
            .toList(),
      );
}
