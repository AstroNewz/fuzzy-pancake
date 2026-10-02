import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/mock_squad_data.dart';
import '../../core/theme/app_theme.dart';
import 'attendance_repository.dart';
import 'attendance_screen.dart';

/// Screen 8: Mark Attendance Screen Matching Reference Mockup & Stitch Attendance Pool
class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  ConsumerState<MarkAttendanceScreen> createState() =>
      _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  // Pre-checked set matching mockup
  final Set<String> _presentPlayerIds = {
    'p-01', // Arpit Verma
    'p-02', // Ishan Shukla
    'p-04', // Rohan Singh
    'p-06', // Aditya Raj
  };

  DateTime _attendanceDate = DateTime.now();

  void _togglePlayer(String id) {
    setState(() {
      if (_presentPlayerIds.contains(id)) {
        _presentPlayerIds.remove(id);
      } else {
        _presentPlayerIds.add(id);
      }
    });
  }

  Future<void> _submitAttendance() async {
    final repo = ref.read(attendanceRepositoryProvider);
    final count = await repo.markBulkAttendance(
      playerIds: _presentPlayerIds.toList(),
      sessionDate: _attendanceDate,
    );
    ref.invalidate(todayAttendanceRecordsProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attendance recorded for $count players! Synced to Supabase.',
        ),
        backgroundColor: const Color(0xFF0F5132),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final players = MockSquadData.players;

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
          'Mark Attendance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner,
                color: AppTheme.primaryBright),
            tooltip: 'Dynamic QR Scanner Engine',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AttendanceScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
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
                    const Icon(Icons.calendar_today_outlined,
                        color: AppTheme.primaryBright, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formattedDate(_attendanceDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down,
                        color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
          ),

          // Subtitle & Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select players who are present',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  '${_presentPlayerIds.length}/${players.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBright,
                  ),
                ),
              ],
            ),
          ),

          // Player Roster Checklist
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final p = players[index];
                final isChecked = _presentPlayerIds.contains(p.id);

                return InkWell(
                  onTap: () => _togglePlayer(p.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isChecked
                                  ? const Color(0xFF10B981)
                                  : AppTheme.borderDark,
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              p.avatarUrl ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF131D18),
                                alignment: Alignment.center,
                                child: Text(
                                  p.fullName.substring(0, 1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBright,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Player Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.fullName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isChecked
                                      ? AppTheme.textWhite
                                      : AppTheme.textMuted,
                                ),
                              ),
                              Text(
                                p.rollNumber,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMutedDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Checkbox (Square with rounded corners)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isChecked
                                ? const Color(0xFF10B981)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isChecked
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF4B5563),
                              width: 1.5,
                            ),
                          ),
                          child: isChecked
                              ? const Icon(Icons.check,
                                  color: Colors.black, size: 16)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Submit Attendance Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: const Color(0xFF0A122A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: const Color(0x6610B981),
                  ),
                  onPressed: _submitAttendance,
                  child: const Text(
                    'Submit Attendance',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formattedDate(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
