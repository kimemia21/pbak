# PBAK Kenya - Motorcycle Community Super App

A comprehensive Flutter mobile application for PBAK Kenya (Motorcycle Association), featuring club management, bike registration, insurance tracking, events, service providers, trips, payments, and SOS assistance.

## 🏗️ Architecture

### Folder Structure
```
lib/
├── theme/                      # App theming
│   └── app_theme.dart         # Light/Dark themes with PBAK colors
├── models/                     # Data models
│   ├── user_model.dart
│   ├── club_model.dart
│   ├── bike_model.dart
│   ├── package_model.dart
│   ├── insurance_model.dart
│   ├── event_model.dart
│   ├── service_model.dart
│   ├── trip_model.dart
│   ├── payment_model.dart
│   ├── notification_model.dart
│   └── sos_model.dart
├── views/                      # UI screens
│   ├── auth/                  # Authentication
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── clubs/                 # Club management
│   │   ├── clubs_screen.dart
│   │   └── club_detail_screen.dart
│   ├── bikes/                 # Bike management
│   │   ├── bikes_screen.dart
│   │   └── add_bike_screen.dart
│   ├── packages/              # Membership packages
│   │   ├── packages_screen.dart
│   │   └── package_detail_screen.dart
│   ├── insurance/             # Insurance
│   │   ├── insurance_screen.dart
│   │   └── insurance_detail_screen.dart
│   ├── events/                # Events
│   │   ├── events_screen.dart
│   │   ├── event_detail_screen.dart
│   │   └── create_event_screen.dart
│   ├── services/              # Service providers
│   │   ├── services_screen.dart
│   │   └── service_detail_screen.dart
│   ├── trips/                 # Trip tracking
│   │   ├── trips_screen.dart
│   │   ├── trip_detail_screen.dart
│   │   └── start_trip_screen.dart
│   ├── payments/              # Payment history
│   │   ├── payments_screen.dart
│   │   └── payment_detail_screen.dart
│   ├── profile/               # User profile
│   │   ├── profile_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   ├── settings_screen.dart
│   │   └── notifications_screen.dart
│   └── home_screen.dart       # Dashboard
├── widgets/                    # Reusable widgets
│   ├── main_navigation.dart   # Bottom navigation with google_nav_bar
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── loading_widget.dart
│   ├── error_widget.dart
│   ├── empty_state_widget.dart
│   └── animated_card.dart
├── services/                   # Business logic
│   ├── mock_api/
│   │   ├── mock_api_service.dart
│   │   └── mock_data.dart
│   └── local_storage/
│       └── local_storage_service.dart
├── providers/                  # State management (Riverpod)
│   ├── theme_provider.dart
│   ├── auth_provider.dart
│   ├── club_provider.dart
│   ├── bike_provider.dart
│   ├── package_provider.dart
│   ├── insurance_provider.dart
│   ├── event_provider.dart
│   ├── service_provider.dart
│   ├── trip_provider.dart
│   ├── payment_provider.dart
│   └── notification_provider.dart
├── utils/                      # Utilities
│   ├── router.dart            # GoRouter navigation
│   ├── constants.dart         # App constants
│   └── validators.dart        # Form validators
└── main.dart                   # Entry point
```

## 🎨 Design System

### Color Palette (Inspired by pbak.co.ke)
- **Primary Black**: `#0A0A0A` - Main brand color
- **Secondary Black**: `#1A1A1A` - Dark surfaces
- **Deep Red**: `#D32F2F` - Accent color
- **Bright Red**: `#E53935` - Call-to-action
- **Gold Accent**: `#FFD700` - Premium features
- **Silver Grey**: `#C0C0C0` - Secondary elements
- **Light Silver**: `#E8E8E8` - Light backgrounds

### Typography
- **Font Family**: Poppins (via Google Fonts)
- All text styles accessed via `Theme.of(context).textTheme`

### Spacing
- XS: 4px
- S: 8px
- M: 16px
- L: 24px
- XL: 32px

### Border Radius
- S: 8px
- M: 12px
- L: 16px
- XL: 24px

## 🔧 State Management

### Riverpod Providers
- **themeModeProvider**: Theme switching (light/dark)
- **authProvider**: User authentication state
- **clubNotifierProvider**: Club data management
- **bikeNotifierProvider**: User's bikes
- **eventNotifierProvider**: Events management
- **tripNotifierProvider**: Active trip tracking
- **notificationNotifierProvider**: Notifications

## 🗺️ Navigation

### GoRouter Configuration
- **ShellRoute**: Main app with bottom navigation
- **Individual Routes**: Detail screens without bottom nav
- **Deep Linking Support**: All screens have unique routes

