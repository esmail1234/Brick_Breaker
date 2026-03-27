import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Enum for various brick types
enum BrickType { normal, hard, unbreakable, explosive, ghost }

/// Immutable model for a single brick, including flash and boss support.
class BrickModel extends Equatable {
  final int id;
  final int row;
  final int col;
  final Rect rect;
  final int durability;
  final bool isDestroyed;
  final double flashTimer;   // > 0 → render as white (hit flash)
  final double ghostTimer;   // time used for alpha sine wave
  final bool isBoss;
  final double bossVelocityX; // horizontal movement in px/s
  final BrickType type;

  const BrickModel({
    required this.id,
    required this.row,
    required this.col,
    required this.rect,
    required this.durability,
    this.isDestroyed = false,
    this.flashTimer = 0,
    this.ghostTimer = 0,
    this.isBoss = false,
    this.bossVelocityX = 0,
    this.type = BrickType.normal,
  });

  BrickModel hit() {
    final newDur = durability - 1;
    return copyWith(durability: newDur, isDestroyed: newDur <= 0);
  }

  BrickModel copyWith({
    int? id,
    int? row,
    int? col,
    Rect? rect,
    int? durability,
    bool? isDestroyed,
    double? flashTimer,
    double? ghostTimer,
    bool? isBoss,
    double? bossVelocityX,
    BrickType? type,
  }) {
    return BrickModel(
      id: id ?? this.id,
      row: row ?? this.row,
      col: col ?? this.col,
      rect: rect ?? this.rect,
      durability: durability ?? this.durability,
      isDestroyed: isDestroyed ?? this.isDestroyed,
      flashTimer: flashTimer ?? this.flashTimer,
      ghostTimer: ghostTimer ?? this.ghostTimer,
      isBoss: isBoss ?? this.isBoss,
      bossVelocityX: bossVelocityX ?? this.bossVelocityX,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props =>
      [id, row, col, rect, durability, isDestroyed, flashTimer, ghostTimer, isBoss, bossVelocityX, type];
}
