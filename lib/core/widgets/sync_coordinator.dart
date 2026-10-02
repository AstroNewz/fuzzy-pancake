import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/offline_sync_service.dart';
import '../../features/ladder/ladder_state.dart';
import '../../features/trump_card/trump_card_model.dart';

/// Retry durable writes on entry, foreground resume, and while the app is open.
class SyncCoordinator extends ConsumerStatefulWidget {
  const SyncCoordinator({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<SyncCoordinator> createState() => _SyncCoordinatorState();
}

class _SyncCoordinatorState extends ConsumerState<SyncCoordinator>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _running = false;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _sync());
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    if (!mounted || _running || !_foreground) return;
    _running = true;
    try {
      final service = ref.read(offlineSyncServiceProvider);
      if (await service.getPendingRecordsCount() == 0) return;
      final result = await service.flushPendingData();
      if (!mounted) return;
      ref.invalidate(pendingOfflineCountProvider);
      if (result.syncedMatches > 0) {
        ref.invalidate(ladderStandingsProvider);
        ref.invalidate(squadTrumpCardsProvider);
      }
    } catch (_) {/* The durable queue will be retried next time. */} finally {
      _running = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
