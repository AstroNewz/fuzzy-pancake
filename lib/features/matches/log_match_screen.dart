import 'package:flutter/material.dart';
import '../../core/data/mock_squad_data.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_state.dart';

/// Screen 7: Log Match Screen Matching Reference Mockup & Stitch Fast Score Logger
class LogMatchScreen extends StatefulWidget {
  const LogMatchScreen({super.key});

  @override
  State<LogMatchScreen> createState() => _LogMatchScreenState();
}

class _LogMatchScreenState extends State<LogMatchScreen> {
  bool _isSingles = true;
  PlayerProfile? _selectedOpponent;
  DateTime _matchDate = DateTime.now();
  bool _isWon = true;
  final TextEditingController _notesController = TextEditingController();

  // Set scores list
  final List<Map<String, int>> _sets = [
    {'p1': 21, 'p2': 18},
    {'p1': 17, 'p2': 21},
    {'p1': 21, 'p2': 16},
  ];

  @override
  void initState() {
    super.initState();
    // Default opponent to Rohan Singh (#4) matching mockup
    _selectedOpponent = MockSquadData.players.length > 3
        ? MockSquadData.players[3]
        : MockSquadData.players.first;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addSet() {
    if (_sets.length < 5) {
      setState(() {
        _sets.add({'p1': 21, 'p2': 19});
      });
    }
  }

  void _saveMatch() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Match recorded vs ${_selectedOpponent?.fullName ?? "Opponent"}! (+15 Ladder Elo)',
        ),
        backgroundColor: const Color(0xFF0F5132),
      ),
    );
    Navigator.pop(context);
  }

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
          'Log Match',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Singles / Doubles Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.cardDarker,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSingles = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isSingles
                              ? const Color(0xFF0F5132)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Singles',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color:
                                _isSingles ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSingles = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isSingles
                              ? const Color(0xFF0F5132)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Doubles',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color:
                                !_isSingles ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Opponent Selector
            const Text(
              'Opponent',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PlayerProfile>(
                  value: _selectedOpponent,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardDark,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: AppTheme.textMuted),
                  items: MockSquadData.players.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        p.fullName,
                        style: const TextStyle(
                            color: AppTheme.textWhite, fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedOpponent = val),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Date Picker Field
            const Text(
              'Date',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _matchDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2027),
                );
                if (d != null) setState(() => _matchDate = d);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_matchDate.day} ${_monthName(_matchDate.month)} ${_matchDate.year}',
                      style: const TextStyle(
                          color: AppTheme.textWhite, fontSize: 14),
                    ),
                    const Icon(Icons.calendar_today_outlined,
                        color: AppTheme.textMuted, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Set Scores Row
            const Text(
              'Set Scores',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < _sets.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildSetScoreBox(i + 1, _sets[i]),
                    ),
                  if (_sets.length < 5)
                    GestureDetector(
                      onTap: _addSet,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add,
                                color: AppTheme.primaryBright, size: 20),
                            SizedBox(height: 4),
                            Text(
                              'Add Set',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBright,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Result Toggle (Won / Lost)
            const Text(
              'Result',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.cardDarker,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isWon = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isWon
                              ? const Color(0xFF0F5132)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Won',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isWon ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isWon = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isWon
                              ? const Color(0xFF6B1D2A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Lost',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: !_isWon ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notes Text Input
            const Text(
              'Notes (optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'E.g. Good game, close second set.',
                hintStyle: const TextStyle(
                    color: AppTheme.textMutedDark, fontSize: 13),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Save Match Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F5132),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFF10B981), width: 1),
                  ),
                ),
                onPressed: _saveMatch,
                child: const Text(
                  'Save Match',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSetScoreBox(int setNumber, Map<String, int> scores) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          Text(
            'Set $setNumber',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${scores['p1']} - ${scores['p2']}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
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
    return months[m - 1];
  }
}
