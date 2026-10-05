import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_avatars.dart';
import '../auth/auth_state.dart';
import '../auth/current_user_notifier.dart';
import 'attendance_repository.dart';

/// Screen: Manual Squad Attendance (Captain & Master Admin Tool)
/// Replaces QR scanning with quick-tap roster roll & direct database sync.
class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  ConsumerState<MarkAttendanceScreen> createState() =>
      _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  final Set<String> _presentPlayerIds = {};
  DateTime _attendanceDate = DateTime.now();
  String _searchQuery = '';
  bool _isSaving = false;
  bool _initializedWithDefaults = false;

  void _togglePlayer(String id) {
    setState(() {
      if (_presentPlayerIds.contains(id)) {
        _presentPlayerIds.remove(id);
      } else {
        _presentPlayerIds.add(id);
      }
    });
  }

  void _selectAll(List<PlayerProfile> players) {
    setState(() {
      _presentPlayerIds.addAll(players.map((p) => p.id));
    });
  }

  void _clearAll() {
    setState(() {
      _presentPlayerIds.clear();
    });
  }

  Future<void> _submitAttendance() async {
    if (_presentPlayerIds.isEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text('No Players Selected',
              style: TextStyle(color: AppTheme.textWhite)),
          content: const Text(
            'Are you sure you want to submit zero attendance for this date?',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit Zero',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final count = await repo.markBulkAttendance(
        playerIds: _presentPlayerIds.toList(),
        sessionDate: _attendanceDate,
      );
      ref.invalidate(todayAttendanceRecordsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.limeNeon, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Marked attendance for $count players on ${DateFormat('EEE, MMM d').format(_attendanceDate)}!',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F3E28),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save attendance: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(allPlayersProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Manual Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              user?.isCaptain == true ? 'Captain Roll Call' : 'Squad Roll Call',
              style: const TextStyle(fontSize: 11, color: AppTheme.limeNeon),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: playersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.limeNeon),
        ),
        error: (e, _) => Center(
          child: Text('Error loading squad: $e',
              style: const TextStyle(color: Colors.white70)),
        ),
        data: (players) {
          // Pre-select some players initially if first load
          if (!_initializedWithDefaults && _presentPlayerIds.isEmpty) {
            _initializedWithDefaults = true;
            _presentPlayerIds.addAll(
                players.take(8).map((p) => p.id)); // Default sensible set
          }

          final filteredPlayers = players.where((p) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return p.fullName.toLowerCase().contains(q) ||
                p.rollNumber.toLowerCase().contains(q);
          }).toList();

          final total = players.length;
          final presentCount = _presentPlayerIds.length;
          final pct = total > 0 ? ((presentCount / total) * 100).round() : 0;

          return Column(
            children: [
              // Date Selector Header Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _attendanceDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2027),
                    );
                    if (d != null) setState(() => _attendanceDate = d);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppTheme.limeNeon, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy')
                                    .format(_attendanceDate),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              const Text(
                                'Tap to change session date',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
              ),

              // Attendance Summary & Quick Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDarker,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$presentCount of $total Present ($pct%)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.limeNeon,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${total - presentCount} Absent',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Quick buttons
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          backgroundColor:
                              AppTheme.limeNeon.withValues(alpha: 0.15),
                        ),
                        icon: const Icon(Icons.done_all,
                            size: 16, color: AppTheme.limeNeon),
                        label: const Text('All',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.limeNeon)),
                        onPressed: () => _selectAll(players),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                        ),
                        icon: const Icon(Icons.clear,
                            size: 16, color: AppTheme.textMuted),
                        label: const Text('None',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMuted)),
                        onPressed: _clearAll,
                      ),
                    ],
                  ),
                ),
              ),

              // Search Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search player by name or roll ID...',
                    hintStyle:
                        const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: AppTheme.textMuted, size: 20),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderDark),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderDark),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // Player Roster Checklist
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: filteredPlayers.length,
                  itemBuilder: (context, index) {
                    final p = filteredPlayers[index];
                    final isChecked = _presentPlayerIds.contains(p.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isChecked
                            ? const Color(0xFF0F2B1D)
                            : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isChecked
                              ? AppTheme.limeNeon.withValues(alpha: 0.4)
                              : AppTheme.borderDark,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _togglePlayer(p.id),
                        leading: Stack(
                          children: [
                            AppAvatars.buildAvatar(
                              rollNumber: p.rollNumber,
                              size: 42,
                              border: Border.all(
                                color: isChecked
                                    ? AppTheme.limeNeon
                                    : AppTheme.borderDark,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            if (p.isCaptain || p.isMasterAdmin)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    p.isMasterAdmin
                                        ? Icons.stars_rounded
                                        : Icons.military_tech_rounded,
                                    color: p.isMasterAdmin
                                        ? AppTheme.gold
                                        : AppTheme.limeNeon,
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.fullName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isChecked
                                      ? AppTheme.textWhite
                                      : AppTheme.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (p.isMasterAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.gold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'MASTER',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.gold),
                                ),
                              )
                            else if (p.isCaptain)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.limeNeon.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CAPTAIN',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.limeNeon),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${p.rollNumber} • ${p.playstyle} • ELO ${p.eloRating}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        trailing: Checkbox(
                          value: isChecked,
                          activeColor: AppTheme.limeNeon,
                          checkColor: Colors.black,
                          side: const BorderSide(
                              color: AppTheme.textMuted, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (_) => _togglePlayer(p.id),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Submit Attendance Button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: AppTheme.cardDarker,
                  border: Border(top: BorderSide(color: AppTheme.borderDark)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.limeNeon,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSaving ? null : _submitAttendance,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            'Save & Submit Attendance ($presentCount Present)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
