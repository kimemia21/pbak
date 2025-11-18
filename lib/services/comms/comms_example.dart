// // ignore_for_file: unused_local_variable, avoid_print

// /// Example usage of CommsService
// /// This file demonstrates various ways to use the CommsService
// /// for making network requests in the PBAK application.

// import 'package:pbak/services/comms/comms_service.dart';
// import 'package:pbak/services/comms/api_endpoints.dart';

// /// Example: Authentication Flow
// class AuthExample {
//   final _comms = CommsService.instance;

//   /// Example: Login
//   Future<void> login(String email, String password) async {
//     final response = await _comms.post<Map<String, dynamic>>(
//       ApiEndpoints.login,
//       data: {
//         'email': email,
//         'password': password,
//       },
//     );

//     if (response.success) {
//       // Extract token from response
//       final token = response.rawData?['token'] as String?;
//       if (token != null) {
//         // Set authentication token for subsequent requests
//         _comms.setAuthToken(token);
//         print('Login successful!');
//       }
//     } else {
//       print('Login failed: ${response.message}');
//       // Handle specific error types
//       if (response.errorType == CommsErrorType.unauthorized) {
//         print('Invalid credentials');
//       } else if (response.errorType == CommsErrorType.network) {
//         print('No internet connection');
//       }
//     }
//   }

//   /// Example: Register
//   Future<void> register(Map<String, dynamic> userData) async {
//     final response = await _comms.post<Map<String, dynamic>>(
//       ApiEndpoints.register,
//       data: userData,
//     );

//     if (response.success) {
//       print('Registration successful!');
//       // Auto-login after registration
//       final token = response.rawData?['token'] as String?;
//       if (token != null) {
//         _comms.setAuthToken(token);
//       }
//     } else {
//       print('Registration failed: ${response.message}');
//       if (response.errorType == CommsErrorType.validationError) {
//         print('Please check your input fields');
//       }
//     }
//   }

//   /// Example: Logout
//   Future<void> logout() async {
//     final response = await _comms.post(ApiEndpoints.logout);
    
//     // Remove token regardless of response
//     _comms.removeAuthToken();
    
//     if (response.success) {
//       print('Logout successful!');
//     }
//   }
// }

// /// Example: Fetching Data
// class DataFetchingExample {
//   final _comms = CommsService.instance;

//   /// Example: Get all clubs
//   Future<void> fetchClubs() async {
//     final response = await _comms.get<List>(ApiEndpoints.allClubs);

//     if (response.success && response.data != null) {
//       print('Fetched ${response.data!.length} clubs');
//       // Process clubs data
//       for (var club in response.data!) {
//         print('Club: ${club['name']}');
//       }
//     } else {
//       print('Failed to fetch clubs: ${response.message}');
//     }
//   }

//   /// Example: Get clubs with filters
//   Future<void> fetchClubsByRegion(String region) async {
//     final response = await _comms.get<List>(
//       ApiEndpoints.allClubs,
//       queryParameters: {
//         'region': region,
//         'limit': 20,
//         'sort': 'name',
//       },
//     );

//     if (response.success && response.data != null) {
//       print('Found ${response.data!.length} clubs in $region');
//     }
//   }

//   /// Example: Get specific club by ID
//   Future<void> fetchClubDetails(String clubId) async {
//     final response = await _comms.get<Map<String, dynamic>>(
//       ApiEndpoints.clubById(clubId),
//     );

//     if (response.success && response.rawData != null) {
//       print('Club name: ${response.rawData!['name']}');
//       print('Members: ${response.rawData!['memberCount']}');
//     } else if (response.errorType == CommsErrorType.notFound) {
//       print('Club not found');
//     }
//   }
// }

// /// Example: Creating and Updating Data
// class DataMutationExample {
//   final _comms = CommsService.instance;

//   /// Example: Create a new club
//   Future<void> createClub(Map<String, dynamic> clubData) async {
//     final response = await _comms.post<Map<String, dynamic>>(
//       ApiEndpoints.createClub,
//       data: clubData,
//     );

//     if (response.success && response.rawData != null) {
//       final newClubId = response.rawData!['id'];
//       print('Club created successfully with ID: $newClubId');
//     } else {
//       print('Failed to create club: ${response.message}');
//     }
//   }

//   /// Example: Update user profile
//   Future<void> updateProfile(Map<String, dynamic> updates) async {
//     final response = await _comms.put<Map<String, dynamic>>(
//       ApiEndpoints.updateProfile,
//       data: updates,
//     );

//     if (response.success) {
//       print('Profile updated successfully');
//     } else {
//       print('Failed to update profile: ${response.message}');
//     }
//   }

//   /// Example: Delete a bike
//   Future<void> deleteBike(String bikeId) async {
//     final response = await _comms.delete(
//       ApiEndpoints.deleteBike(bikeId),
//     );

//     if (response.success) {
//       print('Bike deleted successfully');
//     } else {
//       print('Failed to delete bike: ${response.message}');
//     }
//   }
// }

// /// Example: File Operations
// class FileOperationsExample {
//   final _comms = CommsService.instance;

//   /// Example: Upload profile image
//   Future<void> uploadProfileImage(String imagePath) async {
//     final response = await _comms.uploadFile<Map<String, dynamic>>(
//       ApiEndpoints.uploadProfileImage,
//       filePath: imagePath,
//       fileField: 'image',
//       onSendProgress: (sent, total) {
//         final progress = (sent / total * 100).toStringAsFixed(0);
//         print('Upload progress: $progress%');
//       },
//     );

