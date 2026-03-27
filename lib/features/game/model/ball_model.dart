import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Immutable model representing the ball's state (position, velocity, trail).
class BallModel extends Equatable {
  final Offset position;
  final Offset velocity;
  final double radius;
  final bool isActive;
  final List<Offset> trail; // recent positions for neon trail rendering

  const BallModel({
    required this.position,
    required this.velocity,
    required this.radius,
    this.isActive = true,
    this.trail = const [],
  });

  BallModel copyWith({
    Offset? position,
    Offset? velocity,
    double? radius,
    bool? isActive,
    List<Offset>? trail,
  }) {
    return BallModel(
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      radius: radius ?? this.radius,
      isActive: isActive ?? this.isActive,
      trail: trail ?? this.trail,
    );
  }

  @override
  List<Object?> get props => [position, velocity, radius, isActive];
  // trail excluded from props – changes every frame, comparison not needed
}
