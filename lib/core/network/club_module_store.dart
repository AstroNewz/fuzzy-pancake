import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Durable local snapshots with optimistic concurrency on shared club records.
/// A remote revision conflict never overwrites either captain's changes.
abstract class ClubModuleStore<T> extends StateNotifier<AsyncValue<T>> {
  ClubModuleStore(this.client, this.module, this.empty)
      : super(const AsyncLoading()) {
    ready = _load();
    _retry = Timer.periodic(const Duration(seconds: 30), (_) => sync());
  }
  final SupabaseClient client;
  final String module;
  final T Function() empty;
  final status = ValueNotifier('Loading club records…');
  late final Future<void> ready;
  Future<void> _operations = Future.value();
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  Timer? _retry;
  int _revision = 0;
  bool _pending = false;
  bool _conflict = false;
  bool _syncing = false;
  bool get hasConflict => _conflict;
  Map<String, dynamic> get exportedSnapshot => encode(state.requireValue);
  T decode(Map<String, dynamic> json);
  Map<String, dynamic> encode(T value);
  String get _key => 'club.module.${client.rest.url}.$module';

  Future<void> _persist(T value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
        _key,
        jsonEncode({
          'revision': _revision,
          'pending': _pending,
          'data': encode(value)
        }))) {
      throw StateError(
          'Device storage is unavailable. Your change was not saved.');
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      T value = empty();
      if (raw != null) {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        _revision = saved['revision'] as int? ?? 0;
        _pending = saved['pending'] == true;
        value = decode(Map<String, dynamic>.from(saved['data'] as Map));
      }
      if (!mounted) return;
      state = AsyncData(value);
      await _sync();
      if (!mounted) return;
      if (client.auth.currentSession == null) return;
      _subscription = client
          .from('club_module_documents')
          .stream(primaryKey: ['module'])
          .eq('module', module)
          .listen((rows) {
            if (mounted &&
                !_pending &&
                !_syncing &&
                rows.isNotEmpty &&
                (rows.first['revision'] as int) > _revision) {
              _operations = _operations.then((_) async {
                if (!_pending && mounted) await _accept(rows.first);
              }).catchError((Object e) {
                if (mounted) {
                  status.value = 'Live updates paused. Tap sync to retry.';
                }
              });
            }
          }, onError: (Object e) {
            if (mounted && !_pending) {
              status.value = 'On this device · live connection unavailable';
            }
          });
    } catch (e, stack) {
      if (mounted) state = AsyncError(e, stack);
    }
  }

  Future<void> _accept(Map<String, dynamic> row) async {
    final value = decode(Map<String, dynamic>.from(row['data'] as Map));
    final previousRevision = _revision;
    final previousPending = _pending;
    _revision = row['revision'] as int;
    _pending = false;
    try {
      await _persist(value);
    } catch (_) {
      _revision = previousRevision;
      _pending = previousPending;
      rethrow;
    }
    if (mounted) {
      state = AsyncData(value);
      status.value = 'Live club sync';
    }
  }

  Future<void> change(void Function(T draft) action) {
    final next = _operations.then((_) async {
      await ready;
      if (_conflict) {
        throw StateError(
            'Another captain updated this record. Resolve the sync conflict first.');
      }
      final value = state.requireValue;
      final draft =
          decode(jsonDecode(jsonEncode(encode(value))) as Map<String, dynamic>);
      action(draft);
      if (jsonEncode(encode(draft)) == jsonEncode(encode(value))) return;
      final previousPending = _pending;
      _pending = true;
      try {
        await _persist(draft);
      } catch (_) {
        _pending = previousPending;
        rethrow;
      }
      if (!mounted) return;
      state = AsyncData(draft);
      await _sync();
    });
    _operations = next.catchError((Object _) {});
    return next;
  }

  Future<void> sync() {
    final next = _operations.then((_) async {
      await ready;
      await _sync();
    });
    _operations = next.catchError((Object _) {});
    return next;
  }

  Future<void> _sync() async {
    if (!mounted || _conflict || _syncing || !state.hasValue) return;
    _syncing = true;
    try {
      if (_pending) {
        final result = await client.rpc('save_club_module', params: {
          'p_module': module,
          'p_expected_revision': _revision,
          'p_data': encode(state.requireValue),
        }).timeout(const Duration(seconds: 8));
        if (mounted) await _accept(Map<String, dynamic>.from(result as Map));
      } else {
        final row = await client
            .from('club_module_documents')
            .select()
            .eq('module', module)
            .maybeSingle()
            .timeout(const Duration(seconds: 8));
        if (mounted && row != null) await _accept(row);
        if (mounted) status.value = 'Live club sync';
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _conflict = e.code == '40001';
        status.value = _conflict
            ? 'Sync conflict · local edits preserved'
            : e.code == '42501'
                ? 'Saved on device · captain access required to sync'
                : 'On this device · cloud setup required';
      }
    } catch (_) {
      if (mounted) {
        status.value = _pending
            ? 'Saved on device · waiting to sync'
            : 'On this device · offline';
      }
    } finally {
      _syncing = false;
    }
  }

  /// Explicitly chosen in the UI after offering export of the local snapshot.
  Future<void> useCloudVersion() {
    final next = _operations.then((_) async {
      await ready;
      final row = await client
          .from('club_module_documents')
          .select()
          .eq('module', module)
          .single()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      await _accept(row);
      _conflict = false;
    });
    _operations = next.catchError((Object _) {});
    return next;
  }

  @override
  void dispose() {
    _retry?.cancel();
    _subscription?.cancel();
    status.dispose();
    super.dispose();
  }
}
