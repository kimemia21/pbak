# Services Layer Documentation

This directory contains all the service classes that handle API interactions in a modular and organized way.

## Architecture Overview

```
lib/services/
├── auth_service.dart           # Authentication operations
├── member_service.dart         # Member/User operations
├── bike_service.dart           # Bike management
├── club_service.dart           # Club operations
├── event_service.dart          # Event management
├── package_service.dart        # Package/subscription operations
├── region_service.dart         # Region/Location data (Counties, Towns, Estates)
├── sos_service.dart            # Emergency SOS operations
├── trip_service.dart           # Trip tracking (existing)
├── upload_service.dart         # File upload operations
├── comms/                      # Communication layer
│   ├── comms_service.dart     # Core HTTP service
│   ├── api_endpoints.dart     # API endpoint constants
│   ├── comms_config.dart      # Configuration
│   └── registration_service.dart
├── crash_detection/            # Crash detection services
├── location/                   # Location services
└── local_storage/              # Local storage service
```

## Service Pattern

All services follow a singleton pattern with consistent structure:

```dart
class ServiceName {
  static final ServiceName _instance = ServiceName._internal();
  factory ServiceName() => _instance;
  ServiceName._internal();

  final _comms = CommsService.instance;

  // Service methods...
}
```

## Usage Examples

### 1. Authentication Service

```dart
import 'package:pbak/services/auth_service.dart';

final authService = AuthService();

// Login
final result = await authService.login(
  email: 'user@example.com',
  password: 'password123',
);

if (result.success) {
  print('Logged in as: ${result.user?.fullName}');
  print('Token: ${result.token}');
}

// Register
final registerResult = await authService.register({
  'email': 'new@example.com',
  'password': 'password123',
  'first_name': 'John',
  'last_name': 'Doe',
  // ... other fields
});

// Logout
await authService.logout();
```

### 2. Member Service

```dart
import 'package:pbak/services/member_service.dart';

final memberService = MemberService();

// Get all members
final members = await memberService.getAllMembers();

// Get member by ID
final member = await memberService.getMemberById(1);

// Update profile
final updatedMember = await memberService.updateProfile(
  memberId: 1,
  profileData: {
    'first_name': 'Jane',
    'phone': '+254712345678',
  },
);

// Upload profile image
final imageUrl = await memberService.uploadProfileImage(
  memberId: 1,
  imagePath: '/path/to/image.jpg',
);
```

### 3. Bike Service

```dart
import 'package:pbak/services/bike_service.dart';

final bikeService = BikeService();

// Get my bikes
final bikes = await bikeService.getMyBikes();

// Get bike makes
final makes = await bikeService.getBikeMakes();

// Get models for a make
final models = await bikeService.getBikeModels(makeId: 1);

// Add a bike
final newBike = await bikeService.addBike({
  'make_id': 1,
  'model_id': 1,
  'registration_number': 'KXX 123Y',
  'year': 2022,
});

// Update bike
final updated = await bikeService.updateBike(
  bikeId: 1,
  bikeData: {'color': 'Red'},
);

// Delete bike
await bikeService.deleteBike(1);
```

### 4. Club Service

```dart
import 'package:pbak/services/club_service.dart';

final clubService = ClubService();

// Get all clubs
final clubs = await clubService.getAllClubs();

// Get club details
final club = await clubService.getClubById(1);

// Join a club
await clubService.joinClub(1);

// Leave a club
await clubService.leaveClub(1);

// Get club members
final members = await clubService.getClubMembers(1);
```

### 5. Event Service

```dart
import 'package:pbak/services/event_service.dart';

final eventService = EventService();

// Get all events
final events = await eventService.getAllEvents();

// Get event details
final event = await eventService.getEventById(1);

// Register for event
await eventService.registerForEvent(1);

// Unregister from event
await eventService.unregisterFromEvent(1);

// Get attendees
final attendees = await eventService.getEventAttendees(1);
```

### 6. Package Service

```dart
import 'package:pbak/services/package_service.dart';

final packageService = PackageService();

// Get all packages
final packages = await packageService.getAllPackages();

// Subscribe to package
await packageService.subscribeToPackage(
  packageId: 1,
  memberId: 1,
);
```

