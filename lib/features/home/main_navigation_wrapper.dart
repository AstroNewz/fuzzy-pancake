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
      extendBody: true,
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
        width: 204,
        decoration: const BoxDecoration(
            color: AppTheme.bgDarker,
            border: Border(right: BorderSide(color: AppTheme.borderDark))),
        child: SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SMASHDECK',
                style: AppTheme.chivo(
                    size: 20,
                    weight: FontWeight.w900,
                    color: AppTheme.limeNeon)),
            const SizedBox(height: 6),
            Text('YOUR COURT. YOUR CLUB.',
                style:
                    AppTheme.jetBrainsMono(size: 9, color: AppTheme.textMuted)),
            const SizedBox(height: 40),
            ...List.generate(
                5,
                (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _navItem(i, horizontal: true),
                    )),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MoreMenuScreen())),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Club & account'),
            ),
          ]),
        )),
      );

  Widget _bottomBar() => Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: GlassPanel(
            radius: 24,
            child: SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children:
                        List.generate(5, (i) => Expanded(child: _navItem(i))),
                  )),
            )),
      );

  Widget _navItem(int i, {bool horizontal = false}) {
    final selected = _index == i;
    final umpire = i == 2;
    final color = umpire
        ? AppTheme.bgDarker
        : selected
            ? AppTheme.limeNeon
            : AppTheme.textMuted;
    final icon = AnimatedSlide(
        duration: AppMotion.durationOf(context),
        offset: selected ? const Offset(0, -.06) : Offset.zero,
        curve: Curves.easeOutBack,
        child: Icon(_icons[i], size: umpire ? 25 : 22, color: color));
    final label = Text(_labels[i],
        maxLines: 1,
        style: AppTheme.spaceGrotesk(
            size: horizontal ? 14 : 10, weight: FontWeight.w700, color: color));
    return Semantics(
      selected: selected,
      button: true,
      label: umpire ? 'Start live umpire' : _labels[i],
      child: PressScale(
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _select(i),
                child: AnimatedContainer(
                  duration: AppMotion.durationOf(context),
                  curve: AppMotion.curve,
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontal ? 14 : 4, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: selected
                            ? AppTheme.limeNeon.withValues(alpha: .18)
                            : Colors.transparent),
                    color: umpire
                        ? AppTheme.limeNeon
                        : selected
                            ? AppTheme.limeNeon.withValues(alpha: .09)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: horizontal
                      ? Row(children: [icon, const SizedBox(width: 12), label])
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [icon, const SizedBox(height: 4), label]),
                ),
              ))),
    );
  }
}
