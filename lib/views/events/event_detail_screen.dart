import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/event_model.dart';
import 'package:pbak/providers/event_provider.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/maps_launcher.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/providers/payment_provider.dart';
import 'package:pbak/utils/validators.dart';
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

  Future<String?> _promptForStkPhone(BuildContext context, {String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');

    final phone = await showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        return AlertDialog(
          title: const Text('M-Pesa STK Push'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the phone number that will receive the payment prompt.',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+254712345678',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                final err = Validators.validatePhone(value);
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: AppTheme.brightRed),
                  );
                  return;
                }
                Navigator.pop(context, value);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return phone;
  }

  Future<void> _initiateEventStkPush(BuildContext context, WidgetRef ref, {required String phone}) async {
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

    final reference = 'event:${event.eventId ?? event.id}';
    final ok = await ref.read(paymentNotifierProvider.notifier).initiatePayment({
      'amount': amount,
      'method': 'mpesa',
      'purpose': 'event',
      'reference': reference,
      'phone': phone,
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppTheme.successGreen : AppTheme.brightRed,
        content: Text(
          ok
              ? 'STK push initiated. Check your phone to complete payment.'
              : 'Failed to initiate payment. Please try again.',
        ),
      ),
    );
  }

  // Backwards-compat: keep the old method name used by kycPayMode.
  Future<void> _showKycPayPhonePrompt(BuildContext context, WidgetRef ref) async {
    final phone = await _promptForStkPhone(context);
    if (phone == null || phone.trim().isEmpty) return;
    await _initiateEventStkPush(context, ref, phone: phone.trim());
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
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final phone = await _promptForStkPhone(context);
                      if (phone == null || phone.trim().isEmpty) return;
                      await _initiateEventStkPush(context, ref, phone: phone.trim());
                    },
                    icon: const Icon(Icons.payments_rounded),
                    label: const Text('Pay for this event'),
                  ),
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

                  // Actions
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: hasCoords
                                  ? () => MapsLauncher.openDirections(
                                        latitude: event.latitude!,
                                        longitude: event.longitude!,
                                        label: event.location,
                                      )
                                  : null,
                              icon: const Icon(Icons.directions_rounded),
                              label: const Text('Directions'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.paddingS),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (event.routeMapUrl ?? '').isNotEmpty
                                  ? () async {
                                      final uri = Uri.parse(event.routeMapUrl!);
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  : null,
                              icon: const Icon(Icons.map_rounded),
                              label: const Text('Route'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.paddingS),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
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
                              icon: const Icon(Icons.chat_rounded),
                              label: const Text('WhatsApp'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.paddingS),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                final phone = await _promptForStkPhone(context);
                                if (phone == null || phone.trim().isEmpty) return;
                                await _initiateEventStkPush(context, ref, phone: phone.trim());
                              },
                              icon: const Icon(Icons.payments_rounded),
                              label: const Text('Pay'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: theme.dividerColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.paddingM),
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
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppTheme.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: copy,
                      icon: Icon(Icons.copy_rounded, color: theme.colorScheme.onSurfaceVariant),
                      tooltip: 'Copy',
                    ),
                  ],
                ),
              ],
            ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: AppTheme.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.all(AppTheme.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
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
