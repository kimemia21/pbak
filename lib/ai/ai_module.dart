/// AI Module for Concrete and Demolition Material Detection
/// 
/// This module provides on-device AI detection capabilities for:
/// - Concrete structures
/// - Demolition materials / rubble
/// - Volume estimation
/// 
/// Usage:
/// ```dart
/// import 'package:pbak/ai/ai_module.dart';
/// 
/// final service = ConcreteDetectionService();
/// await service.initialize();
/// final result = await service.analyze(imageFile);
/// ```
library ai_module;

export 'concrete_detection_service.dart';
export 'models/bounding_box.dart';
export 'models/detection_result.dart';
