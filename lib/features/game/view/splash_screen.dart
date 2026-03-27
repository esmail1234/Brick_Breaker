import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/color_constants.dart';
import 'level_selection_screen.dart';

/// Animated splash screen with neon glow logo and tap-to-start button.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 4, end: 22).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: const LevelSelectionScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: GestureDetector(
        onTap: _startGame,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Radial background glow
            Center(
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ColorConstants.neonCyan.withOpacity(0.08),
                        blurRadius: _glowAnim.value * 8,
                        spreadRadius: _glowAnim.value * 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated title
                  AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => Text(
                      'BRICK',
                      style: GoogleFonts.orbitron(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: ColorConstants.neonCyan,
                        shadows: [
                          Shadow(
                            color: ColorConstants.neonCyan,
                            blurRadius: _glowAnim.value,
                          ),
                        ],
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => Text(
                      'BREAKER',
                      style: GoogleFonts.orbitron(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.neonPink,
                        shadows: [
                          Shadow(
                            color: ColorConstants.neonPink,
                            blurRadius: _glowAnim.value,
                          ),
                        ],
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Animated ball icon
                  AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Colors.white, ColorConstants.neonCyan],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstants.neonCyan,
                            blurRadius: _glowAnim.value,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Pulsing TAP TO PLAY
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Opacity(
                      opacity: _pulseAnim.value,
                      child: Text(
                        'TAP TO PLAY',
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          color: ColorConstants.neonCyan,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  Text(
                    'Developed by ESMAIL',
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      color: Colors.white24,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
