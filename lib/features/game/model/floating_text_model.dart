import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Immutable model for combat text floating above destroyed bricks.
class FloatingTextModel extends Equatable {
  final int id;
  final Offset position;
  final String text;
  final double life; // 1.0 down to 0.0

  const FloatingTextModel({
    required this.id,
    required this.position,
    required this.text,
    required this.life,
  });

  FloatingTextModel copyWith({
    int? id,
    Offset? position,
    String? text,
    double? life,
  }) {
    return FloatingTextModel(
      id: id ?? this.id,
      position: position ?? this.position,
      text: text ?? this.text,
      life: life ?? this.life,
    );
  }

  @override
  List<Object?> get props => [id, position, text, life];
}
