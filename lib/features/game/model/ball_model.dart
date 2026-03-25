import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Immutable model representing the ball's state.
class BallModel extends Equatable {
  final Offset position;
  final Offset velocity;
  final double radius;
  final bool isActive;

  const BallModel({
    required this.position,
    required this.velocity,
    required this.radius,
    this.isActive = true,
  });

  BallModel copyWith({
    Offset? position,
    Offset? velocity,
    double? radius,
    bool? isActive,
  }) {
    return BallModel(
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      radius: radius ?? this.radius,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [position, velocity, radius, isActive];
}
