import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_motion.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/offline_sync_service.dart';
import '../auth/current_user_notifier.dart';
import '../attendance/attendance_screen.dart';
import '../training/training_screen.dart';
import '../more/appearance_screen.dart';
import '../../core/widgets/court_panel.dart';
import 'gear_model.dart';

class GearTrackerScreen extends ConsumerStatefulWidget {
  const GearTrackerScreen({super.key});
  @override
  ConsumerState<GearTrackerScreen> createState() => _GearTrackerScreenState();
}

class _GearTrackerScreenState extends ConsumerState<GearTrackerScreen> {
  bool _syncing = false;

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final result =
          await ref.read(offlineSyncServiceProvider).flushPendingData();
      if (!mounted) return;
      ref.invalidate(pendingOfflineCountProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.isSuccess
              ? 'Your saved records are up to date.'
              : 'Some records are still waiting for a connection. They remain on this device.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Couldn’t sync yet. Your saved records are still on this device.')));
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final gear = ref.watch(playerGearLogsProvider(user.id));
    final pending = ref.watch(pendingOfflineCountProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
          title: Text('GEAR & PLAY',
              style: AppTheme.chivo(size: 18, weight: FontWeight.w900))),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(playerGearLogsProvider(user.id));
          ref.invalidate(pendingOfflineCountProvider);
          try {
            await ref.read(playerGearLogsProvider(user.id).future);
          } catch (_) {}
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Reveal(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('READY FOR THE NEXT RALLY',
                      style: AppTheme.jetBrainsMono(
                          size: 10,
                          color: AppTheme.mintTeal,
                          letterSpacing: 1.4)),
                  const SizedBox(height: 10),
                  Text('Keep your edge.',
                      style: AppTheme.chivo(
                          size: 34,
                          weight: FontWeight.w900,
                          letterSpacing: -1)),
                  const SizedBox(height: 10),
                  Text('Look after your racket. Stay connected to your club.',
                      style: AppTheme.spaceGrotesk(
                          color: AppTheme.textMuted, height: 1.5)),
                  const SizedBox(height: 26),
                ])),
            Reveal(
                delay: 100,
                child: CourtPanel(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.timer_outlined,
                          color: AppTheme.limeNeon),
                      const SizedBox(width: 10),
                      Text('THE TRAINING LAB',
                          style: AppTheme.labelCaps
                              .copyWith(color: AppTheme.limeNeon)),
                    ]),
                    const SizedBox(height: 14),
                    Text('Better starts here.', style: AppTheme.headlineLg),
                    const SizedBox(height: 8),
                    Text(
                        'Footwork, power, endurance. Guided intervals to build your next win.',
                        style: AppTheme.bodyMd
                            .copyWith(color: AppTheme.textMuted)),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TrainingScreen())),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('START TRAINING')),
                  ],
                ))),
            const SizedBox(height: 16),
            _tool(
                Icons.qr_code_scanner,
                'Court check-in',
                'Attendance and captain check-in tools',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AttendanceScreen()))),
            const SizedBox(height: 12),
            _tool(
                Icons.tune_rounded,
                'Look & feel',
                'Film grain and motion, your way',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AppearanceScreen()))),
            const SizedBox(height: 12),
            _tool(
                Icons.cloud_done_outlined,
                _syncing ? 'Syncing your records…' : 'Saved on your device',
                pending.when(
                    data: (n) => n == 0
                        ? 'All local records are synced'
                        : '$n records waiting to sync',
                    error: (_, __) => 'Tap to retry syncing',
                    loading: () => 'Checking saved records…'),
                _syncing ? null : _sync),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(
                  child: Text('YOUR RACKETS',
                      style: AppTheme.jetBrainsMono(
                          size: 11,
                          color: AppTheme.textMuted,
                          letterSpacing: 1))),
              TextButton.icon(
                  onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => _GearForm(playerId: user.id)),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Log restring')),
            ]),
            const SizedBox(height: 8),
            gear.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => _tool(
                  Icons.wifi_off,
                  'Couldn’t load your gear',
                  'Tap to try again',
                  () => ref.invalidate(playerGearLogsProvider(user.id))),
              data: (logs) => logs.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(28),
                      decoration: _decoration,
                      child: Column(children: [
                        const Icon(Icons.sports_tennis,
                            size: 40, color: AppTheme.limeNeon),
                        const SizedBox(height: 16),
                        Text('Give your racket a home.',
                            style: AppTheme.chivo(size: 20),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        Text(
                            'Log your string and tension to keep track of your next restring.',
                            style: AppTheme.spaceGrotesk(
                                color: AppTheme.textMuted, height: 1.5),
                            textAlign: TextAlign.center),
                      ]))
                  : Column(children: logs.map(_gearCard).toList()),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration get _decoration => BoxDecoration(
      color: AppTheme.cardDark,
      border: Border.all(color: AppTheme.borderDark),
      borderRadius: BorderRadius.circular(20));

  Widget _tool(
          IconData icon, String title, String subtitle, VoidCallback? onTap) =>
      Material(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(18),
          child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppTheme.borderDark)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Icon(icon, color: AppTheme.mintTeal),
              onTap: onTap,
              title: Text(title,
                  style:
                      AppTheme.spaceGrotesk(size: 14, weight: FontWeight.w700)),
              subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle,
                      style: AppTheme.spaceGrotesk(
                          size: 12, color: AppTheme.textMuted))),
              trailing: const Icon(Icons.chevron_right,
                  size: 18, color: AppTheme.textMuted)));

  Widget _gearCard(GearLog log) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: _decoration,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.sports_tennis, color: AppTheme.limeNeon, size: 24),
            const SizedBox(width: 12),
            Expanded(
                child: Text(log.racketBrandModel,
                    style: AppTheme.chivo(size: 18, weight: FontWeight.w800))),
          ]),
          const SizedBox(height: 14),
          Text(
              '${log.stringModel} · ${log.tensionLbs.toStringAsFixed(0)} lbs when strung',
              style: AppTheme.spaceGrotesk(color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: log.tensionHealthPct,
                  color: log.statusColor,
                  backgroundColor: AppTheme.bgDarker,
                  minHeight: 5)),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 8, children: [
            Text(log.statusLabel,
                style: AppTheme.spaceGrotesk(
                    size: 12, color: log.statusColor, weight: FontWeight.w700)),
            Text('Strung ${DateFormat.yMMMd().format(log.stringingDate)}',
                style:
                    AppTheme.spaceGrotesk(size: 12, color: AppTheme.textMuted)),
          ]),
          const SizedBox(height: 6),
          Text('Tension health is an estimate, not a measurement.',
              style:
                  AppTheme.spaceGrotesk(size: 10, color: AppTheme.textMuted)),
        ]),
      );
}

