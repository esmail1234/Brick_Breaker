import 'package:flutter/scheduler.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';
import 'package:flutter/material.dart';

/// Owns the Ticker and drives the BLoC game loop at ~60 FPS.
class GameController {
  final GameBloc bloc;
  Ticker? _ticker;
  Duration _lastTime = Duration.zero;
  Size _screenSize = Size.zero;

  GameController({required this.bloc});

  void setScreenSize(Size size) => _screenSize = size;

  void start(TickerProvider vsync) {
    _ticker ??= vsync.createTicker(_onTick);
    _lastTime = Duration.zero;
    if (_ticker?.isTicking == false) {
      _ticker?.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }
    final rawDt = (elapsed - _lastTime).inMicroseconds / 1_000_000.0;
    // Clamp to avoid huge dt spikes when app is backgrounded
    final dt = rawDt.clamp(0.0, 0.05);
    _lastTime = elapsed;

    if (_screenSize == Size.zero) return;
    if (bloc.state is GamePlayingState) {
      bloc.add(TickGameEvent(deltaTime: dt, screenSize: _screenSize));
    }
  }

  void pause() {
    _ticker?.stop();
    bloc.add(const PauseGameEvent());
  }

  void resume(TickerProvider vsync) {
    _lastTime = Duration.zero;
    if (_ticker?.isTicking == false) _ticker?.start();
    bloc.add(const ResumeGameEvent());
  }

  void dispose() {
    _ticker?.dispose();
    _ticker = null;
  }
}
