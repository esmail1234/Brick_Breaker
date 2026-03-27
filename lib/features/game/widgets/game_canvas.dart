import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/game_constants.dart';
import '../model/ball_model.dart';
import '../model/brick_model.dart';
import '../model/game_state_model.dart';
import '../model/paddle_model.dart';
import '../model/particle_model.dart';
import '../model/power_up_model.dart';
import '../model/laser_model.dart';
import '../model/floating_text_model.dart';
import 'dart:math' as math;

/// Main game canvas – renders everything via a single CustomPainter.
class GameCanvas extends StatelessWidget {
  final GameStateModel state;
  const GameCanvas({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GamePainter(state),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GamePainter extends CustomPainter {
  final GameStateModel state;
  _GamePainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGrid(canvas, size);
    if (state.hasShield) _drawShield(canvas, size);
    _drawBricks(canvas, state.bricks);
    _drawPowerUps(canvas, state.powerUps);
    _drawParticles(canvas, state.particles);
    _drawLasers(canvas, state.lasers);
    _drawPaddle(canvas, state.paddle);
    for (final ball in state.balls) { if (ball.isActive) { _drawTrail(canvas, ball); _drawBall(canvas, ball); } }
    _drawFloatingTexts(canvas, state.floatingTexts);
    if (!state.ballLaunched && !state.pendingGameOver) _drawLaunchHint(canvas, size);
    if (state.comboCount >= 2 && state.comboTimer > 0) _drawCombo(canvas, size);
  }

  // ── Background (level-tinted) ─────────────────────────────────────────────
  void _drawBackground(Canvas canvas, Size size) {
    final hue = (state.level * 28.0) % 360;
    final accent = HSVColor.fromAHSV(1, hue, 0.6, 0.09).toColor();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF050514), accent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x08FFFFFF)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), p); }
    for (double y = 0; y < size.height; y += 40) { canvas.drawLine(Offset(0, y), Offset(size.width, y), p); }
  }

  // ── Shield ──────────────────────────────────────────────────────────────────
  void _drawShield(Canvas canvas, Size size) {
    canvas.drawLine(Offset(0, size.height - 3), Offset(size.width, size.height - 3),
        Paint()..color = ColorConstants.shieldColor.withValues(alpha: 0.7)..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8));
  }

  // ── Bricks ──────────────────────────────────────────────────────────────────
  void _drawBricks(Canvas canvas, List<BrickModel> bricks) {
    for (final bk in bricks) { if (!bk.isDestroyed) _drawBrick(canvas, bk); }
  }

  void _drawBrick(Canvas canvas, BrickModel bk) {
    if (bk.type == BrickType.ghost && math.sin(bk.ghostTimer * 3) < 0) return;

    Color fill; Color glow;
    if (bk.isBoss) { fill = const Color(0xFFFF1744); glow = const Color(0xFFB71C1C); }
    else if (bk.type == BrickType.unbreakable) { fill = Colors.grey.shade400; glow = Colors.grey.shade700; }
    else if (bk.type == BrickType.explosive) { fill = Colors.black87; glow = Colors.orangeAccent; }
    else if (bk.type == BrickType.ghost) { 
       final alpha = (0.5 + 0.5 * math.sin(bk.ghostTimer * 3)).clamp(0.0, 1.0);
       fill = Colors.deepPurpleAccent.withValues(alpha: alpha); glow = Colors.deepPurple; 
    }
    else {
       final idx = (bk.durability - 1).clamp(0, 3);
       fill = ColorConstants.brickColors[idx];
       glow = ColorConstants.brickGlowColors[idx];
    }

    if (bk.flashTimer > 0) {
      final t = bk.flashTimer / GameConstants.flashDuration;
      fill = Color.lerp(fill, Colors.white, t)!;
    }

    final rRect = RRect.fromRectAndRadius(bk.rect, const Radius.circular(5));
    canvas.drawRRect(rRect, Paint()..color = glow.withValues(alpha: 0.4)..maskFilter = MaskFilter.blur(BlurStyle.outer, bk.isBoss ? 14.0 : 8.0));
    canvas.drawRRect(rRect, Paint()..color = fill.withValues(alpha: bk.type == BrickType.ghost ? 0.6 : 0.9));
    
    if (bk.type != BrickType.ghost && bk.type != BrickType.unbreakable) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bk.rect.left + 4, bk.rect.top + 2, bk.rect.width - 8, bk.rect.height * 0.35), const Radius.circular(3)),
        Paint()..color = Colors.white.withValues(alpha: 0.18)
      );
    }
    
    if (bk.type == BrickType.explosive) {
       final tp = TextPainter(text: const TextSpan(text: 'TNT', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)), textDirection: TextDirection.ltr)..layout();
       tp.paint(canvas, bk.rect.center - Offset(tp.width / 2, tp.height / 2));
    } else {
       canvas.drawRRect(rRect, Paint()..color = fill..style = PaintingStyle.stroke..strokeWidth = bk.isBoss ? 2.0 : (bk.type == BrickType.unbreakable ? 1.5 : 1.2));
    }

    if (bk.isBoss) {
      final double maxHp = (GameConstants.bossBrickHP + state.level).toDouble();
      final double pct = (bk.durability / maxHp).clamp(0.0, 1.0);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bk.rect.left, bk.rect.top - 12, bk.rect.width, 5), const Radius.circular(2)), Paint()..color = Colors.red.withValues(alpha: 0.2));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bk.rect.left, bk.rect.top - 12, bk.rect.width * pct, 5), const Radius.circular(2)), Paint()..color = Colors.redAccent);

      final tp = TextPainter(
        text: TextSpan(text: '${bk.durability} HP', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, bk.rect.center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  // ── Power-ups ────────────────────────────────────────────────────────────────
  void _drawPowerUps(Canvas canvas, List<PowerUpModel> powerUps) {
    for (final pu in powerUps) { if (pu.isActive) _drawPowerUp(canvas, pu); }
  }

  void _drawPowerUp(Canvas canvas, PowerUpModel pu) {
    final color = _puColor(pu.type);
    final r = GameConstants.powerUpSize / 2;
    canvas.drawCircle(pu.position, r + 5, Paint()..color = color.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8));
    canvas.drawCircle(pu.position, r, Paint()..color = color.withValues(alpha: 0.9));
    final tp = TextPainter(text: TextSpan(text: _puIcon(pu.type), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, pu.position - Offset(tp.width / 2, tp.height / 2));
  }

  Color _puColor(PowerUpType t) { 
    switch (t) { 
      case PowerUpType.expandPaddle: return ColorConstants.puExpand; 
      case PowerUpType.shrinkPaddle: return ColorConstants.puShrink; 
      case PowerUpType.slowBall: return ColorConstants.puSlow; 
      case PowerUpType.multiBall: return ColorConstants.puMultiBall; 
      case PowerUpType.shield: return ColorConstants.puShield; 
      case PowerUpType.laserPaddle: return Colors.redAccent;
      case PowerUpType.fireball: return Colors.deepOrange;
      case PowerUpType.catchBall: return Colors.greenAccent;
      case PowerUpType.extraLife: return Colors.pinkAccent;
    } 
  }
  
  String _puIcon(PowerUpType t) { 
    switch (t) { 
      case PowerUpType.expandPaddle: return '↔'; 
      case PowerUpType.shrinkPaddle: return '↕'; 
      case PowerUpType.slowBall: return 'S'; 
      case PowerUpType.multiBall: return '×3'; 
      case PowerUpType.shield: return '🛡'; 
      case PowerUpType.laserPaddle: return '⚡';
      case PowerUpType.fireball: return '🔥';
      case PowerUpType.catchBall: return '🧲';
      case PowerUpType.extraLife: return '❤';
    } 
  }

  // ── Particles ────────────────────────────────────────────────────────────────
  void _drawParticles(Canvas canvas, List<ParticleModel> particles) {
    for (final p in particles) {
      if (!p.isAlive) continue;
      final alpha = p.life.clamp(0.0, 1.0);
      canvas.drawCircle(p.position, p.size * alpha,
          Paint()..color = p.color.withValues(alpha: alpha)..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.5));
    }
  }

  // ── Ball trail ───────────────────────────────────────────────────────────────
  void _drawTrail(Canvas canvas, BallModel ball) {
    Color tColor = state.hasFireball ? Colors.deepOrangeAccent : ColorConstants.ballGlow;
    for (int i = 0; i < ball.trail.length; i++) {
      final t = 1.0 - i / ball.trail.length;
      final r = ball.radius * t * 0.7;
      canvas.drawCircle(ball.trail[i], r,
          Paint()..color = tColor.withValues(alpha: t * 0.35)..maskFilter = MaskFilter.blur(BlurStyle.outer, r));
    }
  }

  // ── Paddle ───────────────────────────────────────────────────────────────────
  void _drawPaddle(Canvas canvas, PaddleModel paddle) {
    final rect = Rect.fromLTWH(paddle.x, paddle.y, paddle.width, GameConstants.paddleHeight);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    if (state.isSticky) {
      canvas.drawRRect(rRect, Paint()..color = Colors.greenAccent.withValues(alpha: 0.6)..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10));
    } else {
      canvas.drawRRect(rRect, Paint()..color = ColorConstants.paddleGlow.withValues(alpha: 0.45)..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14));
    }
    canvas.drawRRect(rRect, Paint()..shader = LinearGradient(colors: [ColorConstants.paddleStart, ColorConstants.paddleEnd]).createShader(rect));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rect.left + 6, rect.top + 2, rect.width - 12, 4), const Radius.circular(2)), Paint()..color = Colors.white.withValues(alpha: 0.3));
    
    // Laser turrets
    if (state.activePowerUpType == PowerUpType.laserPaddle) {
      final p1 = Rect.fromLTWH(rect.left + 6, rect.top - 4, 8, 8);
      final p2 = Rect.fromLTWH(rect.right - 14, rect.top - 4, 8, 8);
      final pt = Paint()..color = Colors.redAccent;
      canvas.drawRRect(RRect.fromRectAndRadius(p1, const Radius.circular(2)), pt);
      canvas.drawRRect(RRect.fromRectAndRadius(p2, const Radius.circular(2)), pt);
    }

    if (paddle.flashTimer > 0) {
      canvas.drawRRect(rRect, Paint()..color = Colors.white.withValues(alpha: 0.7 * (paddle.flashTimer / 0.15)));
    }
  }

  // ── Ball ─────────────────────────────────────────────────────────────────────
  void _drawBall(Canvas canvas, BallModel ball) {
    final r = ball.radius;
    Color glow = state.hasFireball ? Colors.deepOrange : ColorConstants.ballGlow;
    canvas.drawCircle(ball.position, r + 8, Paint()..color = glow.withValues(alpha: 0.22)..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14));
    canvas.drawCircle(ball.position, r + 3, Paint()..color = glow.withValues(alpha: 0.45)..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6));
    canvas.drawCircle(ball.position, r, Paint()..shader = RadialGradient(center: const Alignment(-0.35, -0.35), colors: [Colors.white, glow]).createShader(Rect.fromCircle(center: ball.position, radius: r)));
  }

  // ── Combo text ───────────────────────────────────────────────────────────────
  void _drawCombo(Canvas canvas, Size size) {
    final t = (state.comboTimer / GameConstants.comboTimeout).clamp(0.0, 1.0);
    final multiplier = state.comboCount;
    if (multiplier < 2) return;
    final scale = 1.0 + (multiplier * 0.05).clamp(0.0, 0.4);
    final glowPower = (multiplier * 4.0).clamp(10.0, 40.0);
    final tp = TextPainter(
      text: TextSpan(text: 'x$multiplier COMBO!',
          style: TextStyle(color: ColorConstants.neonCyan.withValues(alpha: t), fontSize: 24 * scale,
              fontWeight: FontWeight.bold, shadows: [Shadow(color: ColorConstants.neonCyan, blurRadius: glowPower)])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.44));
  }

  // ── Launch hint ──────────────────────────────────────────────────────────────
  void _drawLaunchHint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: const TextSpan(text: 'TAP TO LAUNCH', style: TextStyle(color: Color(0xFF80DEEA), fontSize: 13, letterSpacing: 2.5, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.72));
  }

  // ── Lasers ───────────────────────────────────────────────────────────────────
  void _drawLasers(Canvas canvas, List<LaserModel> lasers) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4.0);
    final corePaint = Paint()..color = Colors.white;
    for (var l in lasers) {
      final r = Rect.fromCenter(center: l.position, width: GameConstants.laserWidth, height: GameConstants.laserHeight);
      canvas.drawRect(r, paint);
      canvas.drawRect(Rect.fromCenter(center: l.position, width: 2, height: GameConstants.laserHeight), corePaint);
    }
  }

  // ── Floating Texts ───────────────────────────────────────────────────────────
  void _drawFloatingTexts(Canvas canvas, List<FloatingTextModel> texts) {
    for (var t in texts) {
      if (t.life <= 0) continue;
      final fw = t.text.startsWith('+') ? FontWeight.bold : FontWeight.w900;
      final sz = t.text.startsWith('+') ? 14.0 : 18.0;
      final clr = t.text.startsWith('+') ? Colors.greenAccent : (t.text == 'BOOM!' ? Colors.orange : Colors.yellowAccent);
      
      final tp = TextPainter(
        text: TextSpan(text: t.text, style: TextStyle(
          color: clr.withValues(alpha: t.life),
          fontSize: sz, fontWeight: fw,
          shadows: [Shadow(color: Colors.black.withValues(alpha: t.life), blurRadius: 4)]
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, t.position - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_GamePainter old) => true;
}
