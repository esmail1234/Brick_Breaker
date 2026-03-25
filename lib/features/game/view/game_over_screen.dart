import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/color_constants.dart';

/// Displayed when all lives are gone.
class GameOverScreen extends StatefulWidget {
  final int score;
  final int level;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.level,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.scale(
          scale: _scaleAnim.value,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D2B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ColorConstants.neonPink.withOpacity(0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: ColorConstants.neonPink.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 2),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('GAME OVER',
                      style: GoogleFonts.orbitron(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: ColorConstants.neonPink,
                          shadows: [
                            Shadow(
                                color: ColorConstants.neonPink,
                                blurRadius: 16)
                          ])),
                  const SizedBox(height: 24),
                  Text('SCORE',
                      style: GoogleFonts.orbitron(
                          fontSize: 12,
                          color: Colors.white38,
                          letterSpacing: 3)),
                  Text('${widget.score}',
                      style: GoogleFonts.orbitron(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.neonCyan,
                          shadows: [
                            Shadow(
                                color: ColorConstants.neonCyan,
                                blurRadius: 12)
                          ])),
                  const SizedBox(height: 4),
                  Text('LEVEL ${widget.level}',
                      style: GoogleFonts.orbitron(
                          fontSize: 14,
                          color: Colors.white54,
                          letterSpacing: 2)),
                  const SizedBox(height: 32),
                  _NeonButton(
                      label: 'PLAY AGAIN',
                      color: ColorConstants.neonCyan,
                      onTap: widget.onRestart),
                  const SizedBox(height: 12),
                  _NeonButton(
                      label: 'MAIN MENU',
                      color: Colors.white38,
                      onTap: widget.onMainMenu),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Displayed when all bricks are cleared.
class LevelCompleteScreen extends StatefulWidget {
  final int level;
  final int score;
  final VoidCallback onNextLevel;

  const LevelCompleteScreen({
    super.key,
    required this.level,
    required this.score,
    required this.onNextLevel,
  });

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<double>(begin: -60, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D2B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: ColorConstants.neonCyan.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: ColorConstants.neonCyan.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 2),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('LEVEL ${widget.level}',
                      style: GoogleFonts.orbitron(
                          fontSize: 16,
                          color: Colors.white54,
                          letterSpacing: 4)),
                  const SizedBox(height: 8),
                  Text('COMPLETE!',
                      style: GoogleFonts.orbitron(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: ColorConstants.neonCyan,
                          shadows: [
                            Shadow(
                                color: ColorConstants.neonCyan,
                                blurRadius: 18)
                          ])),
                  const SizedBox(height: 24),
                  Text('+${(widget.level) * 150} BONUS',
                      style: GoogleFonts.orbitron(
                          fontSize: 18,
                          color: ColorConstants.puShield,
                          shadows: [
                            Shadow(
                                color: ColorConstants.puShield,
                                blurRadius: 8)
                          ])),
                  const SizedBox(height: 4),
                  Text('SCORE  ${widget.score}',
                      style: GoogleFonts.orbitron(
                          fontSize: 14,
                          color: Colors.white38,
                          letterSpacing: 2)),
                  const SizedBox(height: 36),
                  _NeonButton(
                      label: 'NEXT LEVEL →',
                      color: ColorConstants.neonCyan,
                      onTap: widget.onNextLevel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _NeonButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NeonButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.6)),
          color: color.withOpacity(0.08),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.15), blurRadius: 12)
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
