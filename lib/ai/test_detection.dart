import 'dart:io';
import 'package:flutter/material.dart';
import 'concrete_detection_service.dart';

/// Simple standalone test for concrete detection
/// Run this with: flutter run -t lib/ai/test_detection.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== Concrete Detection Test ===\n');
  
  final service = ConcreteDetectionService();
  
  print('Initializing model...');
  final initialized = await service.initialize();
  
  if (!initialized) {
    print('❌ Failed to initialize model');
    return;
  }
  
  print('✅ Model initialized successfully\n');
  
  // Test with demo image
  final demoImage = File('assets/ai/demo.jpg');
  
  if (!await demoImage.exists()) {
    print('⚠️  Demo image not found at: ${demoImage.path}');
    print('Please add a test image at this location\n');
    return;
  }
  
  print('Analyzing demo image...');
  final result = await service.analyze(demoImage);
  
  print('\n=== Results ===\n');
  print(result.getSummary());
  
  print('\n=== Detailed Info ===');
  print('Bounding boxes: ${result.boundingBoxes.length}');
  for (int i = 0; i < result.boundingBoxes.length && i < 10; i++) {
    final box = result.boundingBoxes[i];
    print('  [$i] ${box.label}: ${(box.confidence * 100).toStringAsFixed(1)}% '
          '(x:${box.x.toInt()}, y:${box.y.toInt()}, '
          'w:${box.width.toInt()}, h:${box.height.toInt()})');
  }
  
  if (result.boundingBoxes.length > 10) {
    print('  ... and ${result.boundingBoxes.length - 10} more');
  }
  
  service.dispose();
  print('\n✅ Test completed');
}
