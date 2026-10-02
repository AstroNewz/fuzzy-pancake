import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/card_theme.dart';
import '../../core/theme/app_avatars.dart';
import '../../core/widgets/stitch_background.dart';
import '../../core/widgets/app_motion.dart';
import '../auth/current_user_notifier.dart';
import '../auth/auth_state.dart';
import '../players/player_profile_screen.dart';
import 'card_export_service.dart';
import 'trump_card_model.dart';

/// Personal Club ID & 3D FIFA Apex Card Screen
/// Displays the member's personal card with authentic FIFA FUT Golden Card physics
/// and rich tactile haptic feedback.
class TrumpCardShowcaseScreen extends ConsumerStatefulWidget {
  final TrumpCardModel? initialCard;

  const TrumpCardShowcaseScreen({super.key, this.initialCard});

  @override
  ConsumerState<TrumpCardShowcaseScreen> createState() =>
      _TrumpCardShowcaseScreenState();
}

class _TrumpCardShowcaseScreenState
    extends ConsumerState<TrumpCardShowcaseScreen> {
  final GlobalKey _cardRepaintKey = GlobalKey();
  final GlobalKey<InteractiveTrumpCardState> _cardStateKey = GlobalKey();
  TrumpCardModel? _previewCardOverride;

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(squadTrumpCardsProvider);
    final activeUser = ref.watch(currentUserProvider);

    return StitchAppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('PLAYER CARD',
              style: AppTheme.chivo(size: 17, weight: FontWeight.w900)),
          actions: [
            // Quick Toggle: View Marvin's Golden Card vs My Card
            ActionChip(
              backgroundColor: _previewCardOverride != null
                  ? const Color(0x33FFD700)
                  : AppTheme.cardMid,
              side: BorderSide(
                color: _previewCardOverride != null
                    ? const Color(0xFFFFD700)
                    : AppTheme.limeNeon.withValues(alpha: 0.3),
              ),
              label: Text(
                _previewCardOverride != null ? 'SHOW MY CARD' : 'TOP CARD',
                style: AppTheme.jetBrainsMono(
                  size: 9,
                  weight: FontWeight.w800,
                  color: _previewCardOverride != null
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFFFD700),
                ),
              ),
              avatar: const Icon(Icons.military_tech,
                  size: 14, color: Color(0xFFFFD700)),
              onPressed: () {
                HapticFeedback.mediumImpact();
                final cards = cardsAsync.asData?.value ?? [];
                if (cards.isEmpty) return;
                setState(() {
                  if (_previewCardOverride == null) {
                    _previewCardOverride = cards.firstWhere(
                      (c) => c.ladderRank == 1,
                      orElse: () => cards.first,
                    );
                  } else {
                    _previewCardOverride = null;
                  }
                });
              },
            ),
            const SizedBox(width: 4),

            // Account Profile View Button
            IconButton(
              icon: const Icon(Icons.account_circle_outlined,
                  color: AppTheme.textWhite, size: 22),
              tooltip: 'Account Profile',
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PlayerProfileScreen()),
                );
              },
            ),

            // Share HD Card
            IconButton(
              icon: const Icon(Icons.share_outlined,
                  color: AppTheme.limeNeon, size: 22),
              tooltip: 'Export & Share Card',
              onPressed: () {
                HapticFeedback.selectionClick();
                final card =
                    _resolveMyCard(cardsAsync.asData?.value, activeUser);
                CardExportService.exportAndShareCard(
                  context: context,
                  repaintKey: _cardRepaintKey,
                  card: card,
                );
              },
            ),
          ],
        ),
        body: cardsAsync.when(
          data: (cards) {
            if (cards.isEmpty &&
                activeUser == null &&
                widget.initialCard == null) {
              return const Center(
                  child: Text(
                      'Your player card will appear after you join the club.'));
            }
            // "we can only see our card in the id card"
            // Top player Marvin Joseph holds Rank #1 Golden Card
            final myCard = _resolveMyCard(cards, activeUser);
            final isGold = myCard.cardTier == CardTier.gold;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Member Digital Pass Verification Pill
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isGold
                            ? const Color(0xE63D2E00)
                            : AppTheme.cardMid.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isGold
                              ? const Color(0xFFFFD700)
                              : AppTheme.limeNeon.withValues(alpha: 0.3),
                          width: isGold ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGold ? Icons.military_tech : Icons.verified_user,
                            size: 15,
                            color: isGold
                                ? const Color(0xFFFFD700)
                                : AppTheme.limeNeon,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isGold
                                ? 'MEMBER ID: ${myCard.rollNumber} • GOLD APEX CARD HOLDER'
                                : 'MEMBER ID: ${myCard.rollNumber} • ${myCard.cardTier.displayName} PASS',
                            style: AppTheme.jetBrainsMono(
                              size: 9.5,
                              weight: FontWeight.w800,
                              color: isGold
                                  ? const Color(0xFFFFD700)
                                  : AppTheme.limeNeon,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active 3D Card Stage with Behind-the-Card Tactile Bloom
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dynamic Aura Bloom tailored to Card Tier
                        Positioned(
                          child: Container(
                            width: 270,
                            height: 350,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isGold
                                  ? const Color(0x38FFD700)
                                  : AppTheme.limeNeon.withValues(alpha: 0.14),
                              boxShadow: [
                                BoxShadow(
                                  color: isGold
                                      ? const Color(0x55FFD700)
                                      : AppTheme.limeNeon
                                          .withValues(alpha: 0.18),
                                  blurRadius: 70,
                                  spreadRadius: 24,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // The 3D Interactive FIFA Card
                        InteractiveTrumpCard(
                          key: _cardStateKey,
                          card: myCard,
                          repaintKey: _cardRepaintKey,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Action Controls: Share Card & 360° Dossier
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isGold
                                  ? const Color(0xFFFFD700)
                                  : AppTheme.limeNeon,
                              foregroundColor: const Color(0xFF283500),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: isGold ? 4 : 0,
                              shadowColor: isGold
                                  ? const Color(0xFFFFD700)
                                      .withValues(alpha: 0.5)
                                  : null,
                            ),
                            icon: const Icon(Icons.ios_share,
                                size: 19, color: Color(0xFF283500)),
                            label: Text(
                              'SHARE MY ID CARD',
                              style: AppTheme.chivo(
                                size: 13,
                                weight: FontWeight.w900,
                                color: const Color(0xFF283500),
                                letterSpacing: 0.5,
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              CardExportService.exportAndShareCard(
                                context: context,
                                repaintKey: _cardRepaintKey,
                                card: myCard,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: isGold
                                  ? const Color(0x88FFD700)
                                  : AppTheme.borderDark,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(
                            Icons.threesixty,
                            size: 19,
                            color: isGold
                                ? const Color(0xFFFFD700)
                                : AppTheme.mintTeal,
                          ),
                          label: Text(
                            'DOSSIER',
                            style: AppTheme.jetBrainsMono(
                              size: 12,
                              weight: FontWeight.w800,
                              color: AppTheme.textWhite,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _cardStateKey.currentState?.flipCard();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Official Digital Club Pass & Telemetry Bento
                    _buildDigitalPassDetails(myCard),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.limeNeon),
          ),
          error: (err, _) => Center(
            child: Text(
              'Error loading card: $err',
              style: const TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ),
      ),
    );
  }

  /// Resolves the active user's personal card.
  /// If preview override is active, returns preview card.
  /// If logged in, binds directly to that member.
  /// If guest / not logged in, defaults to Marvin Joseph (Rank #1 Golden Card holder).
  TrumpCardModel _resolveMyCard(
      List<TrumpCardModel>? squadCards, PlayerProfile? activeUser) {
    if (_previewCardOverride != null) return _previewCardOverride!;
    if (widget.initialCard != null) return widget.initialCard!;
    final list = squadCards ?? [];
    final found = list.where((c) => c.playerId == activeUser?.id).firstOrNull;
    if (found != null) return found;
    if (activeUser != null) {
      return TrumpCardModel.fromMap({
        'id': activeUser.id,
        'roll_number': activeUser.rollNumber,
        'full_name': activeUser.fullName,
        'avatar_url': activeUser.avatarUrl,
        'base_smash': activeUser.baseSmash,
        'base_agility': activeUser.baseAgility,
        'base_stamina': activeUser.baseStamina,
        'base_consistency': activeUser.baseConsistency,
        'elo_rating': activeUser.eloRating,
        'playstyle': activeUser.playstyle,
        'dominant_hand': activeUser.dominantHand,
        'role': activeUser.role.name,
      });
    }
    return list.first;
  }

  Widget _buildDigitalPassDetails(TrumpCardModel card) {
    final isGold = card.cardTier == CardTier.gold;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isGold
            ? const Color(0xF01F1700)
            : AppTheme.cardDark.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGold
              ? const Color(0xFFFFD700).withValues(alpha: 0.5)
              : AppTheme.borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PLAYER RECORD',
                style: AppTheme.jetBrainsMono(
                  size: 9.5,
                  weight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isGold ? const Color(0x40FFD700) : AppTheme.cardMid,
                  borderRadius: BorderRadius.circular(4),
                  border: isGold
                      ? Border.all(color: const Color(0xFFFFD700))
                      : null,
                ),
                child: Text(
                  isGold
                      ? 'RANK #1 • GOLDEN CARD'
                      : 'CLUB RANK #${card.ladderRank ?? 1}',
                  style: AppTheme.jetBrainsMono(
                    size: 9,
                    weight: FontWeight.w800,
                    color: isGold ? const Color(0xFFFFD700) : AppTheme.limeNeon,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPassTile(
                  'MATCHES',
                  '${card.matchesPlayed}',
                  '${card.matchesWon}W - ${card.matchesLost}L',
                  AppTheme.textWhite,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPassTile(
                  'WIN RATE',
                  '${card.winRatePct.toStringAsFixed(1)}%',
                  'Career matches',
                  isGold ? const Color(0xFFFFD700) : AppTheme.limeNeon,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPassTile(
                  'ELO RATING',
                  '${card.eloRating}',
                  'Ladder Points',
                  isGold ? const Color(0xFFFFD700) : AppTheme.mintTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Verified Equipment Specs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isGold
                  ? const Color(0xFF140E00)
                  : AppTheme.bgDarker.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_tennis,
                  size: 16,
                  color: isGold ? const Color(0xFFFFD700) : AppTheme.mintTeal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Keep your racket and string setup up to date in Gear.',
                    style: AppTheme.spaceGrotesk(
                        size: 11.5,
                        color: AppTheme.textWhite,
                        weight: FontWeight.w500),
                  ),
                ),
                Text(
                  'GEAR',
                  style: AppTheme.jetBrainsMono(
                    size: 9,
                    weight: FontWeight.w800,
                    color: isGold ? const Color(0xFFFFD700) : AppTheme.mintTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassTile(
      String label, String value, String sub, Color valColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgDarker,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.jetBrainsMono(
                size: 8.5, color: AppTheme.textMuted, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.chivo(
                size: 16, weight: FontWeight.w900, color: valColor),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTheme.spaceGrotesk(size: 9.5, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Interactive 3D Card with Holographic Shader Sweep & Tactile Tilt
class InteractiveTrumpCard extends StatefulWidget {
  final TrumpCardModel card;
  final GlobalKey repaintKey;

  const InteractiveTrumpCard({
    super.key,
    required this.card,
    required this.repaintKey,
  });

  @override
  State<InteractiveTrumpCard> createState() => InteractiveTrumpCardState();
}

class InteractiveTrumpCardState extends State<InteractiveTrumpCard>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _shaderAnimController;
  late Animation<double> _flipAnimation;

  double _rotateX = 0;
  double _rotateY = 0;
  Offset _touchPos = const Offset(0.5, 0.5);
  bool _isFlipped = false;
  bool _hasTiltedHaptic = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );

    // Continuous 45-degree holographic foil sheen animation matching shader/code.html
    _shaderAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _shaderAnimController.stop();
    } else if (!_shaderAnimController.isAnimating) {
      _shaderAnimController.repeat();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _shaderAnimController.dispose();
    super.dispose();
  }

  void flipCard() {
    if (_flipController.isAnimating) return;
    _flipController.duration = AppMotion.durationOf(context);
    HapticFeedback.selectionClick();
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    _isFlipped = !_isFlipped;
  }

  void _onPointerMove(PointerEvent event, Size size) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    final xPct = (event.localPosition.dx / size.width) - 0.5;
    final yPct = (event.localPosition.dy / size.height) - 0.5;

    final newRotY = (xPct * 0.45).clamp(-0.25, 0.25);
    final newRotX = (-yPct * 0.45).clamp(-0.25, 0.25);

    // Subtle tactile haptic tick when reaching tilt crest
    if ((newRotX.abs() > 0.12 || newRotY.abs() > 0.12) && !_hasTiltedHaptic) {
      HapticFeedback.selectionClick();
      _hasTiltedHaptic = true;
    }

    setState(() {
      _rotateY = newRotY;
      _rotateX = newRotX;
      _touchPos = Offset(
        (event.localPosition.dx / size.width).clamp(0.0, 1.0),
        (event.localPosition.dy / size.height).clamp(0.0, 1.0),
      );
    });
  }

  void _onPointerUp(PointerUpEvent event) => _resetTilt();

  void _resetTilt() {
    _hasTiltedHaptic = false;
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
      _touchPos = const Offset(0.5, 0.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth =
        (MediaQuery.of(context).size.width - 48).clamp(310.0, 345.0);
    const cardHeight = 505.0;
    final isGold = widget.card.cardTier == CardTier.gold;

    return FittedBox(
        fit: BoxFit.scaleDown,
        child: Listener(
          onPointerCancel: (_) => _resetTilt(),
          onPointerMove: (e) => _onPointerMove(e, Size(cardWidth, cardHeight)),
          onPointerHover: (e) => _onPointerMove(e, Size(cardWidth, cardHeight)),
          onPointerUp: _onPointerUp,
          child: GestureDetector(
            onTap: flipCard,
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_flipAnimation, _shaderAnimController]),
              builder: (context, child) {
                final isFront = _flipAnimation.value < (pi / 2);

                return AnimatedContainer(
                  duration: _flipController.isAnimating
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  transformAlignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateX(_rotateX)
                    ..rotateY(_rotateY + _flipAnimation.value),
                  child: RepaintBoundary(
                    key: widget.repaintKey,
                    child: Container(
                      width: cardWidth,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: isGold
                                ? const Color(0x66FFD700)
                                : AppTheme.limeNeon.withValues(alpha: 0.22),
                            blurRadius: isGold ? 44 : 36,
                            spreadRadius: isGold ? 4 : 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.7),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          children: [
                            // 1. Base Gradient: Molten Gold for Golden Card, Athletic Navy for Others
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: isGold
                                        ? const [
                                            Color(
                                                0xFF4A3800), // Molten gold crest
                                            Color(
                                                0xFF2B1F00), // Deep metallic bronze mid
                                            Color(0xFF1A1200), // Dark gold core
                                            Color(
                                                0xFF0D0900), // Rich amber shadow base
                                          ]
                                        : const [
                                            Color(
                                                0xFF212942), // #212942 surface-container-high
                                            Color(
                                                0xFF171E37), // #171e37 surface-container
                                            Color(
                                                0xFF0A122A), // #0a122a stadium dark canvas
                                            Color(
                                                0xFF050D25), // #050d25 surface-container-lowest
                                          ],
                                    stops: const [0.0, 0.35, 0.7, 1.0],
                                  ),
                                ),
                              ),
                            ),

                            // 2. Badminton Court Vector Wireframe Overlay
                            Positioned.fill(
                              child: CustomPaint(
                                painter: CourtWireframePainter(
                                  netColor: isGold
                                      ? const Color(0xFFFFD700)
                                      : AppTheme.limeNeon,
                                  lineColor: isGold
                                      ? const Color(0xFFFFE066)
                                          .withValues(alpha: 0.16)
                                      : const Color(0xFFDBE1FF)
                                          .withValues(alpha: 0.10),
                                ),
                              ),
                            ),

                            // 3. Front or Back Card Face
                            if (isFront)
                              _buildCardFront()
                            else
                              Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(pi),
                                child: _buildCardBack(),
                              ),

                            // 4. TOP Holographic Kinetic Foil Shader Overlay (shader/code.html)
                            // Sweeps across the entire card face, character avatar, OVR number, and badges
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: HolographicSheenPainter(
                                    time: _shaderAnimController.value,
                                    tier: widget.card.cardTier,
                                    touchPos: _touchPos,
                                  ),
                                ),
                              ),
                            ),

                            // 5. Shimmering Iridescent / Golden Outer Border
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: HolographicBorderPainter(
                                    time: _shaderAnimController.value,
                                    tier: widget.card.cardTier,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ));
  }

  /// Front Face: FIFA-Style Elite Player Card (fifa_style_ovr_player_card/code.html)
  Widget _buildCardFront() {
    final card = widget.card;
    final isGold = card.cardTier == CardTier.gold;
    final primaryAccent = isGold ? const Color(0xFFFFD700) : AppTheme.limeNeon;

    // Badminton stat metrics

    final defLabel = card.consistency > 82 ? 'Lift & Block' : 'Recovery';
    final netLabel = card.agility > 82 ? 'Tumbling Spin' : 'Hairpin Net';
    const spdLabel = 'Court Footwork';
    const stmLabel = 'Set 3 Gas Tank';
    final tacLabel = card.smash > 84 ? 'Deceptive IQ' : 'Pace Control';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Tier, Stars, Club Mark
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isGold
                      ? const Color(0xE64A3800)
                      : const Color(0xCC212942),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryAccent,
                    width: isGold ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.military_tech,
                      color: primaryAccent,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGold
                          ? 'CLUB RANK #1 • GOLD APEX TIER'
                          : 'CLUB RANK #${card.ladderRank ?? 2} • ${card.cardTier.displayName} TIER',
                      style: AppTheme.jetBrainsMono(
                        size: 9,
                        weight: FontWeight.w800,
                        color: primaryAccent,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(3, (_) {
                  return Icon(Icons.star, color: primaryAccent, size: 14);
                }),
              ),
            ],
          ),

          // Upper Mid: OVR Stack + Player Cutout Portrait
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: OVR & Archetype
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${card.ovrRating}',
                    style: AppTheme.chivo(
                      size: 60,
                      weight: FontWeight.w900,
                      color: primaryAccent,
                      letterSpacing: -2.2,
                    ),
                  ),
                  Text(
                    'SGL',
                    style: AppTheme.chivo(
                      size: 17,
                      weight: FontWeight.w900,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  Text(
                    card.playstyle.toUpperCase(),
                    style: AppTheme.jetBrainsMono(
                      size: 9.5,
                      weight: FontWeight.w700,
                      color:
                          isGold ? const Color(0xFFFFE066) : AppTheme.mintTeal,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Badges: Squad / Weapon Crest / Division
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isGold
                              ? const Color(0xE63D2E00)
                              : const Color(0xCC2C344D),
                          borderRadius: BorderRadius.circular(5),
                          border: isGold
                              ? Border.all(color: const Color(0x88FFD700))
                              : null,
                        ),
                        child: Text(
                          'DIV 1',
                          style: AppTheme.jetBrainsMono(
                            size: 8.5,
                            weight: FontWeight.w800,
                            color: isGold
                                ? const Color(0xFFFFD700)
                                : AppTheme.textWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isGold
                              ? const Color(0xE63D2E00)
                              : const Color(0xCC2C344D),
                          borderRadius: BorderRadius.circular(5),
                          border: isGold
                              ? Border.all(color: const Color(0x88FFD700))
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sports_tennis,
                              color: isGold
                                  ? const Color(0xFFFFD700)
                                  : AppTheme.mintTeal,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '88D',
                              style: AppTheme.jetBrainsMono(
                                size: 8.5,
                                weight: FontWeight.w800,
                                color: isGold
                                    ? const Color(0xFFFFD700)
                                    : AppTheme.mintTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Apex Seed Pulsing Tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isGold
                          ? const Color(0xE6261A00)
                          : const Color(0xB3050D25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: primaryAccent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryAccent,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isGold ? 'GOLDEN LEADER' : 'APEX SQUAD',
                          style: AppTheme.jetBrainsMono(
                            size: 8.5,
                            weight: FontWeight.w800,
                            color: primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Right Column: Hero Cutout Athlete Mascot Portrait
              SizedBox(
                width: 146,
                height: 165,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // Stadium Rim Glow Halo
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryAccent.withValues(
                              alpha: isGold ? 0.28 : 0.18),
                        ),
                      ),
                    ),
                    // Mascot Cutout
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        AppAvatars.getAvatarForRoll(card.rollNumber),
                        width: 144,
                        height: 160,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: 144,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppTheme.cardMid,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              card.fullName
                                  .split(' ')
                                  .map((n) => n[0])
                                  .take(2)
                                  .join(),
                              style: AppTheme.chivo(
                                  size: 36,
                                  weight: FontWeight.w900,
                                  color: primaryAccent),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Nameplate Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: isGold ? const Color(0xE6261A00) : const Color(0xCC050D25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isGold ? const Color(0x88FFD700) : const Color(0x442C344D),
              ),
            ),
            child: Column(
              children: [
                Text(
                  card.fullName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTheme.chivo(
                    size: 17,
                    weight: FontWeight.w900,
                    color: AppTheme.textWhite,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 16, height: 1.5, color: primaryAccent),
                    const SizedBox(width: 6),
                    Text(
                      isGold
                          ? 'SMASH SQUAD #1 • ${card.dominantHand.toUpperCase()} HANDED'
                          : 'SMASH CLUB SEED #${card.ladderRank ?? 1} • ${card.dominantHand.toUpperCase()} HANDED',
                      style: AppTheme.jetBrainsMono(
                        size: 9,
                        weight: FontWeight.w700,
                        color: isGold
                            ? const Color(0xFFFFE066)
                            : AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(width: 16, height: 1.5, color: primaryAccent),
                  ],
                ),
              ],
            ),
          ),

          // 6-Grid FIFA-Style Badminton Stats Matrix
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGold ? const Color(0xE6332400) : const Color(0xCC171E37),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isGold ? const Color(0x88FFD700) : const Color(0x442C344D),
              ),
            ),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.75,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                _buildStatCell(
                    'SMA', card.smash, 'Shot power', primaryAccent, isGold),
                _buildStatCell('DEF', card.consistency, defLabel,
                    AppTheme.textWhite, isGold),
                _buildStatCell('NET', ((card.smash + card.agility) / 2).round(),
                    netLabel, primaryAccent, isGold),
                _buildStatCell(
                    'SPD', card.agility, spdLabel, AppTheme.textWhite, isGold),
                _buildStatCell(
                    'STM', card.stamina, stmLabel, AppTheme.textWhite, isGold),
                _buildStatCell('TAC', ((card.smash + card.stamina) / 2).round(),
                    tacLabel, primaryAccent, isGold),
              ],
            ),
          ),

          // Tap to flip hint
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app,
                    size: 12,
                    color:
                        isGold ? const Color(0xFFFFD700) : AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  'TILT OR TOUCH TO SHINE • TAP TO FLIP',
                  style: AppTheme.jetBrainsMono(
                    size: 8.5,
                    weight: FontWeight.w700,
                    color:
                        isGold ? const Color(0xFFFFD700) : AppTheme.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(
      String label, int value, String sub, Color color, bool isGold) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isGold ? const Color(0xB31F1700) : const Color(0xB3050D25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.jetBrainsMono(
                    size: 9.5,
                    weight: FontWeight.w800,
                    color: AppTheme.textMuted),
              ),
              Text(
                '$value',
                style: AppTheme.chivo(
                    size: 13, weight: FontWeight.w900, color: color),
              ),
            ],
          ),
          const SizedBox(height: 1),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 2.2,
              backgroundColor:
                  isGold ? const Color(0xFF332400) : AppTheme.cardMid,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.spaceGrotesk(
                size: 8.5,
                color: isGold ? const Color(0xFFC4B080) : AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  /// Back Face: Career Stats & Match History Dossier
  Widget _buildCardBack() {
    final card = widget.card;
    final isGold = card.cardTier == CardTier.gold;
    final primaryAccent = isGold ? const Color(0xFFFFD700) : AppTheme.limeNeon;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CAREER DOSSIER',
                style: AppTheme.jetBrainsMono(
                  size: 11,
                  weight: FontWeight.w900,
                  color: primaryAccent,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                card.rollNumber,
                style: AppTheme.jetBrainsMono(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),

          // Win Rate & Match Stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGold ? const Color(0xE6261A00) : const Color(0xCC050D25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isGold ? const Color(0x88FFD700) : AppTheme.borderDark,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBackStat('WIN RATE',
                    '${card.winRatePct.toStringAsFixed(1)}%', primaryAccent),
                Container(width: 1, height: 28, color: AppTheme.borderDark),
                _buildBackStat(
                    'PLAYED', '${card.matchesPlayed}', AppTheme.textWhite),
                Container(width: 1, height: 28, color: AppTheme.borderDark),
                _buildBackStat(
                    'WON / LOST',
                    '${card.matchesWon} - ${card.matchesLost}',
                    isGold ? const Color(0xFFFFE066) : AppTheme.mintTeal),
              ],
            ),
          ),

          // Elo Rating Tile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isGold ? const Color(0xE6261A00) : const Color(0xCC050D25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isGold ? const Color(0x88FFD700) : AppTheme.borderDark,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ELO RATING',
                    style: AppTheme.jetBrainsMono(
                        size: 11,
                        color: AppTheme.textMuted,
                        weight: FontWeight.bold)),
                Text(
                  '${card.eloRating} PTS',
                  style: AppTheme.jetBrainsMono(
                      size: 15, weight: FontWeight.w900, color: primaryAccent),
                ),
              ],
            ),
          ),

          // Gear Specs
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGold ? const Color(0xE6261A00) : const Color(0xCC050D25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isGold ? const Color(0x88FFD700) : AppTheme.borderDark,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RACKET & GEAR SETUP',
                    style: AppTheme.jetBrainsMono(
                        size: 9.5,
                        color: AppTheme.textMuted,
                        weight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Yonex Astrox 88D Pro',
                        style: AppTheme.spaceGrotesk(
                            size: 12, color: AppTheme.textWhite)),
                    Text('@ 28 LBS',
                        style: AppTheme.jetBrainsMono(
                            size: 11,
                            color: primaryAccent,
                            weight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Yonex BG80 • Strung 6 days ago • Optimal Tension',
                  style: AppTheme.spaceGrotesk(
                      size: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),

          // Return hint
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app,
                    size: 12,
                    color:
                        isGold ? const Color(0xFFFFD700) : AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  'TAP TO RETURN TO CARD FACE',
                  style: AppTheme.jetBrainsMono(
                    size: 9,
                    weight: FontWeight.w700,
                    color:
                        isGold ? const Color(0xFFFFD700) : AppTheme.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackStat(String label, String val, Color col) {
    return Column(
      children: [
        Text(label,
            style: AppTheme.jetBrainsMono(
                size: 9, color: AppTheme.textMuted, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(val,
            style:
                AppTheme.chivo(size: 14, weight: FontWeight.w900, color: col)),
      ],
    );
  }
}

/// WebGL-Style Holographic Kinetic Sheen Painter (matching shader/code.html)
/// Implements rich Golden Foil for Gold Tier, electric Cyan for Diamond, Platinum for Silver
class HolographicSheenPainter extends CustomPainter {
  final double time;
  final CardTier tier;
  final Offset touchPos;

  HolographicSheenPainter({
    required this.time,
    required this.tier,
    required this.touchPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final isGold = tier == CardTier.gold;

    // 1. Continuous 45-degree Angle Holographic Foil Sweep (shader/code.html)
    // dir = vec2(cos(45deg), sin(45deg)), pos = dot(p, dir) - time * 0.45
    final sweepProgress = (time * 1.8) % 2.4 - 0.4;
    final sweepCenter =
        Offset(size.width * sweepProgress, size.height * sweepProgress);

    final sweepRect = Rect.fromCenter(
      center: sweepCenter,
      width: size.width * 2.4,
      height: size.height * 2.4,
    );

    // Dynamic color stops tailored to tier
    final List<Color> foilColors = isGold
        ? const [
            Colors.transparent,
            Color(0x33FFD700), // Warm gold edge
            Color(0x77FFE066), // Bright gold foil band
            Color(0xAAC3F400), // Volt gold glint
            Color(0xEEFFFFFF), // Pure white core glint
            Color(0x88FFA500), // Amber gold warmth
            Color(0x44FFD700), // Gold trail
            Colors.transparent,
          ]
        : const [
            Colors.transparent,
            Color(0x22C3F400), // Subtle volt edge
            Color(0x5500E5FF), // Electric cyan foil band
            Color(0x99C3F400), // Intense volt neon glint
            Color(0xCCFFFFFF), // Sharp specular white core glint
            Color(0x88FF007F), // Prismatic magenta refraction edge
            Color(0x444EDEA3), // Mint teal trail
            Colors.transparent,
          ];

    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1.2, -1.2),
        end: const Alignment(1.2, 1.2),
        stops: const [0.0, 0.35, 0.42, 0.48, 0.52, 0.58, 0.65, 1.0],
        colors: foilColors,
      ).createShader(sweepRect)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, sheenPaint);

    // 2. Secondary Shimmer Harmonics Band (Repeated subtle light bands from shader)
    final sweep2Progress = ((time + 0.45) * 1.8) % 2.4 - 0.4;
    final sweep2Rect = Rect.fromCenter(
      center: Offset(size.width * sweep2Progress, size.height * sweep2Progress),
      width: size.width * 2.0,
      height: size.height * 2.0,
    );
    final sheen2Paint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1.2, -1.2),
        end: const Alignment(1.2, 1.2),
        stops: const [0.0, 0.42, 0.50, 0.58, 1.0],
        colors: isGold
            ? const [
                Colors.transparent,
                Color(0x30FFD700),
                Color(0x66FFE066),
                Color(0x30FFD700),
                Colors.transparent,
              ]
            : const [
                Colors.transparent,
                Color(0x25C3F400),
                Color(0x6600E5FF),
                Color(0x25C3F400),
                Colors.transparent,
              ],
      ).createShader(sweep2Rect)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, sheen2Paint);

    // 3. Dynamic Specular Radial Spotlight following finger touch / pointer
    final glarePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(touchPos.dx * 2 - 1, touchPos.dy * 2 - 1),
        radius: 0.65,
        colors: isGold
            ? [
                Colors.white.withValues(alpha: 0.35),
                const Color(0xFFFFD700).withValues(alpha: 0.22),
                const Color(0xFFC3F400).withValues(alpha: 0.10),
                Colors.transparent,
              ]
            : [
                Colors.white.withValues(alpha: 0.32),
                const Color(0xFFC3F400).withValues(alpha: 0.18),
                const Color(0xFF00E5FF).withValues(alpha: 0.08),
                Colors.transparent,
              ],
        stops: const [0.0, 0.25, 0.55, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, glarePaint);

    // 4. Subtle Corner Vignette to make card center pop
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.35),
        ],
        stops: const [0.65, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant HolographicSheenPainter oldDelegate) => true;
}

/// Shimmering Holographic Perimeter Border Painter
class HolographicBorderPainter extends CustomPainter {
  final double time;
  final CardTier tier;

  HolographicBorderPainter({required this.time, required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect =
        RRect.fromRectAndRadius(rect.deflate(1.0), const Radius.circular(21));

    final progress = time * 2 * pi;
    final isGold = tier == CardTier.gold;

    final borderColors = isGold
        ? const [
            Color(0xFFFFD700), // Pure Gold
            Color(0xFFC3F400), // Volt neon
            Color(0xFFFFA500), // Amber
            Color(0xFFFFE066), // Light gold
            Color(0xFFFFD700), // Pure Gold
          ]
        : const [
            Color(0xFFC3F400), // Volt neon
            Color(0xFF00E5FF), // Electric cyan
            Color(0xFFFF007F), // Prismatic magenta
            Color(0xFF4EDEA3), // Mint teal
            Color(0xFFC3F400), // Volt neon
          ];

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: 2 * pi,
        transform: GradientRotation(progress),
        colors: borderColors,
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant HolographicBorderPainter oldDelegate) => true;
}

/// Badminton Court Vector Wireframe Overlay (fifa_style_ovr_player_card)
class CourtWireframePainter extends CustomPainter {
  final Color netColor;
  final Color? lineColor;

  CourtWireframePainter({
    this.netColor = AppTheme.limeNeon,
    this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final courtLinePaint = Paint()
      ..color = lineColor ?? const Color(0xFFDBE1FF).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final netLinePaint = Paint()
      ..color = netColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final tacticalArcPaint = Paint()
      ..color = netColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer boundaries
    canvas.drawRect(Rect.fromLTWH(14, 14, w - 28, h - 28), courtLinePaint);

    // Singles sidelines
    canvas.drawLine(const Offset(28, 14), Offset(28, h - 14), courtLinePaint);
    canvas.drawLine(Offset(w - 28, 14), Offset(w - 28, h - 14), courtLinePaint);

    // Short service lines
    canvas.drawLine(
        Offset(14, h * 0.38), Offset(w - 14, h * 0.38), courtLinePaint);
    canvas.drawLine(
        Offset(14, h * 0.62), Offset(w - 14, h * 0.62), courtLinePaint);

    // Center Service Line
    canvas.drawLine(Offset(w / 2, 14), Offset(w / 2, h * 0.38), courtLinePaint);
    canvas.drawLine(
        Offset(w / 2, h * 0.62), Offset(w / 2, h - 14), courtLinePaint);

    // Center Net Line (Electric Highlight)
    canvas.drawLine(Offset(14, h / 2), Offset(w - 14, h / 2), netLinePaint);

    // Tactical Circle Arc at center
    canvas.drawCircle(Offset(w / 2, h / 2), 65, tacticalArcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
