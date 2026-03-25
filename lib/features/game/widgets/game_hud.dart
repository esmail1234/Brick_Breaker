import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/color_constants.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';

/// Top HUD bar: score, level, lives + pause button.
class GameHud extends StatelessWidget {
  const GameHud({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      buildWhen: (prev, curr) =>
          curr is GamePlayingState || curr is GamePausedState,
      builder: (context, state) {
        final data = switch (state) {
          GamePlayingState s => s.data,
          GamePausedState s => s.data,
          _ => null,
        };
        if (data == null) return const SizedBox.shrink();
        final isPaused = state is GamePausedState;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                // Score
                _NeonStat(
                  label: 'SCORE',
                  value: '${data.score}',
                  color: ColorConstants.neonCyan,
                ),
                const Spacer(),
                // Level
                _NeonStat(
                  label: 'LVL',
                  value: '${data.level}',
                  color: ColorConstants.neonBlue,
                ),
                const Spacer(),
                // Lives (hearts)
                Row(
                  children: List.generate(
                    3,
                    (i) => Icon(
                      Icons.favorite,
                      size: 18,
                      color: i < data.lives
                          ? ColorConstants.heartColor
                          : Colors.white12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Pause / Resume
                GestureDetector(
                  onTap: () {
                    if (isPaused) {
                      context.read<GameBloc>().add(const ResumeGameEvent());
                    } else {
                      context.read<GameBloc>().add(const PauseGameEvent());
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NeonStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NeonStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: color.withOpacity(0.7), blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}
