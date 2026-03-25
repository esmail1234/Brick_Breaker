import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PowerUpType { expandPaddle, shrinkPaddle, slowBall, multiBall, shield }

/// Immutable model for a falling power-up pickup.
class PowerUpModel extends Equatable {
  final int id;
  final PowerUpType type;
  final Offset position;
  final bool isActive;

  const PowerUpModel({
    required this.id,
    required this.type,
    required this.position,
    this.isActive = true,
  });

  Rect get rect => Rect.fromCenter(
        center: position,
        width: 22,
        height: 22,
      );

  PowerUpModel copyWith({
    int? id,
    PowerUpType? type,
    Offset? position,
    bool? isActive,
  }) {
    return PowerUpModel(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, type, position, isActive];
}
