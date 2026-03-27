// Core game constants – physics, grid, and gameplay values.
class GameConstants {
  GameConstants._();

  // Ball
  static const double ballRadius = 10.0;
  static const double initialBallSpeed = 340.0;
  static const double ballSpeedIncrement = 20.0;
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
  static const double flashDuration = 0.12;

  // Boss
  static const int bossLevelInterval = 5;
  static const int bossBrickHP = 12;
  static const double bossBrickSpeed = 85.0;

  // Power-ups
  static const double powerUpSize = 22.0;
  static const double powerUpFallSpeed = 130.0;
  static const double powerUpDropChance = 0.22;
  static const double powerUpDuration = 8.0;
  static const double expandFactor = 1.4;
  static const double shrinkFactor = 0.72;
  static const double slowFactor = 0.60;
  static const double shieldDuration = 7.0;
  static const double slowBallDuration = 7.0;

  // Particles
  static const int particlesPerBrick = 9;
  static const double particleSpeed = 210.0;
  static const double particleLife = 0.75;
  static const double particleSize = 5.0;
  static const int bossParticlesPerBrick = 20;

  // Combo
  static const double comboTimeout = 1.6;

  // Trail
  static const int trailLength = 14;

  // Screen shake
  static const double shakeDuration = 0.18;
  static const double shakeIntensity = 5.5;

  // Slow-motion at game-over
  static const double slowMoScale = 0.12;
  static const double slowMoDuration = 1.4;

  // Descending Bricks Mechanics
  static const double descendStep = 12.0;
  static const int hitsToDescend = 4;

  // New Power-ups
  static const double laserSpeed = 450.0;
  static const double laserWidth = 4.0;
  static const double laserHeight = 16.0;
  static const double laserDuration = 5.0;
  static const double stickyDuration = 5.0;
  static const double fireballDuration = 6.0;
  static const double laserSpawnRate = 0.4; // fire every 0.4s

  // Floating Combat Text
  static const double floatingTextDuration = 1.2;
  static const double floatingTextVelocityY = -40.0;

  // Boss minions
  static const double bossMinionSpawnRate = 3.5; // Every 3.5 seconds

  // Scoring
  static const int maxLives = 3;
  static const int scorePerBrick = 10;
  static const int scoreBonusPerLevel = 150;

}
