import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shuttle_logo.dart';
import 'login_screen.dart';

/// Screen 1: Welcome & Onboarding Splash Screen Matching Stitch Kinetic Aesthetic
class WelcomeSplashScreen extends StatelessWidget {
  const WelcomeSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dark Stadium Arena Background with Radial Volt Shimmer
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 1.1,
                colors: [
                  Color(0xFF171E37), // Stadium surface center
                  Color(0xFF0F162E),
                  Color(0xFF0A122A), // Deep stadium navy
                ],
              ),
            ),
          ),

          // Court Line Markings (Abstract Stadium Geometric Overlay)
          Positioned.fill(
            child: CustomPaint(
              painter: _CourtLinesPainter(),
            ),
          ),

          // Content Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Brand Header
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: SmashDeckLogo(
                      size: 72,
                      showText: true,
                      showTagline: true,
                    ),
                  ),

                  // Center Cinematic Display ("MORE THAN A GAME")
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PRECISION & VELOCITY',
                        style: AppTheme.jetBrainsMono(
                          size: 11,
                          weight: FontWeight.w700,
                          color: AppTheme.limeNeon,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'COLLEGIATE SQUAD LADDER',
                        textAlign: TextAlign.center,
                        style: AppTheme.chivo(
                          size: 32,
                          weight: FontWeight.w900,
                          color: AppTheme.textWhite,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.limeNeon,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.limeNeon.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom Action Section
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.limeNeon,
                            foregroundColor: const Color(0xFF283500),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                            shadowColor:
                                AppTheme.limeNeon.withValues(alpha: 0.4),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ENTER SMASHDECK',
                                style: AppTheme.chivo(
                                  size: 15,
                                  weight: FontWeight.w900,
                                  color: const Color(0xFF283500),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward,
                                  size: 18, color: Color(0xFF283500)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'SMASH CLUB • 7 SQUAD MEMBERS',
                        style: AppTheme.jetBrainsMono(
                          size: 10.5,
                          weight: FontWeight.w600,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer court boundaries
    canvas.drawLine(Offset(0, h * 0.70), Offset(w, h * 0.58), linePaint);
    canvas.drawLine(Offset(0, h * 0.82), Offset(w, h * 0.70), linePaint);
    canvas.drawLine(Offset(w * 0.48, h * 0.50), Offset(w * 0.52, h), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
