import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'auth_gate.dart';
import 'auth_state.dart';
import 'current_user_notifier.dart';

/// Clean Stitch-Style Player Profile Registration Screen
/// Matches stitch_smashdeck_badminton_club_manager design tokens
/// Zero emojis used.
class CreatePlayerProfileScreen extends ConsumerStatefulWidget {
  const CreatePlayerProfileScreen({super.key});

  @override
  ConsumerState<CreatePlayerProfileScreen> createState() =>
      _CreatePlayerProfileScreenState();
}

class _CreatePlayerProfileScreenState
    extends ConsumerState<CreatePlayerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _racketController = TextEditingController(text: 'Yonex Astrox 88D Pro');
  final _stringController = TextEditingController(text: 'BG80 Power');

  String _dominantHand = 'Right';
  String _playstyle = 'All-Rounder';
  String _yearOfStudy = '2nd Year';
  double _tensionLbs = 26.0;
  final bool _isCaptain = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const List<String> _allowedPlaystyles = [
    'Aggressive Smasher',
    'Speed Attacker',
    'Net Dominator',
    'Tactical Trickster',
    'Defensive Retriever',
    'All-Rounder',
  ];

  static const List<String> _studyYears = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _racketController.dispose();
    _stringController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateProfile() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final rollId = _idController.text.trim().toUpperCase();
    final autoEmail = _emailController.text.trim().toLowerCase();

    final error = await ref.read(currentUserProvider.notifier).registerPlayer(
          fullName: _nameController.text.trim(),
          rollNumber: rollId,
          email: autoEmail,
          password: _passwordController.text,
          playstyle: _playstyle,
          dominantHand: _dominantHand,
          role: _isCaptain ? UserRole.captain : UserRole.player,
          avatarUrl:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
          racketBrandModel: _racketController.text.trim(),
          stringModel: _stringController.text.trim(),
          tensionLbs: _tensionLbs,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile registered for ${_nameController.text.trim()} ($rollId). Welcome to the squad.',
          style: AppTheme.spaceGrotesk(size: 13, color: AppTheme.textWhite),
        ),
        backgroundColor: AppTheme.cardMid,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'REGISTER PLAYER PROFILE',
          style: AppTheme.chivo(
            size: 16,
            weight: FontWeight.w800,
            color: AppTheme.textWhite,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              Text(
                'Join the SmashDeck Collegiate Squad & Generate Your Dynamic Player Card',
                style:
                    AppTheme.spaceGrotesk(size: 13, color: AppTheme.textMuted),
              ),

              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.errorRed.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.errorRed, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTheme.spaceGrotesk(
                              size: 12, color: AppTheme.errorRed),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Section: Member Credentials
              _buildSectionHeader('MEMBER CREDENTIALS'),
              const SizedBox(height: 10),

              // Full Name
              _buildInputLabel('EMAIL'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration:
                    _inputDecoration('you@college.edu', Icons.alternate_email),
                validator: (v) => v == null ||
                        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(v.trim())
                    ? 'Enter a valid email for account confirmation.'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildInputLabel('FULL NAME'),
              Container(
                decoration: _inputBoxDecoration,
                child: TextFormField(
                  controller: _nameController,
                  style: AppTheme.spaceGrotesk(color: AppTheme.textWhite),
                  decoration: _inputDecoration(
                      'e.g. Rahul Sharma', Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter player name'
                      : null,
                ),
              ),

              const SizedBox(height: 14),

              // Player ID & Year of Study Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('PLAYER ID'),
                        Container(
                          decoration: _inputBoxDecoration,
                          child: TextFormField(
                            controller: _idController,
                            style: AppTheme.jetBrainsMono(
                              size: 13,
                              weight: FontWeight.bold,
                              color: AppTheme.limeNeon,
                            ),
                            decoration: _inputDecoration(
                                'SD-0008', Icons.badge_outlined),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('STUDY YEAR'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: _inputBoxDecoration,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _yearOfStudy,
                              isExpanded: true,
                              dropdownColor: AppTheme.cardMid,
                              style: AppTheme.spaceGrotesk(
                                  size: 13, color: AppTheme.textWhite),
                              items: _studyYears.map((y) {
                                return DropdownMenuItem(
                                    value: y, child: Text(y));
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _yearOfStudy = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Password
              _buildInputLabel('PASSCODE'),
              Container(
                decoration: _inputBoxDecoration,
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTheme.spaceGrotesk(color: AppTheme.textWhite),
                  decoration: _inputDecoration(
                          'Create account passcode', Icons.lock_outline)
                      .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textMuted,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'At least 6 characters'
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              // Section: Badminton Attributes
              _buildSectionHeader('BADMINTON ATTRIBUTES'),
              const SizedBox(height: 10),

              // Playstyle Selector
              _buildInputLabel('PLAYSTYLE / ARCHETYPE'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allowedPlaystyles.map((style) {
                  final isSelected = _playstyle == style;
                  return ChoiceChip(
                    label: Text(style),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _playstyle = style),
                    selectedColor: AppTheme.limeNeon,
                    backgroundColor: AppTheme.cardMid,
                    labelStyle: AppTheme.jetBrainsMono(
                      size: 11,
                      weight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1A2100)
                          : AppTheme.textMuted,
                    ),
                    side: BorderSide(
                      color:
                          isSelected ? AppTheme.limeNeon : AppTheme.borderDark,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Dominant Hand & Captain Role
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('DOMINANT HAND'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppTheme.cardMid,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: Row(
                            children: ['Right', 'Left'].map((h) {
                              final sel = _dominantHand == h;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _dominantHand = h),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppTheme.surfaceVar
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$h Hand',
                                        style: AppTheme.jetBrainsMono(
                                          size: 11,
                                          weight: sel
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: sel
                                              ? AppTheme.limeNeon
                                              : AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section: Equipment (Optional)
              _buildSectionHeader('EQUIPMENT SPECS'),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('RACKET MODEL'),
                        Container(
                          decoration: _inputBoxDecoration,
                          child: TextFormField(
                            controller: _racketController,
                            style: AppTheme.spaceGrotesk(
                                size: 13, color: AppTheme.textWhite),
                            decoration: _inputDecoration(
                                'e.g. Astrox 88D', Icons.sports_tennis),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('STRING TENSION'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: _inputBoxDecoration,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_tensionLbs.toInt()} LBS',
                                style: AppTheme.jetBrainsMono(
                                  size: 13,
                                  weight: FontWeight.bold,
                                  color: AppTheme.limeNeon,
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => _tensionLbs =
                                        (_tensionLbs - 1).clamp(20.0, 34.0)),
                                    child: const Icon(
                                        Icons.remove_circle_outline,
                                        color: AppTheme.textMuted,
                                        size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => setState(() => _tensionLbs =
                                        (_tensionLbs + 1).clamp(20.0, 34.0)),
                                    child: const Icon(Icons.add_circle_outline,
                                        color: AppTheme.limeNeon, size: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Primary Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.limeNeon,
                    foregroundColor: const Color(0xFF283500),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF283500)),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'REGISTER SQUAD PROFILE',
                              style: AppTheme.chivo(
                                size: 14,
                                weight: FontWeight.w900,
                                color: const Color(0xFF283500),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward,
                                size: 18, color: Color(0xFF283500)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.limeNeon,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.jetBrainsMono(
            size: 11,
            weight: FontWeight.w800,
            color: AppTheme.limeNeon,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: AppTheme.jetBrainsMono(
          size: 10,
          weight: FontWeight.w600,
          color: AppTheme.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  BoxDecoration get _inputBoxDecoration => BoxDecoration(
        color: AppTheme.surfaceVar,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDark),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.spaceGrotesk(size: 13, color: AppTheme.textMutedDark),
      prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 18),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
