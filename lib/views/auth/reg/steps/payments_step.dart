import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/event_model.dart';
import 'package:pbak/models/package_model.dart';
import 'package:pbak/providers/event_provider.dart';
import 'package:pbak/providers/package_provider.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/widgets/kyc_event_card.dart';
import 'package:pbak/widgets/secure_payment_dialog.dart';
import 'package:pbak/utils/event_pricing.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';

/// Payment step widget for KYC registration flow.
///
/// Handles:
/// - Event selection and payment
/// - Package selection with card-based UI
/// - M-Pesa payment integration via SecurePaymentDialog
class PaymentsStep extends ConsumerStatefulWidget {
  // Legacy flag (old UI had a switch). We keep it for backward compatibility
  // with RegisterScreen state but PaymentsStep no longer uses it.
  final bool paymentAlreadyPaidMember;

  final PackageModel? selectedPackage;
  final List<EventModel> selectedEvents;
  final TextEditingController paymentPhoneController;
  // Legacy; ID is captured earlier in registration (Documents step).
  // Keep for compatibility with RegisterScreen but PaymentsStep no longer renders it.
  final TextEditingController memberIdController;

  /// Membership/package status computed earlier.
  final bool? memberHasActivePackage;
  final bool checkingMemberStatus;
  final Future<void> Function() onRefreshMemberStatus;

  // Legacy callback (old UI had a switch). Not used anymore.
  final Function(bool) onAlreadyPaidChanged;

  final Function(PackageModel?) onPackageSelected;
  final Function(List<EventModel>) onEventsChanged;
  final List<int> selectedEventProductIds;
  final void Function(List<int> ids) onEventProductIdsChanged;

  /// Notify parent about membership link status.
  /// null = not checked/unknown, true = linked, false = not linked
  final void Function(bool? linked) onMemberLinkStatusChanged;

  final VoidCallback? onSaveProgress;
  final Widget Function({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  })
  buildTextField;

  const PaymentsStep({
    super.key,
    required this.paymentAlreadyPaidMember,
    required this.selectedPackage,
    required this.selectedEvents,
    required this.paymentPhoneController,
    required this.memberIdController,
    required this.memberHasActivePackage,
    required this.checkingMemberStatus,
    required this.onRefreshMemberStatus,
    required this.onAlreadyPaidChanged,
    required this.onPackageSelected,
    required this.onEventsChanged,
    required this.selectedEventProductIds,
    required this.onEventProductIdsChanged,
    required this.onMemberLinkStatusChanged,
    this.onSaveProgress,
    required this.buildTextField,
  });

  @override
  ConsumerState<PaymentsStep> createState() => _PaymentsStepState();
}

class _PaymentsStepState extends ConsumerState<PaymentsStep> {
  // Membership check now happens earlier in the flow (Documents step).
  // PaymentsStep just consumes the result.

  LocalStorageService? _localStorage;
  List<int> _paidEventIds = [];
  Map<int, List<int>> _paidProductIds = {};

  @override
  void initState() {
    super.initState();
    _loadPaidData();
  }

  Future<void> _loadPaidData() async {
    _localStorage = await LocalStorageService.getInstance();
    if (mounted) {
      setState(() {
        _paidEventIds = _localStorage?.getPaidEventIds() ?? [];
        _paidProductIds = _localStorage?.getPaidProductIdsMap() ?? {};
      });
    }
  }

  bool _isEventPaid(int? eventId) {
    if (eventId == null) return false;
    return _paidEventIds.contains(eventId);
  }

  bool _isProductPaid(int? eventId, int? productId) {
    if (eventId == null || productId == null) return false;
    return (_paidProductIds[eventId] ?? []).contains(productId);
  }

