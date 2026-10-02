import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smashdeck/core/network/supabase_service.dart';
import 'package:smashdeck/features/gear_tracker/gear_screen.dart';
import 'package:smashdeck/features/home/main_navigation_wrapper.dart';
import 'package:smashdeck/features/match_engine/live_scoring_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smashdeck/core/theme/app_theme.dart';
import 'package:smashdeck/core/theme/appearance_preferences.dart';
import 'package:smashdeck/features/training/training_screen.dart';
import 'package:smashdeck/features/more/appearance_screen.dart';
import 'package:smashdeck/features/matches/matches_hub_screen.dart';
import 'package:smashdeck/core/widgets/stitch_background.dart';
import 'package:smashdeck/features/auth/auth_state.dart';
import 'package:smashdeck/features/auth/current_user_notifier.dart';
import 'package:smashdeck/features/auth/login_screen.dart';
import 'package:smashdeck/features/ladder/ladder_screen.dart';
import 'package:smashdeck/features/ladder/ladder_state.dart';
import 'package:smashdeck/features/ladder/ladder_challenge_repository.dart';
import 'package:smashdeck/features/trump_card/trump_card_model.dart';
import 'package:smashdeck/features/trump_card/trump_card_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  List<http.Request>? observedRequests;
  setUpAll(() async {
    client = SupabaseClient('https://example.test', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      observedRequests?.add(request);
      return http.Response('[]', 200,
          request: request, headers: {'content-type': 'application/json'});
    }));
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final weight in [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
      FontWeight.w900
    ]) {
      GoogleFonts.chivo(fontWeight: weight);
      GoogleFonts.spaceGrotesk(fontWeight: weight);
      GoogleFonts.jetBrainsMono(fontWeight: weight);
    }
    await GoogleFonts.pendingFonts();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  tearDownAll(() => client.dispose());
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });
  final user = PlayerProfile.fromMap({
    'id': 'SD-0002',
    'roll_number': 'SD-0002',
    'full_name': 'Ishan Narayan Shukla',
    'email': 'test@example.com'
  });
  final entries = fallbackSquadCards
      .map((c) => LadderEntry(
          rank: c.ladderRank!,
          playerId: c.playerId,
          rollNumber: c.rollNumber,
          fullName: c.fullName,
          avatarUrl: c.avatarUrl,
          playstyle: c.playstyle,
          ovrRating: c.ovrRating,
          cardTier: c.cardTier,
          eloRating: c.eloRating,
          rankChange: 0,
          winRatePct: c.winRatePct,
          matchesPlayed: c.matchesPlayed))
      .toList();

  Future<void> render(WidgetTester tester, Widget screen, Size size,
      {double textScale = 1, List<http.Request>? requests}) async {
    observedRequests = requests;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(client),
          currentUserProvider.overrideWith((ref) =>
              CurrentUserNotifier(restoreSession: false)..setPlayer(user)),
          ladderStandingsProvider.overrideWith((ref) async => entries),
          activeChallengesProvider(user.id).overrideWith((ref) async => []),
          squadTrumpCardsProvider
              .overrideWith((ref) async => fallbackSquadCards),
        ],
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    textScaler: TextScaler.linear(textScale)),
                child: AppAppearance(child: child!)),
            home: StitchAppBackground(child: screen))));
    await tester.pumpAndSettle();
  }

  testWidgets('login handles narrow screens, keyboard and empty submission',
      (tester) async {
    await render(tester, const LoginScreen(), const Size(320, 740));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('LET’S PLAY'));
    await tester.tap(find.text('LET’S PLAY'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email or player ID.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ladder supports long names and filters on a narrow phone',
      (tester) async {
    await render(tester, const LadderScreen(), const Size(320, 740));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('In reach'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('In reach'));
    await tester.pumpAndSettle();
    expect(find.text('2 shown'), findsOneWidget);
    await tester.tap(find.text('My position'));
    await tester.pumpAndSettle();
    expect(find.text('1 shown'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pumpAndSettle();
    expect(find.text('No players here.'), findsOneWidget);
  });

  testWidgets('login and ladder respect larger text', (tester) async {
    await render(tester, const LoginScreen(), const Size(390, 844),
        textScale: 1.4);
    expect(tester.takeException(), isNull);
    await render(tester, const LadderScreen(), const Size(390, 844),
        textScale: 1.4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card fits small phones and honors reduced motion',
      (tester) async {
    await render(
        tester,
        Scaffold(
            body: Center(
                child: InteractiveTrumpCard(
                    card: fallbackSquadCards.first, repaintKey: GlobalKey()))),
        const Size(320, 740));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(InteractiveTrumpCard));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture refined mobile ladder', (tester) async {
    await render(tester, const LadderScreen(), const Size(390, 844));
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/ladder-mobile.png'));
  });

  testWidgets('equipment form validates and actually saves the record',
      (tester) async {
    final requests = <http.Request>[];
    await render(tester, const GearTrackerScreen(), const Size(390, 844),
        requests: requests);
    await tester.ensureVisible(find.text('Log restring'));
    await tester.tap(find.text('Log restring'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAVE RACKET'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your racket model.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Astrox 88D');
    await tester.enterText(find.byType(TextFormField).at(1), 'BG80');
    await tester.tap(find.text('SAVE RACKET'));
    await tester.pumpAndSettle();
    final write = requests.singleWhere((r) => r.method == 'POST');
    expect(write.url.path, endsWith('/gear_logs'));
    expect(jsonDecode(write.body)['racket_brand_model'], 'Astrox 88D');
    expect(find.text('Racket record saved. Ready for the next rally.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation preserves ladder state when returning from card',
      (tester) async {
    await render(tester, const MainNavigationWrapper(), const Size(390, 844));
    await tester.tap(find.text('My card'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Ladder'));
    await tester.pumpAndSettle();
    expect(find.text('Earn your spot.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture refined desktop login', (tester) async {
    await render(tester, const LoginScreen(), const Size(1280, 900));
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/login-desktop.png'));
  });

  testWidgets('training fits small phones and pauses on background',
      (tester) async {
    await render(tester, const TrainingScreen(), const Size(320, 740),
        textScale: 1.3);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('START WORKOUT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START WORKOUT'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('PAUSE WORKOUT'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(find.text('RESUME WORKOUT'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('RESUME WORKOUT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture training and appearance screens', (tester) async {
    await render(tester, const TrainingScreen(), const Size(390, 844));
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/training-mobile.png'));
    await render(tester, const AppearanceScreen(), const Size(390, 844));
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/appearance-mobile.png'));
    await tester.tap(find.text('Clean'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Clean'))
            .selected,
        isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('matches handles empty data at narrow widths and large text',
      (tester) async {
    await render(tester, const MatchesHubScreen(), const Size(320, 740),
        textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('Your next match starts here.'), findsOneWidget);
    await render(tester, const MatchesHubScreen(), const Size(390, 844));
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/matches-mobile.png'));
  });

  testWidgets('podium opens a player dossier and ladder rules', (tester) async {
    await render(tester, const LadderScreen(), const Size(390, 844));
    await tester.tap(find.text('Marvin').first);
    await tester.pumpAndSettle();
    expect(find.text('ELO'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(20, 60));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('How the ladder works'));
    await tester.pumpAndSettle();
    expect(find.text('Your climb starts here.'), findsOneWidget);
  });

  testWidgets('live scoring fits a phone and reacts to scored rallies',
      (tester) async {
    await render(tester, const LiveScoringScreen(), const Size(390, 844));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('0').first);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture Android navigation and card screen', (tester) async {
    await render(tester, const MainNavigationWrapper(), const Size(390, 844));
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/android-ladder.png'));
    await tester.tap(find.text('My card'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/android-card.png'));
  });
}
