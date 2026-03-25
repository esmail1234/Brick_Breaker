// Core game constants – physics, grid, and gameplay values.
class GameConstants {
  GameConstants._();

  // Ball
  static const double ballRadius = 10.0;
  static const double initialBallSpeed = 340.0; // px/s
  static const double ballSpeedIncrement = 20.0; // added per level
  static const double maxBallSpeed = 700.0;

  // Paddle
  static const double paddleHeight = 16.0;
  static const double paddleInitialWidth = 100.0;
  static const double paddleMinWidth = 65.0;
  static const double paddleMaxWidth = 158.0;
  static const double paddleBottomOffset = 60.0;
  static const double maxDeflectionAngleDeg = 65.0;

  // Bricks
  static const double brickHeight = 22.0;
  static const double brickPaddingH = 5.0;
  static const double brickPaddingV = 5.0;
  static const double brickTopOffset = 90.0;
  static const int brickCols = 8;
  static const int maxBrickDurability = 4;

  // Power-ups
  static const double powerUpSize = 22.0;
  static const double powerUpFallSpeed = 130.0;
  static const double powerUpDropChance = 0.22;
  static const double powerUpDuration = 8.0;
  static const double expandFactor = 1.4;
  static const double shrinkFactor = 0.72;
  static const double slowFactor = 0.65;
  static const double shieldDuration = 7.0;

  // Scoring
  static const int maxLives = 3;
  static const int scorePerBrick = 10;
  static const int scoreBonusPerLevel = 150;
}
