import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/providers/notification_provider.dart';
import 'package:pbak/providers/event_provider.dart';
import 'package:pbak/utils/event_selectors.dart';
import 'package:pbak/providers/weather_provider.dart';
import 'package:weather/weather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/animated_card.dart';
import 'package:intl/intl.dart';

enum _HomeBackAction { logout, exit, cancel }

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final notificationsState = ref.watch(notificationNotifierProvider);

    // On web, the browser back button should behave normally.
    // On mobile/desktop we keep the existing "confirm exit / logout" behavior.
    return PopScope(
      canPop: kIsWeb,
      onPopInvoked: (didPop) async {
        if (kIsWeb) return;
        if (didPop) return;

        final action = await showDialog<_HomeBackAction>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Leave app?'),
              content: const Text('What would you like to do?'),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_HomeBackAction.cancel),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_HomeBackAction.exit),
                  child: const Text('Exit App'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_HomeBackAction.logout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepRed,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            );
          },
        );

        if (!context.mounted) return;

        switch (action) {
          case _HomeBackAction.logout:
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              context.go('/login');
            }
            break;
          case _HomeBackAction.exit:
            // Browser tabs/windows shouldn't be closed programmatically.
            if (!kIsWeb) {
              SystemNavigator.pop();
            }
            break;
          case _HomeBackAction.cancel:
          case null:
            break;
        }
      },

      child: Scaffold(
        appBar: AppBar(
          title: const Text('PBAK'),
          actions: [
            Stack(
              children: [
                // IconButton(
                //   icon: const Icon(Icons.notifications_rounded),
                //   onPressed: () => context.push('/profile/notifications'),
                //  ),
                // notificationsState.when(
                //   data: (notifications) {
                //     final unreadCount = notifications
                //         .where((n) => !n.isRead)
                //         .length;
                //     if (unreadCount > 0) {
                //       return Positioned(
                //         right: 8,
                //         top: 8,
                //         child: Container(
                //           padding: const EdgeInsets.all(4),
                //           decoration: BoxDecoration(
                //             color: AppTheme.deepRed,
                //             shape: BoxShape.circle,
                //           ),
                //           constraints: const BoxConstraints(
                //             minWidth: 16,
                //             minHeight: 16,
                //           ),
                //           child: Text(
                //             unreadCount > 9 ? '9+' : '$unreadCount',
                //             style: theme.textTheme.bodySmall?.copyWith(
                //               color: Colors.white,
                //               fontSize: 10,
                //             ),
                //             textAlign: TextAlign.center,
                //           ),
                //         ),
                //       );
                //     }
                //     return const SizedBox();
                //   },
                //   loading: () => const SizedBox(),
                //   error: (_, __) => const SizedBox(),
                // ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => context.push('/profile/settings'),
            ),
          ],
        ),
        body: authState.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Not logged in'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(eventsProvider);
                ref.invalidate(notificationNotifierProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    AnimatedCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  user.name,
                                  style: theme.textTheme.headlineSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,

                                      size: 16,
                                      color: AppTheme.goldAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Approved",
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingL),
                    

                    // Weather

                    _WeatherCard(authState: authState),
                      const SizedBox(height: AppTheme.paddingL),

                    // Quick Actions
                    Text('Quick Actions', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppTheme.paddingM),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppTheme.paddingM,
                      crossAxisSpacing: AppTheme.paddingM,
                      children: [
                        _QuickActionCard(
                          icon: Icons.two_wheeler_rounded,
                          label: 'My Bikes',
                          onTap: () => context.push('/bikes'),
                        ),
                        _QuickActionCard(
                          icon: Icons.card_membership_rounded,
                          label: 'Packages',
                          onTap: () => context.push('/packages'),
                        ),
                        _QuickActionCard(
                          icon: Icons.security_rounded,
                          label: 'Insurance',
                          onTap: () => context.push('/insurance'),
                        ),
                        _QuickActionCard(
                          icon: Icons.event_rounded,
                          label: 'Events',
                          onTap: () => context.push('/events'),
                        ),
                        _QuickActionCard(
                          icon: Icons.payment_rounded,
                          label: 'Payments',
                          onTap: () => context.push('/payments'),
                        ),
                        _QuickActionCard(
                          icon: Icons.sos_rounded,
                          label: 'SOS',
                          onTap: () => context.push('/sos'),
                          isEmergency: true,
                        ),
                      ],
                    ),
                  
                    const SizedBox(height: AppTheme.paddingL),

                    // Other Services Section
                    // Hide Sport Mode tile on desktop/wide layouts.
                    Builder(
                      builder: (context) {
                        final width = MediaQuery.sizeOf(context).width;
                        final isDesktopLayout = width >= 900 || (kIsWeb && width >= 800);

                        if (isDesktopLayout) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Other Services',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppTheme.paddingM),
                            AnimatedCard(
                              onTap: () => context.push('/sport-mode'),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.deepRed,
                                      AppTheme.deepRed.withValues(alpha: 0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusM,
                                  ),
                                ),
                                padding: const EdgeInsets.all(AppTheme.paddingL),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppTheme.paddingM,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusM,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.sports_motorsports_rounded,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.paddingM),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Sport Mode',
                                                style: theme.textTheme.titleLarge
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppTheme.paddingS,
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: AppTheme.paddingS,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.goldAccent,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    AppTheme.radiusS,
                                                  ),
                                                ),
                                                child: Text(
                                                  'NEW',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primaryBlack,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Track your performance and lean angles',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.paddingL),
                          ],
                        );
                      },
                    ),

                    // Upcoming Events
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Events',
                          style: theme.textTheme.headlineSmall,
                        ),
                        TextButton(
                          onPressed: () => context.push('/events'),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.paddingM),

                    eventsAsync.when(
                      data: (events) {
                        final upcomingEvents = EventSelectors.upcomingSorted(
                          events,
                          limit: 3,
                        );

                        if (upcomingEvents.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.paddingL),
                              child: Center(
                                child: Text(
                                  'No upcoming events',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: upcomingEvents.map((event) {
                            return AnimatedCard(
                              margin: const EdgeInsets.only(
                                bottom: AppTheme.paddingM,
                              ),
                              onTap: () => context.push('/events/${event.id}', extra: event.toJson()),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(
                                          AppTheme.paddingS,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusS,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.event_rounded,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.paddingM),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event.title,
                                              style: theme.textTheme.titleLarge,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              DateFormat(
                                                'MMM dd, yyyy • HH:mm',
                                              ).format(event.dateTime),
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.paddingS),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 16,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          event.location,
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const LoadingWidget(),
                      error: (error, stack) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.paddingL),
                          child: Text('Error loading events'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const LoadingWidget(),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'This will send an emergency alert to nearby service providers and club members. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to SOS screen or trigger SOS
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SOS Alert Sent!'),
                  backgroundColor: AppTheme.deepRed,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepRed),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }
}

class _WeatherCard extends ConsumerWidget {
  final AsyncValue authState;

  const _WeatherCard({required this.authState});

  String? _guessCityFromRoadName(String? roadName) {
    if (roadName == null || roadName.trim().isEmpty) return null;
    // common format: "Karen, Nairobi, Kenya" => Nairobi
    final parts = roadName
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length >= 2) return parts[1];
    return parts.isNotEmpty ? parts.first : null;
  }

  IconData _iconForCondition(String? condition) {
    final c = (condition ?? '').toLowerCase();
    if (c.contains('rain') || c.contains('drizzle')) return Icons.grain_rounded;
    if (c.contains('storm') || c.contains('thunder'))
      return Icons.thunderstorm_rounded;
    if (c.contains('cloud')) return Icons.cloud_rounded;
    if (c.contains('mist') || c.contains('fog') || c.contains('haze'))
      return Icons.foggy;
    return Icons.wb_sunny_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final user = authState.value;
    String? city;
    if (user != null) {
      city = user.city ?? _guessCityFromRoadName(user.roadName);
    }

    final weatherAsync = (city != null && city.trim().isNotEmpty)
        ? ref.watch(weatherByCityProvider(city))
        : ref.watch(currentWeatherProvider);

    Widget content(Weather weather) {
      final temp = weather.temperature?.celsius;
      final min = weather.tempMin?.celsius;
      final max = weather.tempMax?.celsius;
      final humidity = weather.humidity;
      final wind = weather.windSpeed;
      final condition = weather.weatherDescription ?? weather.weatherMain;

      final ridingCondition = ref
          .read(weatherServiceProvider)
          .getRidingCondition(weather);

      String fmtNum(num? v, {String suffix = ''}) {
        if (v == null) return '—';
        return '${v.toStringAsFixed(0)}$suffix';
      }

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingM),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(
                    _iconForCondition(condition),
                    size: 34,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppTheme.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city ?? (weather.areaName ?? 'Your area'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (condition ?? 'Weather').toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ridingCondition,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  temp == null ? '—' : '${temp.toStringAsFixed(0)}°C',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingM),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingM,
                vertical: AppTheme.paddingS,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Row(
                children: [
                  _WeatherMiniStat(
                    label: 'Min',
                    value: fmtNum(min, suffix: '°C'),
                  ),
                  const SizedBox(width: 12),
                  _WeatherMiniStat(
                    label: 'Max',
                    value: fmtNum(max, suffix: '°C'),
                  ),
                  const SizedBox(width: 12),
                  _WeatherMiniStat(
                    label: 'Wind',
                    value: fmtNum(wind, suffix: ' m/s'),
                  ),
                  const SizedBox(width: 12),
                  _WeatherMiniStat(
                    label: 'Humidity',
                    value: humidity == null ? '—' : '$humidity%',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedCard(
      child: weatherAsync.when(
        data: (weather) {
          if (weather == null) {
            return Padding(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Weather unavailable right now.')),
                ],
              ),
            );
          }
          return content(weather);
        },
        loading: () => Padding(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          child: Row(
            children: [
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('Loading weather…', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(child: Text('Weather unavailable right now.')),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _WeatherMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isEmergency;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.paddingM),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: isEmergency ? AppTheme.deepRed : theme.colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.paddingS),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
