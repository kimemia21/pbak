import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/event_model.dart';
import 'package:pbak/models/package_model.dart';
import 'package:pbak/providers/event_provider.dart';
import 'package:pbak/providers/package_provider.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/widgets/premium_ui.dart';
import 'package:pbak/widgets/kyc_event_card.dart';
import 'package:pbak/widgets/secure_payment_dialog.dart';
/// Format currency with commas
String _formatAmount(double? amount) {
  if (amount == null) return '0';
  return NumberFormat('#,###').format(amount.round());
}

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

  /// Flag indicating if user is registering through a PBAK member referral.
  /// When true, user gets 50% discount (member_registration_fee is used).
  final bool registerByPbak;
  final void Function(bool) onRegisterByPbakChanged;

  /// User's ID number for fetching member-specific event pricing from API
  final String? idNumber;

  /// User's email for payment payload
  final String? email;

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
    this.registerByPbak = false,
    required this.onRegisterByPbakChanged,
    this.idNumber,
    this.email,
    this.onSaveProgress,
    required this.buildTextField,
  });

  @override
  ConsumerState<PaymentsStep> createState() => _PaymentsStepState();
}

class _PaymentsStepState extends ConsumerState<PaymentsStep> {
  // Membership check now happens earlier in the flow (Documents step).
  // PaymentsStep just consumes the result.

  /// Toggle to show/hide package selection
  bool _showPackageSelection = false;

  // Food preferences for event registration
  bool? _isVegetarian;
  String _specialFoodRequirements = '';