class _GearForm extends ConsumerStatefulWidget {
  const _GearForm({required this.playerId});
  final String playerId;
  @override
  ConsumerState<_GearForm> createState() => _GearFormState();
}

class _GearFormState extends ConsumerState<_GearForm> {
  final _form = GlobalKey<FormState>();
  final _racket = TextEditingController();
  final _string = TextEditingController();
  final _tension = TextEditingController(text: '26');
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _racket.dispose();
    _string.dispose();
    _tension.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      await ref.read(supabaseClientProvider).from('gear_logs').insert({
        'player_id': widget.playerId,
        'racket_brand_model': _racket.text.trim(),
        'string_model': _string.text.trim(),
        'tension_lbs': double.parse(_tension.text),
        'stringing_date': DateFormat('yyyy-MM-dd').format(now),
        'expected_restring_date':
            DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 35))),
      }).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      ref.invalidate(playerGearLogsProvider(widget.playerId));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Racket record saved. Ready for the next rally.')));
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Couldn’t save your racket. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 4, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: SingleChildScrollView(
            child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('A fresh set of strings.',
                        style:
                            AppTheme.chivo(size: 24, weight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('Record today’s restring.',
                        style:
                            AppTheme.spaceGrotesk(color: AppTheme.textMuted)),
                    const SizedBox(height: 22),
                    TextFormField(
                        controller: _racket,
                        enabled: !_saving,
                        textInputAction: TextInputAction.next,
                        decoration:
                            const InputDecoration(labelText: 'Racket model'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter your racket model.'
                            : null),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _string,
                        enabled: !_saving,
                        textInputAction: TextInputAction.next,
                        decoration:
                            const InputDecoration(labelText: 'String model'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter your string model.'
                            : null),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _tension,
                        enabled: !_saving,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Tension (lbs)',
                            helperText: '18–38 lbs'),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          return n == null || !n.isFinite || n < 18 || n > 38
                              ? 'Enter a tension between 18 and 38 lbs.'
                              : null;
                        }),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(_error!,
                              style: AppTheme.spaceGrotesk(
                                  color: AppTheme.errorRed))),
                    const SizedBox(height: 22),
                    SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: Text(_saving ? 'SAVING…' : 'SAVE RACKET'))),
                  ],
                ))),
      );
}
