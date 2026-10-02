import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../auth/current_user_notifier.dart';
import 'live_scoring_screen.dart';
import 'match_engine_state.dart';

/// Lightweight player model for match setup
class SetupPlayer {
  final String id;
  final String fullName;
  final String rollNumber;
  final int elo;
  final String? avatarUrl;

  const SetupPlayer({
    required this.id,
    required this.fullName,
    required this.rollNumber,
    required this.elo,
    this.avatarUrl,
  });

  factory SetupPlayer.fromMap(Map<String, dynamic> map) {
    return SetupPlayer(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? 'Club Member',
      rollNumber: (map['roll_number'] as String?) ?? '',
      elo: (map['elo_rating'] as num?)?.toInt() ?? 1200,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}

/// Modal Dialog / Bottom Sheet to configure and start a live court umpire match
class MatchSetupDialog extends ConsumerStatefulWidget {
  const MatchSetupDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MatchSetupDialog(),
    );
  }

  @override
  ConsumerState<MatchSetupDialog> createState() => _MatchSetupDialogState();
}

class _MatchSetupDialogState extends ConsumerState<MatchSetupDialog> {
  bool _isSingles = true;
  String _category = 'ladder'; // 'ladder', 'tournament', 'practice'
  String _court = 'C1';
  int _targetPoints = 21;
  int _bestOfSets = 3;

  List<SetupPlayer> _players = [];
  bool _isLoading = true;

  SetupPlayer? _teamA1;
  SetupPlayer? _teamA2;
  SetupPlayer? _teamB1;
  SetupPlayer? _teamB2;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('players')
          .select('id, full_name, roll_number, elo_rating, avatar_url')
          .order('elo_rating', ascending: false);

      final list = (res as List).map((m) => SetupPlayer.fromMap(m)).toList();
      final currentUser = ref.read(currentUserProvider);

