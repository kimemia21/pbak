/// Represents a bounding box for a detected object.
class BoundingBox {
  /// X-coordinate of the top-left corner (normalized 0-1 or pixel coordinates)
  final double x;
  
  /// Y-coordinate of the top-left corner (normalized 0-1 or pixel coordinates)
  final double y;
  
  /// Width of the bounding box
  final double width;
  
  /// Height of the bounding box
  final double height;
  
  /// Confidence score for this detection (0-1)
  final double confidence;
  
  /// Class label for the detected object (e.g., "concrete", "rubble", "debris")
  final String? label;
  
  /// Class ID from the model
  final int? classId;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
    this.label,
    this.classId,
  });

  /// Creates a copy of this bounding box with optional field overrides
  BoundingBox copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? confidence,
    String? label,
    int? classId,
  }) {
    return BoundingBox(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      confidence: confidence ?? this.confidence,
      label: label ?? this.label,
      classId: classId ?? this.classId,
    );
  }

  /// Computes the area of this bounding box
  double get area => width * height;

  /// Computes the center point of this bounding box
  (double x, double y) get center => (x + width / 2, y + height / 2);

  @override
  String toString() {
    return 'BoundingBox(x: $x, y: $y, w: $width, h: $height, conf: ${confidence.toStringAsFixed(2)}, label: $label)';
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'confidence': confidence,
      'label': label,
      'classId': classId,
    };
  }

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: json['x'] as double,
      y: json['y'] as double,
      width: json['width'] as double,
      height: json['height'] as double,
      confidence: json['confidence'] as double,
      label: json['label'] as String?,
      classId: json['classId'] as int?,
    );
  }
}
