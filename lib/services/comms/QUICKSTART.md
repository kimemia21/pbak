# CommsService Quick Start Guide

Get started with CommsService in 5 minutes!

## 1. Installation ✅

The dio package is already installed in `pubspec.yaml`. Just run:

```bash
flutter pub get
```

## 2. Basic Setup

### Import the service

```dart
import 'package:pbak/services/comms/comms.dart';
```

That's it! The service is ready to use.

## 3. Your First Request

### GET Request

```dart
final comms = CommsService.instance;

final response = await comms.get<Map<String, dynamic>>(
  ApiEndpoints.allClubs,
);

if (response.success) {
  print('Data: ${response.data}');
} else {
  print('Error: ${response.message}');
}
```

### POST Request

```dart
final response = await comms.post<Map<String, dynamic>>(
  ApiEndpoints.login,
  data: {
    'email': 'user@example.com',
    'password': 'password123',
  },
);

if (response.success) {
  final token = response.rawData?['token'];
  comms.setAuthToken(token);
}
```

## 4. Configuration

Edit `lib/services/comms/comms_config.dart`:

```dart
class CommsConfig {
  // Change environment
  static const String currentEnvironment = development; // or staging/production
  
  // Update base URLs
  static const Map<String, String> baseUrls = {
    development: 'http://localhost:3000/api/v1',
    staging: 'https://staging-api.pbak.co.ke/v1',
    production: 'https://api.pbak.co.ke/v1',
  };
  
  // Toggle mock API
  static const bool useMockApi = true; // Set to false for real API
}
```

## 5. Common Patterns

### Authentication Flow

```dart
// Login
final response = await comms.post(ApiEndpoints.login, data: credentials);
if (response.success) {
  comms.setAuthToken(response.rawData?['token']);
}

// Make authenticated requests (token is automatically included)
await comms.get(ApiEndpoints.profile);

// Logout
comms.removeAuthToken();
```

### Error Handling

```dart
final response = await comms.get('/endpoint');

if (!response.success) {
  switch (response.errorType) {
    case CommsErrorType.network:
      showSnackBar('No internet connection');
      break;
    case CommsErrorType.unauthorized:
      navigateToLogin();
      break;
    default:
      showSnackBar(response.message ?? 'An error occurred');
  }
}
```

### File Upload

```dart
await comms.uploadFile(
  ApiEndpoints.uploadProfileImage,
  filePath: '/path/to/image.jpg',
  fileField: 'image',
  onSendProgress: (sent, total) {
    final progress = (sent / total * 100).toStringAsFixed(0);
    print('Upload: $progress%');
  },
);
```

## 6. Testing

Navigate to the test screen in your app:

```
Home > Developer Menu > Comms Test
```

Or navigate directly:
```dart
context.go('/comms-test');
```

## 7. Integration with Providers

### Using with Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/services/comms/comms.dart';

final clubsProvider = FutureProvider<List<Club>>((ref) async {
  final comms = CommsService.instance;
  final response = await comms.get<List>(ApiEndpoints.allClubs);
  
  if (response.success && response.data != null) {
    return response.data!.map((e) => Club.fromJson(e)).toList();
  }
  
  throw Exception(response.message ?? 'Failed to fetch clubs');
});
```

## 8. API Endpoints

All endpoints are defined in `api_endpoints.dart`:

```dart
// Use predefined endpoints
await comms.get(ApiEndpoints.allClubs);
await comms.get(ApiEndpoints.clubById('club_123'));
await comms.post(ApiEndpoints.createClub, data: clubData);

// Add your own endpoints
class ApiEndpoints {
  static const String myEndpoint = '/my-endpoint';
  static String myDynamicEndpoint(String id) => '/my-endpoint/$id';
}
```

## 9. Common Issues

### Issue: Connection timeout
**Solution:** Increase timeout in `comms_config.dart` or check your network

### Issue: 401 Unauthorized
**Solution:** Check if auth token is set: `comms.setAuthToken(token)`

### Issue: SSL certificate error (development only)
**Solution:** Update base URL to use `http://` instead of `https://` for local development

## 10. Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Check [comms_example.dart](comms_example.dart) for more examples
- Explore [api_endpoints.dart](api_endpoints.dart) for all available endpoints
- Configure [comms_config.dart](comms_config.dart) for your environment

## Need Help?

- Check the [README.md](README.md) for detailed documentation
- Look at [comms_example.dart](comms_example.dart) for code examples
- Test your setup using the CommsTestScreen (`/comms-test`)

---

**Happy coding! 🚀**
