import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/event_model.dart';
import 'package:pbak/theme/app_theme.dart';

/// A modern, visually appealing event card for KYC / registration flows.
///
/// Features:
/// - Event banner image with gradient overlay
/// - Host club badge
/// - Attendee count indicator
/// - Registration deadline warning
/// - Improved selection state with animations
class KycEventCard extends StatelessWidget {
  final EventModel event;
  final bool selected;
  final VoidCallback? onTap;

  const KycEventCard({
    super.key,
    required this.event,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final dateFmt = DateFormat('EEE, MMM d');
    final timeFmt = DateFormat('HH:mm');
    final localDate = event.dateTime.toLocal();

    final feeText = event.fee == null || event.fee == 0
        ? 'Free'
        : 'KES ${event.fee!.toStringAsFixed(0)}';

    final hasImage = (event.imageUrl ?? '').isNotEmpty;
    final hostClub = (event.hostClubName ?? '').trim();
    
    // Check if deadline is approaching (within 3 days)
    final deadline = event.registrationDeadline;
    final isDeadlineApproaching = deadline != null && 
        deadline.difference(DateTime.now()).inDays <= 3 &&
        deadline.isAfter(DateTime.now());
    
    // Check if event is upcoming (within 7 days)
    final isUpcomingSoon = event.dateTime.difference(DateTime.now()).inDays <= 7 &&
        event.dateTime.isAfter(DateTime.now());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant.withOpacity(0.5),
          width: selected ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected 
                ? cs.primary.withOpacity(0.15)
                : Colors.black.withOpacity(0.06),
            blurRadius: selected ? 20 : 16,
            offset: const Offset(0, 8),
            spreadRadius: selected ? 2 : 0,
          ),
        ],
      ),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(19),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header with Gradient Overlay
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image or Gradient
                    if (hasImage)
                      Image.network(
                        event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultHeader(cs),
                      )
                    else
                      _buildDefaultHeader(cs),
                    
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    
                    // Top Badges Row
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Row(
                        children: [
                          // Fee Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: event.fee == null || event.fee == 0
                                  ? Colors.green
                                  : cs.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              feeText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Deadline Warning Badge
                          if (isDeadlineApproaching)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Closing soon',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Selection Indicator
                          if (selected) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Event Title on Image
                    Positioned(
                      bottom: 10,
                      left: 12,
                      right: 12,
                      child: Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Host Club Badge
                      if (hostClub.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 12,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  hostClub,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Date & Time Row
                      _buildInfoRow(
                        context,
                        icon: Icons.calendar_month_rounded,
                        text: '${dateFmt.format(localDate)} • ${timeFmt.format(localDate)}',
                        isHighlighted: isUpcomingSoon,
                      ),
                      const SizedBox(height: 6),
                      
                      // Location Row
                      _buildInfoRow(
                        context,
                        icon: Icons.location_on_rounded,
                        text: event.location.isEmpty ? 'Location TBD' : event.location,
                        maxLines: 1,
                      ),
                      
                      const Spacer(),
                      
                      // Action Row
                      Row(
                        children: [
                          // Attendees indicator
                          if (event.maxAttendees != null) ...[
                            Icon(
                              Icons.people_outline_rounded,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.currentAttendees}/${event.maxAttendees}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Spacer(),
                          // CTA Button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selected 
                                  ? cs.primary 
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selected ? 'Selected' : 'View',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: selected ? cs.onPrimary : cs.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  selected 
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: selected ? cs.onPrimary : cs.onSurface,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultHeader(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.8),
            cs.primary.withOpacity(0.4),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.two_wheeler_rounded,
          size: 40,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
    int maxLines = 1,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isHighlighted ? cs.primary : cs.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isHighlighted ? cs.primary : cs.onSurfaceVariant,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
