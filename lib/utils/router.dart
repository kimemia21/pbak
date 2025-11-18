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
import 'package:pbak/services/comms/comms_test_screen.dart';
import 'package:pbak/widgets/main_navigation.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    // Auth routes (without bottom navigation)
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    
    // Main app with persistent bottom navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainNavigation(child: child),
      routes: [
        // Home
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'bikes',
              builder: (context, state) => const BikesScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const AddBikeScreen(),
                ),
              ],
            ),
            GoRoute(
              path: 'packages',
              builder: (context, state) => const PackagesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => PackageDetailScreen(
                    packageId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'insurance',
              builder: (context, state) => const InsuranceScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => InsuranceDetailScreen(
                    insuranceId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'events',
              builder: (context, state) => const EventsScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const CreateEventScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => EventDetailScreen(
                    eventId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'payments',
              builder: (context, state) => const PaymentsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => PaymentDetailScreen(
                    paymentId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'crash-test',
              builder: (context, state) => const CrashDetectionTestScreen(),
            ),
            GoRoute(
              path: 'comms-test',
              builder: (context, state) => const CommsTestScreen(),
            ),
          ],
        ),
        
        // Clubs
        GoRoute(
          path: '/clubs',
          builder: (context, state) => const ClubsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => ClubDetailScreen(
                clubId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        
        // Trips
        GoRoute(
          path: '/trips',
          builder: (context, state) => const TripsScreen(),
          routes: [
            GoRoute(
              path: 'start',
              builder: (context, state) => const StartTripScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => TripDetailScreen(
                tripId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        
        // Services
        GoRoute(
          path: '/services',
          builder: (context, state) => const ServicesScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => ServiceDetailScreen(
                serviceId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        
        // Profile
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => const EditProfileScreen(),
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
