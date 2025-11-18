import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/club_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class ClubDetailScreen extends ConsumerWidget {
  final String clubId;

  const ClubDetailScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clubAsync = ref.watch(clubDetailProvider(int.parse(clubId)));

    return Scaffold(
      body: clubAsync.when(
        data: (club) {
          if (club == null) {
            return const Center(
              child: Text('Club not found'),
            );
          }
          
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(club.name),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.groups_rounded,
                        size: 80,
                        color: theme.colorScheme.onPrimary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Club Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.paddingM),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppTheme.paddingS),
                                  Text(
                                    club.region,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.paddingM),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppTheme.paddingS),
                                  Text(
                                    '${club.memberCount} members',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.paddingM),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppTheme.paddingS),
                                  Text(
                                    'Founded ${DateFormat('MMM yyyy').format(club.foundedDate)}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              if (club.meetingLocation != null) ...[
                                const SizedBox(height: AppTheme.paddingM),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.place_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: AppTheme.paddingS),
                                    Expanded(
                                      child: Text(
                                        club.meetingLocation!,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingM),

                      // Description
                      Text(
                        'About',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppTheme.paddingS),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.paddingM),
                          child: Text(
                            club.description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingM),

                      // Officials
                      if (club.officials.isNotEmpty) ...[
                        Text(
                          'Club Officials',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppTheme.paddingS),
                        Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppTheme.paddingM),
                            itemCount: club.officials.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final official = club.officials[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary,
                                  child: Text(
                                    official.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  official.name,
                                  style: theme.textTheme.titleMedium,
                                ),
                                subtitle: Text(
                                  official.position,
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.paddingM),
                      ],

                      // Contact
                      if (club.contactPhone != null || club.contactEmail != null) ...[
                        Text(
                          'Contact',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppTheme.paddingS),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.paddingM),
                            child: Column(
                              children: [
                                if (club.contactPhone != null)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      Icons.phone_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                    title: Text(club.contactPhone!),
                                  ),
                                if (club.contactEmail != null)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      Icons.email_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                    title: Text(club.contactEmail!),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.paddingXL),

                      // Join Button
                      CustomButton(
                        text: 'Join Club',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Membership request sent!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: LoadingWidget(message: 'Loading club details...'),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Club Details')),
          body: CustomErrorWidget(
            message: 'Failed to load club details',
            onRetry: () => ref.invalidate(clubDetailProvider(int.parse( clubId))),
          ),
        ),
      ),
    );
  }
}