      if (!mounted) return;
      setState(() {
        _players = list;
        _isLoading = false;

        if (list.isNotEmpty) {
          if (currentUser != null) {
            _teamA1 = list.firstWhere(
              (p) =>
                  p.id == currentUser.id ||
                  p.rollNumber == currentUser.rollNumber,
              orElse: () => list.first,
            );
          } else {
            _teamA1 = list.first;
          }

          final opponents = list.where((p) => p.id != _teamA1?.id).toList();
          _teamB1 = opponents.isNotEmpty ? opponents.first : list.first;

          if (opponents.length >= 2) {
            _teamA2 = opponents[1];
          }
          if (opponents.length >= 3) {
            _teamB2 = opponents[2];
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomPointsDialog() {
    final ctrl = TextEditingController(text: _targetPoints.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderDark)),
        title: Text('Custom Match Points',
            style: AppTheme.chivo(size: 16, color: AppTheme.textWhite)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: AppTheme.jetBrainsMono(
              size: 18, color: AppTheme.limeNeon, weight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: 'Enter target points (e.g. 11, 15, 25, 30)',
            labelText: 'Target Points',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTheme.spaceGrotesk(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.limeNeon,
                foregroundColor: const Color(0xFF283500)),
            onPressed: () {
              final pts = int.tryParse(ctrl.text.trim());
              if (pts != null && pts > 0) {
                setState(() => _targetPoints = pts);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set Points'),
          ),
        ],
      ),
    );
  }

  void _startMatch() {
    if (_teamA1 == null || _teamB1 == null) return;
    final players = [
      _teamA1,
      _teamB1,
      if (!_isSingles) _teamA2,
      if (!_isSingles) _teamB2
    ];
    if (players.any((p) => p == null) ||
        players.map((p) => p?.id).toSet().length != players.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Choose a different player for every position.')));
      return;
    }

    final isRatingEligible = _category != 'practice';

    ref.read(liveMatchProvider.notifier).initMatch(
          matchType: _isSingles ? 'singles' : 'doubles',
          category: _category,
          isRatingEligible: isRatingEligible,
          targetPoints: _targetPoints,
          bestOfSets: _bestOfSets,
          teamA1Id: _teamA1!.id,
          teamA1Name: _teamA1!.fullName,
          teamA2Id: _isSingles ? null : _teamA2?.id,
          teamA2Name: _isSingles ? null : _teamA2?.fullName,
          teamB1Id: _teamB1!.id,
          teamB1Name: _teamB1!.fullName,
          teamB2Id: _isSingles ? null : _teamB2?.id,
          teamB2Name: _isSingles ? null : _teamB2?.fullName,
        );

    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(builder: (_) => const LiveScoringScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.limeNeon, width: 2)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.limeNeon.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sports_tennis,
                          color: AppTheme.limeNeon, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIVE COURT UMPIRE SETUP',
                          style: GoogleFonts.chivo(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Configure match points, format & select squad players',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.borderDark, height: 1),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.limeNeon))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Format: Singles / Doubles Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'MATCH FORMAT',
                              style: AppTheme.jetBrainsMono(
                                  size: 10,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 0.8),
                            ),
                            // Court pills C1 / C2 / C3
                            Row(
                              children: ['C1', 'C2', 'C3'].map((c) {
                                final isSel = _court == c;
                                return GestureDetector(
                                  onTap: () => setState(() => _court = c),
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? AppTheme.limeNeon
                                          : AppTheme.cardDark,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: isSel
                                              ? AppTheme.limeNeon
                                              : AppTheme.borderDark),
                                    ),
                                    child: Text(
                                      c,
                                      style: AppTheme.jetBrainsMono(
                                        size: 10,
                                        color: isSel
                                            ? Colors.black
                                            : Colors.white70,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildToggleOption(
                                  label: 'Singles (1v1)',
                                  icon: Icons.person,
                                  isSelected: _isSingles,
                                  onTap: () =>
                                      setState(() => _isSingles = true),
                                ),
                              ),
                              Expanded(
                                child: _buildToggleOption(
                                  label: 'Doubles (2v2)',
                                  icon: Icons.people,
                                  isSelected: !_isSingles,
                                  onTap: () =>
                                      setState(() => _isSingles = false),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Target Points & Best-of Sets Configuration
                        Text(
                          'CUSTOMIZE MATCH POINTS & SETS',
                          style: AppTheme.jetBrainsMono(
                              size: 10,
                              color: AppTheme.limeNeon,
                              letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildPointChip(11, '11 PTS'),
                            const SizedBox(width: 8),
                            _buildPointChip(15, '15 PTS'),
                            const SizedBox(width: 8),
                            _buildPointChip(21, '21 PTS (BWF)'),
                            const SizedBox(width: 8),
                            _buildPointChip(30, '30 PTS'),
                            const SizedBox(width: 8),
                            ActionChip(
                              label: Text(
                                _isStandardPoint(_targetPoints)
                                    ? 'CUSTOM'
                                    : '$_targetPoints PTS',
                                style: AppTheme.jetBrainsMono(
                                  size: 10.5,
                                  weight: FontWeight.bold,
                                  color: !_isStandardPoint(_targetPoints)
                                      ? Colors.black
                                      : AppTheme.limeNeon,
                                ),
                              ),
                              backgroundColor: !_isStandardPoint(_targetPoints)
                                  ? AppTheme.limeNeon
                                  : AppTheme.cardDark,
                              side: BorderSide(
                                  color: !_isStandardPoint(_targetPoints)
                                      ? AppTheme.limeNeon
                                      : AppTheme.borderDark),
                              onPressed: _showCustomPointsDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Best of Sets Pills
                        Row(
                          children: [
                            Text(
                              'SETS:',
                              style: AppTheme.jetBrainsMono(
                                  size: 10, color: AppTheme.textMuted),
                            ),
                            const SizedBox(width: 10),
                            _buildSetChip(1, 'Best of 1'),
                            const SizedBox(width: 8),
                            _buildSetChip(3, 'Best of 3 (Standard)'),
                            const SizedBox(width: 8),
                            _buildSetChip(5, 'Best of 5'),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // 2. Category: Ladder Duel / Tournament / Practice
                        Text(
                          'TIER & RATING ELIGIBILITY',
                          style: AppTheme.jetBrainsMono(
                              size: 10,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCategoryCard(
                                categoryKey: 'ladder',
                                title: 'Ladder Duel',
                                subtitle: 'Elo & OVR Rated',
                                icon: Icons.military_tech,
                                accentColor: AppTheme.limeNeon,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCategoryCard(
                                categoryKey: 'tournament',
                                title: 'Tournament',
                                subtitle: 'Official Event',
                                icon: Icons.emoji_events,
                                accentColor: AppTheme.mintEmerald,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCategoryCard(
                                categoryKey: 'practice',
                                title: 'Practice',
                                subtitle: 'Unranked Spar',
                                icon: Icons.fitness_center,
                                accentColor: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 3. Team A Players
                        _buildTeamSection(
                          teamLabel: 'TEAM A (COURT SIDE A)',
                          accentColor: AppTheme.limeNeon,
                          p1: _teamA1,
                          p2: _teamA2,
                          onChangedP1: (p) => setState(() => _teamA1 = p),
                          onChangedP2: (p) => setState(() => _teamA2 = p),
                        ),
                        const SizedBox(height: 16),

                        // 4. Team B Players
                        _buildTeamSection(
                          teamLabel: 'TEAM B (COURT SIDE B)',
                          accentColor: AppTheme.mintEmerald,
                          p1: _teamB1,
                          p2: _teamB2,
                          onChangedP1: (p) => setState(() => _teamB1 = p),
                          onChangedP2: (p) => setState(() => _teamB2 = p),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),

          // Start Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.limeNeon,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 8,
                    shadowColor: AppTheme.limeNeon.withValues(alpha: 0.4),
                  ),
                  icon: const Icon(Icons.sports_tennis,
                      color: Colors.black, size: 22),
                  label: Text(
                    'LAUNCH LIVE UMPIRE ($_targetPoints PTS • COURT $_court)',
                    style: GoogleFonts.chivo(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed:
                      (_teamA1 != null && _teamB1 != null) ? _startMatch : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isStandardPoint(int p) => p == 11 || p == 15 || p == 21 || p == 30;

  Widget _buildPointChip(int pts, String label) {
    final isSel = _targetPoints == pts;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: AppTheme.limeNeon,
      backgroundColor: AppTheme.cardDark,
      labelStyle: AppTheme.jetBrainsMono(
        size: 10.5,
        weight: FontWeight.bold,
        color: isSel ? Colors.black : AppTheme.textMuted,
      ),
      side: BorderSide(color: isSel ? AppTheme.limeNeon : AppTheme.borderDark),
      onSelected: (_) => setState(() => _targetPoints = pts),
    );
  }

  Widget _buildSetChip(int sets, String label) {
    final isSel = _bestOfSets == sets;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: AppTheme.mintTeal,
      backgroundColor: AppTheme.cardDark,
      labelStyle: AppTheme.jetBrainsMono(
        size: 10,
        weight: FontWeight.bold,
        color: isSel ? Colors.black : AppTheme.textMuted,
      ),
      side: BorderSide(color: isSel ? AppTheme.mintTeal : AppTheme.borderDark),
      onSelected: (_) => setState(() => _bestOfSets = sets),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceVar : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? AppTheme.limeNeon : AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.chivo(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String categoryKey,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _category == categoryKey;
    return GestureDetector(
      onTap: () => setState(() => _category = categoryKey),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : AppTheme.borderDark,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 20, color: isSelected ? accentColor : AppTheme.textMuted),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.chivo(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 9.5, color: AppTheme.textMutedDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection({
    required String teamLabel,
    required Color accentColor,
    required SetupPlayer? p1,
    required SetupPlayer? p2,
    required ValueChanged<SetupPlayer?> onChangedP1,
    required ValueChanged<SetupPlayer?> onChangedP2,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(
                teamLabel,
                style: AppTheme.jetBrainsMono(
                    size: 11,
                    color: accentColor,
                    weight: FontWeight.w800,
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPlayerDropdown(
            label: _isSingles ? 'Player' : 'Player 1',
            selectedPlayer: p1,
            onChanged: onChangedP1,
            accentColor: accentColor,
          ),
          if (!_isSingles) ...[
            const SizedBox(height: 10),
            _buildPlayerDropdown(
              label: 'Player 2 (Partner)',
              selectedPlayer: p2,
              onChanged: onChangedP2,
              accentColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerDropdown({
    required String label,
    required SetupPlayer? selectedPlayer,
    required ValueChanged<SetupPlayer?> onChanged,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.jetBrainsMono(size: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SetupPlayer>(
              value: selectedPlayer,
              isExpanded: true,
              dropdownColor: AppTheme.cardMid,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppTheme.textMuted),
              items: _players.map((p) {
                return DropdownMenuItem<SetupPlayer>(
                  value: p,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${p.fullName} (${p.rollNumber})',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVar,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${p.elo} ELO',
                          style: AppTheme.jetBrainsMono(
                              size: 10,
                              color: accentColor,
                              weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
