import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/club_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:pbak/widgets/animated_card.dart';

class ClubsScreen extends ConsumerWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clubsAsync = ref.watch(clubsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nyumba Kumi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_rounded),
            onPressed: () => context.push('/chat'),
            tooltip: 'Group Chats',
          ),
        ],
      ),
      body: clubsAsync.when(
        data: (clubs) {
          if (clubs.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.groups_rounded,
              title: 'No Nyumba Kumi Yet',
              message: 'Be the first to create a Nyumba Kumi group!',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(clubsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              itemCount: clubs.length,
              itemBuilder: (context, index) {
                final club = clubs[index];
                return AnimatedCard(
                  margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                  onTap: () => context.push('/clubs/${club.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with logo and name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: club.logoUrl != null && club.logoUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      club.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) => Icon(
                                        Icons.groups_rounded,
                                        size: 32,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.groups_rounded,
                                    size: 32,
                                    color: theme.colorScheme.primary,
                                  ),
                          ),
                          const SizedBox(width: AppTheme.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  club.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        club.id,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Est. ${club.foundedDate.year}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.paddingM),
                      
                      // Description
                      Text(
                        club.description,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: AppTheme.paddingM),
                      
                      // Location info
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                club.region,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.paddingM),
                      
                      // Contact info and member count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Contact info
                          if (club.contactPhone != null || club.contactEmail != null)
                            Expanded(
                              child: Row(
                                children: [
                                  if (club.contactPhone != null) ...[
                                    Icon(
                                      Icons.phone_rounded,
                                      size: 14,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        club.contactPhone!,
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  if (club.contactPhone != null && club.contactEmail != null)
                                    const SizedBox(width: 8),
                                  if (club.contactEmail != null) ...[
                                    Icon(
                                      Icons.email_rounded,
                                      size: 14,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          
                          // Member count
                          Row(
                            children: [
                              Icon(
                                Icons.people_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${club.memberCount}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
        loading: () => const LoadingWidget(message: 'Loading clubs...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load clubs',
          onRetry: () => ref.invalidate(clubsProvider),
        ),
      ),
    );
  }
}
