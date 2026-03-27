import 'package:flutter/material.dart';
import '../model/game_state_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/color_constants.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';
import '../controller/game_controller.dart';
import '../widgets/game_canvas.dart';
import '../widgets/game_hud.dart';
import 'game_over_screen.dart';
import 'splash_screen.dart';
import '../../../core/utils/sound_service.dart';

/// Root game screen: owns BLoC provider, controller, gesture handling.
class GameScreen extends StatefulWidget {
  final int initialLevel;
  const GameScreen({super.key, this.initialLevel = 1});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameBloc _bloc;
  late final GameController _controller;
  Size _screenSize = Size.zero;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _bloc = GameBloc();
    _controller = GameController(bloc: _bloc);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    if (_screenSize != size) {
      _screenSize = size;
      _controller.setScreenSize(size);
      // Start the game on first layout
      if (!_started) {
        _started = true;
        _bloc.add(LoadLevelEvent(level: widget.initialLevel, screenSize: size));
        _controller.start(this);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bloc.close();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onHorizontalDrag(DragUpdateDetails details) {
    _bloc.add(MovePaddleEvent(
      delta: details.delta.dx,
      screenWidth: _screenSize.width,
    ));
  }

  void _onTap() {
    final state = _bloc.state;
    if (state is GamePlayingState) {
      if (!state.data.ballLaunched) {
        _bloc.add(const LaunchBallEvent());
      } else if (state.data.isSticky) {
        _bloc.add(const ReleaseBallEvent());
      }
    }
  }

  void _restartGame() {
    _bloc.add(LoadLevelEvent(level: widget.initialLevel, screenSize: _screenSize));
    _controller.setScreenSize(_screenSize);
    _controller.start(this); // start re-creates the ticker safely
  }

  void _nextLevel(GameStateModel data) {
    _bloc.add(NextLevelEvent(screenSize: _screenSize, currentData: data));
    _controller.start(this);
  }

  void _goToMenu() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, anim, __) =>
            FadeTransition(opacity: anim, child: const SplashScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GameBloc>.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: ColorConstants.background,
        body: BlocConsumer<GameBloc, GameState>(
          listener: (context, state) {
            // Stop ticker on terminal states
            if (state is GameOverState || state is LevelCompletedState) {
              _controller.pause();
            }
          },
          builder: (context, state) {
            return GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDrag,
              onTap: _onTap,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  // Game canvas
                  if (state is GamePlayingState)
                    GameCanvas(state: state.data),
                  if (state is GamePausedState)
                    GameCanvas(state: state.data),

                  // HUD (always on top)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: GameHud(),
                  ),

                  // Pause overlay
                  if (state is GamePausedState)
                    _PauseOverlay(
                      onResume: () => _bloc.add(const ResumeGameEvent()),
                      onExit: _goToMenu,
                    ),

                  // Game over overlay
                  if (state is GameOverState)
                    GameOverScreen(
                      score: state.score,
                      level: state.level,
                      onRestart: _restartGame,
                      onMainMenu: _goToMenu,
                    ),

                  // Level complete overlay
                  if (state is LevelCompletedState)
                    LevelCompleteScreen(
                      level: state.data.level,
                      score: state.data.score,
                      onNextLevel: () => _nextLevel(state.data),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _PauseOverlay extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onExit;
  const _PauseOverlay({required this.onResume, required this.onExit});

  @override
  State<_PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<_PauseOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PAUSED',
              style: TextStyle(
                color: ColorConstants.neonCyan,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                      color: ColorConstants.neonCyan, blurRadius: 16)
                ],
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: widget.onResume,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: ColorConstants.neonCyan.withOpacity(0.5)),
                  color: ColorConstants.neonCyan.withOpacity(0.08),
                ),
                child: Text(
                  'RESUME',
                  style: TextStyle(
                    color: ColorConstants.neonCyan,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                setState(() {
                  SoundService.toggleMute();
                });
              },
              child: Icon(
                SoundService.isMuted 
                    ? Icons.volume_off 
                    : Icons.volume_up,
                color: Colors.white54,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: widget.onExit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: ColorConstants.neonPink.withValues(alpha: 0.5)),
                  color: ColorConstants.neonPink.withValues(alpha: 0.08),
                ),
                child: Text(
                  'EXIT TO MENU',
                  style: TextStyle(
                    color: ColorConstants.neonPink,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

