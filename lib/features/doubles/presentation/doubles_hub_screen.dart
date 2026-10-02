import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stitch_background.dart';
import '../../../core/widgets/module_widgets.dart';
import '../../../core/services/file_export_service.dart';
import '../../trump_card/trump_card_model.dart';
import '../../trump_card/card_export_service.dart';
import '../models/doubles_pair_model.dart';
import '../providers/doubles_provider.dart';
import 'widgets/duo_trump_card_widget.dart';

class DoublesHubScreen extends ConsumerStatefulWidget {
  const DoublesHubScreen({super.key});
  @override
  ConsumerState<DoublesHubScreen> createState() => _DoublesHubScreenState();
}

class _DoublesHubScreenState extends ConsumerState<DoublesHubScreen> {
  String? _a, _b;
  final _exportKey = GlobalKey();
  bool _exporting = false;
  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(squadTrumpCardsProvider),
        history = ref.watch(doublesHistoryProvider);
    return StitchAppBackground(
        child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
                title: const Text('Doubles studio'),
                backgroundColor: Colors.transparent),
            body: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child:
                        ListView(padding: const EdgeInsets.all(20), children: [
                      Text('FIND YOUR OTHER HALF',
                          style: AppTheme.labelCaps
                              .copyWith(color: AppTheme.mintTeal)),
                      const SizedBox(height: 8),
                      Text('Two players. One force.',
                          style: AppTheme.headlineXl),
                      const SizedBox(height: 20),
                      cards.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => TextButton(
                              onPressed: () =>
                                  ref.invalidate(squadTrumpCardsProvider),
                              child: const Text('Retry squad')),
                          data: (players) {
                            if (players.length < 2) {
                              return const Text(
                                  'Two club members are needed to create a duo.');
                            }
                            final a = players
                                    .where((p) => p.playerId == _a)
                                    .firstOrNull ??
                                players.first;
                            final b = players
                                    .where((p) =>
                                        p.playerId == _b &&
                                        p.playerId != a.playerId)
                                    .firstOrNull ??
                                players.firstWhere(
                                    (p) => p.playerId != a.playerId);
                            final pair = DoublesPair.fromHistory(
                                a, b, history.valueOrNull ?? []);
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final first in [true, false])
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: DropdownButtonFormField<String>(
                                            key: ValueKey(
                                                '${first ? a.playerId : b.playerId}-$first'),
                                            initialValue:
                                                first ? a.playerId : b.playerId,
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                                labelText: first
                                                    ? 'First player'
                                                    : 'Partner'),
                                            items: players
                                                .where((p) =>
                                                    p.playerId !=
                                                    (first
                                                        ? b.playerId
                                                        : a.playerId))
                                                .map((p) => DropdownMenuItem(
                                                    value: p.playerId,
                                                    child: Text(p.fullName,
                                                        overflow: TextOverflow
                                                            .ellipsis)))
                                                .toList(),
                                            onChanged: (id) => setState(() {
                                                  if (first) {
                                                    _a = id;
                                                    _b = b.playerId;
                                                  } else {
                                                    _b = id;
                                                    _a = a.playerId;
                                                  }
                                                }))),
                                  const SizedBox(height: 16),
                                  DuoTrumpCardWidget(
                                      pair: pair, repaintKey: _exportKey),
                                  const SizedBox(height: 20),
                                  if (history.isLoading)
                                    const LinearProgressIndicator(),
                                  if (history.hasError)
                                    TextButton(
                                        onPressed: () => ref
                                            .invalidate(doublesHistoryProvider),
                                        child: const Text(
                                            'History unavailable · retry chemistry bonus')),
                                  Text(
                                      'Complementary front/back roles start at 95%; two defensive players at 80%. Every three consecutive wins together adds 1%, capped at 100%.',
                                      style: AppTheme.bodySm
                                          .copyWith(color: AppTheme.textMuted)),
                                  const SizedBox(height: 18),
                                  FilledButton.icon(
                                      onPressed: _exporting
                                          ? null
                                          : () =>
                                              runClubAction(context, () async {
                                                setState(
                                                    () => _exporting = true);
                                                try {
                                                  await WidgetsBinding
                                                      .instance.endOfFrame;
                                                  final bytes =
                                                      await CardExportService
                                                          .capturePng(
                                                              repaintKey:
                                                                  _exportKey);
                                                  if (bytes == null) {
                                                    throw StateError(
                                                        'Could not render the duo card.');
                                                  }
                                                  await FileExportService.share(
                                                      bytes,
                                                      'SmashDeck-Duo.png',
                                                      'image/png');
                                                } finally {
                                                  if (mounted) {
                                                    setState(() =>
                                                        _exporting = false);
                                                  }
                                                }
                                              }),
                                      icon: const Icon(Icons.ios_share),
                                      label: Text(_exporting
                                          ? 'RENDERING…'
                                          : 'EXPORT DUO PNG')),
                                ]);
                          }),
                    ])))));
  }
}
