import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../features/match_engine/match_engine_state.dart';
import '../utils/bwf_scoring_rules.dart';

final umpireRouteObserver = RouteObserver<ModalRoute<dynamic>>();

class UmpirePreferences {
  const UmpirePreferences(
      {this.voice = false,
      this.buttons = false,
      this.gestures = false,
      this.sounds = true,
      this.speechRate = .5});
  final bool voice, buttons, gestures, sounds;
  final double speechRate;
}

class UmpirePreferencesNotifier extends StateNotifier<UmpirePreferences> {
  UmpirePreferencesNotifier() : super(const UmpirePreferences()) {
    _ready = _load();
  }
  late Future<void> _ready;
  Future<void> _writes = Future.value();
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      state = UmpirePreferences(
          voice: p.getBool('umpire.voice') ?? false,
          buttons: p.getBool('umpire.buttons') ?? false,
          gestures: p.getBool('umpire.gestures') ?? false,
          sounds: p.getBool('umpire.sounds') ?? true,
          speechRate: (p.getDouble('umpire.rate') ?? .5).clamp(.2, 1));
    }
  }

  Future<void> update(
      {bool? voice,
      bool? buttons,
      bool? gestures,
      bool? sounds,
      double? rate}) {
    final write = _writes.then((_) async {
      await _ready;
      final next = UmpirePreferences(
          voice: voice ?? state.voice,
          buttons: buttons ?? state.buttons,
          gestures: gestures ?? state.gestures,
          sounds: sounds ?? state.sounds,
          speechRate: rate ?? state.speechRate);
      final p = await SharedPreferences.getInstance();
      final results = await Future.wait([
        p.setBool('umpire.voice', next.voice),
        p.setBool('umpire.buttons', next.buttons),
        p.setBool('umpire.gestures', next.gestures),
        p.setBool('umpire.sounds', next.sounds),
        p.setDouble('umpire.rate', next.speechRate)
      ]);
      if (results.any((s) => !s)) {
        throw StateError('Could not save umpire preferences.');
      }
      if (mounted) state = next;
    });
    _writes = write.catchError((Object _) {});
    return write;
  }
}

final umpirePreferencesProvider =
    StateNotifierProvider<UmpirePreferencesNotifier, UmpirePreferences>(
        (ref) => UmpirePreferencesNotifier());

class AudioUmpireService {
  static const channel = MethodChannel('smashdeck/umpire');
  final FlutterTts _tts = FlutterTts();
  bool _disposed = false;
  int _utterance = 0;
  static bool get physicalKeysSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  void listen(void Function(String) callback) {
    channel.setMethodCallHandler((call) async {
      if (!_disposed && call.method == 'scoreKey') {
        callback(call.arguments as String);
      }
    });
  }

  Future<void> active({required bool keepAwake, required bool keys}) async {
    try {
      await WakelockPlus.toggle(enable: keepAwake);
    } catch (_) {}
    if (physicalKeysSupported) {
      try {
        await channel.invokeMethod<void>('enableVolumeScoring', keys);
      } catch (_) {}
    }
  }

  Future<void> chime() async {
    try {
      if (physicalKeysSupported) {
        await channel.invokeMethod<void>('chime');
      } else {
        await SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {}
  }

  Future<void> speak(String text, double rate) async {
    final token = ++_utterance;
    try {
      await _tts.stop();
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(rate);
      if (!_disposed && token == _utterance) await _tts.speak(text);
    } catch (_) {}
  }

  static String callout(LiveMatchState before, LiveMatchState after) {
    if (after.pointEvents.length < before.pointEvents.length) {
      return 'Correction. ${after.teamAScore} ${after.teamBScore}';
    }
    if (after.isMatchCompleted) {
      return 'Match won by ${after.matchWinner == 'A' ? after.teamAPlayer1Name : after.teamBPlayer1Name}';
    }
    if (after.currentSet != before.currentSet) {
      final set = after.completedSets.last;
      return 'Game. ${set['a']} ${set['b']}. Next game, love all.';
    }
    final server = after.servingScore,
        receiver =
            after.servingTeam == 'A' ? after.teamBScore : after.teamAScore;
    final prefix =
        before.servingTeam != after.servingTeam ? 'Service over. ' : '';
    final gamePoint = BwfScoringRules.isSetWon(server + 1, receiver,
        targetPoints: after.targetPoints);
    final wins = after.completedSets
        .where((s) =>
            after.servingTeam == 'A' ? s['a']! > s['b']! : s['b']! > s['a']!)
        .length;
    return '$prefix$server, $receiver${gamePoint ? wins == after.bestOfSets ~/ 2 ? '. Match point.' : '. Game point.' : ''}';
  }

  Future<void> dispose() async {
    _disposed = true;
    _utterance++;
    channel.setMethodCallHandler(null);
    await active(keepAwake: false, keys: false);
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
