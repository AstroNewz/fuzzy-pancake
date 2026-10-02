import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../match_engine/live_scoring_screen.dart';

/// Screen 6: Match Details Screen Matching Reference Mockup
class MatchDetailsScreen extends StatelessWidget {
  const MatchDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Match Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle / Date Row
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Singles',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  '10 Sep 2025 · Club Play',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Face-off Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Player 1 (Winner)
                  Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF10B981), width: 2),
                        ),
                        child: const ClipOval(
                          child: Image(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ishan Shukla',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '2',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),

                  // VS Badge
                  const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                    ),
                  ),

                  // Player 2
                  Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppTheme.borderDark, width: 2),
                        ),
                        child: const ClipOval(
                          child: Image(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Rohan Singh',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Set Scores (Set 1, Set 2, Set 3)
            Row(
              children: [
                _buildSetScoreCard('Set 1', '21 - 18', true),
                const SizedBox(width: 10),
                _buildSetScoreCard('Set 2', '17 - 21', false),
                const SizedBox(width: 10),
                _buildSetScoreCard('Set 3', '21 - 16', true),
              ],
            ),
            const SizedBox(height: 16),

            // Note Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: const Row(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      color: AppTheme.primaryBright, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Great game! Close second set.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textWhite,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // "View Match Stats" / Launch Live Umpire Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F5132),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFF10B981), width: 1),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LiveScoringScreen(),
                    ),
                  );
                },
                child: const Text(
                  'View Match Stats & Umpire Court',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Match Metadata List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                children: [
                  _buildMetaItem(
                      Icons.calendar_today_outlined, '10 Sep 2025, 6:15 PM'),
                  const Divider(color: AppTheme.borderDark, height: 18),
                  _buildMetaItem(Icons.location_on_outlined, 'Main Court'),
                  const Divider(color: AppTheme.borderDark, height: 18),
                  _buildMetaItem(Icons.sports_tennis, 'Singles Club Match'),
                  const Divider(color: AppTheme.borderDark, height: 18),
                  _buildMetaItem(Icons.verified_outlined,
                      'Ladder Rating Verified (+18 Elo)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetScoreCard(String setLabel, String score, bool won) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: won ? const Color(0xFF132A20) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: won ? const Color(0xFF1B4D36) : AppTheme.borderDark,
          ),
        ),
        child: Column(
          children: [
            Text(
              score,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: won ? const Color(0xFF10B981) : AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              setLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBright),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textWhite,
            ),
          ),
        ),
      ],
    );
  }
}
