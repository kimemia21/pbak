import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbak/models/trip_model.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/trip_provider.dart';
import 'package:intl/intl.dart';

/// Drawer to show recent trips history
class TripsHistoryDrawer extends ConsumerWidget {
  const TripsHistoryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider);

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlack,
                    AppTheme.secondaryBlack,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.paddingS),
                        decoration: BoxDecoration(
                          color: AppTheme.deepRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: const Icon(
                          Icons.history,
                          color: AppTheme.deepRed,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.paddingM),
                      Expanded(
                        child: Text(
                          'Trip History',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  tripsAsync.when(
                    data: (trips) => Text(
                      '${trips.length} ${trips.length == 1 ? 'trip' : 'trips'} completed',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.silverGrey,
                      ),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),

            // Trips list
            Expanded(
              child: tripsAsync.when(
                data: (trips) {
                  if (trips.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.paddingM),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return _buildTripCard(context, trip, ref);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.deepRed),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.brightRed,
                          size: 48,
                        ),
                        const SizedBox(height: AppTheme.paddingM),
                        Text(
                          'Failed to load trips',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: AppTheme.paddingS),
                        Text(
                          error.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.mediumGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingXL),
              decoration: BoxDecoration(
                color: AppTheme.lightSilver.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route,
                size: 64,
                color: AppTheme.mediumGrey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppTheme.paddingL),
            Text(
              'No Trips Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlack,
              ),
            ),
            const SizedBox(height: AppTheme.paddingS),
            Text(
              'Start your first trip to see\nyour riding history here',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.mediumGrey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, TripModel trip, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
      decoration: BoxDecoration(
        color: AppTheme.lightSilver.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.lightSilver.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              '/trip-detail',
              arguments: trip.id,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and time
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppTheme.mediumGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(trip.startTime),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlack,
                      ),
                    ),
                    const SizedBox(width: AppTheme.paddingS),
                    Text(
                      '•',
                      style: GoogleFonts.poppins(
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                    const SizedBox(width: AppTheme.paddingS),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppTheme.mediumGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeFormat.format(trip.startTime),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.paddingM),

                // Route info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.deepRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppTheme.paddingS),
                              Expanded(
                                child: Text(
                                  trip.route,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlack,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.paddingM),

                // Stats row
                Row(
                  children: [
                    _buildStatChip(
                      Icons.route,
                      '${trip.distance.toStringAsFixed(1)} km',
                      AppTheme.deepRed,
                    ),
                    const SizedBox(width: AppTheme.paddingS),
                    _buildStatChip(
                      Icons.speed,
                      '${(trip.averageSpeed ?? 0).toStringAsFixed(0)} km/h',
                      AppTheme.goldAccent,
                    ),
                    const SizedBox(width: AppTheme.paddingS),
                    _buildStatChip(
                      Icons.access_time,
                      _formatDuration(trip.durationMinutes),
                      AppTheme.primaryBlack,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}
