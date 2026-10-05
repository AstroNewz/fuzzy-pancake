import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_avatars.dart';
import '../../core/theme/card_theme.dart';
import '../auth/auth_state.dart';
import '../auth/current_user_notifier.dart';
import '../auth/login_screen.dart';
import '../gear_tracker/gear_model.dart';
import '../trump_card/trump_card_model.dart';
import '../trump_card/trump_card_view.dart';
import '../attendance/mark_attendance_screen.dart';
import '../events/squad_common_space_screen.dart';
import '../admin/master_control_screen.dart';

/// MY CARD tab — Stitch FIFA-style player card
/// Shows: giant OVR, 6-stat grid, gear status, season record, rival showdown
class PlayerProfileScreen extends ConsumerStatefulWidget {
  final PlayerProfile? player;
  const PlayerProfileScreen({super.key, this.player});

  @override
  ConsumerState<PlayerProfileScreen> createState() =>
      _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  int _computeOvr(double elo) =>
      ((elo - 1000) / 800 * 44 + 55).clamp(55, 99).round();

  @override
  Widget build(BuildContext context) {
    final activeUser = ref.watch(currentUserProvider);

    if (activeUser == null && widget.player == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body:
            Center(child: CircularProgressIndicator(color: AppTheme.limeNeon)),
      );
    }

    final p = widget.player ?? activeUser!;
    final ovr = _computeOvr(p.eloRating.toDouble());
    final isMyCard = widget.player == null;

    // Simulated stats from ELO
    final smash = (ovr * 0.98).round().clamp(60, 99);
    final defense = (ovr * 0.88).round().clamp(55, 99);
    final net = (ovr * 0.95).round().clamp(60, 99);
    final speed = (ovr * 0.91).round().clamp(58, 99);
    final stamina = (ovr * 0.87).round().clamp(55, 99);
    final tactic = (ovr * 0.93).round().clamp(58, 99);

