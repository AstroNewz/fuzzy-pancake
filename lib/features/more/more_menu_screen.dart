import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/supabase_connect_dialog.dart';
import '../gear_tracker/gear_screen.dart';
import '../ladder/ladder_screen.dart';
import '../matches/match_details_screen.dart';
import '../players/player_profile_screen.dart';
import '../trump_card/trump_card_view.dart';
import '../training/training_screen.dart';
import 'appearance_screen.dart';
import '../../core/widgets/stitch_background.dart';
import '../../core/widgets/player_avatar.dart';
import '../ladder/ladder_state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/telegram_notification_service.dart';
import '../auth/current_user_notifier.dart';
import '../auth/login_screen.dart';
import '../../core/services/app_update_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/master_control_screen.dart';
import '../events/squad_common_space_screen.dart';
import '../attendance/mark_attendance_screen.dart';

/// Screen 10: More Screen Matching Reference Mockup & Stitch Settings
class MoreMenuScreen extends ConsumerWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final myRank = ref
        .watch(ladderStandingsProvider)
        .valueOrNull
        ?.where((entry) => entry.playerId == currentUser.id)
        .firstOrNull
        ?.rank;
    return StitchAppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Club & account',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // Current User Profile Tile
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerProfileScreen(player: currentUser),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    PlayerAvatar(
                        name: currentUser.fullName,
                        url: currentUser.avatarUrl,
                        size: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textWhite,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text(
                                'Member',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•',
                                  style: TextStyle(color: AppTheme.textMuted)),
                              const SizedBox(width: 8),
                              Text(
                                myRank == null
                                    ? 'Club member'
                                    : 'Rank #$myRank',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryBright,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Navigation Menu Items Group
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                children: [
                  if (currentUser.isMasterAdmin) ...[
                    _buildMenuItem(
                      context,
                      Icons.stars_rounded,
                      'Master Control Hub',
                      'Squad accounts, APK releases & master overrides',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MasterControlScreen())),
                    ),
                    const Divider(color: AppTheme.borderDark, height: 1),
                  ],
                  _buildMenuItem(
                    context,
                    Icons.forum_outlined,
                    'Squad Common Space & Chat',
                    'Practice sessions, events RSVP & chat room',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SquadCommonSpaceScreen())),
                  ),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  _buildMenuItem(
                    context,
                    Icons.how_to_reg_outlined,
                    'Manual Squad Attendance',
                    'Captain roll call & attendance history',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MarkAttendanceScreen())),
                  ),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  _buildMenuItem(
                      context,
                      Icons.timer_outlined,
                      'Training lab',
                      'Guided drills and your workout history',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TrainingScreen()))),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  _buildMenuItem(
                      context,
                      Icons.tune_rounded,
                      'Look & feel',
                      'Film grain and motion preferences',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AppearanceScreen()))),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  _buildMenuItem(
                    context,
                    Icons.military_tech_outlined,
                    'Club Ladder',
                    'Track your ranking journey',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LadderScreen())),
                  ),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  _buildMenuItem(
                    context,
                    Icons.history,
                    'Match History',
                    'View past matches',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MatchDetailsScreen())),
                  ),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  _buildMenuItem(
                    context,
                    Icons.sports_tennis,
                    'Gear Logs',
                    'Rackets, strings, etc.',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GearTrackerScreen())),
                  ),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  _buildMenuItem(
                    context,
                    Icons.style_outlined,
                    '3D Trump Cards',
                    'Collect and inspect squad cards',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TrumpCardShowcaseScreen())),
                  ),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  _buildMenuItem(
                    context,
                    Icons.campaign_outlined,
                    'Club Announcements',
                    'Stay updated',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Next Inter-Department Friendly this Saturday!')),
                      );
                    },
                  ),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  _buildMenuItem(
                    context,
                    Icons.send_outlined,
                    'Telegram Alerts',
                    'Broadcast bot & webhook',
                    () => _showTelegramDialog(context),
                  ),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  _buildMenuItem(
                    context,
                    Icons.cloud_sync_outlined,
                    'Supabase & Cloud Sync',
                    'Configure database connection',
                    () => SupabaseConnectDialog.show(context),
                  ),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  _buildMenuItem(
                    context,
                    Icons.system_update_alt_rounded,
                    'Check for APK Updates',
                    'v1.0.0 · Get latest release or download new build',
                    () => AppUpdateService.checkForUpdates(
                      context,
                      Supabase.instance.client,
                      isManualCheck: true,
                    ),
                  ),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  _buildMenuItem(
                    context,
                    Icons.info_outline,
                    'About SmashDeck',
                    'v1.0.0 · Collegiate Badminton Club',
                    () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'SmashDeck',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            'Crafted for our 20-player College Badminton Club',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Motivational Banner Card Matching Mockup
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0D251A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF194C35)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"Good players inspire themselves. Great players inspire others."',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF86EFAC),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— SmashDeck',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBright,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sign Out
            _buildSignOutTile(context, ref),
            const SizedBox(height: 36),
          ],
        ),
      ),
    ));
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textMuted, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textMutedDark, size: 18),
          ],
        ),
      ),
    );
  }

  void _showTelegramDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderDark),
        ),
        title: const Row(
          children: [
            Icon(Icons.send_rounded, color: AppTheme.secondaryCyan, size: 24),
            SizedBox(width: 10),
            Text(
              'Telegram Bot Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      color: AppTheme.primaryNeon, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'ZERO-BUDGET WEBHOOK ACTIVE',
                    style: TextStyle(
                      color: AppTheme.primaryNeon,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Automated alerts are broadcasted to your club channel:',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 10),
            _buildAlertBullet('Match Results & Elo Deltas (+-16 PTS)'),
            _buildAlertBullet('King of the Court Ladder Challenges'),
            _buildAlertBullet('Practice Schedule & Dynamic QR Reminders'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryCyan,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.notifications_active, size: 16),
            label: const Text(
              'Send Test Ping',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await TelegramNotificationService.testWebhookPing();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.cardDark,
                    content: Text(
                      'Telegram webhook ping broadcasted successfully.',
                      style: TextStyle(
                          color: AppTheme.secondaryCyan,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  color: AppTheme.secondaryCyan, fontWeight: FontWeight.w900)),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 12, color: Colors.white70))),
        ],
      ),
    );
  }

  /// Sign Out tile — added at the bottom of the More screen
  Widget _buildSignOutTile(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B1111)),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded,
            color: Color(0xFFF87171), size: 22),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF87171),
          ),
        ),
        subtitle: const Text(
          'You will need to sign in again',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.cardDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Sign Out',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              content: const Text(
                'Are you sure you want to sign out of SmashDeck?',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F1D1D),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await ref.read(currentUserProvider.notifier).signOut();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        },
      ),
    );
  }
}
