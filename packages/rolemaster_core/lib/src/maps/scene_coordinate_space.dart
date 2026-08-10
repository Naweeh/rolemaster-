final class SceneCoordinateSpace {
  SceneCoordinateSpace({required this.width, required this.height}) {
    if (!width.isFinite || width <= 0) {
      throw ArgumentError.value(width, 'width', 'Map width must be positive.');
    }
    if (!height.isFinite || height <= 0) {
      throw ArgumentError.value(height, 'height', 'Map height must be positive.');
    }
  }

  final double width;
  final double height;

  bool contains(double x, double y) =>
      x.isFinite && y.isFinite && x >= 0 && y >= 0 && x <= width && y <= height;
}
