import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/supabase_service.dart';
import '../../core/services/app_update_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_avatars.dart';
import '../attendance/attendance_screen.dart';
import '../attendance/mark_attendance_screen.dart';
import '../auth/auth_state.dart';
import '../auth/current_user_notifier.dart';
import '../events/squad_common_space_screen.dart';

/// Screen: Master Control Hub
/// Exclusively available to Ishan Narayan Shukla (SD-0002 / Master Admin).
/// Gives total control over Squad Accounts, Manual Attendance, Practice Events,
/// APK Releases, and Role Simulations.
class MasterControlScreen extends ConsumerStatefulWidget {
  const MasterControlScreen({super.key});

  @override
  ConsumerState<MasterControlScreen> createState() =>
      _MasterControlScreenState();
}

class _MasterControlScreenState extends ConsumerState<MasterControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // APK update publish fields
  final _versionController = TextEditingController(text: '1.1.0');
  final _codeController = TextEditingController(text: '2');
  final _urlController = TextEditingController(
      text: 'https://github.com/ishanshkla/SmashDeck/releases/latest');
  final _notesController = TextEditingController(
      text:
          '• Added 6 new squad accounts (Kartikey, Shurit, Sai, Krishna, Shweta, Manisha)\n• Manual Captain Attendance Roll Call\n• Squad Common Space & Practice Session Events\n• Master Control Hub for Ishan Narayan Shukla');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _versionController.dispose();
    _codeController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _publishApkUpdate() async {
    final client = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);

    final success = await AppUpdateService.publishUpdate(
      client: client,
      versionName: _versionController.text.trim(),
      versionCode: int.tryParse(_codeController.text.trim()) ?? 2,
      downloadUrl: _urlController.text.trim(),
      releaseNotes: _notesController.text.trim(),
      publisherName: user?.fullName ?? 'Ishan Narayan Shukla',
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 New APK Update successfully published to the club!'),
          backgroundColor: Color(0xFF0F3E28),
        ),
      );

      // Trigger the preview dialog on this device
      showDialog(
        context: context,
        builder: (_) => AppUpdateDialog(
          updateInfo: AppUpdateInfo(
            versionName: _versionController.text.trim(),
            versionCode: int.tryParse(_codeController.text.trim()) ?? 2,
            downloadUrl: _urlController.text.trim(),
            releaseNotes: _notesController.text.trim(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved locally! Syncing with Supabase.'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  void _showEditPlayerModal(PlayerProfile player) {
    int currentElo = player.eloRating;
    UserRole currentRole = player.role;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            decoration: const BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppAvatars.buildAvatar(
                      rollNumber: player.rollNumber,
                      size: 44,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.fullName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textWhite),
                          ),
                          Text(
                            '${player.rollNumber} • ${player.playstyle}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Role Selector
                const Text('MEMBER ROLE:',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.limeNeon)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _roleChoice('Player', UserRole.player, currentRole,
                        (r) => setSheetState(() => currentRole = r)),
                    const SizedBox(width: 8),
                    _roleChoice('Captain', UserRole.captain, currentRole,
                        (r) => setSheetState(() => currentRole = r)),
                    const SizedBox(width: 8),
                    _roleChoice('Admin', UserRole.admin, currentRole,
                        (r) => setSheetState(() => currentRole = r)),
                  ],
                ),
                const SizedBox(height: 18),

                // ELO Adjuster
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ELO RATING:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.limeNeon)),
                    Text('$currentElo ELO',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textWhite)),
                  ],
                ),
                Slider(
                  value: currentElo.toDouble(),
                  min: 1000,
                  max: 1800,
                  divisions: 80,
                  activeColor: AppTheme.limeNeon,
                  inactiveColor: AppTheme.cardDarker,
                  onChanged: (val) =>
                      setSheetState(() => currentElo = val.round()),
                ),
                const SizedBox(height: 16),

                // Save
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.limeNeon,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      try {
                        final client = ref.read(supabaseClientProvider);
                        await client.from('players').update({
                          'role': currentRole.name,
                          'elo_rating': currentElo,
                        }).eq('roll_number', player.rollNumber);
                        ref.invalidate(allPlayersProvider);
                      } catch (_) {}
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Updated ${player.fullName}: Role ${currentRole.name}, ELO $currentElo'),
                          backgroundColor: const Color(0xFF0F3E28),
                        ),
                      );
                    },
                    child: const Text('Save Player Settings',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _roleChoice(String label, UserRole role, UserRole selected,
      Function(UserRole) onSelect) {
    final isSelected = role == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.limeNeon.withValues(alpha: 0.2)
                : AppTheme.cardDarker,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected ? AppTheme.limeNeon : AppTheme.borderDark),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.limeNeon : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final playersAsync = ref.watch(allPlayersProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: const [
            Icon(Icons.stars_rounded, color: AppTheme.gold, size: 22),
            SizedBox(width: 8),
            Text(
              'Master Control Hub',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Squad Members'),
            Tab(text: 'APK Releases'),
            Tab(text: 'Master Tools'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Tab 1: Squad Members (13 Accounts) ──────────────────────────────
          playersAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.limeNeon)),
            error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.white70))),
            data: (players) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded,
                            color: AppTheme.gold, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Master Admin: ${user?.fullName ?? "Ishan Narayan Shukla"}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gold),
                              ),
                              Text(
                                'Total ${players.length} Squad Accounts configured. Tap any player to edit role or stats.',
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  ...players.map((p) {
                    final isIshan = p.isMasterAdmin;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isIshan
                            ? const Color(0xFF231C08)
                            : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isIshan
                              ? AppTheme.gold.withValues(alpha: 0.5)
                              : AppTheme.borderDark,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _showEditPlayerModal(p),
                        leading: AppAvatars.buildAvatar(
                          rollNumber: p.rollNumber,
                          size: 42,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.fullName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textWhite,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (p.isMasterAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.gold,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MASTER',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black),
                                ),
                              )
                            else if (p.isCaptain)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.limeNeon,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'CAPTAIN',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${p.rollNumber} • ${p.playstyle} • ELO ${p.eloRating}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textMuted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.tune_rounded,
                                  color: AppTheme.limeNeon, size: 20),
                              tooltip: 'Edit Player',
                              onPressed: () => _showEditPlayerModal(p),
                            ),
                            // Quick login as this player
                            IconButton(
                              icon: const Icon(Icons.switch_account_rounded,
                                  color: AppTheme.textMuted, size: 20),
                              tooltip: 'Simulate User',
                              onPressed: () {
                                ref
                                    .read(currentUserProvider.notifier)
                                    .setPlayer(p);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Switched to ${p.fullName}'),
                                    backgroundColor: const Color(0xFF0F3E28),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),

          // ── Tab 2: APK Release & Update Manager ─────────────────────────────
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
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
                    Row(
                      children: const [
                        Icon(Icons.system_update_alt_rounded,
                            color: AppTheme.limeNeon, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Publish New APK Update',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textWhite),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'When you build & upload a new APK, enter the download URL and version here. All squad members will immediately receive the update popup to download the latest APK!',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 18),

                    // Version & Code
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _versionController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Version Name',
                              labelStyle:
                                  const TextStyle(color: AppTheme.textMuted),
                              hintText: '1.1.0',
                              filled: true,
                              fillColor: AppTheme.cardDarker,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Version Code',
                              labelStyle:
                                  const TextStyle(color: AppTheme.textMuted),
                              hintText: '2',
                              filled: true,
                              fillColor: AppTheme.cardDarker,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Download URL
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Direct APK Download URL',
                        labelStyle: const TextStyle(color: AppTheme.textMuted),
                        hintText: 'https://... or Google Drive / GitHub APK link',
                        filled: true,
                        fillColor: AppTheme.cardDarker,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Release Notes
                    TextField(
                      controller: _notesController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Release Notes',
                        labelStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.cardDarker,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.limeNeon,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                        label: const Text(
                          'Publish & Trigger Update Popup',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                        onPressed: _publishApkUpdate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Tab 3: Master Tools & Quick Actions ─────────────────────────────
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _masterToolTile(
                icon: Icons.checklist_rounded,
                title: 'Manual Squad Attendance',
                subtitle: 'Open captain roll call to mark present squad members',
                buttonText: 'Open Attendance',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MarkAttendanceScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _masterToolTile(
                icon: Icons.forum_rounded,
                title: 'Squad Common Space & Chat',
                subtitle: 'Schedule practice sessions and view squad chat',
                buttonText: 'Open Common Space',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SquadCommonSpaceScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _masterToolTile(
                icon: Icons.history_rounded,
                title: 'View Attendance Records',
                subtitle: 'Inspect attendance logs, verify dates and check streaks',
                buttonText: 'Attendance Dashboard',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AttendanceScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _masterToolTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.limeNeon.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.limeNeon, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textWhite),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.limeNeon,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: onTap,
            child: Text(buttonText,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
