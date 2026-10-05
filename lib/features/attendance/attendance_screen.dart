import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/network/offline_sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_avatars.dart';
import '../auth/auth_state.dart';
import '../auth/current_user_notifier.dart';
import 'attendance_repository.dart';
import 'mark_attendance_screen.dart';

/// Screen: Squad Attendance Dashboard & History
/// Pure Manual Attendance engine for Captain & Master Admin.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _squadFilter = 'all'; // 'all', 'present', 'absent'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _triggerManualSync() async {
    final syncService = ref.read(offlineSyncServiceProvider);
    final result = await syncService.flushPendingData();

    if (!mounted) return;
    ref.invalidate(pendingOfflineCountProvider);
    ref.invalidate(todayAttendanceRecordsProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.isSuccess ? AppTheme.limeNeon : Colors.amber,
        content: Text(
          result.isSuccess
              ? 'Successfully synced ${result.totalSynced} records to Supabase!'
              : 'Synced ${result.totalSynced} items. Remaining offline: ${result.remainingPending}',
          style: TextStyle(
            color: result.isSuccess ? Colors.black : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isCaptainOrMaster = currentUser?.isCaptain ?? false;
    final playersAsync = ref.watch(allPlayersProvider);
    final pendingCountAsync = ref.watch(pendingOfflineCountProvider);
    final todayLogsAsync = ref.watch(todayAttendanceRecordsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Squad Attendance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppTheme.limeNeon),
            tooltip: 'Sync Offline Data',
            onPressed: _triggerManualSync,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.limeNeon,
          labelColor: AppTheme.limeNeon,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: "Today's Roster"),
            Tab(text: 'History & Logs'),
          ],
        ),
      ),
      body: playersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.limeNeon)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.white70))),
        data: (squad) {
          final todayLogs = todayLogsAsync.value ?? [];
          final todayPresentSet =
              todayLogs.map((e) => e.playerId.toLowerCase()).toSet();

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Today's Squad Roster
              _buildTodayRosterTab(
                context,
                squad,
                todayPresentSet,
                isCaptainOrMaster,
                pendingCountAsync.value ?? 0,
              ),

              // Tab 2: Attendance Records & History
              _buildHistoryTab(todayLogs, squad),
            ],
          );
        },
      ),
      floatingActionButton: isCaptainOrMaster
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.limeNeon,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.playlist_add_check_rounded, size: 22),
              label: const Text(
                'Take Attendance',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MarkAttendanceScreen()),
                );
              },
            )
          : null,
    );
  }

  Widget _buildTodayRosterTab(
    BuildContext context,
    List<PlayerProfile> squad,
    Set<String> todayPresentSet,
    bool isCaptainOrMaster,
    int pendingCount,
  ) {
    // Filter squad
    final filteredSquad = squad.where((p) {
      final isPresent = todayPresentSet.contains(p.id.toLowerCase()) ||
          todayPresentSet.contains(p.rollNumber.toLowerCase());
      if (_squadFilter == 'present') return isPresent;
      if (_squadFilter == 'absent') return !isPresent;
      return true;
    }).toList();

    final presentCount = squad.where((p) {
      return todayPresentSet.contains(p.id.toLowerCase()) ||
          todayPresentSet.contains(p.rollNumber.toLowerCase());
    }).length;

    final todayFormatted =
        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        // Date Banner
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
                children: [
                  const Icon(Icons.event_available_rounded,
                      color: AppTheme.limeNeon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    todayFormatted,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const Spacer(),
                  if (pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$pendingCount Offline',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$presentCount / ${squad.length} Present',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.limeNeon,
                        ),
                      ),
                      Text(
                        '${squad.length - presentCount} members absent',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (isCaptainOrMaster)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.limeNeon,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text(
                        'Manual Roll',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MarkAttendanceScreen()),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Filter Pills
        Row(
          children: [
            _buildFilterChip('All Squad (${squad.length})', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Present ($presentCount)', 'present'),
            const SizedBox(width: 8),
            _buildFilterChip(
                'Absent (${squad.length - presentCount})', 'absent'),
          ],
        ),

        const SizedBox(height: 12),

        // Squad Roster List
        ...filteredSquad.map((player) {
          final isPresent = todayPresentSet.contains(player.id.toLowerCase()) ||
              todayPresentSet.contains(player.rollNumber.toLowerCase());

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isPresent
                  ? const Color(0xFF0D251A)
                  : AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPresent
                    ? AppTheme.limeNeon.withValues(alpha: 0.3)
                    : AppTheme.borderDark,
              ),
            ),
            child: Row(
              children: [
                AppAvatars.buildAvatar(
                  rollNumber: player.rollNumber,
                  size: 40,
                  border: Border.all(
                    color: isPresent ? AppTheme.limeNeon : AppTheme.borderDark,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              player.fullName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isPresent
                                    ? AppTheme.textWhite
                                    : AppTheme.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (player.isMasterAdmin) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.stars_rounded,
                                size: 14, color: AppTheme.gold),
                          ] else if (player.isCaptain) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.military_tech_rounded,
                                size: 14, color: AppTheme.limeNeon),
                          ],
                        ],
                      ),
                      Text(
                        '${player.rollNumber} • ${player.playstyle}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPresent
                        ? AppTheme.limeNeon.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPresent
                          ? AppTheme.limeNeon.withValues(alpha: 0.4)
                          : AppTheme.borderDark,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPresent
                            ? Icons.check_circle_rounded
                            : Icons.cancel_outlined,
                        size: 14,
                        color: isPresent
                            ? AppTheme.limeNeon
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isPresent ? 'PRESENT' : 'ABSENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isPresent
                              ? AppTheme.limeNeon
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _squadFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _squadFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.limeNeon.withValues(alpha: 0.2)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.limeNeon : AppTheme.borderDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? AppTheme.limeNeon : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(
      List<AttendanceRecord> logs, List<PlayerProfile> squad) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded,
                size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No attendance logs recorded yet today.',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "Take Attendance" to mark present squad members.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMutedDark),
            ),
          ],
        ),
      );
    }

    final playerMap = {for (var p in squad) p.id: p};

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final record = logs[index];
        final p = playerMap[record.playerId];
        final timeStr = DateFormat('hh:mm a').format(record.checkInTime);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: AppTheme.limeNeon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p?.fullName ?? record.playerId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    Text(
                      'Session ${record.sessionDate} • Checked in at $timeStr',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.limeNeon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MANUAL',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.limeNeon),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
