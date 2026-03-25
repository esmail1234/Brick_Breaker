import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Immutable model for a single brick.
class BrickModel extends Equatable {
  final int id;
  final int row;
  final int col;
  final Rect rect;
  final int durability; // 1-4, decrements on hit
  final bool isDestroyed;

  const BrickModel({
    required this.id,
    required this.row,
    required this.col,
    required this.rect,
    required this.durability,
    this.isDestroyed = false,
  });

  /// Returns a new BrickModel after being hit once.
  BrickModel hit() {
    final newDur = durability - 1;
    return copyWith(
      durability: newDur,
      isDestroyed: newDur <= 0,
    );
  }

  BrickModel copyWith({
    int? id,
    int? row,
    int? col,
    Rect? rect,
    int? durability,
    bool? isDestroyed,
  }) {
    return BrickModel(
      id: id ?? this.id,
      row: row ?? this.row,
      col: col ?? this.col,
      rect: rect ?? this.rect,
      durability: durability ?? this.durability,
      isDestroyed: isDestroyed ?? this.isDestroyed,
    );
  }

  @override
  List<Object?> get props => [id, row, col, rect, durability, isDestroyed];
}
