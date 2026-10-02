import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_motion.dart';
import '../../core/widgets/player_avatar.dart';
import '../../core/widgets/court_panel.dart';
import '../../core/widgets/shuttle_logo.dart';
import '../training/training_screen.dart';
import '../attendance/attendance_screen.dart';
import '../auth/current_user_notifier.dart';
import '../more/more_menu_screen.dart';
import 'ladder_state.dart';
import 'ladder_challenge_repository.dart';

class LadderScreen extends ConsumerStatefulWidget {
  const LadderScreen({super.key});
  @override
  ConsumerState<LadderScreen> createState() => _LadderScreenState();
}

class _LadderScreenState extends ConsumerState<LadderScreen> {
  int _filter = 0;
  String _query = '';
  final _search = TextEditingController();
  String? _challenging;
  final Set<String> _issued = {};
  static const _filters = ['Everyone', 'In reach', 'My position'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(ladderStandingsProvider);
    try {
      await ref.read(ladderStandingsProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final standings = ref.watch(ladderStandingsProvider);
    final pending = user == null
        ? <LadderChallenge>[]
        : ref.watch(activeChallengesProvider(user.id)).valueOrNull ?? [];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            key: const PageStorageKey('ladder-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.bgDark,
                title: Row(children: [
                  const SmashDeckLogo(
                      size: 30, showText: false, showTagline: false),
                  const SizedBox(width: 10),
                  Text('SMASHDECK',
                      style: AppTheme.chivo(
                          size: 18,
                          weight: FontWeight.w900,
                          letterSpacing: -.5)),
                ]),
                actions: [
                  IconButton(
                      tooltip: 'Refresh standings',
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh, size: 21)),
                  IconButton(
                      tooltip: 'Club and account',
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MoreMenuScreen())),
                      icon: PlayerAvatar(
                          name: user?.fullName ?? '',
                          url: user?.avatarUrl,
                          size: 32)),
                  const SizedBox(width: 12),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                sliver: SliverToBoxAdapter(
                    child: standings.when(
                  loading: () => const Padding(
                      padding: EdgeInsets.all(64),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, __) => _empty('The court is reconnecting.',
                      'We couldn’t load the standings. Check your connection and try again.',
                      retry: true),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return _empty('A fresh start.',
                          'Your club ladder will appear here when members join.');
                    }
                    final mine = entries
                        .where((e) => e.playerId == user?.id)
                        .firstOrNull;
                    final visible = entries.where((e) {
                      final match = ('${e.fullName} ${e.rollNumber}')
                          .toLowerCase()
                          .contains(_query.toLowerCase());
                      return match &&
                          (_filter == 0 ||
                              (_filter == 1 &&
                                  mine != null &&
                                  e.canBeChallengedBy(mine.rank)) ||
                              (_filter == 2 && e.playerId == user?.id));
                    }).toList();
                    return Reveal(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          CourtPanel(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(
                                                'THE CLUB LADDER / ${entries.length}',
                                                style: AppTheme.jetBrainsMono(
                                                    size: 10,
                                                    letterSpacing: 1.8,
                                                    color: AppTheme.mintTeal)),
                                            const SizedBox(height: 8),
                                            Text('Earn your spot.',
                                                style: AppTheme.chivo(
                                                    size: 29,
                                                    weight: FontWeight.w900,
                                                    letterSpacing: -1.3)),
                                          ])),
                                      IconButton(
                                          tooltip: 'How the ladder works',
                                          onPressed: _showRules,
                                          icon: const Icon(Icons.info_outline,
                                              size: 20,
                                              color: AppTheme.textMuted)),
                                    ]),
                                    const SizedBox(height: 8),
                                    Text(
                                        'Good games. Better rivals. Challenge up to two ranks above you.',
                                        style: AppTheme.spaceGrotesk(
                                            size: 13,
                                            color: AppTheme.textMuted,
                                            height: 1.5)),
                                  ])),
                          const SizedBox(height: 22),
                          Text('APEX COMPETITORS',
                              style: AppTheme.labelCaps
                                  .copyWith(color: AppTheme.textMuted)),
                          const SizedBox(height: 12),
                          _podium(entries),
                          const SizedBox(height: 18),
                          if (mine != null) ...[
                            _myPosition(mine),
                            const SizedBox(height: 14)
                          ],
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            ActionChip(
                                avatar:
                                    const Icon(Icons.qr_code_scanner, size: 16),
                                label: const Text('Court check-in'),
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AttendanceScreen()))),
                            ActionChip(
                                avatar:
                                    const Icon(Icons.timer_outlined, size: 16),
                                label: const Text('Training lab'),
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const TrainingScreen()))),
                          ]),
                          const SizedBox(height: 16),
                          TextField(
                              controller: _search,
                              onChanged: (v) => setState(() => _query = v),
                              decoration: InputDecoration(
                                  hintText: 'Find a player',
                                  prefixIcon:
                                      const Icon(Icons.search, size: 20),
                                  suffixIcon: _query.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Clear search',
                                          onPressed: () {
                                            _search.clear();
                                            setState(() => _query = '');
                                          },
                                          icon: const Icon(Icons.close,
                                              size: 18)),
                                  isDense: true)),
                          const SizedBox(height: 14),
                          Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(
                                  _filters.length,
                                  (i) => ChoiceChip(
                                      label: Text(_filters[i]),
                                      selected: _filter == i,
                                      showCheckmark: false,
                                      selectedColor: AppTheme.limeNeon,
                                      backgroundColor: AppTheme.cardDark,
                                      side: BorderSide(
                                          color: _filter == i
                                              ? AppTheme.limeNeon
                                              : AppTheme.borderDark),
                                      labelStyle: AppTheme.spaceGrotesk(
                                          size: 12,
                                          weight: FontWeight.w700,
                                          color: _filter == i
                                              ? AppTheme.bgDarker
                                              : AppTheme.textMuted),
                                      onSelected: (_) =>
                                          setState(() => _filter = i)))),
                          const SizedBox(height: 24),
                          Row(children: [
                            Text('STANDINGS',
                                style: AppTheme.jetBrainsMono(
                                    size: 10,
                                    letterSpacing: 1.5,
                                    color: AppTheme.textMuted)),
                            const Spacer(),
                            Text('${visible.length} shown',
                                style: AppTheme.spaceGrotesk(
                                    size: 11, color: AppTheme.textMuted)),
                          ]),
                          const SizedBox(height: 12),
                          MotionSize(
                              duration: AppMotion.durationOf(context),
                              alignment: Alignment.topCenter,
                              child: Column(children: [
                                if (visible.isEmpty)
                                  _empty(
                                      'No players here.',
                                      _filter == 1
                                          ? 'You’re at the top, or there are no eligible rivals in reach.'
                                          : 'Try another name or filter.'),
                                ...visible.map((entry) => _standing(
                                    entry,
                                    mine,
                                    pending.any((c) =>
                                        c.challengerId == entry.playerId ||
                                        c.defenderId == entry.playerId))),
                              ])),
                        ]));
                  },
                )),
              ),
            ],
          )),
    );
  }

  Widget _podium(List<LadderEntry> entries) {
    final top = entries.take(3).toList();
    final ordered = [
      if (top.length > 1) top[1],
      top[0],
      if (top.length > 2) top[2]
    ];
    return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: ordered.map((entry) {
          final first = entry.rank == 1;
          final color = first
              ? AppTheme.limeNeon
              : entry.rank == 2
                  ? AppTheme.silver
                  : AppTheme.bronze;
          return Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Reveal(
                delay: first ? 70 : 150,
                child: PressScale(
                    child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                            onTap: () => _showPlayer(entry),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                  8, first ? 14 : 10, 8, 14),
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: first
                                          ? [
                                              const Color(0xFF283923),
                                              AppTheme.cardDark
                                            ]
                                          : [
                                              AppTheme.cardMid,
                                              AppTheme.cardDark
                                            ]),
                                  boxShadow: first
                                      ? [
                                          BoxShadow(
                                              color: AppTheme.limeNeon
                                                  .withValues(alpha: .09),
                                              blurRadius: 24)
                                        ]
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: color.withValues(
                                          alpha: first ? .5 : .18))),
                              child: Column(children: [
                                Icon(
                                    first
                                        ? Icons.emoji_events
                                        : Icons.workspace_premium_outlined,
                                    color: color,
                                    size: first ? 26 : 20),
                                const SizedBox(height: 8),
                                PlayerAvatar(
                                    name: entry.fullName,
                                    url: entry.avatarUrl,
                                    size: first ? 48 : 40,
                                    color: color),
                                const SizedBox(height: 8),
                                Text(entry.fullName.trim().split(' ').first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.chivo(
                                        size: first ? 16 : 14,
                                        weight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(entry.playstyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.spaceGrotesk(
                                        size: 10,
                                        color: first
                                            ? AppTheme.limeNeon
                                            : AppTheme.textMuted)),
                                const SizedBox(height: 8),
                                AnimatedStat(
                                    value: entry.ovrRating,
                                    style: AppTheme.chivo(
                                        size: first ? 28 : 24,
                                        weight: FontWeight.w900,
                                        color: color,
                                        letterSpacing: -1)),
                                Text('#${entry.rank} / OVR',
                                    style: AppTheme.jetBrainsMono(
                                        size: 8, color: AppTheme.textMuted)),
                              ]),
                            ))))),
          ));
        }).toList());
  }

  Widget _myPosition(LadderEntry mine) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppTheme.limeNeon.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.limeNeon.withValues(alpha: .2))),
        child: Row(children: [
          Text('#${mine.rank}',
              style: AppTheme.chivo(
                  size: 32, color: AppTheme.limeNeon, weight: FontWeight.w900)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Your place in the club',
                    style: AppTheme.spaceGrotesk(
                        size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                    mine.rank == 1
                        ? 'The spot everyone’s chasing.'
                        : 'Your next move starts on court.',
                    style: AppTheme.spaceGrotesk(
                        size: 12, color: AppTheme.textMuted)),
              ])),
        ]),
      );

  Widget _standing(LadderEntry entry, LadderEntry? mine, bool pending) {
    final isMe = mine?.playerId == entry.playerId;
    final eligible = mine != null && entry.canBeChallengedBy(mine.rank);
    final issued = pending || _issued.contains(entry.playerId);
    return Container(
      key: ValueKey(entry.playerId),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: isMe
              ? AppTheme.limeNeon.withValues(alpha: .055)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isMe
                  ? AppTheme.limeNeon.withValues(alpha: .35)
                  : AppTheme.borderDark)),
      child: InkWell(
          onTap: () => _showPlayer(entry),
          borderRadius: BorderRadius.circular(12),
          child: Column(children: [
            Row(children: [
              SizedBox(
                  width: 28,
                  child: Text(entry.rank.toString(),
                      style: AppTheme.jetBrainsMono(
                          size: 13,
                          color:
                              isMe ? AppTheme.limeNeon : AppTheme.textMuted))),
              PlayerAvatar(
                  name: entry.fullName, url: entry.avatarUrl, size: 38),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(entry.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTheme.chivo(size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(entry.playstyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.spaceGrotesk(
                            size: 11, color: AppTheme.textMuted)),
                  ])),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(entry.ovrRating.toString(),
                    style: AppTheme.jetBrainsMono(
                        size: 13, color: AppTheme.limeNeon)),
                Text('OVR',
                    style: AppTheme.jetBrainsMono(
                        size: 8, color: AppTheme.textMuted)),
              ]),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: Text(
                      '${entry.matchesPlayed} played  ·  ${entry.winRatePct.toStringAsFixed(0)}% wins',
                      style: AppTheme.spaceGrotesk(
                          size: 11, color: AppTheme.textMuted))),
              if (isMe)
                _pill('YOU', AppTheme.limeNeon)
              else if (issued)
                _pill('PENDING', AppTheme.mintTeal)
              else if (eligible)
                SizedBox(
                    height: 36,
                    child: TextButton(
                        onPressed: _challenging == null
                            ? () => _challenge(mine, entry)
                            : null,
                        child: Text(
                            _challenging == entry.playerId
                                ? 'Sending…'
                                : 'Challenge ↗',
                            style: AppTheme.spaceGrotesk(
                                size: 12,
                                weight: FontWeight.w700,
                                color: AppTheme.limeNeon)))),
            ]),
          ])),
    );
  }

  void _showRules() => showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Your climb starts here.', style: AppTheme.headlineLg),
                const SizedBox(height: 16),
                Text(
                    'Challenge a player up to two ranks above you. A verified ladder win can move you into their spot. Pending challenges are shown in Matches.',
                    style: AppTheme.bodyLg),
                const SizedBox(height: 16),
                Text(
                    'OVR reflects player attributes. Elo reflects rated match results. Tap any player to see their record.',
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textMuted)),
              ])));

  void _showPlayer(LadderEntry entry) {
    final user = ref.read(currentUserProvider);
    final mine = ref
        .read(ladderStandingsProvider)
        .valueOrNull
        ?.where((e) => e.playerId == user?.id)
        .firstOrNull;
    final pending = user == null
        ? <LadderChallenge>[]
        : ref.read(activeChallengesProvider(user.id)).valueOrNull ?? [];
    final issued = _issued.contains(entry.playerId) ||
        pending.any((c) =>
            c.challengerId == entry.playerId || c.defenderId == entry.playerId);
    showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (sheetContext) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              PlayerAvatar(
                  name: entry.fullName, url: entry.avatarUrl, size: 72),
              const SizedBox(height: 14),
              Text(entry.fullName,
                  style: AppTheme.headlineLg, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(entry.playstyle,
                  style: AppTheme.bodyMd.copyWith(color: AppTheme.mintTeal)),
              const SizedBox(height: 20),
              CourtPanel(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                    for (final stat in [
                      ('RANK', '#${entry.rank}'),
                      ('OVR', '${entry.ovrRating}'),
                      ('ELO', '${entry.eloRating}')
                    ])
                      Column(children: [
                        Text(stat.$2,
                            style: AppTheme.headlineLg
                                .copyWith(color: AppTheme.limeNeon)),
                        const SizedBox(height: 4),
                        Text(stat.$1, style: AppTheme.labelCaps)
                      ]),
                  ])),
              const SizedBox(height: 20),
              Text(
                  '${entry.matchesPlayed} played · ${entry.winRatePct.toStringAsFixed(0)}% win rate',
                  style: AppTheme.bodyLg),
              const SizedBox(height: 14),
              if (mine != null && entry.canBeChallengedBy(mine.rank))
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: issued
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                _challenge(mine, entry);
                              },
                        icon: const Icon(Icons.sports_tennis),
                        label: Text(issued
                            ? 'CHALLENGE PENDING'
                            : 'CHALLENGE PLAYER'))),
            ])));
  }

  Future<void> _challenge(LadderEntry mine, LadderEntry target) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('Challenge ${target.fullName.split(' ').first}?'),
              content: Text(
                  'Play for rank #${target.rank}. Your challenge will appear in the club’s pending matches.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Not now')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Challenge')),
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() => _challenging = target.playerId);
    try {
      await ref.read(ladderChallengeRepositoryProvider).issueChallenge(
          challengerId: mine.playerId,
          challengerName: mine.fullName,
          challengerRank: mine.rank,
          defenderId: target.playerId,
          defenderName: target.fullName,
          defenderRank: target.rank);
      if (!mounted) return;
      setState(() => _issued.add(target.playerId));
      ref.invalidate(activeChallengesProvider(mine.playerId));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Challenge sent. Your next match awaits.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Couldn’t send the challenge. Check your connection and try again.')));
      }
    } finally {
      if (mounted) setState(() => _challenging = null);
    }
  }

  Widget _pill(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(30)),
      child: Text(text, style: AppTheme.jetBrainsMono(size: 9, color: color)));

  Widget _empty(String title, String message, {bool retry = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 16),
        child: Column(children: [
          const Icon(Icons.sports_tennis, size: 36, color: AppTheme.limeNeon),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: AppTheme.chivo(size: 23, weight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: AppTheme.spaceGrotesk(
                  color: AppTheme.textMuted, height: 1.5)),
          if (retry) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'))
          ],
        ]),
      );
}
