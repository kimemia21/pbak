class AppConstants {
  // App Info
  static const String appName = 'PBAK Kenya';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String apiVersion = 'v1';
  static const int apiTimeout = 30; // seconds
  
  // Regions
  static const List<String> regions = [
    'Nairobi',
    'Mombasa',
    'Kisumu',
    'Nakuru',
    'Eldoret',
    'Thika',
    'Nyeri',
    'Meru',
    'Kakamega',
    'Machakos',
  ];
  
  // User Roles
  static const List<String> userRoles = [
    'Member',
    'Club Official',
    'Regional Coordinator',
    'National Official',
  ];
  
  // Club Positions
  static const List<String> clubPositions = [
    'Chairman',
    'Vice Chairman',
    'Secretary',
    'Treasurer',
    'Organizing Secretary',
    'Member',
  ];
  
  // Motorcycle Types
  static const List<String> motorcycleTypes = [
    'Sport',
    'Cruiser',
    'Touring',
    'Adventure',
    'Street',
    'Off-road',
    'Dual-sport',
    'Scooter',
  ];
  
  // Service Categories
  static const List<String> serviceCategories = [
    'Mechanic',
    'Spare Parts',
    'Fuel Station',
    'Towing',
    'Tire Repair',
    'Wash & Detailing',
    'Insurance',
    'Registration Services',
  ];
  
  // Insurance Types
  static const List<String> insuranceTypes = [
    'Third Party',
    'Comprehensive',
    'Third Party Fire & Theft',
  ];
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'M-PESA',
    'Bank Transfer',
    'Card Payment',
    'Cash',
  ];
  
  // Event Types
  static const List<String> eventTypes = [
    'Ride Out',
    'Meeting',
    'Training',
    'Social Event',
    'Competition',
    'Charity Event',
  ];
  
  // SOS Types
  static const List<String> sosTypes = [
    'Breakdown',
    'Accident',
    'Medical Emergency',
    'Security Threat',
    'Lost/Stolen Bike',
    'Fuel Emergency',
    'Other',
  ];
  
  // Notification Types
  static const List<String> notificationTypes = [
    'Event',
    'Payment',
    'Membership',
    'Package',
    'Insurance',
    'General',
  ];
}
