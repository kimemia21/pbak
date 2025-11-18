# CommsService - Global Network Communication Service

A centralized service for handling all HTTP network requests in the PBAK application using the Dio package.

## Features

- ✅ Singleton pattern for global access
- ✅ Built-in error handling and response wrapping
- ✅ Request/Response logging (debug mode only)
- ✅ Authentication token management
- ✅ Support for all HTTP methods (GET, POST, PUT, PATCH, DELETE)
- ✅ File upload and download support
- ✅ Timeout configuration
- ✅ Custom interceptors
- ✅ Type-safe responses

## Installation

The service uses the `dio` package which is already added to `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.4.0
```

Run `flutter pub get` to install the dependency.

## Basic Usage

### 1. Accessing the Service

```dart
import 'package:pbak/services/comms/comms_service.dart';

// Get the singleton instance
final comms = CommsService.instance;
```

### 2. Making GET Requests

```dart
// Simple GET request
final response = await comms.get<Map<String, dynamic>>('/users/profile');

if (response.success) {
  print('Data: ${response.data}');
} else {
  print('Error: ${response.message}');
}

// GET with query parameters
final response = await comms.get<List>(
  '/clubs',
  queryParameters: {'region': 'Nairobi', 'limit': 10},
);
```

### 3. Making POST Requests

```dart
// POST request with data
final response = await comms.post<Map<String, dynamic>>(
  '/auth/login',
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

### 4. Making PUT/PATCH Requests

```dart
// Update user profile
final response = await comms.put<Map<String, dynamic>>(
  '/users/profile',
  data: {
    'name': 'John Doe',
    'phone': '+254712345678',
  },
);
```

### 5. Making DELETE Requests

```dart
// Delete a bike
final response = await comms.delete('/bikes/${bikeId}');

if (response.success) {
  print('Bike deleted successfully');
}
```

### 6. File Upload

```dart
// Upload profile image
final response = await comms.uploadFile<Map<String, dynamic>>(
  '/users/profile/image',
  filePath: '/path/to/image.jpg',
  fileField: 'image',
  data: {'userId': 'user_123'},
  onSendProgress: (sent, total) {
    print('Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
  },
);
```

### 7. File Download

```dart
// Download a file
final response = await comms.downloadFile(
  '/documents/policy.pdf',
  '/path/to/save/policy.pdf',
  onReceiveProgress: (received, total) {
    print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
  },
);
```

## Authentication

### Setting Auth Token

```dart
// After successful login
comms.setAuthToken('your_jwt_token_here');

// All subsequent requests will include the Authorization header
```

### Removing Auth Token

```dart
// On logout
comms.removeAuthToken();
```

## Error Handling

The service provides a structured response wrapper with detailed error information:

```dart
final response = await comms.get('/some-endpoint');

if (response.success) {
  // Handle success
  print('Data: ${response.data}');
} else {
  // Handle error based on type
  switch (response.errorType) {
    case CommsErrorType.network:
      print('No internet connection');
      break;
    case CommsErrorType.timeout:
      print('Request timeout');
      break;
    case CommsErrorType.unauthorized:
      print('Unauthorized - please login again');
      break;
    case CommsErrorType.notFound:
      print('Resource not found');
      break;
    case CommsErrorType.validationError:
      print('Validation error: ${response.message}');
      break;
    default:
      print('Error: ${response.message}');
  }
}
```

## Response Structure

### CommsResponse<T>

```dart
class CommsResponse<T> {
  final T? data;              // Typed response data
  final int? statusCode;      // HTTP status code
  final String? message;      // Success or error message
  final bool success;         // Whether request was successful
  final CommsErrorType? errorType;  // Type of error if failed
  final Map<String, dynamic>? rawData;  // Raw response data
}
```

### Error Types

```dart
enum CommsErrorType {
  network,          // No internet connection
  timeout,          // Request timeout
  unauthorized,     // 401 - Need to login
  forbidden,        // 403 - No permission
  notFound,         // 404 - Resource not found
  validationError,  // 422 - Validation failed
  clientError,      // Other 4xx errors
  serverError,      // 5xx errors
  cancelled,        // Request was cancelled
  unknown,          // Unknown error
}
```

## Configuration

### Changing Base URL

```dart
// Useful for switching between environments
comms.updateBaseUrl('https://staging-api.pbak.co.ke/v1');
```

### Custom Timeout

```dart
// Access the underlying Dio instance for advanced configuration
comms.dio.options.connectTimeout = Duration(seconds: 60);
comms.dio.options.receiveTimeout = Duration(seconds: 60);
```

### Custom Headers

```dart
// Add custom headers
comms.dio.options.headers['X-Custom-Header'] = 'value';
```

## Advanced Usage

### Custom Interceptors

```dart
import 'package:dio/dio.dart';

class CustomInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Modify request before sending
    options.headers['X-Request-ID'] = generateRequestId();
    super.onRequest(options, handler);
  }
}

