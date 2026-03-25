import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/game_constants.dart';
import '../model/ball_model.dart';
import '../model/brick_model.dart';
import '../model/game_state_model.dart';
import '../model/paddle_model.dart';
import '../model/power_up_model.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  int _powerUpIdCounter = 0;

  GameBloc() : super(const GameInitialState()) {
    on<StartGameEvent>(_onStartGame);
    on<RestartGameEvent>(_onRestartGame);
    on<NextLevelEvent>(_onNextLevel);
    on<TickGameEvent>(_onTick);
    on<MovePaddleEvent>(_onMovePaddle);
    on<LaunchBallEvent>(_onLaunchBall);
    on<PauseGameEvent>(_onPause);
    on<ResumeGameEvent>(_onResume);
  }

  // ── Event Handlers ────────────────────────────────────────────────────────

  void _onStartGame(StartGameEvent e, Emitter<GameState> emit) {
    emit(GamePlayingState(data: _buildLevel(e.screenSize, 1, GameConstants.maxLives, 0)));
  }

  void _onRestartGame(RestartGameEvent e, Emitter<GameState> emit) {
    _powerUpIdCounter = 0;
    emit(GamePlayingState(data: _buildLevel(e.screenSize, 1, GameConstants.maxLives, 0)));
  }

  void _onNextLevel(NextLevelEvent e, Emitter<GameState> emit) {
    final d = e.currentData;
    final newScore = d.score + GameConstants.scoreBonusPerLevel;
    emit(GamePlayingState(
        data: _buildLevel(e.screenSize, d.level + 1, d.lives, newScore)));
  }

  void _onLaunchBall(LaunchBallEvent e, Emitter<GameState> emit) {
    if (state is! GamePlayingState) return;
    final d = (state as GamePlayingState).data;
    if (d.ballLaunched) return;

    final speed = (GameConstants.initialBallSpeed +
            (d.level - 1) * GameConstants.ballSpeedIncrement)
        .clamp(GameConstants.initialBallSpeed, GameConstants.maxBallSpeed);
    const angle = -math.pi / 3.5;
    final vel = Offset(math.cos(angle) * speed, math.sin(angle) * speed);
    emit(GamePlayingState(
        data: d.copyWith(balls: [d.balls.first.copyWith(velocity: vel)], ballLaunched: true)));
  }

  void _onMovePaddle(MovePaddleEvent e, Emitter<GameState> emit) {
    if (state is! GamePlayingState) return;
    final d = (state as GamePlayingState).data;
    final paddle = d.paddle;
    final newX = (paddle.x + e.delta).clamp(0.0, e.screenWidth - paddle.width);
    List<BallModel> updatedBalls = d.balls;
    if (!d.ballLaunched && d.balls.isNotEmpty) {
      updatedBalls = [
        d.balls.first.copyWith(position: Offset(newX + paddle.width / 2, d.balls.first.position.dy))
      ];
    }
    emit(GamePlayingState(data: d.copyWith(paddle: paddle.copyWith(x: newX), balls: updatedBalls)));
  }

  void _onPause(PauseGameEvent e, Emitter<GameState> emit) {
    if (state is GamePlayingState) {
      emit(GamePausedState(data: (state as GamePlayingState).data));
    }
  }

  void _onResume(ResumeGameEvent e, Emitter<GameState> emit) {
    if (state is GamePausedState) {
      emit(GamePlayingState(data: (state as GamePausedState).data));
    }
  }

  void _onTick(TickGameEvent e, Emitter<GameState> emit) {
    if (state is! GamePlayingState) return;
    final d = (state as GamePlayingState).data;
    if (!d.ballLaunched) return;

    final updated = _physicsStep(d, e.deltaTime, e.screenSize);

    if (updated.lives <= 0) {
      HapticFeedback.heavyImpact();
      emit(GameOverState(score: updated.score, level: updated.level));
      return;
    }
    if (updated.bricks.every((b) => b.isDestroyed)) {
      emit(LevelCompletedState(data: updated));
      return;
    }
    emit(GamePlayingState(data: updated));
  }

  // ── Physics Engine ─────────────────────────────────────────────────────────

  GameStateModel _physicsStep(GameStateModel d, double dt, Size screen) {
    var balls = List<BallModel>.from(d.balls);
    var bricks = List<BrickModel>.from(d.bricks);
    var powerUps = List<PowerUpModel>.from(d.powerUps);
    var paddle = d.paddle;
    var score = d.score;
    var lives = d.lives;
    var hasShield = d.hasShield;
    var shieldTimer = d.shieldTimer;
    var ballLaunched = d.ballLaunched;

    // Shield timer
    if (hasShield) {
      shieldTimer = (shieldTimer - dt).clamp(0.0, double.infinity);
      if (shieldTimer == 0) hasShield = false;
    }

    // Paddle rect for collisions
    final paddleRect =
        Rect.fromLTWH(paddle.x, paddle.y, paddle.width, GameConstants.paddleHeight);

    // ── Power-ups: fall & collect ──────────────────────────────────────────
    final remainingPUs = <PowerUpModel>[];
    for (var pu in powerUps) {
      if (!pu.isActive) continue;
      final updated = pu.copyWith(
          position: pu.position + Offset(0, GameConstants.powerUpFallSpeed * dt));
      if (updated.position.dy > screen.height) continue; // gone
      if (updated.rect.overlaps(paddleRect)) {
        // Apply effect
        final result = _applyPowerUp(updated.type, balls, paddle, hasShield, shieldTimer);
        balls = result['balls'] as List<BallModel>;
        paddle = result['paddle'] as PaddleModel;
        hasShield = result['hasShield'] as bool;
        shieldTimer = result['shieldTimer'] as double;
        HapticFeedback.lightImpact();
      } else {
        remainingPUs.add(updated);
      }
    }
    powerUps = remainingPUs;

    // ── Ball physics ────────────────────────────────────────────────────────
    final newBalls = <BallModel>[];
    bool lostBall = false;

    for (var ball in balls) {
      if (!ball.isActive) continue;
      var pos = ball.position + ball.velocity * dt;
      var vel = ball.velocity;

      // Walls
      if (pos.dx - ball.radius < 0) {
        pos = Offset(ball.radius, pos.dy);
        vel = Offset(vel.dx.abs(), vel.dy);
        HapticFeedback.selectionClick();
      }
      if (pos.dx + ball.radius > screen.width) {
        pos = Offset(screen.width - ball.radius, pos.dy);
        vel = Offset(-vel.dx.abs(), vel.dy);
        HapticFeedback.selectionClick();
      }
      if (pos.dy - ball.radius < 0) {
        pos = Offset(pos.dx, ball.radius);
        vel = Offset(vel.dx, vel.dy.abs());
        HapticFeedback.selectionClick();
      }

      // Bottom edge
      if (pos.dy + ball.radius > screen.height) {
        if (hasShield) {
          pos = Offset(pos.dx, screen.height - ball.radius);
          vel = Offset(vel.dx, -vel.dy.abs());
        } else {
          lostBall = true;
          continue;
        }
      }

      // Paddle collision (only when moving down)
      final ballRect = Rect.fromCircle(center: pos, radius: ball.radius);
      if (vel.dy > 0 && ballRect.overlaps(paddleRect)) {
        final hitRatio = ((pos.dx - paddle.x) / paddle.width).clamp(0.0, 1.0);
        final angle =
            (hitRatio - 0.5) * 2.0 * (GameConstants.maxDeflectionAngleDeg * math.pi / 180.0);
        final spd = vel.distance;
        vel = Offset(math.sin(angle) * spd, -math.cos(angle).abs() * spd);
        pos = Offset(pos.dx, paddle.y - ball.radius);
        HapticFeedback.lightImpact();
      }

      // Brick collisions
      var bouncedH = false;
      var bouncedV = false;
      for (int i = 0; i < bricks.length; i++) {
        final brick = bricks[i];
        if (brick.isDestroyed) continue;
        final ballR = Rect.fromCircle(center: pos, radius: ball.radius);
        if (!ballR.overlaps(brick.rect)) continue;

        // Determine side using penetration depth
        final overlapL = ballR.right - brick.rect.left;
        final overlapR = brick.rect.right - ballR.left;
        final overlapT = ballR.bottom - brick.rect.top;
        final overlapB = brick.rect.bottom - ballR.top;
        final minH = math.min(overlapL, overlapR);
        final minV = math.min(overlapT, overlapB);

        if (minH < minV && !bouncedH) {
          vel = Offset(-vel.dx, vel.dy);
          bouncedH = true;
        } else if (!bouncedV) {
          vel = Offset(vel.dx, -vel.dy);
          bouncedV = true;
        }

        bricks[i] = brick.hit();
        if (bricks[i].isDestroyed) {
          score += GameConstants.scorePerBrick;
          // Maybe drop power-up
          if (math.Random().nextDouble() < GameConstants.powerUpDropChance) {
            final types = PowerUpType.values;
            final type = types[math.Random().nextInt(types.length)];
            powerUps.add(PowerUpModel(
              id: _powerUpIdCounter++,
              type: type,
              position: brick.rect.center,
            ));
          }
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.selectionClick();
        }
      }

      newBalls.add(ball.copyWith(position: pos, velocity: vel));
    }

    // Ball lost?
    if (lostBall && newBalls.isEmpty) {
      lives -= 1;
      if (lives > 0) {
        final cx = paddle.x + paddle.width / 2;
        final by = paddle.y - GameConstants.ballRadius - 2;
        newBalls.add(BallModel(
          position: Offset(cx, by),
          velocity: Offset.zero,
          radius: GameConstants.ballRadius,
        ));
        ballLaunched = false;
      }
    }

    return d.copyWith(
      balls: newBalls,
      bricks: bricks,
      powerUps: powerUps,
      paddle: paddle,
      score: score,
      lives: lives,
      hasShield: hasShield,
      shieldTimer: shieldTimer,
      ballLaunched: ballLaunched,
    );
  }

  // ── Power-up Application ───────────────────────────────────────────────────

  Map<String, dynamic> _applyPowerUp(
    PowerUpType type,
    List<BallModel> balls,
    PaddleModel paddle,
    bool hasShield,
    double shieldTimer,
  ) {
    switch (type) {
      case PowerUpType.expandPaddle:
        final w = (paddle.width * GameConstants.expandFactor)
            .clamp(paddle.width, GameConstants.paddleMaxWidth);
        return {'balls': balls, 'paddle': paddle.copyWith(width: w), 'hasShield': hasShield, 'shieldTimer': shieldTimer};

      case PowerUpType.shrinkPaddle:
        final w = (paddle.width * GameConstants.shrinkFactor)
            .clamp(GameConstants.paddleMinWidth, paddle.width);
        return {'balls': balls, 'paddle': paddle.copyWith(width: w), 'hasShield': hasShield, 'shieldTimer': shieldTimer};

      case PowerUpType.slowBall:
        final slow = balls.map((b) {
          final spd = b.velocity.distance;
          if (spd == 0) return b;
          final newSpd = (spd * GameConstants.slowFactor)
              .clamp(GameConstants.initialBallSpeed * 0.5, spd);
          final dir = b.velocity / spd;
          return b.copyWith(velocity: dir * newSpd);
        }).toList();
        return {'balls': slow, 'paddle': paddle, 'hasShield': hasShield, 'shieldTimer': shieldTimer};

      case PowerUpType.multiBall:
        final extra = <BallModel>[];
        if (balls.isNotEmpty) {
          final ref = balls.first;
          final spd = ref.velocity.distance > 0
              ? ref.velocity.distance
              : GameConstants.initialBallSpeed;
          for (final offset in [-0.45, 0.45]) {
            final a = math.atan2(ref.velocity.dy, ref.velocity.dx) + offset;
            extra.add(BallModel(
              position: ref.position,
              velocity: Offset(math.cos(a) * spd, math.sin(a) * spd),
              radius: GameConstants.ballRadius,
            ));
          }
        }
        return {'balls': [...balls, ...extra], 'paddle': paddle, 'hasShield': hasShield, 'shieldTimer': shieldTimer};

      case PowerUpType.shield:
        return {'balls': balls, 'paddle': paddle, 'hasShield': true, 'shieldTimer': GameConstants.shieldDuration};
    }
  }

  // ── Level Builder ──────────────────────────────────────────────────────────

  GameStateModel _buildLevel(Size screen, int level, int lives, int score) {
    const cols = GameConstants.brickCols;
    final totalH = (cols + 1) * GameConstants.brickPaddingH;
    final brickW = (screen.width - totalH) / cols;
    final rows = math.min(3 + level, 8);

    final bricks = <BrickModel>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final left = GameConstants.brickPaddingH + c * (brickW + GameConstants.brickPaddingH);
        final top = GameConstants.brickTopOffset +
            r * (GameConstants.brickHeight + GameConstants.brickPaddingV);
        final maxDur = math.min(
            1 + (level - 1) ~/ 2 + r ~/ 2, GameConstants.maxBrickDurability);
        final durability = math.max(1, math.Random().nextInt(maxDur) + 1);
        bricks.add(BrickModel(
          id: r * cols + c,
          row: r,
          col: c,
          rect: Rect.fromLTWH(left, top, brickW, GameConstants.brickHeight),
          durability: durability,
        ));
      }
    }

    final paddleY = screen.height - GameConstants.paddleBottomOffset;
    final paddleX = (screen.width - GameConstants.paddleInitialWidth) / 2;
    final paddle = PaddleModel(x: paddleX, y: paddleY, width: GameConstants.paddleInitialWidth);
    final ballPos = Offset(screen.width / 2, paddleY - GameConstants.ballRadius - 2);

    return GameStateModel(
      balls: [BallModel(position: ballPos, velocity: Offset.zero, radius: GameConstants.ballRadius)],
      paddle: paddle,
      bricks: bricks,
      powerUps: const [],
      score: score,
      lives: lives,
      level: level,
      hasShield: false,
      shieldTimer: 0,
      ballLaunched: false,
    );
  }
}
