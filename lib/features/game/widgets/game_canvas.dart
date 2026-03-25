import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/game_constants.dart';
import '../model/ball_model.dart';
import '../model/brick_model.dart';
import '../model/game_state_model.dart';
import '../model/paddle_model.dart';
import '../model/power_up_model.dart';

/// The main game canvas drawn with a single CustomPainter.
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

// ─────────────────────────────────────────────────────────────────────────────
class _GamePainter extends CustomPainter {
  final GameStateModel state;
  _GamePainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGridLines(canvas, size);
    if (state.hasShield) _drawShield(canvas, size, state.paddle);
    _drawBricks(canvas, state.bricks);
    _drawPowerUps(canvas, state.powerUps);
    _drawPaddle(canvas, state.paddle);
    for (final ball in state.balls) {
      if (ball.isActive) _drawBall(canvas, ball);
    }
    if (!state.ballLaunched) _drawLaunchHint(canvas, size);
  }

  // ── Background ─────────────────────────────────────────────────────────────
  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF050514), Color(0xFF0A0A22)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  // ── Subtle grid ─────────────────────────────────────────────────────────────
  void _drawGridLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  // ── Shield arc ─────────────────────────────────────────────────────────────
  void _drawShield(Canvas canvas, Size size, PaddleModel paddle) {
    final paint = Paint()
      ..color = ColorConstants.shieldColor.withOpacity(0.6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);
    canvas.drawLine(
      Offset(0, size.height - 2),
      Offset(size.width, size.height - 2),
      paint,
    );
  }

  // ── Bricks ─────────────────────────────────────────────────────────────────
  void _drawBricks(Canvas canvas, List<BrickModel> bricks) {
    for (final brick in bricks) {
      if (brick.isDestroyed) continue;
      _drawBrick(canvas, brick);
    }
  }

  void _drawBrick(Canvas canvas, BrickModel brick) {
    final idx = (brick.durability - 1).clamp(0, 3);
    final color = ColorConstants.brickColors[idx];
    final glow = ColorConstants.brickGlowColors[idx];
    final rRect = RRect.fromRectAndRadius(brick.rect, const Radius.circular(5));

    // Outer glow
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = glow.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8),
    );

    // Fill
    canvas.drawRRect(rRect, Paint()..color = color.withOpacity(0.85));

    // Top shine
    final shinRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(brick.rect.left + 4, brick.rect.top + 2,
          brick.rect.width - 8, brick.rect.height * 0.35),
      const Radius.circular(3),
    );
    canvas.drawRRect(
        shinRect, Paint()..color = Colors.white.withOpacity(0.18));

    // Border
    canvas.drawRRect(
        rRect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  // ── Power-ups ───────────────────────────────────────────────────────────────
  void _drawPowerUps(Canvas canvas, List<PowerUpModel> powerUps) {
    for (final pu in powerUps) {
      if (!pu.isActive) continue;
      _drawPowerUp(canvas, pu);
    }
  }

  void _drawPowerUp(Canvas canvas, PowerUpModel pu) {
    final color = _puColor(pu.type);
    final r = GameConstants.powerUpSize / 2;

    // Glow
    canvas.drawCircle(
        pu.position,
        r + 5,
        Paint()
          ..color = color.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8));

    // Body
    canvas.drawCircle(pu.position, r, Paint()..color = color.withOpacity(0.9));

    // Icon letter
    final tp = TextPainter(
      text: TextSpan(
        text: _puIcon(pu.type),
        style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)]),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pu.position - Offset(tp.width / 2, tp.height / 2));
  }

  Color _puColor(PowerUpType t) {
    switch (t) {
      case PowerUpType.expandPaddle:
        return ColorConstants.puExpand;
      case PowerUpType.shrinkPaddle:
        return ColorConstants.puShrink;
      case PowerUpType.slowBall:
        return ColorConstants.puSlow;
      case PowerUpType.multiBall:
        return ColorConstants.puMultiBall;
      case PowerUpType.shield:
        return ColorConstants.puShield;
    }
  }

  String _puIcon(PowerUpType t) {
    switch (t) {
      case PowerUpType.expandPaddle:
        return '↔';
      case PowerUpType.shrinkPaddle:
        return '↕';
      case PowerUpType.slowBall:
        return 'S';
      case PowerUpType.multiBall:
        return '×3';
      case PowerUpType.shield:
        return '🛡';
    }
  }

  // ── Paddle ─────────────────────────────────────────────────────────────────
  void _drawPaddle(Canvas canvas, PaddleModel paddle) {
    final rect = Rect.fromLTWH(
        paddle.x, paddle.y, paddle.width, GameConstants.paddleHeight);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Glow
    canvas.drawRRect(
        rRect,
        Paint()
          ..color = ColorConstants.paddleGlow.withOpacity(0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14));

    // Gradient fill
    canvas.drawRRect(
        rRect,
        Paint()
          ..shader = LinearGradient(
            colors: [ColorConstants.paddleStart, ColorConstants.paddleEnd],
          ).createShader(rect));

    // Top shine
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(rect.left + 6, rect.top + 2, rect.width - 12, 4),
            const Radius.circular(2)),
        Paint()..color = Colors.white.withOpacity(0.3));
  }

  // ── Ball ───────────────────────────────────────────────────────────────────
  void _drawBall(Canvas canvas, BallModel ball) {
    final r = ball.radius;

    // Outer glow
    canvas.drawCircle(
        ball.position,
        r + 8,
        Paint()
          ..color = ColorConstants.ballGlow.withOpacity(0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14));

    // Mid glow
    canvas.drawCircle(
        ball.position,
        r + 3,
        Paint()
          ..color = ColorConstants.ballGlow.withOpacity(0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6));

    // Core with radial gradient
    canvas.drawCircle(
        ball.position,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.35),
            colors: [Colors.white, ColorConstants.ballGlow],
          ).createShader(
              Rect.fromCircle(center: ball.position, radius: r)));
  }

  // ── Launch hint ─────────────────────────────────────────────────────────────
  void _drawLaunchHint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'TAP TO LAUNCH',
        style: TextStyle(
          color: Color(0xFF80DEEA),
          fontSize: 13,
          letterSpacing: 2.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.72));
  }

  @override
  bool shouldRepaint(_GamePainter old) => true; // always repaint (game loop)
}
