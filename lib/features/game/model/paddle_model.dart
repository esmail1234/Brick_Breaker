import 'package:equatable/equatable.dart';

/// Immutable model representing the paddle's state.
class PaddleModel extends Equatable {
  final double x;
  final double y;
  final double width;

  const PaddleModel({
    required this.x,
    required this.y,
    required this.width,
  });

  PaddleModel copyWith({double? x, double? y, double? width}) {
    return PaddleModel(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
    );
  }

  @override
  List<Object?> get props => [x, y, width];
}
