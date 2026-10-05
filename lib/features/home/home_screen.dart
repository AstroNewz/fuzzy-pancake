import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_avatars.dart';
import '../attendance/mark_attendance_screen.dart';
import '../auth/current_user_notifier.dart';
import '../ladder/ladder_screen.dart';
import '../matches/log_match_screen.dart';
import '../players/player_profile_screen.dart';
import '../events/squad_common_space_screen.dart';

/// Screen 3: Home Screen Matching Reference Mockup & Stitch Pulse
class HomeScreen extends ConsumerWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Guard: should not reach here without a user (AuthGate handles routing)
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryEmerald)),
      );
    }

    final firstName = user.fullName.split(' ').first;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: "Hey, [Name]! 👋"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Hey, $firstName! 👋',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textWhite,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Good to see you back.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Notification Bell -> opens Squad Common Space
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SquadCommonSpaceScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.notifications_none,
                                  color: AppTheme.textWhite, size: 20),
                              Positioned(
                                top: 9,
                                right: 10,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.limeNeon,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // User Avatar
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerProfileScreen(player: user),
                            ),
                          );
                        },
                        child: AppAvatars.buildAvatar(
                          rollNumber: user.rollNumber,
                          size: 40,
                          border:
                              Border.all(color: AppTheme.limeNeon, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Motivational Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F3826),
                      Color(0xFF0A2216),
                      Color(0xFF06140D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border:
                      Border.all(color: const Color(0xFF1B5539), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3300C853),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"Smaller court,\nbigger friendships."',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textWhite,
                              height: 1.25,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.sports_tennis,
                                  color: AppTheme.primaryBright, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'SmashDeck',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryBright,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Shuttlecock Graphic Badge
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFF164831),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF287950)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.sports_tennis,
                          color: Color(0xFF6EE7B7),
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Squad Common Space & Practice Session Banner
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SquadCommonSpaceScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14241B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.limeNeon.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.limeNeon.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.forum_outlined,
                            color: AppTheme.limeNeon, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Squad Common Space & Chat',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textWhite,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Practice sessions, captain events & squad chat',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.limeNeon),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4 Action Tiles (2x2 Grid)
              Row(
                children: [
                  _buildActionTile(
                    title: 'Log Match',
                    subtitle: 'Record a new match',
                    icon: Icons.edit_note,
                    accentColor: const Color(0xFF10B981),
                    bgColor: const Color(0x1F10B981),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LogMatchScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildActionTile(
                    title: 'Mark Attendance',
                    subtitle: "Let us know you're playing",
                    icon: Icons.how_to_reg,
                    accentColor: const Color(0xFF38BDF8),
                    bgColor: const Color(0x1F38BDF8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MarkAttendanceScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildActionTile(
                    title: 'View Rankings',
                    subtitle: 'See where you stand',
                    icon: Icons.leaderboard,
                    accentColor: const Color(0xFFA855F7),
                    bgColor: const Color(0x1FA855F7),
                    onTap: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(1); // Go to Players tab
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LadderScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildActionTile(
                    title: 'Club Players',
                    subtitle: 'Meet the squad',
                    icon: Icons.groups,
                    accentColor: const Color(0xFFFB923C),
                    bgColor: const Color(0x1FFB923C),
                    onTap: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(1); // Go to Players tab
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Upcoming Events Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textWhite,
                      letterSpacing: -0.2,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'All club sessions are open for check-in!')),
                      );
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBright,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Upcoming Card 1: Club Play Session
              _buildUpcomingEventCard(
                title: 'Club Play Session',
                timeText: 'Today · 5:00 PM - 7:00 PM',
                locationText: 'Main Court',
                badgeText: 'TODAY',
                badgeColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 10),

              // Upcoming Card 2: Inter-Department Friendly
              _buildUpcomingEventCard(
                title: 'Inter-Department Friendly',
                timeText: 'Sat, 13 Sep · 4:00 PM',
                locationText: 'Sports Complex',
                badgeText: 'EVENT',
                badgeColor: const Color(0xFF38BDF8),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEventCard({
    required String title,
    required String timeText,
    required String locationText,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF163829),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_outlined,
                color: AppTheme.primaryBright, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppTheme.textMutedDark, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      locationText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMutedDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
