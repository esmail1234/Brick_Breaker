import 'package:equatable/equatable.dart';
import '../model/game_state_model.dart';

abstract class GameState extends Equatable {
  const GameState();
  @override
  List<Object?> get props => [];
}

class GameInitialState extends GameState {
  const GameInitialState();
}

class GamePlayingState extends GameState {
  final GameStateModel data;
  const GamePlayingState({required this.data});
  @override
  List<Object?> get props => [data];
}

class GamePausedState extends GameState {
  final GameStateModel data;
  const GamePausedState({required this.data});
  @override
  List<Object?> get props => [data];
}

class GameOverState extends GameState {
  final int score;
  final int level;
  const GameOverState({required this.score, required this.level});
  @override
  List<Object?> get props => [score, level];
}

class LevelCompletedState extends GameState {
  final GameStateModel data;
  const LevelCompletedState({required this.data});
  @override
  List<Object?> get props => [data];
}
