import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/utils/score_service.dart';
import '../../../core/utils/sound_service.dart';
import '../model/ball_model.dart';
import '../model/brick_model.dart';
import '../model/game_state_model.dart';
import '../model/paddle_model.dart';
import '../model/particle_model.dart';
import '../model/power_up_model.dart';
import '../model/laser_model.dart';
import '../model/floating_text_model.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  int _powerUpIdCounter = 0;
  int _particleIdCounter = 0;
  int _laserIdCounter = 0;
  int _textIdCounter = 0;
  int _highScore = 0;
  double _laserTimer = 0.0;
  double _bossMinionTimer = 0.0;

  GameBloc() : super(const GameInitialState()) {
    on<StartGameEvent>(_onStartGame);
    on<RestartGameEvent>(_onRestartGame);
    on<NextLevelEvent>(_onNextLevel);
    on<LoadLevelEvent>(_onLoadLevel);
    on<TickGameEvent>(_onTick);
    on<MovePaddleEvent>(_onMovePaddle);
    on<LaunchBallEvent>(_onLaunchBall);
    on<ReleaseBallEvent>(_onReleaseBall);
    on<PauseGameEvent>(_onPause);
    on<ResumeGameEvent>(_onResume);
    ScoreService.getHighScore().then((hs) => _highScore = hs);
  }

  void _onStartGame(StartGameEvent e, Emitter<GameState> emit) => emit(
    GamePlayingState(
      data: _buildLevel(e.screenSize, 1, GameConstants.maxLives, 0),
    ),
  );

  void _onRestartGame(RestartGameEvent e, Emitter<GameState> emit) {
    _powerUpIdCounter = 0;
    _particleIdCounter = 0;
    _laserIdCounter = 0;
    _textIdCounter = 0;
    emit(
      GamePlayingState(
        data: _buildLevel(e.screenSize, 1, GameConstants.maxLives, 0),
      ),
    );
  }

  void _onNextLevel(NextLevelEvent e, Emitter<GameState> emit) {
    final d = e.currentData;
    final bonus = d.level * GameConstants.scoreBonusPerLevel;
    emit(
      GamePlayingState(
        data: _buildLevel(
          e.screenSize,
          d.level + 1,
          d.lives,
          d.score + bonus,
          highScore: d.highScore,
          unlocked: math.max(d.level + 1, d.unlockedLevel),
        ),
      ),
    );
  }

  void _onLoadLevel(LoadLevelEvent e, Emitter<GameState> emit) {
    emit(
      GamePlayingState(
        data: _buildLevel(
          e.screenSize,
          e.level,
          GameConstants.maxLives,
          0,
          highScore: _highScore,
        ),
      ),
    );
  }

  void _onLaunchBall(LaunchBallEvent e, Emitter<GameState> emit) {
    if (state is! GamePlayingState) return;
    final d = (state as GamePlayingState).data;
    if (d.ballLaunched || d.balls.isEmpty) return;
    final speed = (GameConstants.initialBallSpeed +
            (d.level - 1) * GameConstants.ballSpeedIncrement)
        .clamp(GameConstants.initialBallSpeed, GameConstants.maxBallSpeed);
    const angle = -math.pi / 3.5;
    final vel = Offset(math.cos(angle) * speed, math.sin(angle) * speed);
    emit(
      GamePlayingState(
        data: d.copyWith(
          balls: [d.balls.first.copyWith(velocity: vel)],
          ballLaunched: true,
        ),
      ),
    );
  }

  void _onReleaseBall(ReleaseBallEvent e, Emitter<GameState> emit) {
    if (state is! GamePlayingState) return;
    final d = (state as GamePlayingState).data;
    if (d.isSticky) {
      final speed = (GameConstants.initialBallSpeed +
              (d.level - 1) * GameConstants.ballSpeedIncrement)
          .clamp(GameConstants.initialBallSpeed, GameConstants.maxBallSpeed);
      const angle = -math.pi / 2.5;
      final vel = Offset(math.cos(angle) * speed, math.sin(angle) * speed);
      final balls =
          d.balls
              .map(
                (b) =>
                    b.velocity == Offset.zero ? b.copyWith(velocity: vel) : b,
              )
              .toList();
      emit(GamePlayingState(data: d.copyWith(isSticky: false, balls: balls)));
    }
  }

  void _onMovePaddle(MovePaddleEvent e, Emitter<GameState> emit) {
    if (state is! GamePlayingState) return;
    final d = (state as GamePlayingState).data;
    final newX = (d.paddle.x + e.delta).clamp(
      0.0,
      e.screenWidth - d.paddle.width,
    );
    emit(
      GamePlayingState(data: d.copyWith(paddle: d.paddle.copyWith(x: newX))),
    );
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

    // Always step physics to allow particles/powerups to fall even before launch
    final updated = _physicsStep(d, e.deltaTime, e.screenSize);

    if (updated.pendingGameOver) {
      if (updated.pendingTimer <= 0) {
        SoundService.playGameOver();
        ScoreService.saveHighScore(updated.score);
        emit(GameOverState(score: updated.score, level: updated.level));
        return;
      }
      emit(GamePlayingState(data: updated));
      return;
    }

    // Check win condition (all breakable/target bricks destroyed)
    final allCleared = updated.bricks.every(
      (b) => b.isDestroyed || b.type == BrickType.unbreakable,
    );
    if (allCleared && updated.bricks.isNotEmpty) {
      ScoreService.saveHighScore(updated.score);
      ScoreService.saveUnlockedLevel(updated.level + 1);
      emit(LevelCompletedState(data: updated));
      return;
    }

    emit(GamePlayingState(data: updated));
  }

  // ── Physics Step ──────────────────────────────────────────────────────────

  GameStateModel _physicsStep(GameStateModel d, double dt, Size screen) {
    final rdt = dt * d.timeScale;

    var balls = List<BallModel>.from(d.balls);
    var bricks = List<BrickModel>.from(d.bricks);
    var powerUps = List<PowerUpModel>.from(d.powerUps);
    var particles = List<ParticleModel>.from(d.particles);
    var lasers = List<LaserModel>.from(d.lasers);
    var texts = List<FloatingTextModel>.from(d.floatingTexts);

    var paddle = d.paddle.copyWith(
      flashTimer: math.max(0, d.paddle.flashTimer - rdt),
    );
    var score = d.score;
    var lives = d.lives;
    var hasShield = d.hasShield;
    var shieldTimer = d.shieldTimer;
    var ballLaunched = d.ballLaunched;
    var comboCount = d.comboCount;
    var comboTimer = d.comboTimer;
    var maxCombo = d.maxCombo;
    var shakeTimer = math.max(0.0, d.shakeTimer - rdt);

    var potType = d.activePowerUpType;
    var potTimer = d.activePowerUpTimer;
    var potMax = d.activePowerUpMaxTimer;
    var slowTimer = d.slowBallTimer;
    var timeScale = d.timeScale;
    var pending = d.pendingGameOver;
    var pendingT = d.pendingTimer;
    var highScore = d.highScore;

    var isSticky = d.isSticky;
    var hasFireball = d.hasFireball;
    var fireballTimer = d.fireballTimer;
    var hitCount = d.hitCount;
    var spawnedRowsCount = d.spawnedRowsCount;

    if (pending) {
      pendingT = math.max(0, pendingT - dt); // Use raw dt for consistent duration
      particles = _updateParticles(particles, rdt);
      return d.copyWith(pendingTimer: pendingT, particles: particles);
    }

    // Power-up Timers
    if (hasShield) {
      shieldTimer = math.max(0, shieldTimer - rdt);
      if (shieldTimer == 0) hasShield = false;
    }
    if (comboCount > 0 && comboTimer > 0) {
      comboTimer = math.max(0, comboTimer - rdt);
      if (comboTimer == 0) comboCount = 0;
    }
    if (hasFireball) {
      fireballTimer = math.max(0, fireballTimer - rdt);
      if (fireballTimer == 0) hasFireball = false;
    }

    if (potTimer > 0) {
      potTimer = math.max(0, potTimer - rdt);
      if (potTimer == 0) {
        if (potType == PowerUpType.laserPaddle) _laserTimer = 0;
        potType = null;
        isSticky = false;
      }
    }

    // Laser Firing Logic
    if (potType == PowerUpType.laserPaddle) {
      _laserTimer += rdt;
      if (_laserTimer >= GameConstants.laserSpawnRate) {
        _laserTimer = 0;
        lasers.add(
          LaserModel(
            id: _laserIdCounter++,
            position: Offset(paddle.x + 10, paddle.y),
          ),
        );
        lasers.add(
          LaserModel(
            id: _laserIdCounter++,
            position: Offset(paddle.x + paddle.width - 10, paddle.y),
          ),
        );
        SoundService.playBallHit(); // Laser sound
      }
    }

    if (slowTimer > 0) {
      slowTimer = math.max(0, slowTimer - rdt);
      if (slowTimer == 0) {
        final ls =
            GameConstants.initialBallSpeed +
            (d.level - 1) * GameConstants.ballSpeedIncrement;
        balls =
            balls.map((b) {
              final sp = b.velocity.distance;
              if (sp == 0) return b;
              return b.copyWith(velocity: b.velocity / sp * ls);
            }).toList();
      }
    }

    // Update aesthetic entities
    particles = _updateParticles(particles, rdt);

    texts =
        texts
            .map(
              (t) => t.copyWith(
                position:
                    t.position +
                    Offset(0, GameConstants.floatingTextVelocityY * rdt),
                life: math.max(
                  0,
                  t.life - rdt / GameConstants.floatingTextDuration,
                ),
              ),
            )
            .where((t) => t.life > 0)
            .toList();

    // Lasers update
    var remainLasers = <LaserModel>[];
    for (var lz in lasers) {
      var nlz = lz.copyWith(
        position: lz.position + Offset(0, -GameConstants.laserSpeed * rdt),
      );
      if (nlz.position.dy < 0) continue;

      bool hit = false;
      final lRect = Rect.fromCenter(
        center: nlz.position,
        width: GameConstants.laserWidth,
        height: GameConstants.laserHeight,
      );

      for (int i = 0; i < bricks.length; i++) {
        var bk = bricks[i];
        if (bk.isDestroyed ||
            bk.type == BrickType.ghost && math.sin(bk.ghostTimer * 3) < 0) {
          continue;
        }

        if (bk.rect.overlaps(lRect)) {
          hit = true;
          if (bk.type != BrickType.unbreakable) {
            bricks[i] = bk.hit().copyWith(
              flashTimer: GameConstants.flashDuration,
            );
            if (bricks[i].isDestroyed) {
              _onBrickDestroyed(
                bricks[i],
                i,
                bricks,
                particles,
                powerUps,
                texts,
                comboCount,
                score,
                highScore,
              );
              score += GameConstants.scorePerBrick;
              highScore = math.max(highScore, score);
            } else {
              SoundService.playBallHit();
            }
          }
          break; // laser destroyed
        }
      }
      if (!hit) remainLasers.add(nlz);
    }
    lasers = remainLasers;

    // Boss & Brick Timers
    bool bossExists = false;
    for (int i = 0; i < bricks.length; i++) {
      var bk = bricks[i];
      if (bk.isDestroyed) continue;

      if (bk.type == BrickType.ghost) {
        bk = bk.copyWith(ghostTimer: bk.ghostTimer + rdt);
      }
      if (bk.flashTimer > 0) {
        bk = bk.copyWith(flashTimer: math.max(0, bk.flashTimer - rdt));
      }

      if (bk.isBoss) {
        bossExists = true;
        var vx = bk.bossVelocityX;
        var left = bk.rect.left + vx * rdt;
        if (left <= 0 || left + bk.rect.width >= screen.width) {
          vx = -vx;
          left = left.clamp(0.0, screen.width - bk.rect.width);
        }
        bk = bk.copyWith(
          rect: Rect.fromLTWH(left, bk.rect.top, bk.rect.width, bk.rect.height),
          bossVelocityX: vx,
        );

        // Boss minions
        _bossMinionTimer += rdt;
        if (_bossMinionTimer >= GameConstants.bossMinionSpawnRate) {
          _bossMinionTimer = 0;
          bricks.add(
            BrickModel(
              id: bricks.length,
              row: 99,
              col: 99,
              rect: Rect.fromLTWH(
                bk.rect.center.dx - 20,
                bk.rect.bottom + 5,
                40,
                15,
              ),
              durability: 1,
            ),
          );
        }
      }
      bricks[i] = bk;
    }
    if (!bossExists) _bossMinionTimer = 0;

    final paddleRect = Rect.fromLTWH(
      paddle.x,
      paddle.y,
      paddle.width,
      GameConstants.paddleHeight,
    );

    // Power-up collecting
    final remainPUs = <PowerUpModel>[];
    for (final pu in powerUps) {
      if (!pu.isActive) continue;
      final np = pu.copyWith(
        position: pu.position + Offset(0, GameConstants.powerUpFallSpeed * rdt),
      );
      if (np.position.dy > screen.height) continue;
      if (np.rect.overlaps(paddleRect)) {
        final r = _applyPowerUp(
          np.type,
          balls,
          paddle,
          hasShield,
          shieldTimer,
          slowTimer,
          lives,
        );
        balls = r['balls'] as List<BallModel>;
        paddle = r['paddle'] as PaddleModel;
        hasShield = r['shield'] as bool;
        shieldTimer = r['shieldT'] as double;
        slowTimer = r['slowT'] as double;
        lives = r['lives'] as int;

        potType = np.type;
        potTimer = GameConstants.powerUpDuration;
        potMax = GameConstants.powerUpDuration;
        if (np.type == PowerUpType.catchBall) isSticky = true;
        if (np.type == PowerUpType.fireball) {
          hasFireball = true;
          fireballTimer = GameConstants.fireballDuration;
        }

        SoundService.playPowerUp();
        texts.add(
          FloatingTextModel(
            id: _textIdCounter++,
            position: paddleRect.topCenter,
            text: _puName(np.type),
            life: 1.0,
          ),
        );
        HapticFeedback.lightImpact();
      } else {
        remainPUs.add(np);
      }
    }
    powerUps = remainPUs;

    final newBalls = <BallModel>[];
    bool lostBall = false;
    bool paddleHitOccurred = false;

    for (var ball in balls) {
      if (!ball.isActive) continue;

      if (!ballLaunched || (isSticky && ball.velocity == Offset.zero)) {
        var cx = paddle.x + paddle.width / 2;
        newBalls.add(
          ball.copyWith(
            position: Offset(cx, paddle.y - ball.radius - 2),
            velocity: Offset.zero,
          ),
        );
        continue;
      }

      var pos = ball.position + ball.velocity * rdt;
      var vel = ball.velocity;

      // Walls
      if (pos.dx - ball.radius < 0) {
        pos = Offset(ball.radius, pos.dy);
        vel = Offset(vel.dx.abs(), vel.dy);
        SoundService.playBallHit();
      }
      if (pos.dx + ball.radius > screen.width) {
        pos = Offset(screen.width - ball.radius, pos.dy);
        vel = Offset(-vel.dx.abs(), vel.dy);
        SoundService.playBallHit();
      }
      if (pos.dy - ball.radius < 0) {
        pos = Offset(pos.dx, ball.radius);
        vel = Offset(vel.dx, vel.dy.abs());
        SoundService.playBallHit();
      }

      // Bottom
      if (pos.dy + ball.radius > screen.height) {
        if (hasShield) {
          pos = Offset(pos.dx, screen.height - ball.radius);
          vel = Offset(vel.dx, -vel.dy.abs());
        } else {
          lostBall = true;
          continue;
        }
      }

      // Paddle collision
      final ballRect = Rect.fromCircle(center: pos, radius: ball.radius);
      if (vel.dy > 0 && ballRect.overlaps(paddleRect)) {
        if (isSticky) {
          vel = Offset.zero;
          pos = Offset(
            pos.dx.clamp(paddle.x, paddle.x + paddle.width),
            paddle.y - ball.radius,
          );
        } else {
          final hr = ((pos.dx - paddle.x) / paddle.width).clamp(0.0, 1.0);
          final ang =
              (hr - 0.5) *
              2.0 *
              (GameConstants.maxDeflectionAngleDeg * math.pi / 180.0);
          final sp = vel.distance;
          vel = Offset(math.sin(ang) * sp, -math.cos(ang).abs() * sp);
          pos = Offset(pos.dx, paddle.y - ball.radius);
        }
        shakeTimer = GameConstants.shakeDuration * 0.5;
        SoundService.playBallHit();
        HapticFeedback.lightImpact();
        comboCount = 0; // reset combo on paddle hit
        paddleHitOccurred = true;
        paddle = paddle.copyWith(flashTimer: 0.15); // Flash on hit
      }

      // Brick collisions
      bool bH = false, bV = false;
      for (int i = 0; i < bricks.length; i++) {
        final bk = bricks[i];
        if (bk.isDestroyed ||
            (bk.type == BrickType.ghost && math.sin(bk.ghostTimer * 3) < 0)) {
          continue;
        }
        final br = Rect.fromCircle(center: pos, radius: ball.radius);
        if (!br.overlaps(bk.rect)) continue;

        // Deflection (skip if fireball and breakable)
        bool pierce = hasFireball && bk.type != BrickType.unbreakable;
        if (!pierce) {
          final olL = br.right - bk.rect.left, olR = bk.rect.right - br.left;
          final olT = br.bottom - bk.rect.top, olB = bk.rect.bottom - br.top;
          if (math.min(olL, olR) < math.min(olT, olB)) {
            if (!bH) {
              vel = Offset(-vel.dx, vel.dy);
              bH = true;
            }
          } else {
            if (!bV) {
              vel = Offset(vel.dx, -vel.dy);
              bV = true;
            }
          }
        }

        if (bk.type != BrickType.unbreakable) {
          bricks[i] = bk.hit().copyWith(
            flashTimer: GameConstants.flashDuration,
          );
          if (pierce) {
            bricks[i] = bricks[i].copyWith(
              isDestroyed: true,
            ); // insta-kill for fireball
          }

          if (bricks[i].isDestroyed) {
            comboCount++;
            comboTimer = GameConstants.comboTimeout;
            maxCombo = math.max(maxCombo, comboCount);
            int earned =
                GameConstants.scorePerBrick * math.max(1, comboCount ~/ 2 + 1);
            score += earned;
            highScore = math.max(highScore, score);
            shakeTimer =
                bk.isBoss
                    ? GameConstants.shakeDuration * 2
                    : GameConstants.shakeDuration;

            _onBrickDestroyed(
              bricks[i],
              i,
              bricks,
              particles,
              powerUps,
              texts,
              comboCount,
              score,
              highScore,
            );
            texts.add(
              FloatingTextModel(
                id: _textIdCounter++,
                position: bk.rect.center,
                text: "+$earned",
                life: 1.0,
              ),
            );
            if (comboCount >= 3) {
              texts.add(
                FloatingTextModel(
                  id: _textIdCounter++,
                  position: bk.rect.topCenter,
                  text: "Combo x$comboCount",
                  life: 1.0,
                ),
              );
            }

            if (bk.isBoss) {
              SoundService.playBossHit();
            } else {
              SoundService.playBrickBreak();
            }
            if (comboCount >= 3) {
              SoundService.playCombo();
            }
            HapticFeedback.mediumImpact();
          } else {
            if (bk.isBoss) {
              SoundService.playBossHit();
            } else {
              SoundService.playBallHit();
            }
            HapticFeedback.selectionClick();
          }
        } else {
          SoundService.playBallHit();
        }
      }

      final trail = [pos, ...ball.trail.take(GameConstants.trailLength - 1)];
      newBalls.add(ball.copyWith(position: pos, velocity: vel, trail: trail));
    }

    // Process descending bricks on paddle hit
    bool overflowGameOver = false;
    if (paddleHitOccurred && ballLaunched && !isSticky) {
      hitCount++;
      // Every paddle hit, descend by 15 pixels (as requested)
      double descendStep = 15.0;
      for (int i = 0; i < bricks.length; i++) {
        if (bricks[i].isDestroyed || bricks[i].isBoss) continue;
        final nr = Rect.fromLTWH(
          bricks[i].rect.left,
          bricks[i].rect.top + descendStep,
          bricks[i].rect.width,
          bricks[i].rect.height,
        );
        bricks[i] = bricks[i].copyWith(rect: nr);
        if (nr.bottom >= paddle.y) {
          overflowGameOver = true;
        }
      }

      // Every 4 paddle hits, spawn exactly 1 row, up to the fixed limit (4)
      if (hitCount >= 4 && d.spawnedRowsCount < d.maxSpawnedRows) {
        hitCount = 0;
        final int rowsToAdd = 1;
        spawnedRowsCount += 1;
        final double spawnRowStep = GameConstants.brickHeight + GameConstants.brickPaddingV;
        final double startY = GameConstants.brickTopOffset - (rowsToAdd * spawnRowStep);
        for (int r = 0; r < rowsToAdd; r++) {
          final rowY = startY + r * spawnRowStep;
          for (int c = 0; c < GameConstants.brickCols; c++) {
            if (math.Random().nextDouble() < 0.2) continue; // 20% empty space
            final bw = screen.width / GameConstants.brickCols;
            final rect = Rect.fromLTWH(
              c * bw + GameConstants.brickPaddingH / 2,
              rowY,
              bw - GameConstants.brickPaddingH,
              GameConstants.brickHeight,
            );
            BrickType type = BrickType.normal;
            int durability = 1;
            final rand = math.Random().nextDouble();
            if (rand < 0.05) {
              type = BrickType.explosive;
            } else if (rand < 0.1) {
              type = BrickType.unbreakable;
            } else if (rand < 0.25) {
              durability = 2;
            } else if (rand < 0.35) {
              durability = 3;
            }

            bricks.add(
              BrickModel(
                id: bricks.length,
                row: -rowsToAdd + r,
                col: c,
                rect: rect,
                type: type,
                durability: durability,
              ),
            );
          }
        }
      }
    }

    // Ball lost handling
    if ((lostBall && newBalls.isEmpty) || overflowGameOver) {
      if (overflowGameOver) {
        lives = 0;
      } else {
        lives -= 1;
      }
      comboCount = 0;
      HapticFeedback.heavyImpact();
      if (lives <= 0) {
        ScoreService.saveHighScore(score);
        return d.copyWith(
          balls: [],
          bricks: bricks,
          powerUps: powerUps,
          particles: particles,
          lasers: lasers,
          floatingTexts: texts,
          score: score,
          highScore: highScore,
          lives: 0,
          timeScale: GameConstants.slowMoScale,
          pendingGameOver: true,
          pendingTimer: GameConstants.slowMoDuration,
          comboCount: 0,
          comboTimer: 0,
        );
      }
      final cx = paddle.x + paddle.width / 2;
      newBalls.add(
        BallModel(
          position: Offset(cx, paddle.y - GameConstants.ballRadius - 2),
          velocity: Offset.zero,
          radius: GameConstants.ballRadius,
        ),
      );
      ballLaunched = false;
      isSticky = false;
      potType = null;
    }

    return d.copyWith(
      balls: newBalls,
      bricks: bricks,
      powerUps: powerUps,
      particles: particles,
      lasers: lasers,
      floatingTexts: texts,
      paddle: paddle,
      score: score,
      highScore: highScore,
      lives: lives,
      hasShield: hasShield,
      shieldTimer: shieldTimer,
      ballLaunched: ballLaunched,
      comboCount: comboCount,
      comboTimer: comboTimer,
      maxCombo: maxCombo,
      shakeTimer: shakeTimer,
      activePowerUpType: potType,
      activePowerUpTimer: potTimer,
      activePowerUpMaxTimer: potMax,
      slowBallTimer: slowTimer,
      timeScale: timeScale,
      isSticky: isSticky,
      hasFireball: hasFireball,
      fireballTimer: fireballTimer,
      hitCount: hitCount,
      spawnedRowsCount: spawnedRowsCount,
      pendingGameOver: false,
      pendingTimer: 0,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _onBrickDestroyed(
    BrickModel bk,
    int index,
    List<BrickModel> bricks,
    List<ParticleModel> particles,
    List<PowerUpModel> powerUps,
    List<FloatingTextModel> texts,
    int combo,
    int score,
    int hScore,
  ) {
    if (bk.type == BrickType.explosive) {
      // Chain reaction damage within radius
      const radius = 60.0;
      final c = bk.rect.center;
      for (int j = 0; j < bricks.length; j++) {
        if (bricks[j].isDestroyed ||
            j == index ||
            bricks[j].type == BrickType.unbreakable) {
          continue;
        }
        if ((bricks[j].rect.center - c).distance <= radius) {
          bricks[j] = bricks[j].hit();
          if (bricks[j].isDestroyed) {
            particles.addAll(
              _spawnParticles(
                bricks[j].rect.center,
                _brickColor(bricks[j]),
                GameConstants.particlesPerBrick,
              ),
            );
            texts.add(
              FloatingTextModel(
                id: _textIdCounter++,
                position: bricks[j].rect.center,
                text: "BOOM!",
                life: 1.0,
              ),
            );
          }
        }
      }
    }

    particles.addAll(
      _spawnParticles(
        bk.rect.center,
        bk.isBoss ? const Color(0xFFFF1744) : _brickColor(bk),
        bk.isBoss
            ? GameConstants.bossParticlesPerBrick
            : GameConstants.particlesPerBrick,
      ),
    );

    if (math.Random().nextDouble() < GameConstants.powerUpDropChance) {
      final types = PowerUpType.values;
      powerUps.add(
        PowerUpModel(
          id: _powerUpIdCounter++,
          type: types[math.Random().nextInt(types.length)],
          position: bk.rect.center,
        ),
      );
    }
  }

  List<ParticleModel> _updateParticles(
    List<ParticleModel> particles,
    double dt,
  ) {
    return particles
        .map(
          (p) => p.copyWith(
            position: p.position + p.velocity * dt,
            life: math.max(0, p.life - dt / p.maxLife),
          ),
        )
        .where((p) => p.life > 0)
        .toList();
  }

  Color _brickColor(BrickModel bk) {
    if (bk.type == BrickType.explosive) return Colors.black87;
    if (bk.type == BrickType.unbreakable) return Colors.grey;
    if (bk.type == BrickType.ghost) return Colors.deepPurpleAccent;
    const colors = [
      Color(0xFF00E5FF),
      Color(0xFF69F0AE),
      Color(0xFFFFD740),
      Color(0xFFFF5252),
    ];
    return colors[(bk.durability - 1).clamp(0, 3)];
  }

  List<ParticleModel> _spawnParticles(Offset center, Color color, int count) {
    final rng = math.Random();
    return List.generate(count, (i) {
      final angle = (i / count) * 2 * math.pi + rng.nextDouble() * 0.5;
      final speed =
          GameConstants.particleSpeed * (0.5 + rng.nextDouble() * 0.8);
      return ParticleModel(
        id: _particleIdCounter++,
        position: center,
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        color: color,
        life: 1.0,
        maxLife: GameConstants.particleLife * (0.6 + rng.nextDouble() * 0.8),
        size: GameConstants.particleSize * (0.5 + rng.nextDouble()),
      );
    });
  }

  String _puName(PowerUpType pu) {
    switch (pu) {
      case PowerUpType.expandPaddle:
        return "Expand";
      case PowerUpType.shrinkPaddle:
        return "Shrink";
      case PowerUpType.slowBall:
        return "Slow";
      case PowerUpType.multiBall:
        return "Multi";
      case PowerUpType.shield:
        return "Shield";
      case PowerUpType.laserPaddle:
        return "Laser";
      case PowerUpType.fireball:
        return "Fireball";
      case PowerUpType.catchBall:
        return "Sticky";
      case PowerUpType.extraLife:
        return "1-UP";
    }
  }

  Map<String, dynamic> _applyPowerUp(
    PowerUpType type,
    List<BallModel> balls,
    PaddleModel paddle,
    bool hasShield,
    double shieldTimer,
    double slowTimer,
    int lives,
  ) {
    switch (type) {
      case PowerUpType.expandPaddle:
        return {
          'balls': balls,
          'paddle': paddle.copyWith(
            width: (paddle.width * GameConstants.expandFactor).clamp(
              paddle.width,
              GameConstants.paddleMaxWidth,
            ),
          ),
          'shield': hasShield,
          'shieldT': shieldTimer,
          'slowT': slowTimer,
          'lives': lives,
        };
      case PowerUpType.shrinkPaddle:
        return {
          'balls': balls,
          'paddle': paddle.copyWith(
            width: (paddle.width * GameConstants.shrinkFactor).clamp(
              GameConstants.paddleMinWidth,
              paddle.width,
            ),
          ),
          'shield': hasShield,
          'shieldT': shieldTimer,
          'slowT': slowTimer,
          'lives': lives,
        };
      case PowerUpType.slowBall:
        final slow =
            balls.map((b) {
              final sp = b.velocity.distance;
              if (sp == 0) return b;
              return b.copyWith(
                velocity: b.velocity / sp * (sp * GameConstants.slowFactor),
              );
            }).toList();
        return {
          'balls': slow,
          'paddle': paddle,
          'shield': hasShield,
          'shieldT': shieldTimer,
          'slowT': GameConstants.slowBallDuration,
          'lives': lives,
        };
      case PowerUpType.multiBall:
        final extra = <BallModel>[];
        if (balls.isNotEmpty) {
          final ref = balls.first;
          final sp =
              ref.velocity.distance > 0
                  ? ref.velocity.distance
                  : GameConstants.initialBallSpeed;
          for (final off in [-0.4, 0.4]) {
            final a = math.atan2(ref.velocity.dy, ref.velocity.dx) + off;
            extra.add(
              BallModel(
                position: ref.position,
                velocity: Offset(math.cos(a) * sp, math.sin(a) * sp),
                radius: GameConstants.ballRadius,
              ),
            );
          }
        }
        return {
          'balls': [...balls, ...extra],
          'paddle': paddle,
          'shield': hasShield,
          'shieldT': shieldTimer,
          'slowT': slowTimer,
          'lives': lives,
        };
      case PowerUpType.shield:
        return {
          'balls': balls,
          'paddle': paddle,
          'shield': true,
          'shieldT': GameConstants.shieldDuration,
          'slowT': slowTimer,
          'lives': lives,
        };
      case PowerUpType.extraLife:
        return {
          'balls': balls,
          'paddle': paddle,
          'shield': hasShield,
          'shieldT': shieldTimer,
          'slowT': slowTimer,
          'lives': lives + 1,
        };
      default:
        return {
          'balls': balls,
          'paddle': paddle,
          'shield': hasShield,
          'shieldT': shieldTimer,
          'slowT': slowTimer,
          'lives': lives,
        };
    }
  }

  // ── Level Builder ──────────────────────────────────────────────────────────

  GameStateModel _buildLevel(
    Size screen,
    int level,
    int lives,
    int score, {
    int? highScore,
    int unlocked = 1,
  }) {
    _highScore = math.max(_highScore, highScore ?? 0);
    const cols = GameConstants.brickCols;
    final brickW =
        (screen.width - (cols + 1) * GameConstants.brickPaddingH) / cols;
    final rng = math.Random();
    final bricks = <BrickModel>[];

    // Procedural generation beyond level 10
    final isProcedural = level > 10;
    final rows =
        isProcedural
            ? math.min(8, 4 + (level - 10) ~/ 2)
            : _getLevelRows(level);

    for (int r = 0; r < rows; r++) {
      String rowPattern = isProcedural ? "1" * cols : _getLevelLayout(level)[r];
      for (int c = 0; c < cols; c++) {
        if (c >= rowPattern.length) continue;
        String p = rowPattern[c];
        if (p == '0' || p == ' ') continue;

        final left =
            GameConstants.brickPaddingH +
            c * (brickW + GameConstants.brickPaddingH);
        final top =
            GameConstants.brickTopOffset +
            r * (GameConstants.brickHeight + GameConstants.brickPaddingV);

        BrickType bType = BrickType.normal;
        int durb = 1;
        if (isProcedural) {
          final chances = rng.nextDouble();
          if (chances < 0.05) {
            bType = BrickType.explosive;
          } else if (chances < 0.10) {
            bType = BrickType.ghost;
          } else if (chances < 0.15) {
            bType = BrickType.unbreakable;
          }

          durb = math.max(
            1,
            rng.nextInt(
                  math.min(GameConstants.maxBrickDurability, 1 + level ~/ 3),
                ) +
                1,
          );
        } else {
          if (p == '2') durb = 2;
          if (p == '3') durb = 3;
          if (p == 'X') bType = BrickType.explosive;
          if (p == 'U') bType = BrickType.unbreakable;
          if (p == 'G') bType = BrickType.ghost;
        }

        bricks.add(
          BrickModel(
            id: r * cols + c,
            row: r,
            col: c,
            rect: Rect.fromLTWH(left, top, brickW, GameConstants.brickHeight),
            durability: durb,
            type: bType,
          ),
        );
      }
    }

    if (level % GameConstants.bossLevelInterval == 0) {
      const bossW = 120.0;
      bricks.add(
        BrickModel(
          id: -1,
          row: -1,
          col: -1,
          rect: Rect.fromCenter(
            center: Offset(
              screen.width / 2,
              GameConstants.brickTopOffset +
                  rows *
                      (GameConstants.brickHeight +
                          GameConstants.brickPaddingV) +
                  20,
            ),
            width: bossW,
            height: 34,
          ),
          durability: GameConstants.bossBrickHP + level,
          isBoss: true,
          bossVelocityX: GameConstants.bossBrickSpeed * (1.0 + level * 0.06),
        ),
      );
    }

    final paddleY = screen.height - GameConstants.paddleBottomOffset;
    final paddleX = (screen.width - GameConstants.paddleInitialWidth) / 2;
    final paddle = PaddleModel(
      x: paddleX,
      y: paddleY,
      width: GameConstants.paddleInitialWidth,
    );
    final ballPos = Offset(
      screen.width / 2,
      paddleY - GameConstants.ballRadius - 2,
    );

    return GameStateModel(
      balls: [
        BallModel(
          position: ballPos,
          velocity: Offset.zero,
          radius: GameConstants.ballRadius,
        ),
      ],
      paddle: paddle,
      bricks: bricks,
      powerUps: const [],
      particles: const [],
      lasers: const [],
      floatingTexts: const [],
      score: score,
      highScore: _highScore,
      lives: lives,
      level: level,
      unlockedLevel: unlocked,
      themeIndex: level % 5,
      comboCount: 0,
      comboTimer: 0,
      maxCombo: 0,
      activePowerUpType: null,
      activePowerUpTimer: 0,
      activePowerUpMaxTimer: 1,
      slowBallTimer: 0,
      hasShield: false,
      shieldTimer: 0,
      isSticky: false,
      hasFireball: false,
      fireballTimer: 0,
      hitCount: 0,
      spawnedRowsCount: 0,
      maxSpawnedRows: 4, // Fixed limit of 4 rows as requested
      ballLaunched: false,
      shakeTimer: 0,
      timeScale: 1.0,
      pendingGameOver: false,
      pendingTimer: 0,
    );
  }

  int _getLevelRows(int level) => _getLevelLayout(level).length;

  List<String> _getLevelLayout(int level) {
    const layouts = {
      1: ["11111111", " 111111 ", "  1111  "],
      2: ["22222222", "11111111", "1X1111X1"],
      3: [" U1111U ", "11111111", "  G  G  ", "22222222"],
      4: ["11111111", "X222222X", "X111111X", " U  U  U"],
      5: ["2X2X2X2X", " G G G G", "G G G G ", "22222222"], // Boss Level 1
      6: ["333u333u", "11X11X11", "22222222", "1 1 1 1 "],
      7: ["G U G U G", "22222222", "111X111X", "33333333"],
      8: ["XXXX1111", "1111XXXX", "22222222", "G  G  G "],
      9: ["U111111U", "U222222U", "U333333U", "X G G X "],
      10: [
        "333X333X",
        " X333X33",
        "U U U U ",
        "G G G G",
        "22222222",
      ], // Boss Level 2
    };
    return layouts[level] ?? ["11111111"];
  }
}
