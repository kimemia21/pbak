/// API Endpoints constants
/// Centralized location for all API endpoints
/// Based on actual API structure from server.http
class ApiEndpoints {
  // Base paths
  static const String auth = '/auth';
  static const String members = '/members';
  static const String bikes = '/bikes';
  static const String packages = '/packages';
  static const String clubs = '/clubs';
  static const String events = '/events';
  static const String regions = '/regions';
  static const String sos = '/sos';
  static const String upload = '/upload';

  // Health check
  static const String healthCheck = '/';

  // Launch endpoint - check app configuration (discount availability, etc.)
  static const String launch = '/launch';

  // Auth endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  static const String verifyEmail = '$auth/verify-email';

  // Member endpoints
  static const String allMembers = members; // GET /members
  static const String memberStats = '$members/stats'; // GET /members/stats
  static String memberById(int id) => '$members/$id'; // GET /members/{id}
  static String updateMemberParams(int id) => '$members/$id/params'; // PUT /members/{id}/params
  static String memberPackages(int id) => '$members/$id/packages'; // GET /members/{id}/packages

  // Registration / membership check
  // GET /searchmember?id_number=...
  static const String searchMember = '/searchmember';

  // Region endpoints (Counties, Towns, Estates)
  static const String allRegions = regions; // GET /regions (counties)
  static String townsInRegion(int countyId) => '$regions/$countyId'; // GET /regions/{countyId}
  static String estatesInTown(int countyId, int townId) => '$regions/$countyId/$townId'; // GET /regions/{countyId}/{townId}

  // Club endpoints
  static const String allClubs = clubs; // GET /clubs
  static String clubById(int id) => '$clubs/$id';
  static const String createClub = clubs;
  static String updateClub(int id) => '$clubs/$id';
  static String deleteClub(int id) => '$clubs/$id';
  static String joinClub(int id) => '$clubs/$id/join';
  static String leaveClub(int id) => '$clubs/$id/leave';
  static String clubMembers(int id) => '$clubs/$id/members';

  // Event endpoints
  static const String allEvents = events; // GET /events
  static String eventsByMemberId(int memberId) => '$events?member_id=$memberId'; 
  static String eventsWithDiscount(int memberId) => '$events?member_id=$memberId&discounted=true'; 

  /// Fetch events with member-specific pricing based on ID number
  /// [discounted] - if true (1), returns 50% discounted pricing
  static String eventsByIdNumber(String idNumber, {bool discounted = false}) => 
      '$events?id_number=$idNumber${discounted ? '&discounted=1' : ''}'; 
      // GET /events?id_number={id_number}&discounted=1
  static String currentEvents({int current = 1}) => '$events?current=$current';
  static String eventById(int id) => '$events/$id';
  static const String createEvent = events;
  static String updateEvent(int id) => '$events/$id';
  static String deleteEvent(int id) => '$events/$id';
  static String registerForEvent(int id) => '$events/$id/register';
  static String unregisterFromEvent(int id) => '$events/$id/unregister';
  static String eventAttendees(int id) => '$events/$id/attendees';

  // Package endpoints
  static const String allPackages = packages; // GET /packages
  static String packageById(int id) => '$packages/$id';
  static const String subscribePackage = '$packages/subscribe';

  // Bike endpoints
  static const String allBikes = bikes; // GET /bikes
  static const String bikeMakes = '$bikes/makes'; // GET /bikes/makes
  static String bikeModels(int makeId) => '$bikes/models/$makeId'; // GET /bikes/models/{makeId}
  static const String addBike = bikes; // POST /bikes
  static String bikeById(int id) => '$bikes/$id'; // GET /bikes/{id}
  static String updateBike(int id) => '$bikes/$id'; // PUT /bikes/{id}
  static String deleteBike(int id) => '$bikes/$id'; // DELETE /bikes/{id}

  // SOS endpoints
  static const String sendSOS = sos; // POST /sos
  static String sosById(int id) => '$sos/$id';
  static const String mySOS = '$sos/my-sos';
  static String cancelSOS(int id) => '$sos/$id/cancel';
  static const String nearestProviders = '$sos/nearest-providers';

  // Upload endpoint
  static const String uploadFile = upload; // POST /upload

