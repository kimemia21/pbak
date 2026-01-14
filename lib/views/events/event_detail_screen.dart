import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/event_model.dart';
import 'package:pbak/providers/event_provider.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/maps_launcher.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/secure_payment_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  final EventModel? event;

  /// If true, the screen is opened from KYC/registration with the intention to pay.
  /// We will show a lightweight "Pay for this event" next step (phone entry only).
  final bool kycPayMode;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.event,
    this.kycPayMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If we were navigated from the list, the full event object is already in memory.
    // Render immediately and do not fetch.
    if (event != null) {
      return _EventDetailScaffold(event: event!, kycPayMode: kycPayMode);
    }

    final id = int.tryParse(eventId);
    if (id == null) {
      return const Scaffold(
        body: Center(child: Text('Invalid event id')),
      );
    }

    final eventAsync = ref.watch(eventDetailProvider(id));

    return eventAsync.when(
      loading: () => const Scaffold(
        body: LoadingWidget(message: 'Loading event...'),
      ),
      error: (err, st) => Scaffold(
        appBar: AppBar(title: const Text('Event')),
        body: CustomErrorWidget(
          message: 'Failed to load event',
          onRetry: () => ref.refresh(eventDetailProvider(id)),
        ),
      ),
      data: (event) {
        if (event == null) {
          return const Scaffold(
            body: Center(child: Text('Event not found')),
          );
        }

        return _EventDetailScaffold(event: event, kycPayMode: kycPayMode);
      },
    );
  }
}

class _EventBannerBackground extends StatelessWidget {
  final EventModel event;