// Add the interceptor
comms.addInterceptor(CustomInterceptor());
```

### Cancel Requests

```dart
import 'package:dio/dio.dart';

final cancelToken = CancelToken();

// Make request with cancel token
final response = comms.get('/long-running-request', cancelToken: cancelToken);

// Cancel the request
cancelToken.cancel('User cancelled');
```

### Progress Tracking

```dart
// Upload with progress
await comms.uploadFile(
  '/uploads',
  filePath: filePath,
  fileField: 'file',
  onSendProgress: (sent, total) {
    final progress = (sent / total * 100).toStringAsFixed(0);
    print('Upload: $progress%');
  },
);

// Download with progress
await comms.downloadFile(
  '/downloads/large-file.zip',
  savePath,
  onReceiveProgress: (received, total) {
    final progress = (received / total * 100).toStringAsFixed(0);
    print('Download: $progress%');
  },
);
```

## Integration Example

### Creating an API Service Class

```dart
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

class UserApiService {
  final _comms = CommsService.instance;

  Future<User?> getProfile() async {
    final response = await _comms.get<Map<String, dynamic>>(
      ApiEndpoints.profile,
    );

    if (response.success && response.rawData != null) {
      return User.fromJson(response.rawData!);
    }
    return null;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final response = await _comms.put(
      ApiEndpoints.updateProfile,
      data: data,
    );
    return response.success;
  }
}
```

## Best Practices

1. **Use API Endpoints Constants**: Define all endpoints in `api_endpoints.dart` for better maintainability.

2. **Type Safety**: Always specify the generic type for better type safety:
   ```dart
   final response = await comms.get<Map<String, dynamic>>('/endpoint');
   ```

3. **Error Handling**: Always check `response.success` before accessing data.

4. **Token Management**: Set the auth token once after login, remove on logout.

5. **Environment Configuration**: Use different base URLs for dev, staging, and production.

6. **Logging**: The service logs all requests/responses in debug mode. This is automatically disabled in release builds.

## Troubleshooting

### No Internet Connection

The service automatically detects network issues and returns a `CommsErrorType.network` error.

### Timeout Issues

If you're experiencing timeouts, consider increasing the timeout duration:

```dart
comms.dio.options.connectTimeout = Duration(seconds: 60);
```

### SSL Certificate Issues

For development with self-signed certificates (not recommended for production):

```dart
comms.dio.httpClientAdapter = IOHttpClientAdapter(
  createHttpClient: () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  },
);
```

## Migration from MockApiService

If you're currently using `MockApiService`, you can gradually migrate to `CommsService`:

1. Keep `MockApiService` for development/testing
2. Create new API service classes using `CommsService`
3. Use feature flags to switch between mock and real API
4. Test thoroughly before removing `MockApiService`

## Support

For issues or questions about the CommsService, please refer to the main project documentation or contact the development team.
