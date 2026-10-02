import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearancePreferences {
  const AppearancePreferences({this.grain = .65, this.reduceMotion = false});
  final double grain;
  final bool reduceMotion;
}

final appearanceProvider =
    StateNotifierProvider<AppearanceController, AppearancePreferences>(
        (ref) => AppearanceController());

class AppearanceController extends StateNotifier<AppearancePreferences> {
  AppearanceController() : super(const AppearancePreferences()) {
    _ready = _restore();
  }
  late final Future<void> _ready;
  Future<void> _writes = Future.value();

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        state = AppearancePreferences(
          grain: (prefs.getDouble('appearance.grain') ?? .65).clamp(0, 1),
          reduceMotion: prefs.getBool('appearance.reduceMotion') ?? false,
        );
      }
    } catch (_) {
      // Defaults remain usable if device storage is unavailable.
    }
  }

  Future<void> update({double? grain, bool? reduceMotion}) {
    final write = _writes.then((_) async {
      await _ready;
      if (!mounted) return;
      final next = AppearancePreferences(
        grain: (grain ?? state.grain).clamp(0, 1),
        reduceMotion: reduceMotion ?? state.reduceMotion,
      );
      final prefs = await SharedPreferences.getInstance();
      final savedGrain = await prefs.setDouble('appearance.grain', next.grain);
      final savedMotion =
          await prefs.setBool('appearance.reduceMotion', next.reduceMotion);
      if (!savedGrain || !savedMotion) {
        throw StateError('Could not save appearance preferences.');
      }
      if (mounted) state = next;
    });
    _writes = write.catchError((Object _) {});
    return write;
  }
}

/// Motion preferences are inherited by routes, cards and sheets.
class AppAppearance extends ConsumerWidget {
  const AppAppearance({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
          disableAnimations:
              media.disableAnimations || appearance.reduceMotion),
      child: child,
    );
  }
}
