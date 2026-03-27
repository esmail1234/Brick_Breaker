import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../model/game_state_model.dart';
import '../model/power_up_model.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();
  @override
  List<Object?> get props => [];
}

class StartGameEvent extends GameEvent {
  final Size screenSize;
  const StartGameEvent(this.screenSize);
  @override
  List<Object?> get props => [screenSize];
}

class RestartGameEvent extends GameEvent {
  final Size screenSize;
  const RestartGameEvent(this.screenSize);
  @override
  List<Object?> get props => [screenSize];
}

class NextLevelEvent extends GameEvent {
  final Size screenSize;
  final GameStateModel currentData;
  const NextLevelEvent({required this.screenSize, required this.currentData});
  @override
  List<Object?> get props => [screenSize, currentData];
}

class TickGameEvent extends GameEvent {
  final double deltaTime;
  final Size screenSize;
  const TickGameEvent({required this.deltaTime, required this.screenSize});
  @override
  List<Object?> get props => [deltaTime, screenSize];
}

class MovePaddleEvent extends GameEvent {
  final double delta;
  final double screenWidth;
  const MovePaddleEvent({required this.delta, required this.screenWidth});
  @override
  List<Object?> get props => [delta, screenWidth];
}

class LaunchBallEvent extends GameEvent {
  const LaunchBallEvent();
}

class PauseGameEvent extends GameEvent {
  const PauseGameEvent();
}

class ResumeGameEvent extends GameEvent {
  const ResumeGameEvent();
}

class CollectPowerUpEvent extends GameEvent {
  final PowerUpType type;
  const CollectPowerUpEvent(this.type);
  @override
  List<Object?> get props => [type];
}

class ReleaseBallEvent extends GameEvent {
  const ReleaseBallEvent();
}

class LoadLevelEvent extends GameEvent {
  final int level;
  final Size screenSize;
  const LoadLevelEvent({required this.level, required this.screenSize});
  @override
  List<Object?> get props => [level, screenSize];
}
