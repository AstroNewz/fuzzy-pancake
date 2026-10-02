import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/network/supabase_service.dart';
import '../../core/widgets/court_panel.dart';
import '../../core/widgets/player_avatar.dart';
import '../../core/theme/app_theme.dart';
import '../auth/current_user_notifier.dart';
import '../match_engine/match_setup_dialog.dart';
import '../match_engine/match_repository.dart';
import '../../core/utils/bwf_scoring_rules.dart';
import '../../core/widgets/app_motion.dart';
import '../../core/widgets/glass_panel.dart';
import '../ladder/ladder_state.dart';
import '../trump_card/trump_card_model.dart';

/// MATCHES Hub — Exact Stitch Design & Feature Parity
/// Recent Matches | Fast Score Log | Live Court Umpire Trigger
class MatchesHubScreen extends ConsumerStatefulWidget {
  const MatchesHubScreen({super.key});

  @override
  ConsumerState<MatchesHubScreen> createState() => _MatchesHubScreenState();
}

class _MatchesHubScreenState extends ConsumerState<MatchesHubScreen> {
  int _activeTab = 0; // 0=Recent, 1=Log Score, 2=Disputes
  int _historyFilter = 0;
  bool _isLadderTier = true;
  int _matchType = 0; // 0=Singles, 1=Doubles
  int _selectedCourt = 1; // 1, 2, 3

  // Fast Score Log Controllers
  final _set1ACtrl = TextEditingController();
  final _set1BCtrl = TextEditingController();
  final _set2ACtrl = TextEditingController();
  final _set2BCtrl = TextEditingController();
  final _set3ACtrl = TextEditingController();
  final _set3BCtrl = TextEditingController();

  List<Map<String, dynamic>> _clubPlayers = [];
  String? _selectedPlayerAId;
  String? _selectedPlayerBId;
  bool _isLogging = false;
  late Future<List<Map<String, dynamic>>> _recentMatches;

  @override
  void initState() {
    super.initState();
    _loadClubPlayers();
    _recentMatches = _fetchRecentMatches();
  }

  Future<void> _loadClubPlayers() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final res = await supabase
          .from('players')
          .select(
              'id, full_name, roll_number, elo_rating, playstyle, avatar_url')
          .order('elo_rating', ascending: false);

      final list = List<Map<String, dynamic>>.from(res as List);
      final currentUser = ref.read(currentUserProvider);

