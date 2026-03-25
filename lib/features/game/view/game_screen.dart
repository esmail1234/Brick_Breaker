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

/// Root game screen: owns BLoC provider, controller, gesture handling.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

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
        _bloc.add(StartGameEvent(size));
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
    if (state is GamePlayingState && !state.data.ballLaunched) {
      _bloc.add(const LaunchBallEvent());
    }
  }

  void _restartGame() {
    _bloc.add(RestartGameEvent(_screenSize));
    _controller.setScreenSize(_screenSize);
    _controller.start(this); // start re-creates the ticker safely
  }

  void _nextLevel(GameStateModel data) {
    _bloc.add(NextLevelEvent(screenSize: _screenSize, currentData: data));
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
class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  const _PauseOverlay({required this.onResume});

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
              onTap: onResume,
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
          ],
        ),
      ),
    );
  }
}
