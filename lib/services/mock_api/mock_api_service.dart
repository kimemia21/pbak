import 'package:pbak/models/club_model.dart';
import 'package:pbak/models/bike_model.dart';
import 'package:pbak/models/package_model.dart';
import 'package:pbak/models/insurance_model.dart';
import 'package:pbak/models/event_model.dart';
import 'package:pbak/models/service_model.dart';
import 'package:pbak/models/trip_model.dart';
import 'package:pbak/models/payment_model.dart';
import 'package:pbak/models/notification_model.dart';
import 'mock_data.dart';

class MockApiService {
  // Simulate network delay
  Future<void> _delay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    await _delay();
    // Mock login - always succeeds
    return {
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': 'current_user',
        'name': 'John Doe',
        'email': email,
        'phone': '+254712345678',
        'idNumber': '12345678',
        'dateOfBirth': '1990-01-15T00:00:00.000Z',
        'emergencyContact': '+254722334455',
        'licenseNumber': 'DL123456',
        'profileImage': null,
        'licenseImage': null,
        'idImage': null,
        'role': 'Member',
        'region': 'Nairobi',
        'isVerified': true,
        'createdAt': '2023-01-01T00:00:00.000Z',
      },
    };
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    await _delay();
    // Mock registration - always succeeds
    return {
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        ...userData,
        'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'isVerified': false,
        'createdAt': DateTime.now().toIso8601String(),
      },
    };
  }

  // Clubs
  Future<List<ClubModel>> getClubs() async {
    await _delay();
    return MockData.clubs.map((json) => ClubModel.fromJson(json)).toList();
  }

  Future<ClubModel> getClubById(String id) async {
    await _delay();
    final clubJson = MockData.clubs.firstWhere(
      (club) => club['id'] == id,
      orElse: () => MockData.clubs.first,
    );
    return ClubModel.fromJson(clubJson);
  }

  Future<ClubModel> createClub(Map<String, dynamic> clubData) async {
    await _delay();
    return ClubModel.fromJson({
      ...clubData,
      'id': 'club_${DateTime.now().millisecondsSinceEpoch}',
      'memberCount': 1,
    });
  }

  // Bikes
  Future<List<BikeModel>> getMyBikes(String userId) async {
    await _delay();
    return MockData.bikes.map((json) => BikeModel.fromJson(json)).toList();
  }

  Future<BikeModel> addBike(Map<String, dynamic> bikeData) async {
    await _delay();
    return BikeModel.fromJson({
      ...bikeData,
      'id': 'bike_${DateTime.now().millisecondsSinceEpoch}',
      'addedDate': DateTime.now().toIso8601String(),
    });
  }

  // Packages
  Future<List<PackageModel>> getPackages() async {
    await _delay();
    return MockData.packages.map((json) => PackageModel.fromJson(json)).toList();
  }

  Future<PackageModel> getPackageById(String id) async {
    await _delay();
    final packageJson = MockData.packages.firstWhere(
      (pkg) => pkg['id'] == id,
      orElse: () => MockData.packages.first,
    );
    return PackageModel.fromJson(packageJson);
  }

  // Insurance
  Future<List<InsuranceModel>> getMyInsurance(String userId) async {
    await _delay();
    return MockData.insurance
        .map((json) => InsuranceModel.fromJson(json))
        .toList();
  }

  Future<List<InsuranceModel>> getAvailableInsurance() async {
    await _delay();
    // Return mock available insurance options
    return [
      InsuranceModel.fromJson({
        'id': 'ins_option_1',
        'userId': '',
        'bikeId': '',
        'type': 'Third Party',
        'provider': 'Jubilee Insurance',
        'price': 8000.0,
        'startDate': DateTime.now().toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'status': 'Available',
        'policyNumber': 'QUOTE-001',
        'documentUrl': null,
      }),
      InsuranceModel.fromJson({
        'id': 'ins_option_2',
        'userId': '',
        'bikeId': '',
        'type': 'Comprehensive',
        'provider': 'AAR Insurance',
        'price': 15000.0,
        'startDate': DateTime.now().toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'status': 'Available',
        'policyNumber': 'QUOTE-002',
        'documentUrl': null,
      }),
    ];
  }

  // Events
  Future<List<EventModel>> getEvents() async {
    await _delay();
    return MockData.events.map((json) => EventModel.fromJson(json)).toList();
  }

  Future<EventModel> getEventById(String id) async {
    await _delay();
    final eventJson = MockData.events.firstWhere(
      (event) => event['id'] == id,
      orElse: () => MockData.events.first,
    );
    return EventModel.fromJson(eventJson);
  }

  Future<EventModel> createEvent(Map<String, dynamic> eventData) async {
    await _delay();
    return EventModel.fromJson({
      ...eventData,
      'id': 'event_${DateTime.now().millisecondsSinceEpoch}',
      'currentAttendees': 0,
      'attendeeIds': [],
    });
  }

  Future<bool> registerForEvent(String eventId, String userId) async {
    await _delay();
    return true;
  }

  // Services
  Future<List<ServiceModel>> getServices() async {
    await _delay();
    return MockData.services.map((json) => ServiceModel.fromJson(json)).toList();
  }

  Future<List<ServiceModel>> getNearbyServices(
      double latitude, double longitude) async {
    await _delay();
    return MockData.services.map((json) => ServiceModel.fromJson(json)).toList();
  }

  Future<ServiceModel> getServiceById(String id) async {
    await _delay();
    final serviceJson = MockData.services.firstWhere(
      (service) => service['id'] == id,
      orElse: () => MockData.services.first,
    );
    return ServiceModel.fromJson(serviceJson);
  }

  // Trips
  Future<List<TripModel>> getMyTrips(String userId) async {
    await _delay();
    return MockData.trips.map((json) => TripModel.fromJson(json)).toList();
  }

  Future<TripModel> startTrip(Map<String, dynamic> tripData) async {
    await _delay();
    return TripModel.fromJson({
      ...tripData,
      'id': 'trip_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'Active',
      'startTime': DateTime.now().toIso8601String(),
      'locations': [],
    });
  }

  Future<TripModel> endTrip(String tripId, Map<String, dynamic> tripData) async {
    await _delay();
    return TripModel.fromJson({
      ...tripData,
      'id': tripId,
      'status': 'Completed',
      'endTime': DateTime.now().toIso8601String(),
    });
  }

  // Payments
  Future<List<PaymentModel>> getMyPayments(String userId) async {
    await _delay();
    return MockData.payments.map((json) => PaymentModel.fromJson(json)).toList();
  }

  Future<PaymentModel> initiatePayment(Map<String, dynamic> paymentData) async {
    await _delay();
    return PaymentModel.fromJson({
      ...paymentData,
      'id': 'payment_${DateTime.now().millisecondsSinceEpoch}',
      'transactionId': 'TXN${DateTime.now().millisecondsSinceEpoch}',
      'status': 'Pending',
      'date': DateTime.now().toIso8601String(),
    });
  }

  // Notifications
  Future<List<NotificationModel>> getMyNotifications(String userId) async {
    await _delay();
    return MockData.notifications
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    await _delay();
    return true;
  }

  // SOS
  Future<Map<String, dynamic>> sendSOS(Map<String, dynamic> sosData) async {
    await _delay();
    return {
      'id': 'sos_${DateTime.now().millisecondsSinceEpoch}',
      ...sosData,
      'status': 'Pending',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<List<ServiceModel>> getNearestProviders(
      double latitude, double longitude, String serviceType) async {
    await _delay();
    // Return services filtered by type
    return MockData.services
        .where((service) => service['category'] == serviceType)
        .map((json) => ServiceModel.fromJson(json))
        .toList();
  }
}