      if (!mounted) return;
      setState(() {
        _clubPlayers = list;
        if (list.isNotEmpty) {
          if (currentUser != null) {
            _selectedPlayerAId = list.firstWhere(
              (p) =>
                  p['id'] == currentUser.id ||
                  p['roll_number'] == currentUser.rollNumber,
              orElse: () => list.first,
            )['id'];
          } else {
            _selectedPlayerAId = list.first['id'];
          }

          final others =
              list.where((p) => p['id'] != _selectedPlayerAId).toList();
          _selectedPlayerBId =
              others.isNotEmpty ? others.first['id'] : list.first['id'];
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _set1ACtrl.dispose();
    _set1BCtrl.dispose();
    _set2ACtrl.dispose();
    _set2BCtrl.dispose();
    _set3ACtrl.dispose();
    _set3BCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.transparent,
            pinned: true,
            title: _buildAppBarTitle(currentUser),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(68),
              child: _buildSegmentedNav(),
            ),
          ),

          SliverToBoxAdapter(
            child: AnimatedSwitcher(
                duration: AppMotion.durationOf(context),
                child: KeyedSubtree(
                    key: ValueKey(_activeTab),
                    child: _activeTab == 0
                        ? _buildRecentMatchesTab()
                        : _activeTab == 1
                            ? _buildLogScoreTab()
                            : _buildDisputesTab())),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(dynamic currentUser) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.limeNeon.withValues(alpha: 0.3)),
          ),
          child: const Center(
            child:
                Icon(Icons.sports_tennis, color: AppTheme.limeNeon, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: 'Smash',
                      style: GoogleFonts.chivo(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textWhite),
                    ),
                    TextSpan(
                      text: 'Deck',
                      style: GoogleFonts.chivo(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.limeNeon),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.cardMid,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'COURT $_selectedCourt',
                    style: AppTheme.jetBrainsMono(
                        size: 9,
                        color: AppTheme.mintEmerald,
                        weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            Text(
              'Smash Club • ${_clubPlayers.length} players',
              style: AppTheme.jetBrainsMono(size: 9, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegmentedNav() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: GlassTabs(
            labels: const ['Recent matches', 'Log score', 'Disputes'],
            selected: _activeTab,
            onSelected: (index) => setState(() {
                  _activeTab = index;
                  if (index == 0) _recentMatches = _fetchRecentMatches();
                })),
      );

  Widget _buildRecentMatchesTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Reveal(
                  child: CourtPanel(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    Row(children: [
                      const Icon(Icons.bolt,
                          color: AppTheme.limeNeon, size: 16),
                      const SizedBox(width: 6),
                      Text('EVERY RALLY COUNTS',
                          style: AppTheme.labelCaps
                              .copyWith(color: AppTheme.limeNeon))
                    ]),
                    const SizedBox(height: 14),
                    Text('Bring your A game.', style: AppTheme.headlineXl),
                    const SizedBox(height: 8),
                    Text(
                        'Two sides. One court. Score every point with your courtside umpire.',
                        style: AppTheme.bodyMd
                            .copyWith(color: AppTheme.textMuted)),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: PressScale(
                            child: FilledButton.icon(
                                onPressed: () => MatchSetupDialog.show(context),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('START LIVE MATCH')))),
                  ])))),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 6),
              child: Row(children: [
                Expanded(
                    child:
                        Text('Recent Match Log', style: AppTheme.headlineLg)),
                IconButton(
                    tooltip: 'Refresh matches',
                    onPressed: () =>
                        setState(() => _recentMatches = _fetchRecentMatches()),
                    icon: const Icon(Icons.refresh, size: 20)),
              ])),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                      4,
                      (i) => ChoiceChip(
                          label: Text([
                            'All matches',
                            'My matches',
                            'Singles',
                            'Doubles'
                          ][i]),
                          selected: _historyFilter == i,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _historyFilter = i))))),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
              future: _recentMatches,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)));
                }
                if (snapshot.hasError) {
                  return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        const Text('Couldn?t load recent matches.'),
                        TextButton.icon(
                            onPressed: () => setState(
                                () => _recentMatches = _fetchRecentMatches()),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again')),
                      ]));
                }
                final all = snapshot.data ?? [];
                final userId = ref.watch(currentUserProvider)?.id;
                final matches = all
                    .where((m) => switch (_historyFilter) {
                          1 => userId != null &&
                              [
                                'team_a_player1_id',
                                'team_a_player2_id',
                                'team_b_player1_id',
                                'team_b_player2_id'
                              ].any((k) => m[k] == userId),
                          2 => m['match_type'] == 'singles',
                          3 => m['match_type'] == 'doubles',
                          _ => true,
                        })
                    .toList();
                if (all.isEmpty) return _buildEmptyMatches();
                return AnimatedSwitcher(
                    duration: AppMotion.durationOf(context),
                    child: Column(key: ValueKey(_historyFilter), children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  '${matches.length} shown ? latest ${all.length} club matches',
                                  style: AppTheme.bodySm
                                      .copyWith(color: AppTheme.textMuted)))),
                      if (matches.isEmpty)
                        Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(children: [
                              const Icon(Icons.filter_list_off,
                                  size: 32, color: AppTheme.textMuted),
                              const SizedBox(height: 12),
                              const Text('No recent matches in this filter.'),
                              TextButton(
                                  onPressed: () =>
                                      setState(() => _historyFilter = 0),
                                  child: const Text('Show all matches')),
                            ])),
                      ...matches.map(_buildMatchCard),
                    ]));
              }),
          const SizedBox(height: 32),
        ],
      );

  Widget _buildMatchCard(Map<String, dynamic> m) {
    String name(String side) {
      final first = m['team_$side']?['full_name'] as String? ??
          'Player ${side.toUpperCase()}';
      final partner = m['partner_$side']?['full_name'] as String?;
      return partner == null ? first : '$first / $partner';
    }

    final teamA = name('a');
    final teamB = name('b');
    final winner = m['winner_team'] as String?;
    final sets = List<Map<String, dynamic>>.from(m['match_sets'] as List? ?? [])
      ..sort((a, b) => ((a['set_number'] as num?) ?? 0)
          .compareTo((b['set_number'] as num?) ?? 0));
    final umpired = m['umpire_id'] != null;
    final confirmed =
        m['confirmed_by_team_a'] == true && m['confirmed_by_team_b'] == true;
    final date = DateTime.tryParse(
            (m['completed_at'] ?? m['created_at'] ?? '').toString())
        ?.toLocal();
    final status = umpired
        ? 'UMPIRED'
        : confirmed
            ? 'CONFIRMED'
            : 'SCORE LOGGED';
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Reveal(
            child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderDark)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 10, runSpacing: 8, children: [
              Text((m['category'] ?? 'match').toString().toUpperCase(),
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.limeNeon)),
              Text(status,
                  style: AppTheme.labelCaps.copyWith(
                      color: umpired || confirmed
                          ? AppTheme.mintTeal
                          : AppTheme.textMuted)),
            ]),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: _matchPlayer(teamA,
                      m['team_a']?['avatar_url'] as String?, winner == 'A')),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text('VS',
                      style: AppTheme.labelCaps
                          .copyWith(color: AppTheme.textMuted))),
              Expanded(
                  child: _matchPlayer(teamB,
                      m['team_b']?['avatar_url'] as String?, winner == 'B')),
            ]),
            const SizedBox(height: 18),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < sets.length; i++)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: AppTheme.bgDarker,
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(children: [
                      Text('SET ${sets[i]['set_number'] ?? i + 1}',
                          style: AppTheme.labelCaps.copyWith(
                              fontSize: 8, color: AppTheme.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                          '${sets[i]['team_a_score']} : ${sets[i]['team_b_score']}',
                          style: AppTheme.statBadge)
                    ])),
            ]),
            const SizedBox(height: 12),
            Text(
                '${(m['match_type'] ?? 'singles').toString().toUpperCase()}${date == null ? '' : ' ? ${DateFormat('d MMM, h:mm a').format(date)}'}',
                style: AppTheme.bodySm.copyWith(color: AppTheme.textMuted)),
          ]),
        )));
  }

  Widget _matchPlayer(String name, String? avatar, bool winner) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PlayerAvatar(name: name, url: avatar, size: 38),
        const SizedBox(height: 8),
        Text(name,
            style: AppTheme.chivo(
                size: 14,
                color: winner ? AppTheme.limeNeon : AppTheme.textWhite)),
        if (winner)
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('WINNER',
                  style: AppTheme.labelCaps
                      .copyWith(fontSize: 8, color: AppTheme.mintTeal))),
      ]);

  Widget _buildEmptyMatches() => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          const Icon(Icons.sports_score, size: 42, color: AppTheme.limeNeon),
          const SizedBox(height: 16),
          Text('Your next match starts here.',
              style: AppTheme.chivo(size: 21), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Play a match or log a score to build your club history.',
              style: AppTheme.spaceGrotesk(color: AppTheme.textMuted),
              textAlign: TextAlign.center),
        ]),
      );

  Future<List<Map<String, dynamic>>> _fetchRecentMatches() async {
    final res = await ref
        .read(supabaseClientProvider)
        .from('matches')
        .select(
            '*, team_a:players!matches_team_a_player1_id_fkey(full_name, avatar_url), team_b:players!matches_team_b_player1_id_fkey(full_name, avatar_url), partner_a:players!matches_team_a_player2_id_fkey(full_name), partner_b:players!matches_team_b_player2_id_fkey(full_name), match_sets(*)')
        .eq('status', 'completed')
        .order('created_at', ascending: false)
        .limit(20)
        .timeout(const Duration(seconds: 10));
    return List<Map<String, dynamic>>.from(res);
  }

  // ── LOG SCORE TAB ──────────────────────────────────────────────────────────
  Widget _buildLogScoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Quick Score Logger Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.limeNeon,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.bolt,
                              color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fast Score Log',
                                style: GoogleFonts.chivo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                            Text('Official Ladder Arbitrated Record',
                                style: AppTheme.jetBrainsMono(
                                    size: 9, color: AppTheme.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    // Ladder toggle
                    Row(
                      children: [
                        Text('LADDER TIER',
                            style: AppTheme.jetBrainsMono(
                                size: 9,
                                color: _isLadderTier
                                    ? AppTheme.limeNeon
                                    : AppTheme.textMuted)),
                        const SizedBox(width: 6),
                        Switch(
                          value: _isLadderTier,
                          activeThumbColor: AppTheme.limeNeon,
                          onChanged: (v) => setState(() => _isLadderTier = v),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Format & Court Row
                Row(
                  children: [
                    // Singles / Doubles
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _matchType = 0),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _matchType == 0
                                        ? AppTheme.cardMid
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Singles (1v1)',
                                      style: AppTheme.jetBrainsMono(
                                        size: 10,
                                        color: _matchType == 0
                                            ? AppTheme.limeNeon
                                            : AppTheme.textMuted,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => MatchSetupDialog.show(context),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _matchType == 1
                                        ? AppTheme.cardMid
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Doubles (2v2)',
                                      style: AppTheme.jetBrainsMono(
                                        size: 10,
                                        color: _matchType == 1
                                            ? AppTheme.limeNeon
                                            : AppTheme.textMuted,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Court pills
                    Row(
                      children: [1, 2, 3].map((c) {
                        final isSel = _selectedCourt == c;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCourt = c),
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  isSel ? AppTheme.limeNeon : AppTheme.bgDark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'C$c',
                              style: AppTheme.jetBrainsMono(
                                size: 11,
                                color: isSel ? Colors.black : Colors.white70,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Player A Dropdown Strip
                Text('TEAM A (PLAYER 1)',
                    style: AppTheme.jetBrainsMono(
                        size: 9, color: AppTheme.limeNeon)),
                const SizedBox(height: 6),
                _buildPlayerSelector(
                  selectedId: _selectedPlayerAId,
                  onChanged: (id) => setState(() => _selectedPlayerAId = id),
                ),
                const SizedBox(height: 16),

                // Set Score Dialers
                Row(
                  children: [
                    Expanded(
                      child: _buildSetBox(
                        label: 'SET 1',
                        ctrlA: _set1ACtrl,
                        ctrlB: _set1BCtrl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSetBox(
                        label: 'SET 2',
                        ctrlA: _set2ACtrl,
                        ctrlB: _set2BCtrl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSetBox(
                        label: 'SET 3 DECIDER',
                        ctrlA: _set3ACtrl,
                        ctrlB: _set3BCtrl,
                        isDecider: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Player B Dropdown Strip
                Text('TEAM B (OPPONENT)',
                    style: AppTheme.jetBrainsMono(
                        size: 9, color: AppTheme.mintEmerald)),
                const SizedBox(height: 6),
                _buildPlayerSelector(
                  selectedId: _selectedPlayerBId,
                  onChanged: (id) => setState(() => _selectedPlayerBId = id),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.limeNeon,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                    ),
                    icon: _isLogging
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.send, color: Colors.black, size: 18),
                    label: Text(
                      _isLogging
                          ? 'BROADCASTING TO SUPABASE...'
                          : 'BROADCAST & VERIFY RESULT',
                      style: GoogleFonts.chivo(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5),
                    ),
                    onPressed: _isLogging ? null : _submitFastScore,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPlayerSelector({
    required String? selectedId,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          dropdownColor: AppTheme.cardDark,
          items: _clubPlayers.map((p) {
            return DropdownMenuItem<String>(
              value: p['id'] as String,
              child: Row(
                children: [
                  Text(
                    p['full_name'] as String,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${p['roll_number']})',
                    style: AppTheme.jetBrainsMono(
                        size: 10, color: AppTheme.textMuted),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.cardMid,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${p['elo_rating'] ?? 1200}',
                      style: AppTheme.jetBrainsMono(
                          size: 9,
                          color: AppTheme.limeNeon,
                          weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSetBox({
    required String label,
    required TextEditingController ctrlA,
    required TextEditingController ctrlB,
    bool isDecider = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(10),
        border: isDecider
            ? Border.all(color: AppTheme.limeNeon.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTheme.jetBrainsMono(
              size: 8,
              color: isDecider ? AppTheme.limeNeon : AppTheme.mintEmerald,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 34,
                child: TextField(
                  controller: ctrlA,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.chivo(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.limeNeon),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero),
                ),
              ),
              const Text(':',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 34,
                child: TextField(
                  controller: ctrlB,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.chivo(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitFastScore() async {
    if (_isLogging) return;
    if (_selectedPlayerAId == null || _selectedPlayerBId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose two players first.')));
      return;
    }
    setState(() => _isLogging = true);
    try {
      final scores = <Map<String, int>>[];
      for (final pair in [
        [_set1ACtrl, _set1BCtrl],
        [_set2ACtrl, _set2BCtrl],
        [_set3ACtrl, _set3BCtrl],
      ]) {
        if (pair.every((c) => c.text.trim().isEmpty)) continue;
        final a = int.tryParse(pair[0].text.trim());
        final b = int.tryParse(pair[1].text.trim());
        if (a == null || b == null) {
          throw ArgumentError('Enter both scores for each played set.');
        }
        scores.add({'a': a, 'b': b});
      }
      final winner = BwfScoringRules.getMatchWinner(scores);
      if (winner == null) {
        throw ArgumentError('A best-of-three match needs two winning sets.');
      }
      final result = await ref.read(matchRepositoryProvider).saveCompletedMatch(
            matchType: 'singles',
            category: _isLadderTier ? 'ladder' : 'practice',
            teamA1Id: _selectedPlayerAId!,
            teamB1Id: _selectedPlayerBId!,
            winnerTeam: winner,
            sets: scores,
            isRatingEligible: false,
          );
      if (!mounted) return;
      ref.invalidate(ladderStandingsProvider);
      ref.invalidate(squadTrumpCardsProvider);
      setState(() {
        _activeTab = 0;
        _recentMatches = _fetchRecentMatches();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ArgumentError
                ? e.message.toString()
                : 'Couldn’t save this match. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  // ── DISPUTES TAB ──────────────────────────────────────────────────────────
  Widget _buildDisputesTab() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          const Icon(Icons.gavel, color: AppTheme.mintEmerald, size: 44),
          const SizedBox(height: 14),
          Text(
            'Zero Open Disputes',
            style: GoogleFonts.chivo(
                fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'All recent club and ladder matches have been certified by court umpires and confirmed by both teams.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
