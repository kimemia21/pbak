import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/event_model.dart';
import 'package:pbak/models/event_product_model.dart';
import 'package:pbak/providers/event_provider.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/maps_launcher.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/secure_payment_dialog.dart';
import 'package:pbak/widgets/event_route_details_card.dart';
import 'package:url_launcher/url_launcher.dart';

EventModel? _findEvent(List<EventModel> events, String routeId) {
  if (routeId.trim().isEmpty) return null;
  final int? routeIdInt = int.tryParse(routeId);

  for (final e in events) {
    if (e.id == routeId) return e;
    if (e.eventId != null && e.eventId.toString() == routeId) return e;
    if (routeIdInt != null && e.eventId == routeIdInt) return e;
    final int? eIdInt = int.tryParse(e.id);
    if (routeIdInt != null && eIdInt != null && eIdInt == routeIdInt) return e;
  }
  return null;
}

class _EventDetailScaffoldLoadingFallback extends StatelessWidget {
  final EventModel? event;

  const _EventDetailScaffoldLoadingFallback({this.event});

  @override
  Widget build(BuildContext context) {
    // If we have something to show (from navigation extras), render it immediately.
    // Otherwise show a generic loading state.
    if (event != null) {
      return _EventDetailScaffold(event: event!, kycPayMode: false);
    }
    return const LoadingWidget(message: 'Loading event...');
  }
}

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
    // Fetch events normally (/events...) and select this event locally.
    // This avoids relying on /events/{id} endpoints.
    final eventsAsync = ref.watch(eventsProvider);

    // If we already have an event passed through navigation, we can render it as a
    // fallback while the list loads.
    return eventsAsync.when(
      loading: () => Scaffold(
        body: _EventDetailScaffoldLoadingFallback(event: event),
      ),
      error: (err, st) => Scaffold(
        appBar: AppBar(title: const Text('Event')),
        body: CustomErrorWidget(
          message: 'Failed to load events',
          onRetry: () => ref.refresh(eventsProvider),
        ),
      ),
      data: (events) {
        final selected = _findEvent(events, eventId) ?? event;
        if (selected == null) {
          return const Scaffold(
            body: Center(child: Text('Event not found')),
          );
        }
        return _EventDetailScaffold(event: selected, kycPayMode: kycPayMode);
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

    final feeText = (event.fee == null || event.fee == 0) ? 'Free' : 'KES ${event.fee!.toStringAsFixed(2)}';

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

class _EventDetailScaffold extends ConsumerStatefulWidget {
  final EventModel event;
  final bool kycPayMode;

  const _EventDetailScaffold({
    required this.event,
    required this.kycPayMode,
  });

  @override
  ConsumerState<_EventDetailScaffold> createState() => _EventDetailScaffoldState();
}

class _EventDetailScaffoldState extends ConsumerState<_EventDetailScaffold> {
  // Track product quantities: productId -> quantity
  final Map<int, int> _productQuantities = {};
  bool _isProcessing = false;

  // Food preferences
  bool? _isVegetarian;
  String _specialFoodRequirements = '';

  String _formatAmount(double? amount) {
    if (amount == null) return '0';
    return NumberFormat('#,###').format(amount.round());
  }

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

  Future<void> _showPaymentDialog(BuildContext context) async {
    // Only show food preferences dialog if the event has products/addons
    if (widget.event.products.isNotEmpty) {
      final proceed = await _showFoodPreferencesDialog(context);
      if (!proceed || !mounted) return;
    }
    final authState = ref.read(authProvider);
    final user = authState.valueOrNull;
    final isMember = user != null && user.approvalStatus == 'approved';
    
    // If products exist, use selected products price
    if (widget.event.products.isNotEmpty) {
      // Check if any products are selected (quantity > 0)
      final hasSelectedProducts = _productQuantities.values.any((qty) => qty > 0);
      if (!hasSelectedProducts) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Please select at least one registration option.'),
          ),
        );
        return;
      }
      
      // Calculate total price for all selected products with quantities
      double totalPrice = 0;
      final selectedProductIds = <int>[];
      final productNames = <String>[];
      final productsPayload = <Map<String, dynamic>>[];

      for (final product in widget.event.products) {
        final id = product.productId;
        if (id != null && _productQuantities.containsKey(id)) {
          final qty = _productQuantities[id] ?? 0;
          if (qty > 0) {
            final rate = product.amount ?? (isMember ? product.memberPrice : product.basePrice);
            totalPrice += rate * qty;
            selectedProductIds.add(id);
            productNames.add(product.name);
            productsPayload.add({
              'product_id': id,
              'quantity': qty,
              'rate': rate,
            });
          }
        }
      }
      
      // Create product IDs string for reference
      final productIdsStr = selectedProductIds.join(',');
      
      // Use membership_number as reference if logged in, otherwise use event/product ID
      final reference = user != null && user.membershipNumber.isNotEmpty
          ? user.membershipNumber
          : '${widget.event.eventId ?? widget.event.id}-$productIdsStr';
      
      setState(() => _isProcessing = true);
      
      final success = await SecurePaymentDialog.show(
        context,
        reference: reference,
        title: 'Event Registration',
        subtitle: selectedProductIds.length == 1 
            ? productNames.first 
            : '${selectedProductIds.length} items selected',
        amount: totalPrice,
        description: '${widget.event.title}: ${productNames.join(', ')}',
        mpesaOnly: true,
        memberId: user?.memberId.toString(),
        eventId: widget.event.eventId,
        eventProductIds: selectedProductIds,
        products: productsPayload,
        isVegetarian: _isVegetarian,
        specialFoodRequirements: _specialFoodRequirements,
        email: user?.email,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.successGreen,
            content: Text('Payment successful! You are registered for this event.'),
          ),
        );
      }
      ref.read(eventNotifierProvider.notifier).loadEvents();
      // Refresh events list; detail is resolved from the list (no /events/{id}).
      ref.invalidate(eventsProvider);
      return;
    }
    
    // No products - use event fee
    final amount = widget.event.fee ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('This event is free. No payment required.'),
        ),
      );
      return;
    }

    // Use membership_number as reference if logged in, otherwise use event ID
    final reference = user != null && user.membershipNumber.isNotEmpty
        ? user.membershipNumber
        : '${widget.event.eventId ?? widget.event.id}';
    
    setState(() => _isProcessing = true);
    
    final success = await SecurePaymentDialog.show(
      context,
      reference: reference,
      title: 'Event Registration',
      subtitle: widget.event.title,
      amount: amount,
      description: 'PBAK Event: ${widget.event.title}',
      mpesaOnly: true,
      memberId: user?.memberId.toString(),
      eventId: widget.event.eventId,
      isVegetarian: _isVegetarian,
      specialFoodRequirements: _specialFoodRequirements,
      email: user?.email,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.successGreen,
          content: Text('Payment successful! You are registered for this event.'),
        ),
      );
    }
    ref.read(eventNotifierProvider.notifier).loadEvents();
    // Refresh events list; detail is resolved from the list (no /events/{id}).
    ref.invalidate(eventsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('EEE, MMM d, yyyy');
    final event = widget.event;
    final hasCoords = event.latitude != null && event.longitude != null;
    final hasProducts = event.products.isNotEmpty;
    
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    final isMember = user != null && user.approvalStatus == 'approved';

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.paddingM,
            AppTheme.paddingS,
            AppTheme.paddingM,
            AppTheme.paddingM,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Price display
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_productQuantities.values.where((q) => q > 0).length > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_productQuantities.values.where((q) => q > 0).length} items',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _productQuantities.values.any((q) => q > 0)
                          ? 'KES ${_formatAmount(_calculateTotal(isMember))}'
                          : hasProducts 
                              ? 'Select an option'
                              : event.fee == null || event.fee == 0
                                  ? 'Free'
                                  : 'KES ${_formatAmount(event.fee)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.paddingM),
              // Register Button
              FilledButton.icon(
                onPressed: (hasProducts && !_productQuantities.values.any((q) => q > 0)) || _isProcessing
                    ? null
                    : () => _showPaymentDialog(context),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.how_to_reg_rounded),
                label: Text(_isProcessing ? 'Processing...' : 'Register Now'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

                  // Quick Actions Row
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
                  ),

                  const SizedBox(height: AppTheme.paddingM),

                  // Route Details
                  if ((event.routeDetails ?? '').isNotEmpty &&
                      event.routeDetails != '{}') ...[
                    EventRouteDetailsCard(routeDetails: event.routeDetails ?? ''),
                    const SizedBox(height: AppTheme.paddingM),
                  ],

                  // Registration Options / Products Section
                  if (hasProducts) ...[
                    Builder(
                      builder: (context) {
                        // Filter products based on membership status
                        final availableProducts = event.products
                            .where((p) => p.isAvailableForUser(isMember: true))
                            .toList();
                        
                        if (availableProducts.isEmpty) {
                          return _SectionCard(
                            title: 'Registration Options',
                            subtitle: 'No options available',
                            child: Text(
                              isMember 
                                  ? 'No registration options available for this event.'
                                  : 'Some options are only available to members. Become a member to see all options.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        
                        return _SectionCard(
                          title: 'Registration Options',
                          subtitle: isMember 
                              ? 'Member prices applied ✓' 
                              : 'Become a member for discounted prices',
                          child: Column(
                            children: [
                              ...availableProducts.map((product) {
                                final id = product.productId;
                                final qty = id != null ? (_productQuantities[id] ?? 0) : 0;
                                final price = product.amount ?? (isMember ? product.memberPrice : product.basePrice);
                                
                                // Calculate remaining slots from maxCount and taken
                                // maxCount = maxcnt from API (total slots available)
                                // taken = taken from API (slots already purchased)
                                final int totalSlots = product.maxCount ?? 999; // Default to high number if not set
                                final int takenSlots = product.taken;
                                final int remainingSlots = (totalSlots - takenSlots).clamp(0, totalSlots);
                                
                                // Max quantity per user is the minimum of:
                                // 1. max_per_member (if set)
                                // 2. remaining slots available
                                final int maxPerUser = product.maxPerMember ?? remainingSlots;
                                final int maxQty = maxPerUser.clamp(0, remainingSlots);
                                
                                final bool isSoldOut = remainingSlots <= 0;

                                return _ProductQuantityCard(
                                  product: product,
                                  quantity: qty,
                                  maxQuantity: maxQty,
                                  price: price,
                                  isSoldOut: isSoldOut,
                                  isMembersOnly: product.isMembersOnly,
                                  remainingSlots: remainingSlots,
                                  onIncrement: (id == null || qty >= maxQty || isSoldOut)
                                      ? null
                                      : () {
                                          setState(() {
                                            _productQuantities[id] = qty + 1;
                                          });
                                        },
                                  onDecrement: (id == null || qty <= 0)
                                      ? null
                                      : () {
                                          setState(() {
                                            final newQty = qty - 1;
                                            if (newQty <= 0) {
                                              _productQuantities.remove(id);
                                            } else {
                                              _productQuantities[id] = newQty;
                                            }
                                          });
                                        },
                                  formatAmount: _formatAmount,
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    // No products - show event registration fee
                    _SectionCard(
                      title: 'Registration',
                      subtitle: 'Event registration fee',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.confirmation_number_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppTheme.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Event Registration',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.fee == null || event.fee == 0
                                      ? 'Free Event'
                                      : 'KES ${_formatAmount(event.fee)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppTheme.paddingM),

                  // Registration Deadline
                  _SectionCard(
                    title: 'Registration Deadline',
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.paddingS),
                        Text(
                          event.registrationDeadline == null
                              ? 'Not specified'
                              : DateFormat('EEE, MMM d, yyyy • HH:mm')
                                  .format(event.registrationDeadline!.toLocal()),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                        // Expanded(
                        //   child: _StatTile(
                        //     label: 'Joined',
                        //     value: event.joinedCount.toString(),
                        //   ),
                        // ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.description.isEmpty 
                              ? 'No description provided.' 
                              : event.description,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (event.description.isNotEmpty && event.description.length > 100) ...[
                          const SizedBox(height: AppTheme.paddingS),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _showDescriptionDialog(context, event.description),
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

  double _calculateTotal(bool isMember) {
    double total = 0;
    for (final product in widget.event.products) {
      final id = product.productId;
      if (id != null && _productQuantities.containsKey(id)) {
        final qty = _productQuantities[id] ?? 0;
        if (qty > 0) {
          final rate = product.amount ?? (isMember ? product.memberPrice : product.basePrice);
          total += rate * qty;
        }
      }
    }
    return total;
  }

  String _formatTimeRange(String? start, String? end) {
    final s = (start ?? '').trim();
    final e = (end ?? '').trim();
    if (s.isEmpty && e.isEmpty) return 'Not specified';
    if (s.isEmpty) return 'Until $e';
    if (e.isEmpty) return 'From $s';
    return '$s - $e';
  }

  void _showDescriptionDialog(BuildContext context, String description) {
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
              Icons.description_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Event Description'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            description,
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
    final feeText = isFree ? 'REGISTERED' : 'KES ${widget.event.fee!.toStringAsFixed(0)}';

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

/// Product selection card for event registration options
/// Product card with quantity selector (+/-)
class _ProductQuantityCard extends StatelessWidget {
  final EventProductModel product;
  final int quantity;
  final int maxQuantity;
  final double price;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final String Function(double?) formatAmount;
  final bool isSoldOut;
  final bool isMembersOnly;
  final int? remainingSlots;

  const _ProductQuantityCard({
    required this.product,
    required this.quantity,
    required this.maxQuantity,
    required this.price,
    this.onIncrement,
    this.onDecrement,
    required this.formatAmount,
    this.isSoldOut = false,
    this.isMembersOnly = false,
    this.remainingSlots,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuantity = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingS),
      padding: const EdgeInsets.all(AppTheme.paddingM),
      decoration: BoxDecoration(
        color: hasQuantity
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasQuantity
              ? theme.colorScheme.primary.withOpacity(0.5)
              : theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: hasQuantity ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSoldOut ? theme.colorScheme.onSurfaceVariant : null,
                        ),
                      ),
                    ),
                    // Members only badge
                    if (isMembersOnly) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Members Only',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                    // Sold out badge
                    if (isSoldOut) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sold Out',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if ((product.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      price > 0 ? 'KES ${formatAmount(price)}' : 'FREE',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSoldOut ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
                      ),
                    ),
                   
                    // Show remaining slots
                    if (remainingSlots != null && remainingSlots! > 0 && remainingSlots! <= 10 && !isSoldOut) ...[
                      const SizedBox(width: 8),
                      Text(
                        '($remainingSlots left)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: remainingSlots! <= 3 ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                          fontWeight: remainingSlots! <= 3 ? FontWeight.w600 : null,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: AppTheme.paddingS),

          // Quantity selector
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
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
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.remove_rounded,
                      size: 20,
                      color: quantity > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ),
                ),

                // Quantity display
                Container(
                  constraints: const BoxConstraints(minWidth: 36),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: quantity > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
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
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: quantity < maxQuantity
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSelectionCard extends StatelessWidget {
  final EventProductModel product;
  final bool isSelected;
  final bool isMember;
  final VoidCallback onTap;
  final String Function(double?) formatAmount;

  const _ProductSelectionCard({
    required this.product,
    required this.isSelected,
    required this.isMember,
    required this.onTap,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = isMember ? product.memberPrice : product.basePrice;
    final originalPrice = product.basePrice;
    final hasDiscount = isMember && product.memberPrice < product.basePrice;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppTheme.paddingS),
        padding: const EdgeInsets.all(AppTheme.paddingM),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator (checkbox style for multi-select)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppTheme.paddingM),
            
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if ((product.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if ((product.location ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((product.disclaimer ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              product.disclaimer!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade800,
                                fontSize: 10,
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
            
            const SizedBox(width: AppTheme.paddingS),
            
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'KES ${formatAmount(price)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (hasDiscount)
                  Text(
                    'KES ${formatAmount(originalPrice)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (hasDiscount)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Member Price',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