  const _EventBannerBackground({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        if ((event.imageUrl ?? '').isNotEmpty)
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
                size: 72,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        // Vignette + gradient overlay for readability
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.08),
                Colors.black.withOpacity(0.30),
                Colors.black.withOpacity(0.72),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, 0.25),
              radius: 1.2,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.45),
              ],
              stops: const [0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderSubline extends StatelessWidget {
  final EventModel event;

  const _HeaderSubline({required this.event});

  @override
  Widget build(BuildContext context) {
    final timeText = [
      (event.startTime ?? '').trim(),
      (event.endTime ?? '').trim(),
    ].where((e) => e.isNotEmpty).join(' - ');

    final feeText = event.fee == null ? 'Free' : 'KES ${event.fee!.toStringAsFixed(2)}';

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (timeText.isNotEmpty) _HeaderChip(icon: Icons.schedule_rounded, text: timeText),
        _HeaderChip(icon: Icons.payments_rounded, text: feeText),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
            text,
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

class _EventDetailScaffold extends ConsumerWidget {
  // ignore: avoid_unused_constructor_parameters
  final EventModel event;
  final bool kycPayMode;

  const _EventDetailScaffold({
    required this.event,
    required this.kycPayMode,
  });

  Future<void> _showPaymentDialog(BuildContext context, WidgetRef ref) async {
    final amount = event.fee ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('This event is free. No payment required.'),
        ),
      );
      return;
    }

    final reference = '${event.eventId ?? event.id}';
    
    // Show the unified payment dialog - handles phone input AND status
    final success = await SecurePaymentDialog.show(
      context,
      reference: reference,
      title: 'Event Registration',
      subtitle: event.title,
      amount: amount,
      description: 'PBAK Event: ${event.title}',
      mpesaOnly: true,
    );

    if (!context.mounted) return;

    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.successGreen,
          content: Text('Payment successful! You are registered for this event.'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('EEE, MMM d, yyyy');

    final hasCoords = event.latitude != null && event.longitude != null;

    return Scaffold(
      bottomNavigationBar: kycPayMode
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.paddingM,
                  8,
                  AppTheme.paddingM,
                  AppTheme.paddingM,
                ),
                child: _RegisterEventButton(
                  event: event,
                  onPressed: () async {
                    await _showPaymentDialog(context, ref);
                  },
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                // When collapsed, show a small title in the app bar.
                // When expanded, show a large title block on the banner.
                final topPadding = MediaQuery.of(context).padding.top;
                final min = kToolbarHeight + topPadding;
                final max = 280.0;
                final t = ((constraints.maxHeight - min) / (max - min)).clamp(0.0, 1.0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background banner
                    _EventBannerBackground(event: event),

                    // Expanded title block (fades out as we collapse)
                    Positioned(
                      left: AppTheme.paddingM,
                      right: AppTheme.paddingM,
                      bottom: 18,
                      child: Opacity(
                        opacity: t,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                                letterSpacing: -0.4,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 18),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _HeaderSubline(event: event),
                          ],
                        ),
                      ),
                    ),

                    // Collapsed title (fades in as we collapse)
                    Positioned(
                      left: AppTheme.paddingM,
                      right: AppTheme.paddingM,
                      bottom: 12,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 1.0 - t,
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick facts (smooth tiles, no dividers)
                  _SectionCard(
                    child: Wrap(
                      runSpacing: 12,
                      children: [
                        _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          title: 'Date',
                          value: dateFmt.format(event.dateTime.toLocal()),
                        ),
                        _InfoRow(
                          icon: Icons.schedule_rounded,
                          title: 'Time',
                          value: _formatTimeRange(event.startTime, event.endTime),
                        ),
                        _InfoRow(
                          icon: Icons.location_on_rounded,
                          title: 'Location',
                          value: event.location,
                        ),
                        if (hasCoords)
                          _CopyableInfoRow(
                            icon: Icons.my_location_rounded,
                            title: 'Coordinates',
                            value: '${event.latitude}, ${event.longitude}',
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingM),

                  // Actions - Responsive grid layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 400;
                      
                      return Column(
                        children: [
                          // Primary CTA - Register Button (Full width, prominent)
                          _RegisterEventButton(
                            event: event,
                            onPressed: () async {
                              await _showPaymentDialog(context, ref);
                            },
                          ),
                          
                          const SizedBox(height: AppTheme.paddingM),
                          
                          // Secondary actions
                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionButton(
                                    icon: Icons.directions_rounded,
                                    label: 'Directions',
                                    onPressed: hasCoords
                                        ? () => MapsLauncher.openDirections(
                                              latitude: event.latitude!,
                                              longitude: event.longitude!,
                                              label: event.location,
                                            )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.paddingS),
                                Expanded(
                                  child: _ActionButton(
                                    icon: Icons.map_rounded,
                                    label: 'Route Map',
                                    onPressed: (event.routeMapUrl ?? '').isNotEmpty
                                        ? () async {
                                            final uri = Uri.parse(event.routeMapUrl!);
                                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          }
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.paddingS),
                                Expanded(
                                  child: _ActionButton(
                                    icon: Icons.chat_rounded,
                                    label: 'WhatsApp',
                                    isWhatsApp: true,
                                    onPressed: () async {
                                      final link = (event.whatsappLink ?? '').trim();
                                      if (link.isEmpty || link.toLowerCase() == 'null') {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('WhatsApp group not yet set up for this event.'),
                                          ),
                                        );
                                        return;
                                      }

                                      final uri = Uri.tryParse(link);
                                      if (uri == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('Invalid WhatsApp link for this event.'),
                                          ),
                                        );
                                        return;
                                      }

                                      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      if (!ok && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('Unable to open WhatsApp. Please try again.'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ActionButton(
                                        icon: Icons.directions_rounded,
                                        label: 'Directions',
                                        onPressed: hasCoords
                                            ? () => MapsLauncher.openDirections(
                                                  latitude: event.latitude!,
                                                  longitude: event.longitude!,
                                                  label: event.location,
                                                )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.paddingS),
                                    Expanded(
                                      child: _ActionButton(
                                        icon: Icons.map_rounded,
                                        label: 'Route',
                                        onPressed: (event.routeMapUrl ?? '').isNotEmpty
                                            ? () async {
                                                final uri = Uri.parse(event.routeMapUrl!);
                                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                              }
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.paddingS),
                                SizedBox(
                                  width: double.infinity,
                                  child: _ActionButton(
                                    icon: Icons.chat_rounded,
                                    label: 'Join WhatsApp',
                                    isWhatsApp: true,
                                    onPressed: () async {
                                      final link = (event.whatsappLink ?? '').trim();
                                      if (link.isEmpty || link.toLowerCase() == 'null') {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('WhatsApp group not yet set up for this event.'),
                                          ),
                                        );
                                        return;
                                      }

                                      final uri = Uri.tryParse(link);
                                      if (uri == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('Invalid WhatsApp link for this event.'),
                                          ),
                                        );
                                        return;
                                      }

                                      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      if (!ok && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('Unable to open WhatsApp. Please try again.'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppTheme.paddingM),

                  // Payments (compact)
                  _SectionCard(
                    title: 'Payments',
                    subtitle: 'Registration fee and deadline',
                    child: Wrap(
                      runSpacing: 12,
                      children: [
                        _InfoRow(
                          icon: Icons.payments_rounded,
                          title: 'Registration Fee',
                          value: event.fee == null ? 'Free' : 'KES ${event.fee!.toStringAsFixed(2)}',
                        ),
                        _InfoRow(
                          icon: Icons.timer_rounded,
                          title: 'Registration Deadline',
                          value: event.registrationDeadline == null
                              ? 'Not specified'
                              : DateFormat('EEE, MMM d, yyyy • HH:mm')
                                  .format(event.registrationDeadline!.toLocal()),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingM),

                  // Participants
                  _SectionCard(
                    title: 'Participants',
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Joined',
                            value: event.currentAttendees.toString(),
                          ),
                        ),
                        const SizedBox(width: AppTheme.paddingS),
                        Expanded(
                          child: _StatTile(
                            label: 'Capacity',
                            value: event.maxAttendees?.toString() ?? '∞',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingM),

                  // About
                  _SectionCard(
                    title: 'Event Description',
                    child: Text(
                      event.description.isEmpty ? 'No description provided.' : event.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeRange(String? start, String? end) {
    final s = (start ?? '').trim();
    final e = (end ?? '').trim();
    if (s.isEmpty && e.isEmpty) return 'Not specified';
    if (s.isEmpty) return 'Until $e';
    if (e.isEmpty) return 'From $s';
    return '$s - $e';
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        // No border - smooth unified look
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.paddingS),
          ],
          child,
        ],
      ),
    );
  }
}

class _CopyableInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _CopyableInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Future<void> copy() async {
      await Clipboard.setData(ClipboardData(text: value));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $value'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return InkWell(
      onTap: copy,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 16),
          ),
          const SizedBox(width: AppTheme.paddingS + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.copy_rounded,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 16),
        ),
        const SizedBox(width: AppTheme.paddingS + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingS + 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
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

/// A prominent, fun "Register for Event" button with gradient and animation
class _RegisterEventButton extends StatefulWidget {
  final EventModel event;
  final VoidCallback onPressed;

  const _RegisterEventButton({
    required this.event,
    required this.onPressed,
  });

  @override
  State<_RegisterEventButton> createState() => _RegisterEventButtonState();
}

class _RegisterEventButtonState extends State<_RegisterEventButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFree = widget.event.fee == null || widget.event.fee == 0;
    final isFull = widget.event.isFull;
    final feeText = isFree ? 'FREE' : 'KES ${widget.event.fee!.toStringAsFixed(0)}';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: isFull ? 1.0 : _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              gradient: isFull
                  ? LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade500],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.deepRed,
                        AppTheme.brightRed,
                      ],
                    ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isFull ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingM,
                    vertical: AppTheme.paddingS + 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with background
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isFull
                              ? Icons.event_busy_rounded
                              : Icons.celebration_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppTheme.paddingS + 4),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isFull ? 'Event Full' : 'Register for Event',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              isFull
                                  ? 'Registration closed'
                                  : isFree
                                      ? 'Join this ride • Free!'
                                      : 'Join this ride • $feeText',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow icon
                      if (!isFull)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A stylish action button for secondary actions - smooth, borderless design
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isWhatsApp;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
    this.isWhatsApp = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null;
    final buttonColor = color ?? theme.colorScheme.primary;

    // WhatsApp specific styling
    if (isWhatsApp) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          gradient: isDisabled
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF25D366), // WhatsApp green
                    Color(0xFF128C7E), // WhatsApp teal
                  ],
                ),
          color: isDisabled ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingM,
                vertical: AppTheme.paddingS + 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // WhatsApp-style icon
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDisabled ? 0.3 : 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.chat_rounded,
                      size: 16,
                      color: isDisabled ? theme.colorScheme.outline : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isDisabled ? theme.colorScheme.outline : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Regular action button - smooth, no harsh borders
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        color: isDisabled
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.4)
            : buttonColor.withOpacity(0.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          splashColor: buttonColor.withOpacity(0.15),
          highlightColor: buttonColor.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingM,
              vertical: AppTheme.paddingS + 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isDisabled
                      ? theme.colorScheme.outline.withOpacity(0.5)
                      : buttonColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isDisabled
                          ? theme.colorScheme.outline.withOpacity(0.5)
                          : buttonColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
