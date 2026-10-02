import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_avatars.dart';
import '../auth/auth_state.dart';
import '../auth/current_user_notifier.dart';
import 'player_profile_screen.dart';

/// Screen 4: Players List Screen Matching Reference Mockups & Stitch Leaderboard
class PlayersListScreen extends ConsumerStatefulWidget {
  const PlayersListScreen({super.key});

  @override
  ConsumerState<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends ConsumerState<PlayersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _activeFilter = 0; // 0: Ranking, 1: Stats, 2: All Players
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Compute approximate OVR from elo_rating (1000–1800 range → 55–99 scale)
  int _computeOvr(int elo) {
    return ((elo - 1000) / 800 * 44 + 55).clamp(55, 99).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(allPlayersProvider);

    return playersAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryEmerald)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
          child: Text('Error loading players: $e',
              style: const TextStyle(color: Colors.white70)),
        ),
      ),
      data: (allPlayers) {
        final filteredPlayers = allPlayers.where((p) {
          if (_searchQuery.isEmpty) return true;
          return p.fullName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              p.rollNumber.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
        return _buildList(context, allPlayers.length, filteredPlayers);
      },
    );
  }

  Widget _buildList(BuildContext context, int totalCount,
      List<PlayerProfile> filteredPlayers) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 16, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Players',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textWhite,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDarker,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Text(
                      '$totalCount Active',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBright,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style:
                      const TextStyle(color: AppTheme.textWhite, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search players...',
                    hintStyle: const TextStyle(
                        color: AppTheme.textMutedDark, fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: AppTheme.textMuted, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                size: 16, color: AppTheme.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Filter Chips (Ranking, Stats, All Players)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterPill(0, 'Ranking'),
                  const SizedBox(width: 8),
                  _buildFilterPill(1, 'Stats'),
                  const SizedBox(width: 8),
                  _buildFilterPill(2, 'All Players'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Table Header (#, Player, OVR, Win Rate)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '#',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Player',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      'OVR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Win Rate',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppTheme.borderDark, height: 1),

            // Player Rows
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filteredPlayers.length,
                separatorBuilder: (_, __) => const Divider(
                  color: Color(0xFF141F1A),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final player = filteredPlayers[index];
                  final rank = index + 1;
                  final stats = {
                    'ovr': _computeOvr(player.eloRating),
                    'winRate': 'N/A',
                  };

                  return _buildPlayerRow(context, rank, player, stats);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _activeFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F5132) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : AppTheme.borderDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerRow(
    BuildContext context,
    int rank,
    PlayerProfile player,
    Map<String, dynamic> stats,
  ) {
    Color rankColor;
    Color rankBg;

    if (rank == 1) {
      rankColor = const Color(0xFFF59E0B);
      rankBg = const Color(0x33F59E0B);
    } else if (rank == 2) {
      rankColor = const Color(0xFFCBD5E1);
      rankBg = const Color(0x33CBD5E1);
    } else if (rank == 3) {
      rankColor = const Color(0xFFD97706);
      rankBg = const Color(0x33D97706);
    } else {
      rankColor = AppTheme.textMuted;
      rankBg = Colors.transparent;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerProfileScreen(player: player),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            // Rank Number
            SizedBox(
              width: 28,
              child: rank <= 3
                  ? Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rankBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: rankColor, width: 1.5),
                      ),
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: rankColor,
                        ),
                      ),
                    )
                  : Text(
                      '$rank',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                      ),
                    ),
            ),
            const SizedBox(width: 8),

            // Avatar
            AppAvatars.buildAvatar(
              rollNumber: player.rollNumber,
              size: 36,
              border: Border.all(
                color: rank <= 3
                    ? rankColor.withValues(alpha: 0.6)
                    : AppTheme.borderDark,
                width: rank <= 3 ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 12),

            // Player Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  Text(
                    player.playstyle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // OVR
            SizedBox(
              width: 44,
              child: Text(
                '${stats['ovr']}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBright,
                ),
              ),
            ),

            // Win Rate
            SizedBox(
              width: 60,
              child: Text(
                '${stats['winRate']}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