  // M-Pesa Payment endpoints
  static const String pay = '/pay';
  static const String initiateMpesaPayment = pay; // POST /pay
  static String mpesaPaymentStatus(String payId) => '$pay/$payId/status'; // GET /pay/{payId}/status

  // Trip endpoints
  static const String trips = '/trips';
  static const String allTrips = trips; // GET /trips
  static const String startTrip = '$trips/start'; // POST /trips/start
  static const String tripEvent = '$trips/event'; // POST /trips/event (GPS telemetry)
  static const String endTrip = '$trips/end'; // POST /trips/end
  static String tripById(int id) => '$trips/$id'; // GET /trips/{id}

  // Chat/Messaging endpoints (Nyumba Kumi)
  static const String chatrooms = '/chatrooms';
  static String memberChatRooms(int memberId) => '$members/$memberId/chatrooms'; // GET /members/{member_id}/chatrooms
  static String chatRoomMessages(int chatRoomId, int memberId) => 
      '$chatrooms/$chatRoomId/members/$memberId/messages'; // GET /chatrooms/{chat_room_id}/members/{member_id}/messages
  static const String sendMessage = '$chatrooms/messages'; // POST /chatrooms/messages

  // Service Providers endpoints
  static const String providers = '/providers';

  // Services directory endpoints
  static const String services = '/services';
  static String serviceByIdV2(String id) => '$services/$id';
  static const String nearbyServicesV2 = '$services/nearby';

  // Notifications endpoints
  static const String myNotificationsV2 = '/notifications/my-notifications';
  static String markNotificationAsRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsAsRead = '/notifications/read-all';
  static String deleteNotificationById(String id) => '/notifications/$id';
  static String providersByType(int typeId) => '$providers/$typeId'; // GET /providers/{type_id}
  static const String insuranceProviders = '/providers/7'; // Insurance provider type ID = 7

  // Legacy/deprecated endpoints - keeping for backward compatibility
  @deprecated
  static const String myBikes = bikes;
  @deprecated
  static const String profile = members;
  @deprecated
  static const String updateProfile = members;
  @deprecated
  static const String changePassword = '$members/change-password';
  @deprecated
  static const String uploadProfileImage = '$members/profile/image';
  @deprecated
  static const String myPackages = '$packages/my-packages';
  @deprecated
  static const String myInsurance = '/insurance/my-insurance';
  @deprecated
  static const String availableInsurance = '/insurance/available';
  @deprecated
  static const String purchaseInsurance = '/insurance';
  @deprecated
  static String insuranceById(String id) => '/insurance/$id';
  @deprecated
  static const String allServices = '/services';
  @deprecated
  static String serviceById(String id) => '/services/$id';
  @deprecated
  static const String nearbyServices = '/services/nearby';
  @deprecated
  static const String searchServices = '/services/search';
  @deprecated
  static const String myTripsLegacy = '/trips/my-trips';
  @deprecated
  static const String startTripLegacy = '/trips/start-legacy';
  @deprecated
  static String endTripLegacy(String id) => '/trips/$id/end';
  @deprecated
  static String tripByIdLegacy(String id) => '/trips/$id';
  @deprecated
  static String updateTripLocation(String id) => '/trips/$id/location';
  @deprecated
  static const String activeTrip = '/trips/active';
  // Payment history endpoint
  static const String payments = '/payments';
  static const String allPayments = payments; // GET /payments
  static String paymentByOrderId(int orderId) => '$payments/$orderId'; // GET /payments/{order_id}

  @deprecated
  static const String myPayments = '/payments/my-payments';
  @deprecated
  static const String initiatePaymentLegacy = '/payments/initiate';
  @deprecated
  static String paymentByIdLegacy(String id) => '/payments/$id';
  @deprecated
  static String verifyPayment(String id) => '/payments/$id/verify';
  @deprecated
  static const String myNotifications = '/notifications/my-notifications';
  @deprecated
  static String markAsRead(String id) => '/notifications/$id/read';
  @deprecated
  static const String markAllAsRead = '/notifications/read-all';
  @deprecated
  static String deleteNotification(String id) => '/notifications/$id';
  // Removed - no endpoint exists for occupations
  // Use static list in registration_service.dart instead
  @deprecated
  static const String tiers = '/params/tiers';
  @deprecated
  static const String counties = '/params/counties';
}
