import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/color_constants.dart';
import 'splash_screen.dart';
import 'game_screen.dart';
import '../../../core/utils/sound_service.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int _unlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _unlockedLevel = prefs.getInt('unlocked_level') ?? 1;
    });
  }

  void _selectLevel(int level) {
    if (level > _unlockedLevel) {
      SoundService.playBallHit(); // error sound
      return;
    }
    SoundService.playPowerUp();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: GameScreen(initialLevel: level),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'SELECT LEVEL',
              style: GoogleFonts.orbitron(
                color: ColorConstants.neonBlue,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                shadows: [Shadow(color: ColorConstants.neonBlue, blurRadius: 16)],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 20, // max 20 levels for now
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final isUnlocked = level <= _unlockedLevel;
                  return GestureDetector(
                    onTap: () => _selectLevel(level),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isUnlocked 
                            ? ColorConstants.neonCyan.withValues(alpha: 0.2) 
                            : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: isUnlocked 
                              ? ColorConstants.neonCyan 
                              : Colors.white24,
                          width: isUnlocked ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isUnlocked ? [
                          BoxShadow(color: ColorConstants.neonCyan.withValues(alpha: 0.3), blurRadius: 8)
                        ] : null,
                      ),
                      alignment: Alignment.center,
                      child: isUnlocked 
                          ? Text(
                              '$level', 
                              style: GoogleFonts.orbitron(
                                color: Colors.white, 
                                fontSize: 24, 
                                fontWeight: FontWeight.bold
                              ),
                            )
                          : const Icon(Icons.lock, color: Colors.white38),
                    ),
                  );
                },
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: const SplashScreen()),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'BACK TO MENU',
                  style: GoogleFonts.orbitron(
                    color: Colors.white54,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
