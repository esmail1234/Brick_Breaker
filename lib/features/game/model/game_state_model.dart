import 'package:equatable/equatable.dart';
import 'ball_model.dart';
import 'paddle_model.dart';
import 'brick_model.dart';
import 'particle_model.dart';
import 'power_up_model.dart';
import 'laser_model.dart';
import 'floating_text_model.dart';

/// Complete snapshot of the game world, including all new feature state.
class GameStateModel extends Equatable {
  // Core objects
  final List<BallModel> balls;
  final PaddleModel paddle;
  final List<BrickModel> bricks;
  final List<PowerUpModel> powerUps;
  final List<ParticleModel> particles;
  final List<LaserModel> lasers;
  final List<FloatingTextModel> floatingTexts;

  // Scoring
  final int score;
  final int highScore;
  final int lives;
  final int level;
  final int unlockedLevel;
  final int themeIndex;

  // Combo
  final int comboCount;
  final double comboTimer;
  final int maxCombo;

  // Power-up display timer (for HUD bar)
  final PowerUpType? activePowerUpType;
  final double activePowerUpTimer;
  final double activePowerUpMaxTimer;
  final double slowBallTimer;

  // Shield
  final bool hasShield;
  final double shieldTimer;
  // Power-Ups Extras
  final bool isSticky;
  final bool hasFireball;
  final double fireballTimer;
  final int hitCount; // For descending bricks
  final int spawnedRowsCount; // Current count of rows added
  final int maxSpawnedRows;   // Limit for this level (2-4)

  // Misc gameplay
  final bool ballLaunched;
  final double shakeTimer;    // > 0 → screen shake active
  final double timeScale;     // 1.0 = normal, < 1.0 = slow-mo
  final bool pendingGameOver; // true while slow-mo plays before showing game over
  final double pendingTimer;  // countdown before GameOverState is emitted

  const GameStateModel({
    required this.balls,
    required this.paddle,
    required this.bricks,
    required this.powerUps,
    required this.particles,
    required this.lasers,
    required this.floatingTexts,
    required this.score,
    required this.highScore,
    required this.lives,
    required this.level,
    required this.unlockedLevel,
    required this.themeIndex,
    required this.comboCount,
    required this.comboTimer,
    required this.maxCombo,
    required this.activePowerUpType,
    required this.activePowerUpTimer,
    required this.activePowerUpMaxTimer,
    required this.slowBallTimer,
    required this.hasShield,
    required this.shieldTimer,
    required this.isSticky,
    required this.hasFireball,
    required this.fireballTimer,
    required this.hitCount,
    required this.spawnedRowsCount,
    required this.maxSpawnedRows,
    required this.ballLaunched,
    required this.shakeTimer,
    required this.timeScale,
    required this.pendingGameOver,
    required this.pendingTimer,
  });

  GameStateModel copyWith({
    List<BallModel>? balls,
    PaddleModel? paddle,
    List<BrickModel>? bricks,
    List<PowerUpModel>? powerUps,
    List<ParticleModel>? particles,
    List<LaserModel>? lasers,
    List<FloatingTextModel>? floatingTexts,
    int? score,
    int? highScore,
    int? lives,
    int? level,
    int? unlockedLevel,
    int? themeIndex,
    int? comboCount,
    double? comboTimer,
    int? maxCombo,
    PowerUpType? activePowerUpType,
    bool clearActivePowerUp = false,
    double? activePowerUpTimer,
    double? activePowerUpMaxTimer,
    double? slowBallTimer,
    bool? hasShield,
    double? shieldTimer,
    bool? isSticky,
    bool? hasFireball,
    double? fireballTimer,
    int? hitCount,
    int? spawnedRowsCount,
    int? maxSpawnedRows,
    bool? ballLaunched,
    double? shakeTimer,
    double? timeScale,
    bool? pendingGameOver,
    double? pendingTimer,
  }) {
    return GameStateModel(
      balls: balls ?? this.balls,
      paddle: paddle ?? this.paddle,
      bricks: bricks ?? this.bricks,
      powerUps: powerUps ?? this.powerUps,
      particles: particles ?? this.particles,
      lasers: lasers ?? this.lasers,
      floatingTexts: floatingTexts ?? this.floatingTexts,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      lives: lives ?? this.lives,
      level: level ?? this.level,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      themeIndex: themeIndex ?? this.themeIndex,
      comboCount: comboCount ?? this.comboCount,
      comboTimer: comboTimer ?? this.comboTimer,
      maxCombo: maxCombo ?? this.maxCombo,
      activePowerUpType: clearActivePowerUp ? null : (activePowerUpType ?? this.activePowerUpType),
      activePowerUpTimer: activePowerUpTimer ?? this.activePowerUpTimer,
      activePowerUpMaxTimer: activePowerUpMaxTimer ?? this.activePowerUpMaxTimer,
      slowBallTimer: slowBallTimer ?? this.slowBallTimer,
      hasShield: hasShield ?? this.hasShield,
      shieldTimer: shieldTimer ?? this.shieldTimer,
      isSticky: isSticky ?? this.isSticky,
      hasFireball: hasFireball ?? this.hasFireball,
      fireballTimer: fireballTimer ?? this.fireballTimer,
      hitCount: hitCount ?? this.hitCount,
      spawnedRowsCount: spawnedRowsCount ?? this.spawnedRowsCount,
      maxSpawnedRows: maxSpawnedRows ?? this.maxSpawnedRows,
      ballLaunched: ballLaunched ?? this.ballLaunched,
      shakeTimer: shakeTimer ?? this.shakeTimer,
      timeScale: timeScale ?? this.timeScale,
      pendingGameOver: pendingGameOver ?? this.pendingGameOver,
      pendingTimer: pendingTimer ?? this.pendingTimer,
    );
  }

  @override
  List<Object?> get props => [
        balls, paddle, bricks, powerUps, particles, lasers, floatingTexts,
        score, highScore, lives, level, unlockedLevel, themeIndex,
        comboCount, comboTimer, maxCombo,
        activePowerUpType, activePowerUpTimer, slowBallTimer,
        hasShield, shieldTimer, isSticky, hasFireball, fireballTimer, hitCount, spawnedRowsCount, maxSpawnedRows,
        ballLaunched, shakeTimer, timeScale,
        pendingGameOver, pendingTimer,
      ];
}
