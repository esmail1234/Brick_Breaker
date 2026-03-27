import 'package:flutter/material.dart';

/// A single visual particle spawned when a brick is destroyed.
class ParticleModel {
  final int id;
  final Offset position;
  final Offset velocity;
  final Color color;
  final double life;    // 1.0 = fresh, 0.0 = dead
  final double maxLife;
  final double size;

  const ParticleModel({
    required this.id,
    required this.position,
    required this.velocity,
    required this.color,
    required this.life,
    required this.maxLife,
    required this.size,
  });

  bool get isAlive => life > 0;

  ParticleModel copyWith({
    Offset? position,
    Offset? velocity,
    double? life,
  }) {
    return ParticleModel(
      id: id,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      color: color,
      life: life ?? this.life,
      maxLife: maxLife,
      size: size,
    );
  }
}
