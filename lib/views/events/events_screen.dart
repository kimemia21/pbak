import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/event_provider.dart';
import 'package:pbak/utils/router.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:pbak/widgets/animated_card.dart';
import 'package:pbak/widgets/secure_payment_dialog.dart';
import 'package:pbak/widgets/event_route_details_card.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/event_model.dart';
import 'package:pbak/models/event_product_model.dart';
import 'package:pbak/utils/event_selectors.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes so we can refresh whenever this screen becomes visible again.
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _refreshEvents() {
    // Always fetch fresh data
    ref.read(eventNotifierProvider.notifier).loadEvents();
  }

  @override
  void didPush() {
    // When this screen is first pushed/opened
    _refreshEvents();
  }

  @override
  void didPopNext() {
    // When coming back from another screen (e.g., EventDetail)
    _refreshEvents();
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Event Information',
          ),
        ],
      ),
      body: eventsState.when(
        data: (events) {
          if (events.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.event_rounded,
              title: 'No Events',
              message: 'No events available at the moment.',
            );
          }

          final upcomingEvents = EventSelectors.upcomingSorted(events);
          final pastEvents = EventSelectors.pastSorted(events);
          final allEvents = [...upcomingEvents, ...pastEvents];

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(eventNotifierProvider.notifier).loadEvents();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              itemCount: allEvents.length,
              itemBuilder: (context, index) {
                final event = allEvents[index];
                final isPast = pastEvents.contains(event);
                return EventListItem(
                  event: event, 
                  isPast: isPast,
                  onTap: () => _showEventBottomSheet(context, ref, event),
                );
              },
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading events...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load events',
          onRetry: () => ref.read(eventNotifierProvider.notifier).loadEvents(),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => context.push('/events/create'),
      //   icon: const Icon(Icons.add_rounded),
      //   label: const Text('Create Event'),
      // ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Event Types'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available event types:'),
            SizedBox(height: 12),
            Text('• Group Rides'),
            Text('• Track Days'),
            Text('• Meetups'),
            Text('• Workshops'),
            Text('• Charity Rides'),
            Text('• Other Events'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  

  /// Shows a bottom sheet with event details and products for registration
  Future<void> _showEventBottomSheet(BuildContext context, WidgetRef ref, EventModel event) async {
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

    // Invalidate and refresh events for fresh data
    ref.invalidate(eventsProvider);
    
    // Wait for fresh event data
    EventModel freshEvent = event;
    try {
      final events = await ref.read(eventsProvider.future);
      freshEvent = events.firstWhere(
        (e) => e.eventId == event.eventId || e.id == event.id,
        orElse: () => event,
      );
    } catch (_) {
      // Use original event if refresh fails
    }

    // Dismiss loading dialog
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EventDetailBottomSheet(event: freshEvent),
    );
  }
}
/// Event list item widget with optimized performance and accessibility.
///
/// Displays event information in a card format with:
/// - Event type icon
/// - Title, date, and fee information
/// - Visual indicators for past events and full capacity
/// - Tap interaction for navigation
///
/// Example:
/// ```dart
/// EventListItem(
///   event: eventModel,
///   isPast: false,
///   onTap: () => _navigateToEventDetails(eventModel.id),
/// )
/// ```
class EventListItem extends StatelessWidget {
  /// The event data to display
  final EventModel event;

  /// Whether this is a past event (affects visual styling)
  final bool isPast;

  /// Callback when the item is tapped
  final VoidCallback? onTap;

  const EventListItem({
    required this.event,
    this.isPast = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
      child: _buildListTile(context),
    );
  }

