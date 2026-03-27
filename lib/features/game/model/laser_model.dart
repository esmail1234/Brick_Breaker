import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Immutable model for a laser fired by the paddle.
class LaserModel extends Equatable {
  final int id;
  final Offset position;
  final bool isActive;

  const LaserModel({
    required this.id,
    required this.position,
    this.isActive = true,
  });

  LaserModel copyWith({
    int? id,
    Offset? position,
    bool? isActive,
  }) {
    return LaserModel(
      id: id ?? this.id,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, position, isActive];
}
