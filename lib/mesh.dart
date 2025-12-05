import 'dart:io';

import 'package:pbak/ai/concrete_detection_service.dart';

void main() async {
  final service = ConcreteDetectionService();
  
  print('Initializing model...');
  final initialized = await service.initialize();
  
  if (!initialized) {
    print('❌ Failed to initialize');
    return;
  }
  
  print('✅ Model initialized successfully');
  
  // Test with demo image
  final demoImage = File('assets/ai/demo.jpg');
  if (await demoImage.exists()) {
    print('Analyzing demo image...');
    final result = await service.analyze(demoImage);
    
    print('✅ Analysis complete!');
    print(result.getSummary());
  }
  
  service.dispose();
}