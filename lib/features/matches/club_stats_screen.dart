import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/data/mock_squad_data.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_state.dart';
import '../players/player_profile_screen.dart';

/// Screen 9: Club Stats Screen Matching Reference Mockup & Stitch Telemetry
class ClubStatsScreen extends StatefulWidget {
  const ClubStatsScreen({super.key});

  @override
  State<ClubStatsScreen> createState() => _ClubStatsScreenState();
}

class _ClubStatsScreenState extends State<ClubStatsScreen> {
  String _selectedPeriod = 'This Semester';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Club Stats',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardDarker,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                dropdownColor: AppTheme.cardDark,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600),
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 16, color: AppTheme.textMuted),
                items: const [
                  DropdownMenuItem(
                      value: 'This Semester', child: Text('This Semester')),
                  DropdownMenuItem(
                      value: 'Last 30 Days', child: Text('Last 30 Days')),
                  DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedPeriod = v);
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4 Metrics (2x2 Grid)
            Row(
              children: [
                _buildMetricTile(
                  Icons.sports_tennis,
                  '124',
                  'Total Matches',
                  const Color(0xFF10B981),
                  const Color(0x2210B981),
                ),
                const SizedBox(width: 12),
                _buildMetricTile(
                  Icons.emoji_events_outlined,
                  '91',
                  'Total Wins',
                  const Color(0xFF38BDF8),
                  const Color(0x2238BDF8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetricTile(
                  Icons.show_chart,
                  '73%',
                  'Win Rate',
                  const Color(0xFFA855F7),
                  const Color(0x22A855F7),
                ),
                const SizedBox(width: 12),
                _buildMetricTile(
                  Icons.people_outline,
                  '20',
                  'Active Players',
                  const Color(0xFFFB923C),
                  const Color(0x22FB923C),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Monthly Matches Bar Chart
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Matches',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBright,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 140,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 22,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                const labels = [
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'May',
                                  'Jun'
                                ];
                                if (val.toInt() >= 0 &&
                                    val.toInt() < labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      labels[val.toInt()],
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _makeBarGroup(0, 10),
                          _makeBarGroup(1, 14),
                          _makeBarGroup(2, 12),
                          _makeBarGroup(3, 17),
                          _makeBarGroup(4, 19),
                          _makeBarGroup(5, 21),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Top Performers Section
            const Text(
              'Top Performers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 12),
            _buildPerformerTile(context, 1, MockSquadData.players[0], 92,
                const Color(0xFFF59E0B)),
            const SizedBox(height: 8),
            _buildPerformerTile(context, 2, MockSquadData.players[1], 89,
                const Color(0xFFCBD5E1)),
            const SizedBox(height: 8),
            _buildPerformerTile(context, 3, MockSquadData.players[2], 87,
                const Color(0xFFD97706)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF10B981),
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    IconData icon,
    String value,
    String label,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformerTile(
    BuildContext context,
    int rank,
    PlayerProfile player,
    int ovr,
    Color rankColor,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerProfileScreen(player: player),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.2),
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
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.network(
                  player.avatarUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF131D18),
                    alignment: Alignment.center,
                    child: Text(
                      player.fullName.substring(0, 1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBright,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                player.fullName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
            Text(
              '$ovr',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryBright,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
