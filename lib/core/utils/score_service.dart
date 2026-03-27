import 'package:shared_preferences/shared_preferences.dart';

/// Persists the player's all-time high score via SharedPreferences.
class ScoreService {
  ScoreService._();

  static const String _key = 'brick_breaker_high_score';
  static const String _unlockedKey = 'unlocked_level';

  static Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  static Future<void> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key) ?? 0;
    if (score > current) {
      await prefs.setInt(_key, score);
    }
  }

  static Future<void> saveUnlockedLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_unlockedKey) ?? 1;
    if (level > current) {
      await prefs.setInt(_unlockedKey, level);
    }
  }
}