//     if (response.success && response.rawData != null) {
//       final imageUrl = response.rawData!['url'];
//       print('Image uploaded successfully: $imageUrl');
//     } else {
//       print('Failed to upload image: ${response.message}');
//     }
//   }

//   /// Example: Download insurance document
//   Future<void> downloadInsuranceDocument(
//     String documentUrl,
//     String savePath,
//   ) async {
//     final response = await _comms.downloadFile(
//       documentUrl,
//       savePath,
//       onReceiveProgress: (received, total) {
//         final progress = (received / total * 100).toStringAsFixed(0);
//         print('Download progress: $progress%');
//       },
//     );

//     if (response.success) {
//       print('Document downloaded successfully to: $savePath');
//     } else {
//       print('Failed to download document: ${response.message}');
//     }
//   }
// }

// /// Example: Trip Operations
// class TripOperationsExample {
//   final _comms = CommsService.instance;

//   /// Example: Start a new trip
//   Future<String?> startTrip(Map<String, dynamic> tripData) async {
//     final response = await _comms.post<Map<String, dynamic>>(
//       ApiEndpoints.startTrip,
//       data: tripData,
//     );

//     if (response.success && response.rawData != null) {
//       final tripId = response.rawData!['id'] as String?;
//       print('Trip started with ID: $tripId');
//       return tripId;
//     } else {
//       print('Failed to start trip: ${response.message}');
//       return null;
//     }
//   }

//   /// Example: Update trip location
//   Future<void> updateTripLocation(
//     String tripId,
//     double latitude,
//     double longitude,
//   ) async {
//     final response = await _comms.patch(
//       ApiEndpoints.updateTripLocation(tripId),
//       data: {
//         'latitude': latitude,
//         'longitude': longitude,
//         'timestamp': DateTime.now().toIso8601String(),
//       },
//     );

//     if (!response.success) {
//       print('Failed to update location: ${response.message}');
//     }
//   }

//   /// Example: End trip
//   Future<void> endTrip(String tripId, Map<String, dynamic> finalData) async {
//     final response = await _comms.post<Map<String, dynamic>>(
//       ApiEndpoints.endTrip(tripId),
//       data: finalData,
//     );

//     if (response.success && response.rawData != null) {
//       print('Trip ended successfully');
//       print('Distance: ${response.rawData!['distance']} km');
//       print('Duration: ${response.rawData!['duration']} minutes');
//     } else {
//       print('Failed to end trip: ${response.message}');
//     }
//   }
// }

// /// Example: Error Handling Patterns
// class ErrorHandlingExample {
//   final _comms = CommsService.instance;

//   /// Example: Comprehensive error handling
//   Future<void> makeRequestWithErrorHandling() async {
//     final response = await _comms.get('/some-endpoint');

//     if (response.success) {
//       // Handle success
//       print('Request successful');
//     } else {
//       // Handle different error types
//       switch (response.errorType) {
//         case CommsErrorType.network:
//           print('No internet connection. Please check your network.');
//           // Show retry button
//           break;

//         case CommsErrorType.timeout:
//           print('Request timed out. Please try again.');
//           // Show retry button
//           break;

//         case CommsErrorType.unauthorized:
//           print('Session expired. Please login again.');
//           // Navigate to login screen
//           break;

//         case CommsErrorType.forbidden:
//           print('You don\'t have permission to access this resource.');
//           break;

//         case CommsErrorType.notFound:
//           print('Resource not found.');
//           break;

//         case CommsErrorType.validationError:
//           print('Validation error: ${response.message}');
//           // Show validation errors to user
//           break;

//         case CommsErrorType.serverError:
//           print('Server error. Please try again later.');
//           break;

//         case CommsErrorType.cancelled:
//           print('Request cancelled.');
//           break;

//         default:
//           print('An error occurred: ${response.message}');
//       }
//     }
//   }

//   /// Example: Retry logic
//   Future<void> makeRequestWithRetry({int maxRetries = 3}) async {
//     int retryCount = 0;

//     while (retryCount < maxRetries) {
//       final response = await _comms.get('/some-endpoint');

//       if (response.success) {
//         print('Request successful');
//         return;
//       }

//       // Only retry on network or timeout errors
//       if (response.errorType == CommsErrorType.network ||
//           response.errorType == CommsErrorType.timeout) {
//         retryCount++;
//         print('Retry attempt $retryCount of $maxRetries');
//         await Future.delayed(Duration(seconds: retryCount * 2));
//       } else {
//         // Don't retry for other error types
//         print('Request failed: ${response.message}');
//         return;
//       }
//     }

//     print('Max retries reached. Request failed.');
//   }
// }

// /// Example: Using with Riverpod Providers
// class ProviderIntegrationExample {
//   final _comms = CommsService.instance;

//   /// Example: Fetch data for a provider
//   Future<List<Map<String, dynamic>>> fetchEventsForProvider() async {
//     final response = await _comms.get<List>(ApiEndpoints.allEvents);

//     if (response.success && response.data != null) {
//       return response.data!.cast<Map<String, dynamic>>();
//     }

//     // Return empty list on error or let provider handle error
//     throw Exception(response.message ?? 'Failed to fetch events');
//   }

//   /// Example: Paginated data fetching
//   Future<Map<String, dynamic>> fetchPaginatedData(
//     String endpoint, {
//     int page = 1,
//     int limit = 20,
//   }) async {
//     final response = await _comms.get<Map<String, dynamic>>(
//       endpoint,
//       queryParameters: {
//         'page': page,
//         'limit': limit,
//       },
//     );

//     if (response.success && response.rawData != null) {
//       return response.rawData!;
//     }

//     throw Exception(response.message ?? 'Failed to fetch data');
//   }
// }