    final gearAsync = ref.watch(playerGearLogsProvider(p.id));
    final currentGear = gearAsync.asData?.value.isNotEmpty == true
        ? gearAsync.asData!.value.first
        : null;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.bgDark,
            pinned: true,
            elevation: 0,
            leading:
                isMyCard ? null : const BackButton(color: AppTheme.textWhite),
            title: _buildAppBarTitle(p),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardMid,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      '$ovr OVR',
                      style: AppTheme.jetBrainsMono(
                          size: 11, color: AppTheme.limeNeon),
                    ),
                  ],
                ),
              ),
              if (isMyCard)
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: AppTheme.errorRed, size: 20),
                  tooltip: 'Log Out',
                  onPressed: () => _showLogoutDialog(context, ref),
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Rank Badge ────────────────────────────────────────────────
                _buildRankBadge(),

                // ── FIFA Card Hero ────────────────────────────────────────────
                _buildFifaCard(
                    p, ovr, smash, defense, net, speed, stamina, tactic),

                // ── Share Button ──────────────────────────────────────────────
                _buildShareButton(),

                // ── Master Admin Hub (Ishan Narayan Shukla) ───────────────────
                if (p.isMasterAdmin || (activeUser?.isMasterAdmin ?? false))
                  _buildMasterHubBanner(context),

                // ── Captain Tools: Manual Attendance & Sessions ───────────────
                if (p.isCaptain || (activeUser?.isCaptain ?? false))
                  _buildCaptainToolsCard(context, p),

                // ── Gear Status ───────────────────────────────────────────────
                _buildGearStatus(currentGear),

                // ── Season Record ─────────────────────────────────────────────
                _buildSeasonRecord(p, ovr),

                // ── Rival Showdown ────────────────────────────────────────────
                _buildRivalShowdown(p),

                // ── Point Winning Weaponry ────────────────────────────────────
                _buildWeaponrySection(smash, net, tactic),

                // ── Log Out Button (Only for own profile) ──────────────────────
                if (isMyCard)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                          side: BorderSide(
                              color: AppTheme.errorRed.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.logout_rounded,
                            size: 18, color: AppTheme.errorRed),
                        label: Text(
                          'LOG OUT OF SMASHDECK',
                          style: AppTheme.jetBrainsMono(
                            size: 12,
                            weight: FontWeight.w800,
                            color: AppTheme.errorRed,
                            letterSpacing: 0.5,
                          ),
                        ),
                        onPressed: () => _showLogoutDialog(context, ref),
                      ),
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(PlayerProfile p) {
    return Row(
      children: [
        const Icon(Icons.sports_tennis, size: 18, color: AppTheme.limeNeon),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: 'Smash',
                    style: GoogleFonts.chivo(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textWhite)),
                TextSpan(
                    text: 'Deck',
                    style: GoogleFonts.chivo(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.limeNeon)),
              ]),
            ),
            Text('Smash Club • Squad',
                style:
                    AppTheme.jetBrainsMono(size: 8, color: AppTheme.textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildRankBadge() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardMid,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_outlined,
              size: 14, color: AppTheme.gold),
          const SizedBox(width: 6),
          Text('CLUB RANK #— • GOLD APEX TIER',
              style: AppTheme.jetBrainsMono(
                  size: 10, color: AppTheme.textMuted, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildFifaCard(
    PlayerProfile p,
    int ovr,
    int smash,
    int defense,
    int net,
    int speed,
    int stamina,
    int tactic,
  ) {
    final cardModel = TrumpCardModel(
      playerId: p.id,
      rollNumber: p.rollNumber,
      fullName: p.fullName,
      avatarUrl: AppAvatars.getAvatarForRoll(p.rollNumber),
      playstyle: p.playstyle,
      dominantHand: p.dominantHand,
      role: p.role.name,
      eloRating: p.eloRating,
      ladderRank: 1,
      smash: smash,
      agility: speed,
      stamina: stamina,
      consistency: defense,
      ovrRating: ovr,
      cardTier: ovr >= 90
          ? CardTier.diamond
          : (ovr >= 85
              ? CardTier.gold
              : (ovr >= 78 ? CardTier.silver : CardTier.bronze)),
      matchesPlayed: 21,
      matchesWon: 18,
      matchesLost: 3,
      winRatePct: 85.7,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InteractiveTrumpCard(
        card: cardModel,
        repaintKey: GlobalKey(),
      ),
    );
  }

  Widget _buildShareButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.limeNeon,
            foregroundColor: const Color(0xFF1A2100),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.ios_share_outlined, size: 18),
          label: Text(
            'SHARE CARD',
            style: GoogleFonts.jetBrainsMono(
                fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildGearStatus(GearLog? gear) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_outlined,
              color: AppTheme.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: gear != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${gear.racketBrandModel} @ ${gear.tensionLbs.toStringAsFixed(0)} lbs',
                        style: AppTheme.spaceGrotesk(
                            size: 13, weight: FontWeight.w600),
                      ),
                      Text(
                        'Strung ${_daysSince(gear.stringingDate)} • ${gear.stringModel}',
                        style: AppTheme.spaceGrotesk(
                            size: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  )
                : Text(
                    'No gear logged yet',
                    style: AppTheme.spaceGrotesk(
                        size: 13, color: AppTheme.textMuted),
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.mintTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('READY',
                style:
                    AppTheme.jetBrainsMono(size: 9, color: AppTheme.mintTeal)),
          ),
        ],
      ),
    );
  }

  String _daysSince(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'today';
    return '$days days ago';
  }

  Widget _buildSeasonRecord(PlayerProfile p, int ovr) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SEASON 2024–25 RECORD',
                  style: AppTheme.chivo(size: 15, weight: FontWeight.w800)),
              Text('FALL LADDER #1',
                  style: AppTheme.jetBrainsMono(
                      size: 9, color: AppTheme.limeNeon)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildRecordStat('PLAYED', '—M', null),
              const SizedBox(width: 20),
              _buildRecordStat('WIN RATE', '—%', null),
              const SizedBox(width: 20),
              _buildRecordStat(
                  'HOT STREAK', '—', Icons.local_fire_department_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordStat(String label, String value, IconData? icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.jetBrainsMono(
                size: 9, color: AppTheme.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(value,
                style: AppTheme.chivo(
                    size: 26,
                    weight: FontWeight.w900,
                    color: AppTheme.textWhite)),
            if (icon != null) Icon(icon, size: 18, color: AppTheme.limeNeon),
          ],
        ),
      ],
    );
  }

  Widget _buildRivalShowdown(PlayerProfile p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.compare_arrows_outlined,
                      size: 18, color: AppTheme.mintTeal),
                  const SizedBox(width: 8),
                  Text('RIVAL SHOWDOWN',
                      style: AppTheme.chivo(size: 15, weight: FontWeight.w800)),
                ],
              ),
              Text('— ENCOUNTERS',
                  style: AppTheme.jetBrainsMono(
                      size: 9, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // My side
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.bgDarker,
                  border: Border.all(color: AppTheme.limeNeon),
                ),
                child: Center(
                  child: Text(
                    p.fullName.substring(0, 1),
                    style: AppTheme.chivo(
                        size: 18,
                        weight: FontWeight.w900,
                        color: AppTheme.limeNeon),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.fullName.split(' ').first,
                      style: AppTheme.chivo(size: 13, weight: FontWeight.w800)),
                  Text('— Wins',
                      style: AppTheme.spaceGrotesk(
                          size: 10, color: AppTheme.limeNeon)),
                ],
              ),
              const Spacer(),
              Text('—\n',
                  textAlign: TextAlign.center,
                  style: AppTheme.chivo(
                      size: 22,
                      weight: FontWeight.w900,
                      color: AppTheme.textMuted)),
              const Spacer(),
              Text('No rival yet',
                  style: AppTheme.spaceGrotesk(
                      size: 11, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Play more matches to unlock your rival showdown!',
            style: AppTheme.spaceGrotesk(size: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildWeaponrySection(int smash, int net, int tactic) {
    final moves = [
      ('Cross-Court Smash', smash * 42 ~/ 99, smash * 42 ~/ 99),
      ('Net Kill & Tumbler', net * 34 ~/ 99, net * 34 ~/ 99),
      ('Tactical Drop Shot', tactic * 24 ~/ 99, tactic * 24 ~/ 99),
    ];
    final total = moves.fold<int>(0, (a, m) => a + m.$2);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('POINT WINNING WEAPONRY',
                  style: AppTheme.chivo(size: 15, weight: FontWeight.w800)),
              Text('LAST 100\nRALLIES',
                  textAlign: TextAlign.right,
                  style: AppTheme.jetBrainsMono(
                      size: 9, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          ...moves.map((m) {
            final pct = total > 0 ? (m.$2 / total * 100).round() : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(m.$1, style: AppTheme.spaceGrotesk(size: 12)),
                      Text('$pct pts ($pct%)',
                          style: AppTheme.jetBrainsMono(
                              size: 10, color: AppTheme.limeNeon)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: AppTheme.bgDarker,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.limeNeon),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderDark),
        ),
        title: Row(
          children: [
            const Icon(Icons.logout, color: AppTheme.errorRed, size: 20),
            const SizedBox(width: 8),
            Text(
              'LOG OUT',
              style: AppTheme.chivo(
                size: 16,
                weight: FontWeight.w900,
                color: AppTheme.textWhite,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your SmashDeck account?',
          style: AppTheme.spaceGrotesk(size: 13, color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style:
                  AppTheme.jetBrainsMono(size: 12, color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'LOG OUT',
              style: AppTheme.chivo(size: 12, weight: FontWeight.w800),
            ),
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
  }

  Widget _buildMasterHubBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF241C07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'MASTER CONTROL ACTIVE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppTheme.gold,
                  ),
                ),
                Text(
                  'Full root access to all squad accounts, APK releases & attendance.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MasterControlScreen()),
            ),
            child: const Text('Open Hub',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptainToolsCard(BuildContext context, PlayerProfile p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.limeNeon.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.military_tech_rounded,
                  color: AppTheme.limeNeon, size: 20),
              SizedBox(width: 8),
              Text(
                'CAPTAIN TOOLS • SQUAD DECK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.limeNeon,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Manual attendance roll call and practice session scheduling.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.limeNeon,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                  label: const Text('Manual Attendance',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MarkAttendanceScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textWhite,
                    side: const BorderSide(color: AppTheme.borderDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.event_note_rounded,
                      size: 18, color: AppTheme.limeNeon),
                  label: const Text('Schedule Event',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SquadCommonSpaceScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
