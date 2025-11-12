import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/views/auth/login_screen.dart';
import 'package:pbak/views/auth/register_screen.dart';
import 'package:pbak/views/home_screen.dart';
import 'package:pbak/views/clubs/clubs_screen.dart';
import 'package:pbak/views/clubs/club_detail_screen.dart';
import 'package:pbak/views/bikes/bikes_screen.dart';
import 'package:pbak/views/bikes/add_bike_screen.dart';
import 'package:pbak/views/packages/packages_screen.dart';
import 'package:pbak/views/packages/package_detail_screen.dart';
import 'package:pbak/views/insurance/insurance_screen.dart';
import 'package:pbak/views/insurance/insurance_detail_screen.dart';
import 'package:pbak/views/events/events_screen.dart';
import 'package:pbak/views/events/event_detail_screen.dart';
import 'package:pbak/views/events/create_event_screen.dart';
import 'package:pbak/views/services/services_screen.dart';
import 'package:pbak/views/services/service_detail_screen.dart';
import 'package:pbak/views/trips/trips_screen.dart';
import 'package:pbak/views/trips/trip_detail_screen.dart';
import 'package:pbak/views/trips/start_trip_screen.dart';
import 'package:pbak/views/payments/payments_screen.dart';
import 'package:pbak/views/payments/payment_detail_screen.dart';
import 'package:pbak/views/profile/profile_screen.dart';
import 'package:pbak/views/profile/edit_profile_screen.dart';
import 'package:pbak/views/profile/settings_screen.dart';
import 'package:pbak/views/profile/notifications_screen.dart';
import 'package:pbak/views/crash_detection_test_screen.dart';
import 'package:pbak/widgets/main_navigation.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    // Auth routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    
    // Main app with bottom navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainNavigation(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/clubs',
          builder: (context, state) => const ClubsScreen(),
        ),
        GoRoute(
          path: '/trips',
          builder: (context, state) => const TripsScreen(),
        ),
        GoRoute(
          path: '/services',
          builder: (context, state) => const ServicesScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    
    // Detail routes (without bottom navigation)
    GoRoute(
      path: '/club/:id',
      builder: (context, state) => ClubDetailScreen(
        clubId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/bikes',
      builder: (context, state) => const BikesScreen(),
    ),
    GoRoute(
      path: '/bikes/add',
      builder: (context, state) => const AddBikeScreen(),
    ),
    GoRoute(
      path: '/packages',
      builder: (context, state) => const PackagesScreen(),
    ),
    GoRoute(
      path: '/package/:id',
      builder: (context, state) => PackageDetailScreen(
        packageId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/insurance',
      builder: (context, state) => const InsuranceScreen(),
    ),
    GoRoute(
      path: '/insurance/:id',
      builder: (context, state) => InsuranceDetailScreen(
        insuranceId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/events',
      builder: (context, state) => const EventsScreen(),
    ),
    GoRoute(
      path: '/event/:id',
      builder: (context, state) => EventDetailScreen(
        eventId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/events/create',
      builder: (context, state) => const CreateEventScreen(),
    ),
    GoRoute(
      path: '/service/:id',
      builder: (context, state) => ServiceDetailScreen(
        serviceId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/trip/:id',
      builder: (context, state) => TripDetailScreen(
        tripId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/trips/start',
      builder: (context, state) => const StartTripScreen(),
    ),
    GoRoute(
      path: '/payments',
      builder: (context, state) => const PaymentsScreen(),
    ),
    GoRoute(
      path: '/payment/:id',
      builder: (context, state) => PaymentDetailScreen(
        paymentId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/crash-test',
      builder: (context, state) => const CrashDetectionTestScreen(),
    ),
  ],
);
