import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/trip_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:pbak/widgets/animated_card.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tripsAsync = ref.watch(myTripsProvider);
    final activeTripState = ref.watch(tripNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips Available on (App)'),
      ),
      floatingActionButton: activeTripState.value == null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/trips/start'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Trip'),
            )
          : null,
      body: Column(
        children: [
          // Active Trip Card
          activeTripState.when(
            data: (activeTrip) {
              if (activeTrip != null) {
                return Container(
                  margin: const EdgeInsets.all(AppTheme.paddingM),
                  padding: const EdgeInsets.all(AppTheme.paddingM),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.navigation_rounded,
                            color: theme.colorScheme.onPrimary,
                          ),
                          const SizedBox(width: AppTheme.paddingS),
                          Text(
                            'Trip in Progress',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.paddingM),
                      Text(
                        activeTrip.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingS),
                      Text(
                        'Started: ${DateFormat('HH:mm').format(activeTrip.startTime)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingM),
                      CustomButton(
                        text: 'End Trip',
                        onPressed: () {
                          // End trip logic
                        },
                        backgroundColor: theme.colorScheme.onPrimary,
                        textColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),

          // Trips List
          Expanded(
            child: tripsAsync.when(
              data: (trips) {
                if (trips.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.route_rounded,
                    title: 'No Trips Yet',
                    message: 'Start tracking your motorcycle journeys!',
                    action: CustomButton(
                      text: 'Start First Trip',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => context.push('/trips/start'),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(myTripsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.paddingM),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return AnimatedCard(
                        margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                        onTap: () => context.push('/trips/${trip.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.paddingM),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                  ),
                                  child: Icon(
                                    Icons.route_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.paddingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trip.name,
                                        style: theme.textTheme.titleLarge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(trip.startTime),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.paddingM),
                            const Divider(),
                            const SizedBox(height: AppTheme.paddingS),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _TripStat(
                                  icon: Icons.straighten_rounded,
                                  label: 'Distance',
                                  value: '${trip.distance.toStringAsFixed(1)} km',
                                ),
                                _TripStat(
                                  icon: Icons.access_time_rounded,
                                  label: 'Duration',
                                  value: trip.durationText,
                                ),
                                if (trip.averageSpeed != null)
                                  _TripStat(
                                    icon: Icons.speed_rounded,
                                    label: 'Avg Speed',
                                    value: '${trip.averageSpeed!.toStringAsFixed(0)} km/h',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingWidget(message: 'Loading trips...'),
              error: (error, stack) => CustomErrorWidget(
                message: 'Failed to load trips',
                onRetry: () => ref.invalidate(myTripsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TripStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}