  /// Builds the main list tile with event information
  Widget _buildListTile(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingM,
        vertical: AppTheme.paddingS,
      ),
      leading: _buildLeadingIcon(theme),
      title: _buildTitle(theme),
      subtitle: _buildSubtitle(theme),
      trailing: _buildTrailingIcon(),
      onTap: onTap,
    );
  }

  /// Creates the leading icon based on event type and status
  Widget _buildLeadingIcon(ThemeData theme) {
    final backgroundColor = isPast
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primaryContainer;

    final iconColor = isPast
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;

    return CircleAvatar(
      backgroundColor: backgroundColor,
      child: Icon(
        _getEventTypeIcon(),
        color: iconColor,
        size: 22,
      ),
    );
  }

  /// Builds the event title with proper styling
  Widget _buildTitle(ThemeData theme) {
    return Text(
      event.title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: isPast ? theme.colorScheme.onSurfaceVariant : null,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the subtitle containing date, fee, and status information
  Widget _buildSubtitle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateText(theme),
          const SizedBox(height: 2),
          _buildEventMetadata(theme),
        ],
      ),
    );
  }

  /// Creates the formatted date text
  Widget _buildDateText(ThemeData theme) {
    final dateFormatter = DateFormat('EEE, MMM d • HH:mm');
    final localDate = event.dateTime.toLocal();

    return Text(
      dateFormatter.format(localDate),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Builds the metadata row with fee and status indicators
  Widget _buildEventMetadata(ThemeData theme) {
    return Row(
      children: [
        _buildFeeLabel(theme),
        if (event.isFull) ...[
          _buildDivider(theme),
          _buildFullLabel(theme),
        ],
      ],
    );
  }

  /// Creates the fee label with appropriate styling
  Widget _buildFeeLabel(ThemeData theme) {
    final feeText = _formatEventFee();

    return Text(
      feeText,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
    );
  }

  /// Creates a visual divider between metadata items
  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '•',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Creates the "Full" status label
  Widget _buildFullLabel(ThemeData theme) {
    return Text(
      'Full',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Builds the trailing navigation icon
  Widget _buildTrailingIcon() {
    return IconButton(
      icon: const Icon(Icons.chevron_right_rounded),
      onPressed: onTap,
      tooltip: 'View event details',
    );
  }

  /// Formats the event fee for display
  String _formatEventFee() {
    if (event.fee == null || event.fee == 0) {
      return 'Free';
    }
    return 'KES ${event.fee!.toStringAsFixed(0)}';
  }

  /// Returns the appropriate icon based on event type
  ///
  /// Supports the following event types:
  /// - Ride/Group Ride: motorcycle icon
  /// - Track/Track Day: motorsports icon
  /// - Meetup: group icon
  /// - Workshop: build/tools icon
  /// - Charity: volunteer icon
  /// - Default: generic event icon
  IconData _getEventTypeIcon() {
    final eventType = event.type.toLowerCase().trim();

    return switch (eventType) {
      'ride' || 'group ride' => Icons.two_wheeler_rounded,
      'track' || 'track day' => Icons.sports_motorsports_rounded,
      'meetup' => Icons.groups_rounded,
      'workshop' => Icons.build_rounded,
      'charity' => Icons.volunteer_activism_rounded,
      _ => Icons.event_rounded,
    };
  }
}
/// Bottom sheet that displays event details and products for registration
class _EventDetailBottomSheet extends ConsumerStatefulWidget {
  final EventModel event;

  const _EventDetailBottomSheet({required this.event});

  @override
  ConsumerState<_EventDetailBottomSheet> createState() => _EventDetailBottomSheetState();
}

class _EventDetailBottomSheetState extends ConsumerState<_EventDetailBottomSheet> {
  // Track product quantities: productId -> quantity
  final Map<int, int> _productQuantities = {};
  bool _isProcessing = false;

  // Food preferences
  bool? _isVegetarian;
  String _specialFoodRequirements = '';

  // Fresh event data
  EventModel? _freshEvent;
  bool _isLoadingEvent = true;

  @override
  void initState() {
    super.initState();
    _fetchFreshEventData();
  }

  Future<void> _fetchFreshEventData() async {
    // Fetch events normally and select locally (avoid /events/{id}).
    try {
      final events = await ref.read(eventsProvider.future);
      final freshEvent = events.cast<EventModel?>().firstWhere(
            (e) => e != null && (e.eventId?.toString() == widget.event.id || e.id == widget.event.id),
            orElse: () => null,
          );
      if (mounted) {
        setState(() {
          _freshEvent = freshEvent;
          _isLoadingEvent = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingEvent = false;
        });
      }
    }
  }

  /// Get the current event (fresh data if available, otherwise widget.event)
  EventModel get _currentEvent => _freshEvent ?? widget.event;

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

  String _formatAmount(double? amount) {
    if (amount == null) return '0';
    return NumberFormat('#,###').format(amount.round());
  }

  double _calculateTotal(bool isMember) {
    double total = 0;
    for (final product in _currentEvent.products) {
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

  Future<void> _handlePayment() async {
    final hasProducts = _currentEvent.products.isNotEmpty;
    
    // If event has products, check if any are selected
    if (hasProducts) {
      final hasSelectedProducts = _productQuantities.values.any((qty) => qty > 0);
      if (!hasSelectedProducts) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one product to continue'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Only show food preferences dialog if the event has products/addons
      final proceed = await _showFoodPreferencesDialog(context);
      if (!proceed || !mounted) return;
    }

    setState(() => _isProcessing = true);

    try {
      final authState = ref.read(authProvider);
      final user = authState.valueOrNull;
      
      // Determine price based on membership status
      final isMember = user != null && user.approvalStatus == 'approved';
      
      // Calculate total price for all selected products with quantities
      double totalPrice = 0;
      final selectedProductIds = <int>[];
      final productNames = <String>[];
      final productsPayload = <Map<String, dynamic>>[];

      for (final product in _currentEvent.products) {
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
          : '${_currentEvent.eventId ?? _currentEvent.id}-$productIdsStr';

      // Show payment dialog with member_id for logged in users
      final success = await SecurePaymentDialog.show(
        context,
        reference: reference,
        title: 'Event Registration',
        subtitle: selectedProductIds.length == 1 
            ? productNames.first 
            : '${selectedProductIds.length} items selected',
        amount: totalPrice,
        description: '${_currentEvent.title}: ${productNames.join(', ')}',
        mpesaOnly: true,
        memberId: user?.memberId.toString(),
        eventId: _currentEvent.eventId,
        eventProductIds: selectedProductIds,
        products: productsPayload,
        isVegetarian: _isVegetarian,
        specialFoodRequirements: _specialFoodRequirements,
        email: user?.email,
      );

      if (!mounted) return;

      if (success == true) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.successGreen,
            content: Text('Payment successful! You are registered for this event.'),
          ),
        );
        // Refresh events to get updated data
        ref.read(eventNotifierProvider.notifier).loadEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = _currentEvent;
    final dateFmt = DateFormat('EEE, MMM d, yyyy');
    final hasProducts = event.products.isNotEmpty;
    
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    final isMember = user != null && user.approvalStatus == 'approved';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Loading indicator while fetching fresh data
              if (_isLoadingEvent)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Refreshing...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppTheme.paddingM),
                  children: [
                    // Event Banner
                    if ((event.imageUrl ?? '').isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            event.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.two_wheeler_rounded,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: AppTheme.paddingM),
                    
                    // Event Title
                    Text(
                      event.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.paddingS),
                    
                    // Event Info Row
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: dateFmt.format(event.dateTime.toLocal()),
                        ),
                        if (event.startTime != null)
                          _InfoChip(
                            icon: Icons.schedule_rounded,
                            label: event.startTime!,
                          ),
                        _InfoChip(
                          icon: Icons.location_on_rounded,
                          label: event.location,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.paddingM),
                    
                    // Description
                    if (event.description.isNotEmpty) ...[
                      Text(
                        event.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.description.length > 100) ...[
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
                      const SizedBox(height: AppTheme.paddingM),
                    ],
                    
                    // Route Details
                    if ((event.routeDetails ?? '').isNotEmpty &&
                        event.routeDetails != '{}') ...[
                      EventRouteDetailsCard(routeDetails: event.routeDetails ?? ''),
                      const SizedBox(height: AppTheme.paddingM),
                    ],
                    
                    // Products Section
                    if (hasProducts) ...[
                      Text(
                        'Registration Options',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isMember)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          child: Text(
                            'Member prices applied ✓',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          child: Text(
                            'Become a member for discounted prices',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ...event.products.map((product) {
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
                      const SizedBox(height: AppTheme.paddingM),
                    ],
                    
                    const SizedBox(height: AppTheme.paddingL),
                    
                    // View Full Details Button
                    OutlinedButton.icon(
                      
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/events/${event.id}', extra: event.toJson());
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('View Full Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.paddingXL),
                  ],
                ),
              ),
              
              // Bottom Action Bar
              Container(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.paddingM,
                  AppTheme.paddingS,
                  AppTheme.paddingM,
                  MediaQuery.of(context).padding.bottom + AppTheme.paddingM,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
                          : _handlePayment,
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
            ],
          );
        },
      ),
    );
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

/// Info chip for displaying event metadata with modern styling
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final bool isPrimary;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? 
        (isPrimary 
            ? theme.colorScheme.primaryContainer 
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7));
    final icColor = iconColor ?? 
        (isPrimary 
            ? theme.colorScheme.primary 
            : theme.colorScheme.onSurfaceVariant);
    final txtColor = textColor ?? 
        (isPrimary 
            ? theme.colorScheme.primary 
            : theme.colorScheme.onSurface);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary 
            ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: icColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: txtColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Product card with quantity selector (+/-) - Professional design
class _ProductQuantityCard extends StatelessWidget {
  final EventProductModel product;
  final int quantity;
  final int maxQuantity;
  final double price;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final String Function(double?) formatAmount;

  const _ProductQuantityCard({
    required this.product,
    required this.quantity,
    required this.maxQuantity,
    required this.price,
    this.onIncrement,
    this.onDecrement,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuantity = quantity > 0;
    final isSoldOut = maxQuantity <= 0;
    
    // Calculate remaining slots for display
    final totalSlots = product.maxCount ?? 999;
    final takenSlots = product.taken;
    final remainingSlots = (totalSlots - takenSlots).clamp(0, totalSlots);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
      decoration: BoxDecoration(
        color: hasQuantity
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasQuantity
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: hasQuantity ? 2 : 1,
        ),
        boxShadow: hasQuantity
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasQuantity
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getProductIcon(product.name),
                      size: 22,
                      color: hasQuantity
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Product name and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: hasQuantity 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.onSurface,
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
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Status badge
                  if (isSoldOut)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Sold Out',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (hasQuantity)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Selected',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Divider
              Container(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              
              const SizedBox(height: 12),
              
              // Price and quantity row
              Row(
                children: [
                  // Price section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'KES',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              price > 0 ? formatAmount(price) : 'FREE',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (price > 0) ...[
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '/ ticket',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!isSoldOut && remainingSlots < 50) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 14,
                                color: remainingSlots < 10 
                                    ? theme.colorScheme.error 
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$remainingSlots left',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: remainingSlots < 10 
                                      ? theme.colorScheme.error 
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Quantity selector
                  if (!isSoldOut)
                    Container(
                      decoration: BoxDecoration(
                        color: hasQuantity
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasQuantity
                              ? theme.colorScheme.primary.withValues(alpha: 0.3)
                              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Minus button
                          _QuantityButton(
                            icon: Icons.remove_rounded,
                            onTap: onDecrement,
                            isEnabled: quantity > 0,
                            isLeft: true,
                            hasQuantity: hasQuantity,
                          ),

                          // Quantity display
                          Container(
                            constraints: const BoxConstraints(minWidth: 44),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                            child: Text(
                              '$quantity',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: hasQuantity
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),

                          // Plus button
                          _QuantityButton(
                            icon: Icons.add_rounded,
                            onTap: onIncrement,
                            isEnabled: quantity < maxQuantity,
                            isRight: true,
                            hasQuantity: hasQuantity,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              // Subtotal row (when quantity > 0)
              if (hasQuantity && price > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal ($quantity × KES ${formatAmount(price)})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'KES ${formatAmount(price * quantity)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Returns appropriate icon based on product name
  IconData _getProductIcon(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('breakfast')) return Icons.free_breakfast_rounded;
    if (name.contains('lunch') || name.contains('dinner')) return Icons.restaurant_rounded;
    if (name.contains('drink') || name.contains('beverage')) return Icons.local_bar_rounded;
    if (name.contains('ride') || name.contains('bike')) return Icons.two_wheeler_rounded;
    if (name.contains('ticket')) return Icons.confirmation_number_rounded;
    if (name.contains('vip')) return Icons.star_rounded;
    if (name.contains('camping') || name.contains('tent')) return Icons.holiday_village_rounded;
    if (name.contains('parking')) return Icons.local_parking_rounded;
    return Icons.shopping_bag_rounded;
  }
}

/// Quantity button widget for increment/decrement
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isLeft;
  final bool isRight;
  final bool hasQuantity;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    required this.isEnabled,
    this.isLeft = false,
    this.isRight = false,
    required this.hasQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(11) : Radius.zero,
          right: isRight ? const Radius.circular(11) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled
                ? (hasQuantity ? theme.colorScheme.primary : theme.colorScheme.onSurface)
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

/// Product card for event registration options
class _ProductCard extends StatelessWidget {
  final EventProductModel product;
  final bool isSelected;
  final bool isMember;
  final VoidCallback onTap;
  final String Function(double?) formatAmount;

  const _ProductCard({
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
              ? theme.colorScheme.primaryContainer.withOpacity(0.5)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withOpacity(0.5),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
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