### Bottom Navigation Tabs
1. **Home**: Dashboard with quick actions
2. **Clubs**: Browse and manage clubs
3. **Trips**: Track and view trips
4. **Services**: Find service providers
5. **Profile**: User profile and settings

## 📱 Features

### 1️⃣ User Management
- Registration with comprehensive validation
- Login/Logout
- Profile management
- Document uploads (ID, License, Profile Photo)
- Verification status
- Role-based access

### 2️⃣ Clubs
- Browse all clubs
- View club details
- Member count and officials
- Join/Leave clubs
- Regional filtering

### 3️⃣ Bikes
- Add multiple bikes
- View bike details
- Link to packages
- Registration and engine number tracking

### 4️⃣ Packages
- Basic, Premium, and Gold memberships
- Detailed benefits listing
- Add-ons support
- Auto-renewal options
- Subscription management

### 5️⃣ Insurance
- Active insurance policies
- Expiry tracking and alerts
- Available insurance plans
- Policy details
- Multiple bike coverage

### 6️⃣ Events
- Upcoming and past events
- Event registration
- Capacity tracking
- Fee management
- Event creation (for officials)

### 7️⃣ Services
- Service provider directory
- Categories: Mechanic, Spare Parts, Towing, etc.
- Location-based search
- Ratings and reviews
- Contact information

### 8️⃣ Trips
- Start/End trip tracking
- Distance and duration
- Speed tracking
- Route history
- Map integration ready

### 9️⃣ Assistance (SOS)
- Emergency SOS button
- Location sharing
- Nearest provider finder
- Emergency contact alerts

### 🔟 Payments
- Payment history
- Transaction details
- Multiple payment methods (M-PESA, Bank Transfer, Card)
- Receipt access
- Status tracking

### 🔔 Notifications
- Event reminders
- Payment confirmations
- Insurance alerts
- Membership updates
- Read/Unread status

## 🎭 Animations

- **Fade-in animations** on card widgets
- **Scale animations** on interactive elements
- **Smooth transitions** between screens
- **Loading states** with progress indicators

## 🌓 Dark Mode Support

- Full light/dark theme support
- Toggle in settings
- Persistent theme preference
- Optimized colors for both modes

## 📝 Forms & Validation

### Validation Rules
- Required fields
- Email format
- Phone number (Kenyan format)
- ID number length
- Password strength
- Registration number format
- Engine number format
- Amount validation
- Date validation

### Form Features
- Real-time validation
- Error messages
- Dropdown selectors
- Date pickers
- Image uploads (ready for image_picker)
- Auto-capitalization

## 🗄️ Data Layer

### Mock API Service
- Simulates network delays (500ms)
- Returns dummy JSON data
- Ready for real API integration
- Type-safe models

### Local Storage
- User session management
- Token storage
- Theme preference
- Offline data caching

## 🔒 Authentication Flow
1. User lands on Login screen
2. Can navigate to Register
3. Upon successful auth, redirected to Home
4. Session persisted locally
5. Auto-login on app restart

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Dart 3.0+

### Installation
```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Build for release
flutter build apk --release
```

### Dependencies
- `flutter_riverpod`: State management
- `go_router`: Navigation
- `google_fonts`: Typography
- `google_nav_bar`: Bottom navigation
- `shared_preferences`: Local storage
- `intl`: Date formatting
- `uuid`: ID generation
- `image_picker`: Image uploads (configured)

## 📲 Platform Support
- ✅ Android
- ✅ iOS
- ✅ Web (partial - image_picker needs web config)

## 🔄 API Integration Guide

To integrate with a real backend:

1. **Update Mock API Service**:
   - Replace `MockApiService` with real HTTP calls
   - Use `http` or `dio` package
   - Update base URLs in constants

2. **Authentication**:
   - Implement JWT token handling
   - Add refresh token logic
   - Update `AuthNotifier` for real auth

3. **Error Handling**:
   - Add proper error models
   - Implement retry logic
   - Add offline support

## 🎯 Future Enhancements

- [ ] Google Maps integration for trips and services
- [ ] Push notifications (FCM)
- [ ] Image upload implementation
- [ ] Real-time chat between members
- [ ] Advanced trip analytics
- [ ] Social features (likes, comments)
- [ ] Multi-language support
- [ ] Biometric authentication
- [ ] Offline mode with sync

## 📄 License

This project is built for PBAK Kenya.

## 👥 Contributing

1. Follow the existing folder structure
2. Use provided widgets and theme
3. Maintain naming conventions
4. Add proper validation to forms
5. Test on both light and dark modes
