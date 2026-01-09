import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/event_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:pbak/widgets/animated_card.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/event_model.dart';
import 'package:pbak/utils/event_selectors.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eventsState = ref.watch(eventNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/events/create'),
          ),
        ],
      ),
      body: eventsState.when(
        data: (events) {
          if (events.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.event_rounded,
              title: 'No Events',
              message: 'No events available at the moment',
              action: CustomButton(
                text: 'Create Event',
                icon: Icons.add_rounded,
                onPressed: () => context.push('/events/create'),
              ),
            );
          }

          final upcomingEvents = EventSelectors.upcomingSorted(events);
          final pastEvents = EventSelectors.pastSorted(events);

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(eventNotifierProvider.notifier).loadEvents();
            },
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              children: [
                if (upcomingEvents.isNotEmpty) ...[
                  Text(
                    'Upcoming Events',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  ...upcomingEvents.map((event) => _EventCard(event: event)),
                ],
                if (pastEvents.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.paddingL),
                  Text(
                    'Past Events',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  ...pastEvents.map((event) => _EventCard(event: event, isPast: true)),
                ],
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading events...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load events',
          onRetry: () => ref.read(eventNotifierProvider.notifier).loadEvents(),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final bool isPast;

  const _EventCard({
    required this.event,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dateFmt = DateFormat('EEE, MMM d');
    final timeFmt = DateFormat('HH:mm');
    final localDate = event.dateTime.toLocal();

    final hasBanner = (event.imageUrl ?? '').isNotEmpty;
    final feeText = event.fee == null ? 'Free' : 'KES ${event.fee!.toStringAsFixed(2)}';
    final regionText = (event.regionName ?? '').isNotEmpty
        ? event.regionName!
        : (event.hostClubName.isNotEmpty ? event.hostClubName : '');

    return AnimatedCard(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
      onTap: () => context.push('/events/${event.id}', extra: event.toJson()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            SizedBox(
              height: 170,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasBanner)
                    Image.network(
                      event.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    )
                  else
                    Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.sports_motorsports_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.15),
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),

                  // Top badges
                  Positioned(
                    top: AppTheme.paddingS,
                    left: AppTheme.paddingS,
                    right: AppTheme.paddingS,
                    child: Row(
                      children: [
                        _Badge(
                          icon: Icons.category_rounded,
                          label: event.type.toUpperCase(),
                        ),
                        const SizedBox(width: 8),
                        if (event.isMembersOnly)
                          const _Badge(
                            icon: Icons.lock_rounded,
                            label: 'Members',
                          ),
                        const Spacer(),
                        if ((event.status ?? '').isNotEmpty)
                          _Badge(
                            icon: Icons.publish_rounded,
                            label: (event.status ?? '').toUpperCase(),
                          ),
                      ],
                    ),
                  ),

                  // Bottom title
                  Positioned(
                    left: AppTheme.paddingM,
                    right: AppTheme.paddingM,
                    bottom: AppTheme.paddingM,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        if (regionText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.flag_rounded, size: 16, color: Colors.white70),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  regionText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key info row
                  Wrap(
                    spacing: 14,
                    runSpacing: 10,
                    children: [
                      _Meta(
                        icon: Icons.calendar_month_rounded,
                        text: dateFmt.format(localDate),
                      ),
                      _Meta(
                        icon: Icons.schedule_rounded,
                        text: timeFmt.format(localDate),
                      ),
                      _Meta(
                        icon: Icons.payments_rounded,
                        text: feeText,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Optional: description preview (short)
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Icon(
                        Icons.people_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${event.currentAttendees}${event.maxAttendees != null ? '/${event.maxAttendees}' : ''} riders',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),

                  if (event.isFull && !isPast) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_rounded, size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            'Event Full',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