  Future<void> _savePaidEvent(int eventId, List<int> productIds) async {
    await _localStorage?.addPaidEventId(eventId);
    if (productIds.isNotEmpty) {
      await _localStorage?.addPaidProductIds(eventId, productIds);
    }
    // Reload
    await _loadPaidData();
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.brightRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final packagesAsync = ref.watch(packagesProvider);
    final currentEventsAsync = ref.watch(currentEventsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Payments',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick a package or pay for an event via M-Pesa.',
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.35,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Membership status is checked in background before this step.
          // _buildMembershipStatusBanner(context),
          const SizedBox(height: 20),

          // Events Section
          _buildSectionTitle(
            context,
            'Pay for an event',
            subtitle:
                'Select an event to pay for. If you have an active package, only paid events will matter.',
          ),
          const SizedBox(height: 12),
          _buildEventsSection(currentEventsAsync),

          const SizedBox(height: 28),

          // Packages section (only when NOT linked)
          if (widget.memberHasActivePackage == false) ...[
            _buildPackageSelection(context, packagesAsync),
          ] else if (widget.memberHasActivePackage == true) ...[
            _buildEmptyState(
              context,
              icon: Icons.verified_rounded,
              message:
                  'Active package detected. You only need to pay for paid events (if any).',
            ),
          ] else ...[
            _buildEmptyState(
              context,
              icon: Icons.info_outline_rounded,
              message:
                  'Checking membership status... If this takes too long, tap Refresh.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String text, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEventsSection(AsyncValue<List<EventModel>> eventsAsync) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.event_busy_rounded,
            message: 'No current events available right now.',
          );
        }

        return SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 6),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final e = events[index];
              return KycEventCard(
                event: e,
                selected: widget.selectedEvents.any(
                  (x) => x.eventId == e.eventId,
                ),
                onTap: () => _onEventTapped(e),
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          _buildErrorState(context, message: 'Failed to load events: $e'),
    );
  }

  Future<void> _onEventTapped(EventModel event) async {
    final cs = Theme.of(context).colorScheme;

    // Only one event per pay.
    if (widget.selectedEvents.isNotEmpty &&
        widget.selectedEvents.first.eventId != event.eventId) {
      widget.onEventProductIdsChanged(const []);
    }

    final shouldPay = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surface,
      builder: (context) => _buildEventPaymentSheet(event),
    );

    if (shouldPay != true || !mounted) return;

