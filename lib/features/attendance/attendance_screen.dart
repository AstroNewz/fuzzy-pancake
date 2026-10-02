import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/data/mock_squad_data.dart';
import '../../core/network/offline_sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_state.dart';
import 'attendance_repository.dart';
import 'attendance_scanner_sheet.dart';
import 'attendance_state.dart';
import 'mark_attendance_screen.dart';

/// Dynamic QR Attendance Screen (Admin Generator + Player Scanner + Squad Roll)
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _countdownTimer;
  int _secondsLeft = 15;
  String _squadFilter = 'all'; // 'all', 'present', 'absent'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft <= 1) {
          _secondsLeft = 15;
          ref.read(adminAttendanceTokenProvider.notifier).refresh();
        } else {
          _secondsLeft--;
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
        backgroundColor: result.isSuccess ? AppTheme.primaryNeon : Colors.amber,
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
    final token = ref.watch(adminAttendanceTokenProvider);
    final squad = MockSquadData.players;
    final pendingCountAsync = ref.watch(pendingOfflineCountProvider);
    final todayLogsAsync = ref.watch(todayAttendanceRecordsProvider);

    final todayPresentPlayerIds =
        todayLogsAsync.value?.map((e) => e.playerId).toSet() ??
            {
              // Pre-seed sample active players if Supabase has zero rows
              'p-01', 'p-02', 'p-03', 'p-04', 'p-07', 'p-10', 'p-12', 'p-15'
            };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check,
                color: AppTheme.primaryBright),
            tooltip: 'Manual Roster Check',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync, color: AppTheme.secondaryCyan),
            tooltip: 'Sync Offline Data',
            onPressed: _triggerManualSync,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryNeon,
          labelColor: AppTheme.primaryNeon,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2), text: 'Dynamic QR (Admin)'),
            Tab(
                icon: Icon(Icons.people_alt_outlined),
                text: 'Squad Roll (Today)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Offline Pending Banner (if any)
          pendingCountAsync.when(
            data: (count) {
              if (count == 0) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.amber.withValues(alpha: 0.2),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_queue,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$count offline records pending sync to Supabase',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _triggerManualSync,
                      child: const Text('SYNC NOW',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Admin Dynamic QR Generator (Issue-003 Mitigation)
                _buildAdminQrTab(token),

                // Tab 2: Squad Roll & Check-in Verification
                _buildSquadRollTab(squad, todayPresentPlayerIds),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNeon,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text(
          'SCAN QR CODE',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        onPressed: () => AttendanceScannerSheet.show(context),
      ),
    );
  }

  Widget _buildAdminQrTab(AttendanceToken token) {
    final progress = _secondsLeft / 15.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Security Alert Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined,
                    color: AppTheme.primaryNeon, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anti-Proxy Verification Active (ISSUE-003)',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Dynamic cryptographic token auto-refreshes every 15s. Screenshots are invalid.',
                        style:
                            TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Dynamic QR Code Display Frame
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3300FF87),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: QrImageView(
              data: token.payload,
              version: QrVersions.auto,
              size: 210.0,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Circular 15s Countdown Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: AppTheme.borderDark,
                  color: _secondsLeft <= 3
                      ? AppTheme.errorRed
                      : AppTheme.primaryNeon,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Auto-Refreshing in $_secondsLeft seconds',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Token: ${token.totp} • Session Date: ${token.dateString}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),

          // Fast Action Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.borderDark),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.qr_code_scanner,
                      size: 18, color: AppTheme.primaryNeon),
                  label: const Text('OPEN SCANNER',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  onPressed: () => AttendanceScannerSheet.show(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('QUICK CHECK-IN',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  onPressed: () => _simulatePlayerScan(token),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50), // Room for FAB
        ],
      ),
    );
  }

  Widget _buildSquadRollTab(
      List<PlayerProfile> squad, Set<String> presentPlayerIds) {
    final presentCount =
        squad.where((p) => presentPlayerIds.contains(p.id)).length;
    final totalCount = squad.length;

    final filteredSquad = squad.where((p) {
      final isPresent = presentPlayerIds.contains(p.id);
      if (_squadFilter == 'present') return isPresent;
      if (_squadFilter == 'absent') return !isPresent;
      return true;
    }).toList();

    return Column(
      children: [
        // Summary Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.black26,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Present Today: $presentCount / $totalCount Players',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppTheme.primaryNeon,
                ),
              ),
              Text(
                '${((presentCount / totalCount) * 100).toStringAsFixed(0)}% Turnout',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppTheme.secondaryCyan,
                ),
              ),
            ],
          ),
        ),

        // Filter Chips Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('all', 'All ($totalCount)'),
              const SizedBox(width: 8),
              _buildFilterChip('present', 'Present ($presentCount)'),
              const SizedBox(width: 8),
              _buildFilterChip(
                  'absent', 'Absent (${totalCount - presentCount})'),
            ],
          ),
        ),

        // List of Squad Members
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filteredSquad.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final player = filteredSquad[index];
              final isPresent = presentPlayerIds.contains(player.id);

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isPresent
                        ? AppTheme.primaryNeon.withValues(alpha: 0.4)
                        : AppTheme.borderDark,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPresent
                            ? AppTheme.primaryNeon.withValues(alpha: 0.15)
                            : Colors.black26,
                        border: Border.all(
                          color: isPresent
                              ? AppTheme.primaryNeon
                              : AppTheme.borderDark,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          player.fullName
                              .split(' ')
                              .map((e) => e[0])
                              .take(2)
                              .join(),
                          style: TextStyle(
                            color: isPresent
                                ? AppTheme.primaryNeon
                                : AppTheme.textMuted,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.fullName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPresent
                            ? AppTheme.primaryNeon.withValues(alpha: 0.15)
                            : Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPresent ? 'PRESENT' : 'ABSENT',
                        style: TextStyle(
                          color: isPresent
                              ? AppTheme.primaryNeon
                              : AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _squadFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _squadFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryNeon.withValues(alpha: 0.2)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryNeon : AppTheme.borderDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppTheme.primaryNeon : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  void _simulatePlayerScan(AttendanceToken token) async {
    final repo = ref.read(attendanceRepositoryProvider);
    final squad = MockSquadData.players;

    // Pick first player
    final testPlayer = squad[1]; // Ishan Shukla
    final result = await repo.processQrCheckIn(
      playerId: testPlayer.id,
      qrPayload: token.payload,
    );

    ref.invalidate(todayAttendanceRecordsProvider);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              result.isSuccess ? Icons.check_circle : Icons.info_outline,
              color: result.isSuccess ? AppTheme.primaryNeon : Colors.amber,
            ),
            const SizedBox(width: 10),
            Text(result.isSuccess ? 'Check-in Verified!' : 'Check-in Notice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              testPlayer.fullName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Roll No: ${testPlayer.rollNumber}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              result.message,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