  /// Shows food preferences dialog before payment
  /// Returns true if user confirmed, false if cancelled
  Future<bool> _showFoodPreferencesDialog(BuildContext context) async {
    bool? isVegetarian = _isVegetarian;
    final specialFoodController = TextEditingController(text: _specialFoodRequirements);
    bool hasError = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.restaurant_menu_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Text('Food Preferences'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please let us know your food preferences for this event.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Vegetarian checkbox (mandatory)
                    Text(
                      'Are you vegetarian? *',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Yes'),
                            value: true,
                            groupValue: isVegetarian,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            onChanged: (v) {
                              setDialogState(() {
                                isVegetarian = v;
                                hasError = false;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('No'),
                            value: false,
                            groupValue: isVegetarian,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            onChanged: (v) {
                              setDialogState(() {
                                isVegetarian = v;
                                hasError = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (hasError && isVegetarian == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Please select an option',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Special food requirements (optional)
                    Text(
                      'Special food requirements (optional)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: specialFoodController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'E.g., allergies, dietary restrictions...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (isVegetarian == null) {
                      setDialogState(() => hasError = true);
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Continue to Payment'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      setState(() {
        _isVegetarian = isVegetarian;
        _specialFoodRequirements = specialFoodController.text.trim();
      });
      return true;
    }
    return false;
  }

  void _showSnack(
    String message, {
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        elevation: 0,
        duration: duration,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    _showSnack(
      message,
      backgroundColor: AppTheme.successGreen,
      icon: Icons.check_circle_rounded,
      duration: const Duration(seconds: 2),
    );
  }

  void _showError(String message) {
    _showSnack(
      message,
      backgroundColor: AppTheme.brightRed,
      icon: Icons.error_rounded,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final packagesAsync = ref.watch(packagesProvider);
    // Use discounted pricing when user registered via "50% off" button (registerByPbak)
    // Otherwise use member-specific pricing if ID number is provided, or fall back to current events
    final AsyncValue<List<EventModel>> currentEventsAsync;
    if (widget.registerByPbak) {
      // User clicked "Register with 50% off" - use discounted events
      currentEventsAsync = widget.idNumber != null && widget.idNumber!.trim().isNotEmpty
          ? ref.watch(discountedEventsByIdNumberProvider(widget.idNumber!.trim()))
          : ref.watch(discountedEventsProvider);
    } else {
      // Regular registration - use standard pricing
      currentEventsAsync = widget.idNumber != null && widget.idNumber!.trim().isNotEmpty
          ? ref.watch(eventsByIdNumberProvider(widget.idNumber!.trim()))
          : ref.watch(currentEventsProvider);
    }

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
          // PBAK Member Referral Toggle
          // _buildRegisterByPbakToggle(context),
          const SizedBox(height: 20),
          
          _buildSectionTitle(
            context,
            'Pay for an event',
            subtitle:
                'Select an event to pay for',
          ),
          const SizedBox(height: 12),
          _buildEventsSection(currentEventsAsync),

          const SizedBox(height: 28),

          // Packages section (only when NOT linked)
          if (widget.memberHasActivePackage == false) ...[
            // Toggle to show/hide package selection
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Subscribe to a package'),
              subtitle: const Text('Select and pay for a PBAK  membership package.'),
              value: _showPackageSelection,
              activeColor: Colors.black,
              activeTrackColor: Colors.black.withOpacity(0.5),
              inactiveThumbColor: Colors.black,
              inactiveTrackColor: Colors.black.withOpacity(0.3),
              onChanged: (v) {
                setState(() {
                  _showPackageSelection = v;
                  if (!v) {
                    widget.onPackageSelected(null);
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            if (_showPackageSelection) ...[
              _buildPackageSelection(context, packagesAsync),
            ],
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
                is50off: widget.registerByPbak,
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

  Widget _buildPackageSelection(
    BuildContext context,
    AsyncValue<List<PackageModel>> packagesAsync,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context,
          'Select a Package',
          subtitle: 'Choose a membership package to continue',
        ),
        const SizedBox(height: 12),
        packagesAsync.when(
          data: (packages) {
            if (packages.isEmpty) {
              return _buildEmptyState(
                context,
                icon: Icons.inventory_2_outlined,
                message: 'No packages available',
              );
            }

            return Column(
              children: packages.map((pkg) {
                final isSelected =
                    widget.selectedPackage?.packageId == pkg.packageId;

                final isInactive = pkg.isActive != true;

                return GestureDetector(
                  onTap: isInactive ? null : () => _onPayPackage(pkg),
                  child: Opacity(
                    opacity: isInactive ? 0.55 : 1,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primaryContainer.withOpacity(0.3)
                            : cs.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? cs.primary
                              : cs.outlineVariant.withOpacity(0.4),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary
                                  : cs.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.card_membership_rounded,
                              color: isSelected ? Colors.white : cs.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pkg.packageName ?? 'Package',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (isInactive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.errorContainer.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                            color: cs.error.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Text(
                                          'Inactive',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: cs.error,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (pkg.description != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    pkg.description!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            'KES ${_formatAmount(pkg.price)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isInactive ? cs.onSurfaceVariant : cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) =>
              _buildErrorState(context, message: 'Failed to load packages'),
        ),
      ],
    );
  }

  Future<void> _onPayPackage(PackageModel pkg) async {
    // Safety: prevent payment/selection for inactive packages.
    if (pkg.isActive != true) {
      _showError('This package is currently inactive and cannot be selected.');
      return;
    }

    final success = await SecurePaymentDialog.show(
      context,
      reference: widget.memberIdController.text.trim(),
      title: 'Package Payment',
      subtitle: pkg.packageName ?? 'Membership Package',
      amount: pkg.price,
      description: 'Membership package payment',
      initialPhone: widget.paymentPhoneController.text,
      packageId: pkg.packageId,
      memberId: "-1",
      eventId: null,
      eventProductIds: const [],
      email: widget.email,
    );

    if (success == true && mounted) {
      widget.onPackageSelected(pkg);
      widget.onSaveProgress?.call();
      _showSuccess('Package payment successful!');
    }
  }

  Future<void> _onEventTapped(EventModel event) async {
    final cs = Theme.of(context).colorScheme;

    // Show loading dialog while refreshing events
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Loading event...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Invalidate and refresh events before showing the sheet for fresh data
    if (mounted) {
      if (widget.registerByPbak) {
        // Discounted pricing
        if (widget.idNumber != null && widget.idNumber!.trim().isNotEmpty) {
          ref.invalidate(discountedEventsByIdNumberProvider(widget.idNumber!.trim()));
        } else {
          ref.invalidate(discountedEventsProvider);
        }
      } else {
        // Standard pricing
        if (widget.idNumber != null && widget.idNumber!.trim().isNotEmpty) {
          ref.invalidate(eventsByIdNumberProvider(widget.idNumber!.trim()));
        } else {
          ref.invalidate(currentEventsProvider);
        }
      }
    }

    // Wait for fresh event data before showing the sheet
    EventModel freshEvent = event;
    try {
      final Future<List<EventModel>> eventsFuture;
      if (widget.registerByPbak) {
        // Discounted pricing
        eventsFuture = widget.idNumber != null && widget.idNumber!.trim().isNotEmpty
            ? ref.read(discountedEventsByIdNumberProvider(widget.idNumber!.trim()).future)
            : ref.read(discountedEventsProvider.future);
      } else {
        // Standard pricing
        eventsFuture = widget.idNumber != null && widget.idNumber!.trim().isNotEmpty
            ? ref.read(eventsByIdNumberProvider(widget.idNumber!.trim()).future)
            : ref.read(currentEventsProvider.future);
      }
      final events = await eventsFuture;
      freshEvent = events.firstWhere(
        (e) => e.eventId == event.eventId,
        orElse: () => event,
      );
    } catch (_) {
      // Use original event if refresh fails
    }

    // Dismiss loading dialog
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Only one event per pay.
    if (widget.selectedEvents.isNotEmpty &&
        widget.selectedEvents.first.eventId != freshEvent.eventId) {
      widget.onEventProductIdsChanged(const []);
    }

    if (!mounted) return;

    final shouldPay = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surface,
      builder: (context) => _buildEventPaymentSheet(freshEvent, is50off: widget.registerByPbak),
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

  Widget _buildEventPaymentSheet(EventModel event, {required bool is50off}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    // Use member pricing if: user has active package OR registered through PBAK member referral
    final isMember = widget.memberHasActivePackage == true || widget.registerByPbak;

    final dateText = DateFormat('MMM d, yyyy').format(event.dateTime.toLocal());
    final timeText = event.startTime ?? 'TBA';

    final selectedProductIds = <int>{...widget.selectedEventProductIds};
    // Track product quantities: productId -> quantity
    final productQuantities = <int, int>{};
    // Initialize quantities from selectedEventProductIds (count occurrences)
    for (final id in widget.selectedEventProductIds) {
      productQuantities[id] = (productQuantities[id] ?? 0) + 1;
    }
    return SafeArea(
      child: StatefulBuilder(
        builder: (context, setModalState) {
          const bool eventFeePaid = false;
          // Use registration fee directly from event (API returns member-specific pricing)
          final registrationFee = event.fee ?? 0;
          // If fee is 0, event is free - don't count it in total
          final bool isFreeEvent = registrationFee == 0;
          double total = (eventFeePaid || isFreeEvent) ? 0 : registrationFee;

          for (final p in event.products) {
            if (p.productId != null) {
              // Use amount directly from product (API returns member-specific pricing)
              // Fall back to basePrice if amount is not provided
              final price = p.amount ?? p.basePrice;
              final qty = productQuantities[p.productId] ?? 0;
              // Always add selected quantity to total (user can buy more even after previous purchases)
              total += price * qty;
            }
          }

          final bool hasUnpaidItems = total > 0;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            child: Column(
              children: [
                // Header with banner
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: (event.imageUrl?.trim().isNotEmpty == true)
                          ? Image.network(
                              event.imageUrl!,
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildBannerPlaceholder(cs),
                            )
                          : _buildBannerPlaceholder(cs),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.75),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 14,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildInfoChip(
                                Icons.calendar_today_rounded,
                                dateText,
                              ),
                              _buildInfoChip(
                                Icons.access_time_rounded,
                                timeText,
                              ),
                              if (event.location.trim().isNotEmpty)
                                _buildInfoChip(
                                  Icons.location_on_rounded,
                                  event.location,
                                  maxWidth: screenWidth * 0.35,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    children: [
                      // Event Details (Route info)
                      if (event.routeDetails != null &&
                          event.routeDetails!.trim().isNotEmpty &&
                          event.routeDetails!.trim() != '{}') ...[
                        _buildExpandableSection(
                          theme: theme,
                          cs: cs,
                          title: 'Route Details',
                          icon: Icons.route_rounded,
                          content: event.routeDetails!,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Registration card
                      _buildRegistrationCard(
                        theme: theme,
                        cs: cs,
                        // Use registration fee directly from event (API returns member-specific pricing)
                        eventFee: event.fee ?? 0,
                        eventFeePaid: eventFeePaid,
                        isMember: isMember,
                      ),

                      // Products - Always show all products from payload without validation
                      const SizedBox(height: 16),
                      Text(
                        'Add-ons',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (event.products.isEmpty)
                        _buildEmptyState(
                          context,
                          icon: Icons.shopping_bag_outlined,
                          message: 'No add-ons for this event',
                        )
                      else
                        ...event.products.map((p) {
                          final id = p.productId;
                          final qty = id != null ? (productQuantities[id] ?? 0) : 0;
                          // Use amount directly from product (API returns member-specific pricing)
                          // Fall back to basePrice if amount is not provided
                          final price = p.amount ?? p.basePrice;
                          
                          // Calculate remaining slots from maxCount and taken
                          // maxCount = maxcnt from API (total slots available)
                          // taken = taken from API (slots already purchased)
                          final int totalSlots = p.maxCount ?? 999; // Default to high number if not set
                          final int takenSlots = p.taken;
                          final int remainingSlots = (totalSlots - takenSlots).clamp(0, totalSlots);
                          
                          // Max quantity per user is the minimum of:
                          // 1. max_per_member (if set)
                          // 2. remaining slots available
                          final int maxPerUser = p.maxPerMember ?? remainingSlots;
                          final int maxQty = maxPerUser.clamp(0, remainingSlots);
                          
                          final bool isSoldOut = remainingSlots <= 0;

                          return _buildProductQuantityCard(
                            theme: theme,
                            cs: cs,
                            product: p,
                            price: price,
                            quantity: qty,
                            maxQuantity: maxQty,
                            isProductAlreadyPaid: false,
                            previouslyPurchased: 0,
                            originalMaxQuantity: maxQty,
                            onIncrement: (id == null || qty >= maxQty || isSoldOut)
                                ? null
                                : () {
                                    setModalState(() {
                                      productQuantities[id] = qty + 1;
                                      selectedProductIds.add(id);
                                    });
                                  },
                            onDecrement: (id == null || qty <= 0)
                                ? null
                                : () {
                                    setModalState(() {
                                      final newQty = qty - 1;
                                      if (newQty <= 0) {
                                        productQuantities.remove(id);
                                        selectedProductIds.remove(id);
                                      } else {
                                        productQuantities[id] = newQty;
                                      }
                                    });
                                  },
                          );
                        }),
                    ],
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(
                      top: BorderSide(
                        color: cs.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            total > 0 ? 'KES ${_formatAmount(total)}' : 'FREE',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: hasUnpaidItems
                                  ? cs.primary
                                  : AppTheme.successGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Close'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: hasUnpaidItems
                                ? FilledButton(
                                    onPressed: () async {
                                      // Show food preferences dialog first
                                      final proceed = await _showFoodPreferencesDialog(context);
                                      if (!proceed || !mounted) return;

                                      // Build products array with quantity and rate for payment API
                                      final productsPayload = <Map<String, dynamic>>[];
                                      for (final p in event.products) {
                                        final id = p.productId;
                                        if (id != null && productQuantities.containsKey(id)) {
                                          final qty = productQuantities[id] ?? 0;
                                          if (qty > 0) {
                                            final rate = p.amount ?? p.basePrice;
                                            productsPayload.add({
                                              'product_id': id,
                                              'quantity': qty,
                                              'rate': rate,
                                            });
                                          }
                                        }
                                      }

                                      final success =
                                          await SecurePaymentDialog.show(
                                            context,
                                            reference: widget
                                                .memberIdController
                                                .text
                                                .trim(),
                                            title: 'Pay for ${event.title}',
                                            subtitle: isMember
                                                ? 'Member pricing'
                                                : 'Standard pricing',
                                            amount: total,
                                            description: 'Event payment',
                                            initialPhone: widget
                                                .paymentPhoneController
                                                .text,
                                            eventId: event.eventId,
                                            packageId: null,
                                            memberId: widget
                                                .memberIdController
                                                .text
                                                .trim(),
                                            eventProductIds: selectedProductIds
                                                .toList(growable: false),
                                            products: productsPayload,
                                            isVegetarian: _isVegetarian,
                                            specialFoodRequirements: _specialFoodRequirements,
                                            email: widget.email,
                                          );

                                      if (mounted) {
                                        // Invalidate the correct provider based on discount mode
                                        if (widget.registerByPbak) {
                                          if (widget.idNumber != null &&
                                              widget.idNumber!.trim().isNotEmpty) {
                                            ref.invalidate(
                                              discountedEventsByIdNumberProvider(widget.idNumber!.trim()),
                                            );
                                          } else {
                                            ref.invalidate(discountedEventsProvider);
                                          }
                                        } else {
                                          if (widget.idNumber != null &&
                                              widget.idNumber!.trim().isNotEmpty) {
                                            ref.invalidate(
                                              eventsByIdNumberProvider(widget.idNumber!.trim()),
                                            );
                                          } else {
                                            ref.invalidate(currentEventsProvider);
                                          }
                                        }
                                      }

                                      if (success == true && mounted) {
                                        _setSelectedEvent(event);
                                        widget.onEventProductIdsChanged(
                                          selectedProductIds.toList(
                                            growable: false,
                                          ),
                                        );
                                        widget.onSaveProgress?.call();
                                        _showSuccess('Payment successful!');
                                        Navigator.pop(context, true);
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: cs.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Pay KES ${_formatAmount(total)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  )
                                : (isFreeEvent && !eventFeePaid && selectedProductIds.isEmpty)
                                    ? FilledButton(
                                        onPressed: () async {
                                          // Show confirmation dialog before proceeding without add-ons
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Continue Without Add-ons?'),
                                              content: const Text(
                                                'Are you sure you want to continue without selecting any add-ons?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                FilledButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Continue'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm != true || !mounted) return;

                                          // Free event + no add-ons: skip food preferences dialog, just register
                                          _setSelectedEvent(event);
                                          widget.onEventProductIdsChanged(const []);
                                          widget.onSaveProgress?.call();
                                          Navigator.pop(context, true);
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: cs.primary,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Text(
                                          'Register',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppTheme.successGreen
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              size: 18,
                                              color: AppTheme.successGreen,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Already Paid',
                                              style: TextStyle(
                                                color: AppTheme.successGreen,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============ UI HELPER WIDGETS ============

  Widget _buildBannerPlaceholder(ColorScheme cs) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary.withOpacity(0.8), cs.primary],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.two_wheeler_rounded,
          size: 48,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {double? maxWidth}) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required ThemeData theme,
    required ColorScheme cs,
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard({
    required ThemeData theme,
    required ColorScheme cs,
    required double eventFee,
    required bool eventFeePaid,
    required bool isMember,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: eventFeePaid
            ? AppTheme.successGreen.withOpacity(0.08)
            : cs.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: eventFeePaid
              ? AppTheme.successGreen.withOpacity(0.4)
              : cs.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: eventFeePaid ? AppTheme.successGreen : cs.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              eventFeePaid
                  ? Icons.verified_rounded
                  : Icons.confirmation_num_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Registration',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  eventFeePaid
                      ? 'REGISTERED'
                      : (isMember ? 'Member rate' : 'Standard rate'),
                  style: TextStyle(
                    fontSize: 12,
                    color: eventFeePaid
                        ? AppTheme.successGreen
                        : cs.onSurfaceVariant,
                    fontWeight: eventFeePaid
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (eventFeePaid)
                Text(
                  'KES ${_formatAmount(eventFee)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                eventFeePaid ? 'REGISTERED' : (eventFee > 0 ? 'KES ${_formatAmount(eventFee)}' : 'FREE'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: eventFeePaid ? AppTheme.successGreen : cs.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Product card with +/- quantity selector
  Widget _buildProductQuantityCard({
    required ThemeData theme,
    required ColorScheme cs,
    required dynamic product,
    required double price,
    required int quantity,
    required int maxQuantity,
    required bool isProductAlreadyPaid,
    int previouslyPurchased = 0,
    int? originalMaxQuantity,
    VoidCallback? onIncrement,
    VoidCallback? onDecrement,
  }) {
    final hasQuantity = quantity > 0;
    final effectiveMaxQuantity = originalMaxQuantity ?? maxQuantity;
    final isMaxedOut = maxQuantity <= 0;
    print('Product ${product.productId} - quantity: $quantity, maxQuantity: $maxQuantity, effectiveMaxQuantity: $effectiveMaxQuantity');
    

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isProductAlreadyPaid
            ? AppTheme.successGreen.withOpacity(0.08)
            : hasQuantity
                ? cs.primaryContainer.withOpacity(0.15)
                : cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isProductAlreadyPaid
              ? AppTheme.successGreen.withOpacity(0.4)
              : hasQuantity
                  ? cs.primary.withOpacity(0.5)
                  : cs.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name and paid badge
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isProductAlreadyPaid)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'PAID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ),
            ],
          ),
          
          // Product location if available
          if (product.location != null && product.location.toString().trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    product.location.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 10),
          
          // Price and quantity selector row
          Row(
            children: [
              // Price info
              Expanded(
                child: Row(
                  children: [
                    Text(
                      price > 0 ? 'KES ${_formatAmount(price)}' : 'FREE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    // Show max quantity if greater than 1
                    if (effectiveMaxQuantity > 1) ...[
                      const SizedBox(width: 8),
                      Text(
                        '($maxQuantity)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isMaxedOut ? cs.error : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Quantity selector
              if (!isProductAlreadyPaid)
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus button
                      InkWell(
                        onTap: onDecrement,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(9),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.remove_rounded,
                            size: 24,
                            color: quantity > 0 ? cs.primary : cs.onSurfaceVariant.withOpacity(0.4),
                          ),
                        ),
                      ),

                      // Quantity display
                      Container(
                        constraints: const BoxConstraints(minWidth: 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$quantity',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: quantity > 0 ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      ),

                      // Plus button
                      InkWell(
                        onTap: onIncrement,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(9),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.add_rounded,
                            size: 24,
                            color: quantity < maxQuantity ? cs.primary : cs.onSurfaceVariant.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required ThemeData theme,
    required ColorScheme cs,
    required dynamic product,
    required double price,
    required bool selected,
    required bool isProductAlreadyPaid,
    required bool isMember,
    required VoidCallback? onTap,
  }) {
    final p = product;
    final isActive = selected || isProductAlreadyPaid;
    final threshold = p.basePriceFirst ?? 0;
    final showEarlyBird = !isMember && threshold > 0 && !isProductAlreadyPaid;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.successGreen.withOpacity(0.08)
              : cs.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppTheme.successGreen.withOpacity(0.5)
                : cs.outlineVariant.withOpacity(0.4),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.successGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive ? AppTheme.successGreen : cs.outline,
                      width: 2,
                    ),
                  ),
                  child: isActive
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppTheme.successGreen
                              : cs.onSurface,
                        ),
                      ),
                      if (showEarlyBird) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Early bird: first $threshold',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isProductAlreadyPaid ? 'PAID' : 'KES ${_formatAmount(price)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isProductAlreadyPaid
                        ? AppTheme.successGreen
                        : (selected ? AppTheme.successGreen : cs.primary),
                  ),
                ),
              ],
            ),

            // Description
            if ((p.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                p.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],

            // Location
            if ((p.location ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place_outlined, size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      p.location!,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Registration deadline
            if (p.registrationDeadline != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${DateFormat('MMM d, yyyy').format(p.registrationDeadline!)}',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],

            // Disclaimer
            if ((p.disclaimer ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        p.disclaimer!,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
