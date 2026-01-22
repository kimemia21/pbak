import 'package:flutter/material.dart';
import 'package:pbak/theme/app_theme.dart';

/// Displays the event route details in a visually distinct card.
///
/// This widget is used in both the Events bottom sheet and the full Event Details
/// screen so the user sees the same styling in both places.
class EventRouteDetailsCard extends StatelessWidget {
  final String routeDetails;

  const EventRouteDetailsCard({
    super.key,
    required this.routeDetails,
  });

  bool get _hasDetails {
    final v = routeDetails.trim();
    return v.isNotEmpty && v != '{}' && v.toLowerCase() != 'null';
  }

  void _showRouteDetailsDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.route_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Route Details'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            routeDetails.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasDetails) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final trimmedDetails = routeDetails.trim();

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.10),
            cs.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.route_rounded,
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Route Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            trimmedDetails,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
              color: cs.onSurfaceVariant,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (trimmedDetails.length > 100) ...[
            const SizedBox(height: AppTheme.paddingS),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showRouteDetailsDialog(context),
                icon: const Icon(Icons.read_more, size: 18),
                label: const Text('Read More'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
