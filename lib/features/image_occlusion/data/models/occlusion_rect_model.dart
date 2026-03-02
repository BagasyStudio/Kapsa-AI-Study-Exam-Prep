/// A single occlusion rectangle on an image.
///
/// Coordinates are stored as ratios (0.0–1.0) relative to image dimensions,
/// making them resolution-independent.
class OcclusionRect {
  final double x;
  final double y;
  final double width;
  final double height;
  final String label;

  const OcclusionRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
  });

  factory OcclusionRect.fromJson(Map<String, dynamic> json) {
    return OcclusionRect(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'label': label,
      };

  OcclusionRect copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? label,
  }) {
    return OcclusionRect(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      label: label ?? this.label,
    );
  }
}