    // sheet handles payment and selection.
  }

  void _setSelectedEvent(EventModel event) {
    widget.onEventsChanged([event]);
    widget.onSaveProgress?.call();
  }

  void _clearSelectedEvent() {
    widget.onEventsChanged(const []);
    widget.onEventProductIdsChanged(const []);
    widget.onSaveProgress?.call();
  }

  Widget _buildEventPaymentSheet(EventModel event) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMember = widget.memberHasActivePackage == true;

    final alreadySelected =
        widget.selectedEvents.isNotEmpty &&
        widget.selectedEvents.first.eventId == event.eventId;

    final eventFee = EventPricing.eventRegistrationFee(
      event,
      isMember: isMember,
    );

    final dateText = DateFormat(
      'EEE, MMM d, yyyy • HH:mm',
    ).format(event.dateTime.toLocal());
    final startTime = event.startTime ?? '';
    final endTime = event.endTime ?? '';

    // Keep selected product IDs in a mutable set that persists across rebuilds
    final selectedProductIds = <int>{...widget.selectedEventProductIds};

    // Check if event is already paid
    final isEventAlreadyPaid = _isEventPaid(event.eventId);
    final paidProductsForEvent = event.eventId != null
        ? (_paidProductIds[event.eventId!] ?? <int>[])
        : <int>[];

    return SafeArea(
      child: StatefulBuilder(
        builder: (context, setModalState) {
          // Event registration is MANDATORY (always on) - but skip fee if already paid
          final bool eventFeePaid = isEventAlreadyPaid;

          double total = eventFeePaid
              ? 0
              : eventFee; // Only charge if not already paid

          for (final p in event.products) {
            if (p.productId != null &&
                selectedProductIds.contains(p.productId) &&
                !paidProductsForEvent.contains(p.productId)) {
              // Only add to total if product is not already paid
              total += EventPricing.productPrice(event, p, isMember: isMember);
            }
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Event banner
                if (event.imageUrl != null &&
                    event.imageUrl!.trim().isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      event.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.primary.withOpacity(0.7), cs.primary],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.event,
                            size: 64,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                Text(
                  event.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),

                Divider(color: cs.outlineVariant),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    children: [
                      // Event Details Section
                      _buildDetailSection(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: 'Event Details',
                        children: [
                          if (event.description.trim().isNotEmpty)
                            _buildDetailRow(
                              context,
                              'Description',
                              event.description,
                            ),
                          _buildDetailRow(context, 'Date', dateText),
                          if (startTime.isNotEmpty || endTime.isNotEmpty)
                            _buildDetailRow(
                              context,
                              'Time',
                              '${startTime.isNotEmpty ? startTime : 'TBA'} - ${endTime.isNotEmpty ? endTime : 'TBA'}',
                            ),
                          _buildDetailRow(
                            context,
                            'Type',
                            event.type.toUpperCase(),
                          ),
                          if (event.location.trim().isNotEmpty)
                            _buildDetailRow(
                              context,
                              'Location',
                              event.location,
                            ),
                          if (event.hostClubName?.trim().isNotEmpty == true)
                            _buildDetailRow(
                              context,
                              'Host Club',
                              event.hostClubName!,
                            ),
                          if (event.maxAttendees != null)
                            _buildDetailRow(
                              context,
                              'Capacity',
                              '${event.currentAttendees} / ${event.maxAttendees} participants',
                            ),
                          if (event.registrationDeadline != null)
                            _buildDetailRow(
                              context,
                              'Registration Deadline',
                              DateFormat(
                                'MMM d, yyyy',
                              ).format(event.registrationDeadline!),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Event Registration (Mandatory) - Show paid status if already paid
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: eventFeePaid
                              ? AppTheme.successGreen.withOpacity(0.1)
                              : cs.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: eventFeePaid
                                ? AppTheme.successGreen.withOpacity(0.5)
                                : cs.primary.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: eventFeePaid
                                    ? AppTheme.successGreen
                                    : cs.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                eventFeePaid
                                    ? Icons.verified_rounded
                                    : Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Event Registration',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    eventFeePaid
                                        ? 'Already paid'
                                        : (isMember
                                              ? 'Member pricing'
                                              : 'Standard pricing'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: eventFeePaid
                                          ? AppTheme.successGreen
                                          : cs.onSurfaceVariant,
                                      fontWeight: eventFeePaid
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: eventFeePaid
                                          ? AppTheme.successGreen.withOpacity(
                                              0.15,
                                            )
                                          : cs.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      eventFeePaid ? 'PAID ✓' : 'MANDATORY',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: eventFeePaid
                                                ? AppTheme.successGreen
                                                : cs.primary,
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (eventFeePaid)
                                  Text(
                                    'KES ${eventFee.toStringAsFixed(2)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  eventFeePaid
                                      ? 'KES 0.00'
                                      : 'KES ${eventFee.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: eventFeePaid
                                        ? AppTheme.successGreen
                                        : cs.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (event.products.isNotEmpty) ...[
                        _buildDetailSection(
                          context,
                          icon: Icons.shopping_bag_outlined,
                          title: 'Optional Products',
                          children: [],
                        ),
                        const SizedBox(height: 10),
                        ...event.products.map((p) {
                          final id = p.productId;
                          final selected =
                              id != null && selectedProductIds.contains(id);
                          final isProductAlreadyPaid =
                              id != null && paidProductsForEvent.contains(id);
                          final price = EventPricing.productPrice(
                            event,
                            p,
                            isMember: isMember,
                          );
                          final priceLabel = isProductAlreadyPaid
                              ? 'PAID ✓'
                              : 'KES ${price.toStringAsFixed(2)}';
                          final threshold = p.basePriceFirst ?? 0;
                          final showThreshold =
                              !isMember &&
                              threshold > 0 &&
                              !isProductAlreadyPaid;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isProductAlreadyPaid
                                  ? AppTheme.successGreen.withOpacity(0.08)
                                  : (selected
                                        ? AppTheme.successGreen.withOpacity(
                                            0.12,
                                          )
                                        : cs.surface),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isProductAlreadyPaid
                                    ? AppTheme.successGreen.withOpacity(0.4)
                                    : (selected
                                          ? AppTheme.successGreen
                                          : cs.outlineVariant.withOpacity(0.6)),
                                width: selected || isProductAlreadyPaid
                                    ? 2.5
                                    : 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: (id == null || isProductAlreadyPaid)
                                  ? null
                                  : () {
                                      print(
                                        'Product tapped: ${p.name}, ID: $id, currently selected: $selected',
                                      );
                                      setModalState(() {
                                        if (selected) {
                                          selectedProductIds.remove(id);
                                          print(
                                            'Removed $id, now has: $selectedProductIds',
                                          );
                                        } else {
                                          selectedProductIds.add(id);
                                          print(
                                            'Added $id, now has: $selectedProductIds',
                                          );
                                        }
                                      });
                                    },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: selected || isProductAlreadyPaid,
                                        activeColor: AppTheme.successGreen,
                                        checkColor: Colors.white,
                                        onChanged:
                                            (id == null || isProductAlreadyPaid)
                                            ? null
                                            : (v) {
                                                setState(() {});
                                                print(
                                                  'Checkbox changed: ${p.name}, value: $v',
                                                );
                                                setModalState(() {
                                                  if (v == true) {
                                                    selectedProductIds.add(id);
                                                    print(
                                                      'Checkbox added $id, now has: $selectedProductIds',
                                                    );
                                                  } else {
                                                    selectedProductIds.remove(
                                                      id,
                                                    );
                                                    print(
                                                      'Checkbox removed $id, now has: $selectedProductIds',
                                                    );
                                                  }
                                                });
                                              },
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    (selected ||
                                                        isProductAlreadyPaid)
                                                    ? AppTheme.successGreen
                                                    : cs.onSurface,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        priceLabel,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: isProductAlreadyPaid
                                                  ? AppTheme.successGreen
                                                  : (selected
                                                        ? AppTheme.successGreen
                                                        : cs.primary),
                                            ),
                                      ),
                                    ],
                                  ),
                                  if ((p.description ?? '')
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 48),
                                      child: Text(
                                        p.description!,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              height: 1.4,
                                            ),
                                      ),
                                    ),
                                  ],
                                  if ((p.location ?? '').trim().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 48),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              p.location!,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (p.registrationDeadline != null) ...[
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 48),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 16,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Deadline: ${DateFormat('MMM d, yyyy').format(p.registrationDeadline!)}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (showThreshold) ...[
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 48),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Early bird pricing for first $threshold bookings',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: Colors.amber.shade800,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if ((p.disclaimer ?? '')
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 48),
                                      child: Text(
                                        p.disclaimer!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant
                                                  .withOpacity(0.7),
                                              fontStyle: FontStyle.italic,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ] else ...[
                        _buildEmptyState(
                          context,
                          icon: Icons.shopping_bag_outlined,
                          message: 'No products available for this event.',
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Summary + actions
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        'KES ${total.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (total <= 0) {
                            _showError('Event registration is mandatory');
                            return;
                          }

                          final success = await SecurePaymentDialog.show(
                            context,
                            reference: widget.memberIdController.text.trim(),
                            title: 'Pay for ${event.title}',
                            subtitle: isMember
                                ? 'Member pricing applied'
                                : 'Standard pricing applied',
                            amount: total,
                            description: 'Event payment',
                            initialPhone: widget.paymentPhoneController.text,
                            eventId: event.eventId,
                            packageId: widget.selectedPackage?.packageId ?? 0,
                            memberId: widget.memberIdController.text.trim(),
                            eventProductIds: selectedProductIds.toList(
                              growable: false,
                            ),
                          );

                          if (success == true && mounted) {
                            // Save paid event and products to local storage
                            if (event.eventId != null) {
                              await _savePaidEvent(
                                event.eventId!,
                                selectedProductIds.toList(growable: false),
                              );
                            }

                            widget.paymentPhoneController.text =
                                widget.paymentPhoneController.text;
                            _setSelectedEvent(event);
                            widget.onEventProductIdsChanged(
                              selectedProductIds.toList(growable: false),
                            );
                            widget.onSaveProgress?.call();
                            _showSuccess(
                              'Payment successful! Event registration saved.',
                            );
                            Navigator.pop(context, true);
                          }
                        },
                        icon: const Icon(Icons.payments_rounded),
                        label: const Text('Pay Now'),
                      ),
                    ),
                  ],
                ),

                if (alreadySelected) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      _clearSelectedEvent();
                      Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Clear selection'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackageSelection(
    BuildContext context,
    AsyncValue<List<PackageModel>> packagesAsync,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      key: const ValueKey('pay_now'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context,
          'Select a package',
          subtitle: 'Choose what works for you. You can upgrade later.',
        ),
        const SizedBox(height: 14),

        packagesAsync.when(
          data: (packages) {
            if (packages.isEmpty) {
              return _buildEmptyState(
                context,
                icon: Icons.inventory_2_rounded,
                message: 'No packages available right now.',
              );
            }

            final validPackages = packages
                .where((p) => p.packageId != null)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package Cards - Horizontal Scroll
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: validPackages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final pkg = validPackages[index];
                      final isSelected =
                          widget.selectedPackage?.packageId == pkg.packageId;

                      return _buildPackageCard(pkg, isSelected);
                    },
                  ),
                ),

                // Payment Summary & Action
                if (widget.selectedPackage?.packageId != null) ...[
                  const SizedBox(height: 20),
                  _buildPaymentSummary(context),
                  const SizedBox(height: 16),
                  _buildPhoneInput(context),
                  const SizedBox(height: 16),
                  _buildPayButton(context),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              _buildErrorState(context, message: 'Failed to load packages: $e'),
        ),
      ],
    );
  }

  Widget _buildPackageCard(PackageModel pkg, bool isSelected) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final features = pkg.benefitsList.take(3).toList();
    final isPopular =
        pkg.packageName?.toLowerCase().contains('premium') ?? false;

    return GestureDetector(
      onTap: () {
        widget.onPackageSelected(pkg);
        widget.onSaveProgress?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer.withOpacity(0.3) : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant.withOpacity(0.5),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? cs.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 16 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    pkg.packageName ?? 'Package',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Popular',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                if (isSelected && !isPopular)
                  Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
              ],
            ),
            const SizedBox(height: 8),

            // Price
            Text(
              pkg.formattedPrice,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
            Text(
              '/ ${pkg.durationText}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),

            const Spacer(),

            // Features
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final amount = widget.selectedPackage?.price ?? 0;
    final formattedAmount = NumberFormat('#,###.00').format(amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long_rounded, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.selectedPackage?.packageName ?? 'Package'} • KES $formattedAmount',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput(BuildContext context) {
    return widget.buildTextField(
      label: 'M-Pesa Phone Number',
      hint: '+254712345678',
      controller: widget.paymentPhoneController,
      icon: Icons.phone_iphone_rounded,
      keyboardType: TextInputType.phone,
      validator: (v) {
        // Only required when paying for a package.
        if (widget.selectedPackage?.packageId == null) return null;
        return Validators.validatePhone(v);
      },
    );
  }

  Widget _buildPayButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _onPayPackage,
        icon: const Icon(Icons.payments_rounded),
        label: const Text('Pay Now'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _onPayPackage() async {
    final pkg = widget.selectedPackage;
    if (pkg == null || pkg.packageId == null) {
      _showError('Please select a package first');
      return;
    }

    final phone = widget.paymentPhoneController.text.trim();
    final phoneError = Validators.validatePhone(phone);
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }

    final success = await SecurePaymentDialog.show(
      context,
      reference: widget.memberIdController.text.trim(),
      title: 'Package Payment',
      subtitle: pkg.packageName ?? 'Membership Package',
      amount: pkg.price,
      description: 'Membership package payment',
      initialPhone: phone,
      packageId: pkg.packageId,
      memberId: widget.memberIdController.text.trim(),
      eventId: 0,
      eventProductIds: const [],
    );

    if (success == true && mounted) {
      _showSuccess(
        'Payment successful! Your ${pkg.packageName} membership is now active.',
      );
    }
  }

  Widget _buildDetailSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: cs.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, {required String message}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}
