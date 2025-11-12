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

          final upcomingEvents = events.where((e) => e.isUpcoming).toList();
          final pastEvents = events.where((e) => e.isPast).toList();

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
  final dynamic event;
  final bool isPast;

  const _EventCard({
    required this.event,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedCard(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
      onTap: () => context.push('/events/${event.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingM),
                decoration: BoxDecoration(
                  color: isPast
                      ? Colors.grey.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  Icons.event_rounded,
                  color: isPast ? Colors.grey : theme.colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      event.type,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingM),
          Text(
            event.description,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.paddingM),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, yyyy • HH:mm').format(event.dateTime),
                style: theme.textTheme.bodySmall,
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
          const SizedBox(height: AppTheme.paddingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.currentAttendees}${event.maxAttendees != null ? '/${event.maxAttendees}' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (event.fee != null)
                Text(
                  'KES ${NumberFormat('#,###').format(event.fee)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          if (event.isFull && !isPast) ...[
            const SizedBox(height: AppTheme.paddingS),
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingS),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Event Full',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
