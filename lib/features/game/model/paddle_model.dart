import 'package:equatable/equatable.dart';

/// Immutable model representing the paddle's state.
class PaddleModel extends Equatable {
  final double x;
  final double y;
  final double width;
  final double flashTimer;

  const PaddleModel({
    required this.x,
    required this.y,
    required this.width,
    this.flashTimer = 0,
  });

  PaddleModel copyWith({double? x, double? y, double? width, double? flashTimer}) {
    return PaddleModel(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      flashTimer: flashTimer ?? this.flashTimer,
    );
  }

  @override
  List<Object?> get props => [x, y, width, flashTimer];
}
