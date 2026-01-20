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

  @override
  Widget build(BuildContext context) {
    if (!_hasDetails) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
            routeDetails.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
