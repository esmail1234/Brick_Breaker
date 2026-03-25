import 'package:equatable/equatable.dart';
import 'ball_model.dart';
import 'paddle_model.dart';
import 'brick_model.dart';
import 'power_up_model.dart';

/// Composite snapshot of the entire game world.
class GameStateModel extends Equatable {
  final List<BallModel> balls;
  final PaddleModel paddle;
  final List<BrickModel> bricks;
  final List<PowerUpModel> powerUps;
  final int score;
  final int lives;
  final int level;
  final bool hasShield;
  final double shieldTimer;
  final bool ballLaunched;

  const GameStateModel({
    required this.balls,
    required this.paddle,
    required this.bricks,
    required this.powerUps,
    required this.score,
    required this.lives,
    required this.level,
    required this.hasShield,
    required this.shieldTimer,
    required this.ballLaunched,
  });

  GameStateModel copyWith({
    List<BallModel>? balls,
    PaddleModel? paddle,
    List<BrickModel>? bricks,
    List<PowerUpModel>? powerUps,
    int? score,
    int? lives,
    int? level,
    bool? hasShield,
    double? shieldTimer,
    bool? ballLaunched,
  }) {
    return GameStateModel(
      balls: balls ?? this.balls,
      paddle: paddle ?? this.paddle,
      bricks: bricks ?? this.bricks,
      powerUps: powerUps ?? this.powerUps,
      score: score ?? this.score,
      lives: lives ?? this.lives,
      level: level ?? this.level,
      hasShield: hasShield ?? this.hasShield,
      shieldTimer: shieldTimer ?? this.shieldTimer,
      ballLaunched: ballLaunched ?? this.ballLaunched,
    );
  }

  @override
  List<Object?> get props => [
        balls,
        paddle,
        bricks,
        powerUps,
        score,
        lives,
        level,
        hasShield,
        shieldTimer,
        ballLaunched,
      ];
}
