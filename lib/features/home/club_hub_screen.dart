import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_motion.dart';
import '../../core/widgets/court_panel.dart';
import '../tournament/presentation/tournament_hub_screen.dart';
import '../court_queue/presentation/court_queue_screen.dart';
import '../doubles/presentation/doubles_hub_screen.dart';
import '../treasury/presentation/treasury_dashboard_screen.dart';
import '../gear_tracker/gear_screen.dart';
import '../training/training_screen.dart';
import '../more/more_menu_screen.dart';
import '../auth/current_user_notifier.dart';
import '../events/squad_common_space_screen.dart';
import '../attendance/attendance_screen.dart';
import '../admin/master_control_screen.dart';

class ClubHubScreen extends ConsumerWidget {
  const ClubHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isMaster = user?.isMasterAdmin ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('The clubhouse'), actions: [
        IconButton(
            tooltip: 'Club settings',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MoreMenuScreen())))
      ]),
      body: LayoutBuilder(
          builder: (context, constraints) => ListView(
                padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth > 1040
                        ? (constraints.maxWidth - 1000) / 2
                        : 20,
                    16,
                    constraints.maxWidth > 1040
                        ? (constraints.maxWidth - 1000) / 2
                        : 20,
                    40),
                children: [
                  Reveal(
                    child: CourtPanel(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ONE SQUAD. ENDLESS POSSIBILITIES.',
                              style: AppTheme.labelCaps
                                  .copyWith(color: AppTheme.limeNeon)),
                          const SizedBox(height: 14),
                          Text('More than\na match.',
                              style: AppTheme.chivo(
                                  size: constraints.maxWidth < 360 ? 34 : 42,
                                  weight: FontWeight.w900,
                                  letterSpacing: -1.5,
                                  height: 1.05)),
                          const SizedBox(height: 12),
                          Text(
                              'Build your duo. Chase a trophy. Keep your club moving.',
                              style: AppTheme.bodyLg
                                  .copyWith(color: AppTheme.textMuted))
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  LayoutBuilder(builder: (context, c) {
                    final columns = c.maxWidth > 700 &&
                            MediaQuery.textScalerOf(context).scale(14) < 24
                        ? 2
                        : 1;
                    final items = <(String, String, IconData, Widget)>[
                      if (isMaster)
                        (
                          'Master Control Hub',
                          'Squad accounts, APK releases & total root control',
                          Icons.stars_rounded,
                          const MasterControlScreen()
                        ),
                      (
                        'Squad Common Space',
                        'Practice sessions, events RSVP & squad chat room',
                        Icons.forum_outlined,
                        const SquadCommonSpaceScreen()
                      ),
                      (
                        'Manual Attendance',
                        'Captain roll call & daily squad records',
                        Icons.how_to_reg_outlined,
                        const AttendanceScreen()
                      ),
                      (
                        'Tournament arena',
                        'Knockouts, leagues & the road to the final',
                        Icons.emoji_events_outlined,
                        const TournamentHubScreen()
                      ),
                      (
                        'Court rotation',
                        'Fair matches. Full courts. Less waiting.',
                        Icons.grid_view_rounded,
                        const CourtQueueScreen()
                      ),
                      (
                        'Doubles studio',
                        'Find your chemistry. Build your duo card.',
                        Icons.people_alt_outlined,
                        const DoublesHubScreen()
                      ),
                      (
                        'Club treasury',
                        'Shuttle stock, dues & every rupee accounted for',
                        Icons.account_balance_wallet_outlined,
                        const TreasuryDashboardScreen()
                      ),
                      (
                        'Training lab',
                        'Guided intervals for your next breakthrough',
                        Icons.timer_outlined,
                        const TrainingScreen()
                      ),
                      (
                        'Gear & play',
                        'Look after your racket. Keep your edge.',
                        Icons.sports_tennis,
                        const GearTrackerScreen()
                      ),
                    ];

                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        for (final item in items) ...[
                          if (item.$1 == 'Master Control Hub' ||
                              item.$1 == 'Squad Common Space' ||
                              item.$1 == 'Tournament arena' ||
                              item.$1 == 'Club treasury')
                            SizedBox(
                              width: c.maxWidth,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    top: item == items.first ? 0 : 12,
                                    bottom: 2),
                                child: Text(
                                  switch (item.$1) {
                                    'Master Control Hub' => 'CLUB MANAGEMENT',
                                    'Squad Common Space' => 'YOUR SQUAD',
                                    'Tournament arena' => 'ON THE COURT',
                                    _ => 'BEYOND THE GAME',
                                  },
                                  style: AppTheme.labelCaps.copyWith(
                                      color: AppTheme.textMuted,
                                      letterSpacing: 1.6),
                                ),
                              ),
                            ),
                          SizedBox(
                            width: (c.maxWidth - (columns - 1) * 14) / columns,
                            child: PressScale(
                              child: Material(
                                color: AppTheme.cardDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: const BorderSide(
                                      color: AppTheme.borderDark),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => item.$4)),
                                  child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.cardMid,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(item.$3,
                                                    size: 22,
                                                    color: item.$1
                                                            .contains('Master')
                                                        ? AppTheme.gold
                                                        : AppTheme.limeNeon)),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.$1,
                                                      style: AppTheme.headlineMd
                                                          .copyWith(
                                                              fontSize: 16,
                                                              height: 1.3,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: item.$1
                                                                      .contains(
                                                                          'Master')
                                                                  ? AppTheme
                                                                      .gold
                                                                  : AppTheme
                                                                      .textWhite)),
                                                  const SizedBox(height: 6),
                                                  Text(item.$2,
                                                      style: AppTheme.bodyMd
                                                          .copyWith(
                                                              color: AppTheme
                                                                  .textMuted,
                                                              height: 1.5)),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(Icons.arrow_outward_rounded,
                                                size: 14,
                                                color:
                                                    item.$1.contains('Master')
                                                        ? AppTheme.gold
                                                        : AppTheme.textMuted),
                                          ])),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ],
              )),
    );
  }
}
