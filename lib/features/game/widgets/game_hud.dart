import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/color_constants.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';
import '../model/game_state_model.dart';
import '../model/power_up_model.dart';

/// HUD: score, high score, level, lives, pause, active power-up timer bar.
class GameHud extends StatelessWidget {
  const GameHud({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      buildWhen: (_, curr) => curr is GamePlayingState || curr is GamePausedState,
      builder: (context, state) {
        final data = switch (state) {
          GamePlayingState s => s.data,
          GamePausedState s  => s.data,
          _                  => null,
        };
        if (data == null) return const SizedBox.shrink();
        final isPaused = state is GamePausedState;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    _NeonStat(label: 'SCORE', value: '${data.score}', color: ColorConstants.neonCyan),
                    const SizedBox(width: 6),
                    _NeonStat(label: 'BEST', value: '${data.highScore}', color: ColorConstants.neonPink),
                    const Spacer(),
                    _NeonStat(label: 'LVL', value: '${data.level}', color: ColorConstants.neonBlue),
                    const Spacer(),
                    // Lives
                    Row(children: List.generate(3, (i) => Icon(Icons.favorite, size: 18,
                        color: i < data.lives ? ColorConstants.heartColor : Colors.white12))),
                    const SizedBox(width: 10),
                    // Pause button
                    GestureDetector(
                      onTap: () => isPaused
                          ? context.read<GameBloc>().add(const ResumeGameEvent())
                          : context.read<GameBloc>().add(const PauseGameEvent()),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(color: Colors.white24)),
                        child: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            color: Colors.white70, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Power-up timer bar
            _PowerUpBar(data: data),
          ],
        );
      },
    );
  }
}

// ── Power-up timer bar ────────────────────────────────────────────────────────
class _PowerUpBar extends StatelessWidget {
  final GameStateModel data;
  const _PowerUpBar({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.activePowerUpType == null || data.activePowerUpTimer <= 0) {
      return const SizedBox.shrink();
    }
    final frac = (data.activePowerUpTimer / data.activePowerUpMaxTimer).clamp(0.0, 1.0);
    final color = _puColor(data.activePowerUpType!);
    final icon  = _puIcon(data.activePowerUpType!);

    return Container(
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(children: [
                Container(height: 6, color: Colors.white10),
                FractionallySizedBox(
                  widthFactor: frac,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: color, blurRadius: 6)],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Color _puColor(PowerUpType t) {
    switch (t) {
      case PowerUpType.expandPaddle: return ColorConstants.puExpand;
      case PowerUpType.shrinkPaddle: return ColorConstants.puShrink;
      case PowerUpType.slowBall:     return ColorConstants.puSlow;
      case PowerUpType.multiBall:    return ColorConstants.puMultiBall;
      case PowerUpType.shield:       return ColorConstants.puShield;
      case PowerUpType.laserPaddle:  return Colors.redAccent;
      case PowerUpType.fireball:     return Colors.deepOrange;
      case PowerUpType.catchBall:    return Colors.greenAccent;
      case PowerUpType.extraLife:    return Colors.pinkAccent;
    }
  }

  String _puIcon(PowerUpType t) {
    switch (t) {
      case PowerUpType.expandPaddle: return '↔';
      case PowerUpType.shrinkPaddle: return '↕';
      case PowerUpType.slowBall:     return 'S';
      case PowerUpType.multiBall:    return '×3';
      case PowerUpType.shield:       return '🛡';
      case PowerUpType.laserPaddle:  return '⚡';
      case PowerUpType.fireball:     return '🔥';
      case PowerUpType.catchBall:    return '🧲';
      case PowerUpType.extraLife:    return '❤';
    }
  }
}

// ── NeonStat ──────────────────────────────────────────────────────────────────
class _NeonStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _NeonStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 9, letterSpacing: 1.5)),
        Text(value, style: GoogleFonts.orbitron(
            color: color, fontSize: 17, fontWeight: FontWeight.bold,
            shadows: [Shadow(color: color.withValues(alpha: 0.7), blurRadius: 8)])),
      ],
    );
  }
}
