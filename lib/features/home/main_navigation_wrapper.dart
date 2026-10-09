import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_motion.dart';
import '../../core/widgets/stitch_background.dart';
import '../../core/widgets/sync_coordinator.dart';
import 'club_hub_screen.dart';
import '../../core/widgets/glass_panel.dart';
import '../ladder/ladder_screen.dart';
import '../matches/matches_hub_screen.dart';
import '../match_engine/match_setup_dialog.dart';
import '../trump_card/trump_card_view.dart';
import '../more/more_menu_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/app_update_service.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});
  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _movingForward = true;
  bool _openingUmpire = false;
  final Set<int> _visited = {0};
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: AppMotion.duration,
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Widget tests and embedded previews can render the shell without
        // bootstrapping Supabase. The production app always initializes it,
        // but an unavailable client should not make navigation unusable.
        try {
          final client = Supabase.instance.client;
          AppUpdateService.checkForUpdates(context, client);
        } catch (_) {
          // Update checks are non-critical UI enhancement work.
        }
      }
    });
  }

  static const _screens = <Widget>[
    LadderScreen(),
    MatchesHubScreen(),
    SizedBox.shrink(),
    TrumpCardShowcaseScreen(),
    ClubHubScreen(),
  ];
  static const _labels = ['Ladder', 'Matches', 'Umpire', 'My card', 'Club'];
  static const _icons = [
    Icons.leaderboard_outlined,
    Icons.sports_tennis,
    Icons.add,
    Icons.style_outlined,
    Icons.grid_view_rounded
  ];

  @override
  void dispose() {
    _transition.dispose();
    super.dispose();
  }

  Future<void> _select(int value) async {
    if (value == 2) {
      if (_openingUmpire) return;
      _openingUmpire = true;
      try {
        await MatchSetupDialog.show(context);
      } finally {
        _openingUmpire = false;
      }
      return;
    }
    if (_index == value) return;
    HapticFeedback.selectionClick();
    setState(() {
      _movingForward = value > _index;
      _index = value;
      _visited.add(value);
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _transition.value = 1;
    } else {
      _transition.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final animation = _transition.drive(CurveTween(curve: AppMotion.curve));
    final content = FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(Tween(
            begin: Offset(_movingForward ? .025 : -.025, 0), end: Offset.zero)),
        child: IndexedStack(
          index: _index,
          children: List.generate(
              _screens.length,
              (i) => TickerMode(
                    enabled: i == _index,
                    child: _visited.contains(i)
                        ? RepaintBoundary(child: _screens[i])
                        : const SizedBox.shrink(),
                  )),
        ),
      ),
    );
    return SyncCoordinator(
        child: Scaffold(
      extendBody: false,
      body: StitchAppBackground(
          child: Row(children: [
        if (wide) _rail(),
        Expanded(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: content,
        ))),
      ])),
      bottomNavigationBar: wide ? null : _bottomBar(),
    ));
  }

  Widget _rail() => Container(
        width: 216 +
            (MediaQuery.textScalerOf(context).scale(14) - 14)
                .clamp(0, 72)
                .toDouble(),
        decoration: const BoxDecoration(
            color: AppTheme.bgDarker,
            border: Border(right: BorderSide(color: AppTheme.borderDark))),
        child: SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ListView(children: [
            const Icon(Icons.sports_tennis_rounded,
                color: AppTheme.limeNeon, size: 28),
            const SizedBox(height: 14),
            Text('SMASHDECK',
                textAlign: TextAlign.center,
                style: AppTheme.chivo(size: 19, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Your court. Your club.',
                textAlign: TextAlign.center,
                style:
                    AppTheme.spaceGrotesk(size: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 32),
            ...List.generate(
                5,
                (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _navItem(i, horizontal: true),
                    )),
            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MoreMenuScreen())),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Club & account'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textMuted,
                minimumSize: const Size(48, 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ]),
        )),
      );

  Widget _bottomBar() => SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: GlassPanel(
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(11) / 11;
            final itemWidth = math.max(
              constraints.maxWidth / _labels.length,
              textScale > 1.2 ? 64 * textScale : 56.0,
            );
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var i = 0; i < _labels.length; i++)
                  SizedBox(width: itemWidth, child: _navItem(i)),
              ]),
            );
          }),
        ),
      );

  Widget _navItem(int i, {bool horizontal = false}) {
    final selected = _index == i;
    final umpire = i == 2;
    final color = umpire
        ? AppTheme.bgDarker
        : selected
            ? AppTheme.limeNeon
            : AppTheme.textMuted;
    final icon = Icon(_icons[i], size: 22, color: color);
    final label = Text(_labels[i],
        textAlign: horizontal ? TextAlign.start : TextAlign.center,
        style: AppTheme.spaceGrotesk(
            size: horizontal ? 14 : 11,
            height: 1.25,
            weight: selected || umpire ? FontWeight.w700 : FontWeight.w500,
            color: color));
    return Semantics(
      selected: selected,
      button: true,
      label: umpire ? 'Start live umpire' : _labels[i],
      excludeSemantics: true,
      onTap: () => _select(i),
      child: PressScale(
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _select(i),
                child: AnimatedContainer(
                  duration: AppMotion.durationOf(context),
                  curve: AppMotion.curve,
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontal ? 12 : 4, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: selected
                            ? AppTheme.limeNeon.withValues(alpha: .22)
                            : Colors.transparent),
                    color: umpire
                        ? AppTheme.limeNeon
                        : selected
                            ? AppTheme.limeNeon.withValues(alpha: .07)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: horizontal
                      ? Row(children: [
                          icon,
                          const SizedBox(width: 12),
                          Expanded(child: label),
                        ])
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [icon, const SizedBox(height: 4), label]),
                ),
              ))),
    );
  }
}
