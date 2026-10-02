import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_motion.dart';
import '../../core/widgets/stitch_background.dart';
import 'auth_state.dart';
import 'auth_gate.dart';
import 'create_player_profile_screen.dart';
import 'current_user_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await ref.read(currentUserProvider.notifier).signIn(
          email: _idCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
    if (error == null) {
      ref.invalidate(currentPlayerProfileProvider);
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: StitchAppBackground(
          child: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            return Center(
                child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.all(wide ? 48 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: wide
                    ? Row(children: [
                        Expanded(child: _hero(true)),
                        const SizedBox(width: 80),
                        Expanded(child: _form())
                      ])
                    : Column(children: [
                        _hero(false),
                        const SizedBox(height: 28),
                        _form()
                      ]),
              ),
            ));
          })),
        ),
      );

  Widget _hero(bool wide) => Reveal(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: AppTheme.limeNeon,
                    borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.sports_tennis,
                    color: AppTheme.bgDarker, size: 24)),
            const SizedBox(width: 12),
            Expanded(
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('SMASHDECK',
                        style: AppTheme.chivo(
                            size: 21,
                            weight: FontWeight.w900,
                            letterSpacing: -.6)))),
            if (!wide && MediaQuery.sizeOf(context).width >= 400) _clubBadge(),
          ]),
          SizedBox(height: wide ? 64 : 30),
          Text('THE CLUB IS YOURS.',
              style: AppTheme.jetBrainsMono(
                  size: 10, color: AppTheme.mintTeal, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text('Show up.\nStep up.',
              style: AppTheme.chivo(
                  size: wide ? 78 : 48,
                  weight: FontWeight.w900,
                  height: .99,
                  letterSpacing: -2.5)),
          const SizedBox(height: 12),
          Text('Own the court.',
              style: AppTheme.chivo(
                  size: wide ? 56 : 34,
                  weight: FontWeight.w900,
                  color: AppTheme.limeNeon,
                  letterSpacing: -1.5)),
          const SizedBox(height: 18),
          Text(
              'Your squad, your scores, your next big win.\nOne home for everything badminton.',
              style: AppTheme.spaceGrotesk(
                  size: 15, color: AppTheme.textMuted, height: 1.6)),
          if (wide) ...[
            const SizedBox(height: 36),
            _clubBadge(),
            const SizedBox(height: 32),
            Wrap(spacing: 20, runSpacing: 12, children: [
              _feature(Icons.leaderboard_outlined, 'Climb the ladder'),
              _feature(Icons.style_outlined, 'Build your card'),
              _feature(Icons.sports_score, 'Track every point'),
            ]),
          ],
        ],
      ));

  Widget _clubBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderDark),
            borderRadius: BorderRadius.circular(30),
            color: AppTheme.cardDark),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.circle, color: AppTheme.mintTeal, size: 6),
          const SizedBox(width: 6),
          Text('CLUB EDITION',
              style:
                  AppTheme.jetBrainsMono(size: 8, color: AppTheme.textMuted)),
        ]),
      );

  Widget _feature(IconData icon, String text) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppTheme.limeNeon),
        const SizedBox(width: 8),
        Text(text,
            style: AppTheme.spaceGrotesk(size: 12, color: AppTheme.textMuted)),
      ]);

  Widget _form() => Reveal(
      delay: 140,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.borderDark),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 40,
                offset: const Offset(0, 16))
          ],
        ),
        child: AutofillGroup(
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back.',
                        style: AppTheme.chivo(
                            size: 27,
                            weight: FontWeight.w800,
                            letterSpacing: -.7)),
                    const SizedBox(height: 8),
                    Text('Sign in and get back in the game.',
                        style:
                            AppTheme.spaceGrotesk(color: AppTheme.textMuted)),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _idCtrl,
                      enabled: !_loading,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                          labelText: 'Email or player ID',
                          hintText: 'you@college.edu or SD-0001',
                          prefixIcon: Icon(Icons.alternate_email, size: 20)),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter your email or player ID.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _passwordCtrl,
                      enabled: !_loading,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      enableSuggestions: false,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                          labelText: 'Password',
                          helperText: 'Squad passcode: smash2024',
                          helperStyle: AppTheme.jetBrainsMono(
                              size: 11, color: AppTheme.mintTeal),
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                              tooltip:
                                  _obscure ? 'Show password' : 'Hide password',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20))),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter your password.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.bolt,
                              size: 14, color: AppTheme.limeNeon),
                          label: Text('Ishan (SD-0002)',
                              style: AppTheme.jetBrainsMono(
                                  size: 11, color: AppTheme.textWhite)),
                          backgroundColor: AppTheme.cardMid,
                          side: const BorderSide(color: AppTheme.borderDark),
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _idCtrl.text = 'SD-0002';
                                    _passwordCtrl.text = 'smash2024';
                                    _error = null;
                                  });
                                },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.shield_outlined,
                              size: 14, color: AppTheme.mintTeal),
                          label: Text('Captain Sachin',
                              style: AppTheme.jetBrainsMono(
                                  size: 11, color: AppTheme.textWhite)),
                          backgroundColor: AppTheme.cardMid,
                          side: const BorderSide(color: AppTheme.borderDark),
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _idCtrl.text = 'SD-0001';
                                    _passwordCtrl.text = 'smash2024';
                                    _error = null;
                                  });
                                },
                        ),
                      ],
                    ),
                    MotionSize(
                        duration: AppMotion.durationOf(context),
                        alignment: Alignment.topCenter,
                        child: _error == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Semantics(
                                    liveRegion: true,
                                    child: Text(_error!,
                                        style: AppTheme.spaceGrotesk(
                                            size: 13,
                                            color: AppTheme.errorRed))),
                              )),
                    const SizedBox(height: 26),
                    SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          child: AnimatedSwitcher(
                              duration: AppMotion.durationOf(context),
                              child: _loading
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Row(
                                      key: ValueKey('label'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                          Flexible(
                                              child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text('LET’S PLAY'))),
                                          SizedBox(width: 10),
                                          Icon(Icons.arrow_forward, size: 18)
                                        ])),
                        )),
                    const SizedBox(height: 22),
                    const Divider(),
                    const SizedBox(height: 16),
                    Center(
                        child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                          Text('New to the squad?',
                              style: AppTheme.spaceGrotesk(
                                  size: 13, color: AppTheme.textMuted)),
                          TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const CreatePlayerProfileScreen())),
                              child: const Text('Join the club')),
                        ])),
                  ],
                ))),
      ));
}