### 7. Region Service

```dart
import 'package:pbak/services/region_service.dart';

final regionService = RegionService();

// Get all counties
final counties = await regionService.getAllCounties();

// Get towns in county
final towns = await regionService.getTownsInCounty(1);

// Get estates in town
final estates = await regionService.getEstatesInTown(
  countyId: 1,
  townId: 1,
);
```

### 8. SOS Service

```dart
import 'package:pbak/services/sos_service.dart';

final sosService = SOSService();

// Send SOS
final sos = await sosService.sendSOS(
  latitude: -1.2921,
  longitude: 36.8219,
  type: 'accident',
  description: 'Need immediate help',
);

// Get my SOS alerts
final myAlerts = await sosService.getMySOS();

// Cancel SOS
await sosService.cancelSOS(1);

// Get nearest service providers
final providers = await sosService.getNearestProviders(
  latitude: -1.2921,
  longitude: 36.8219,
  serviceType: 'towing',
);
```

### 9. Upload Service

```dart
import 'package:pbak/services/upload_service.dart';

final uploadService = UploadService();

// Upload profile photo
final photoUrl = await uploadService.uploadProfilePhoto(
  filePath: '/path/to/photo.jpg',
  memberId: 1,
);

// Upload bike photo
final bikePhotoUrl = await uploadService.uploadBikePhoto(
  filePath: '/path/to/bike.jpg',
  bikeId: 1,
);

// Upload document
final docUrl = await uploadService.uploadDocument(
  filePath: '/path/to/id.pdf',
  documentType: 'national_id',
  memberId: 1,
);
```

## Integration with Providers

Services are designed to be used within Riverpod providers:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/services/bike_service.dart';

final bikeServiceProvider = Provider((ref) => BikeService());

final myBikesProvider = FutureProvider<List<BikeModel>>((ref) async {
  final bikeService = ref.read(bikeServiceProvider);
  return await bikeService.getMyBikes();
});

class BikeNotifier extends StateNotifier<AsyncValue<List<BikeModel>>> {
  final BikeService _bikeService;

  BikeNotifier(this._bikeService) : super(const AsyncValue.loading()) {
    loadBikes();
  }

  Future<void> loadBikes() async {
    state = const AsyncValue.loading();
    try {
      final bikes = await _bikeService.getMyBikes();
      state = AsyncValue.data(bikes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
```

## Error Handling

All services throw exceptions with descriptive messages. Handle them appropriately:

```dart
try {
  final bikes = await bikeService.getMyBikes();
  // Use bikes
} catch (e) {
  print('Error loading bikes: $e');
  // Show error to user
}
```

## Best Practices

1. **Use Services, Not Direct API Calls**: Always use service methods instead of calling CommsService directly from UI code.

2. **Service Layer is Stateless**: Services should not maintain state. Use Riverpod providers for state management.

3. **Consistent Error Handling**: Services throw exceptions for errors. Catch them in providers or UI code.

4. **Type Safety**: Services return strongly typed models, not raw JSON.

5. **Single Responsibility**: Each service handles one domain (bikes, events, etc.).

6. **Singleton Pattern**: All services use singleton pattern for consistency and performance.

7. **Async/Await**: All API calls are asynchronous and return Futures.

8. **Documentation**: Each service method is documented with its purpose and parameters.

## Testing

Services can be easily mocked for testing:

```dart
class MockBikeService implements BikeService {
  @override
  Future<List<BikeModel>> getMyBikes() async {
    return [
      BikeModel(/* mock data */),
    ];
  }
}
```

## Extending Services

To add new functionality:

1. Add the endpoint to `api_endpoints.dart`
2. Create or update the relevant service
3. Add the method following the existing pattern
4. Update this README with usage examples

## Service Dependencies

- `comms/comms_service.dart`: Core HTTP client
- `comms/api_endpoints.dart`: Endpoint constants
- `local_storage/local_storage_service.dart`: Local data persistence
- `models/*.dart`: Data models

## Migration from Mock API

All services have been migrated from `mock_api_service.dart` to use real API endpoints. The mock service is deprecated and should not be used in new code.
