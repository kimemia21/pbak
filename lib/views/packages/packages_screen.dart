import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/models/package_model.dart';
import 'package:pbak/services/package_service.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/widgets/secure_payment_dialog.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  
  List<PackageModel> _myPackages = [];
  List<PackageModel> _availablePackages = [];
  bool _isLoadingMy = true;
  bool _isLoadingAvailable = true;
  String? _errorMy;
  String? _errorAvailable;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchMyPackages(),
      _fetchAvailablePackages(),
    ]);
    _animationController.forward();
  }

  Future<void> _fetchMyPackages() async {
    setState(() {
      _isLoadingMy = true;
      _errorMy = null;
    });

    try {
      final user = ref.read(authProvider).value;
      if (user != null) {
        final packageService = PackageService();
        final packages = await packageService.getMemberPackages(user.memberId);
        if (mounted) {
          setState(() {
            _myPackages = packages;
            _isLoadingMy = false;
          });
        }
      } else {
        setState(() => _isLoadingMy = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMy = 'Failed to load packages';
          _isLoadingMy = false;
        });
      }
    }
  }

  Future<void> _fetchAvailablePackages() async {
    setState(() {
      _isLoadingAvailable = true;
      _errorAvailable = null;
    });

    try {
      final packageService = PackageService();
      final packages = await packageService.getAllPackages();
      
      // Sort: basic packages first
      packages.sort((a, b) {
        final aIsBasic = _isBasicPackage(a);
        final bIsBasic = _isBasicPackage(b);
        if (aIsBasic && !bIsBasic) return -1;
        if (!aIsBasic && bIsBasic) return 1;
        return 0;
      });

      if (mounted) {
        setState(() {
          _availablePackages = packages;
          _isLoadingAvailable = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorAvailable = 'Failed to load packages';
          _isLoadingAvailable = false;
        });
      }
    }
  }

  bool _isBasicPackage(PackageModel package) {
    final name = package.packageName?.toLowerCase() ?? '';
    final type = package.packageType?.toLowerCase() ?? '';
    return name.contains('basic') || type.contains('basic');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context, theme, isDark),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMyPackagesTab(context, theme, isDark),
            _buildAvailablePackagesTab(context, theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
                  : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.85)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 70),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.card_membership_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Membership',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your PBAK packages',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.primary,
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.goldAccent,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, size: 18),
                    const SizedBox(width: 8),
                    const Text('My Packages'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.explore_rounded, size: 18),
                    const SizedBox(width: 8),
                    const Text('Available'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            ),
            onPressed: _fetchData,
            tooltip: 'Refresh',
          ),
        ),
      ],
    );
  }

  Widget _buildMyPackagesTab(BuildContext context, ThemeData theme, bool isDark) {
    if (_isLoadingMy) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your packages...'),
          ],
        ),
      );
    }

    if (_errorMy != null) {
      return _buildErrorState(context, theme, _errorMy!, _fetchMyPackages);
    }

    if (_myPackages.isEmpty) {
      return _buildEmptyMyPackages(context, theme, isDark);
    }

    return RefreshIndicator(
      onRefresh: _fetchMyPackages,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _myPackages.length,
        itemBuilder: (context, index) {
          return _MyPackageCard(
            package: _myPackages[index],
            isDark: isDark,
          );
        },
      ),
    );
  }

  Widget _buildAvailablePackagesTab(BuildContext context, ThemeData theme, bool isDark) {
    if (_isLoadingAvailable) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading available packages...'),
          ],
        ),
      );
    }

    if (_errorAvailable != null) {
      return _buildErrorState(context, theme, _errorAvailable!, _fetchAvailablePackages);
    }

    if (_availablePackages.isEmpty) {
      return _buildEmptyAvailablePackages(context, theme, isDark);
    }

    return RefreshIndicator(
      onRefresh: _fetchAvailablePackages,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _availablePackages.length,
        itemBuilder: (context, index) {
          final package = _availablePackages[index];
          final isBasic = _isBasicPackage(package);
          return _AvailablePackageCard(
            package: package,
            isDark: isDark,
            isActive: isBasic,
            onSubscribe: () => _showSubscriptionDialog(context, package),
          );
        },
      ),
    );
  }

  Widget _buildEmptyMyPackages(BuildContext context, ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.goldAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_membership_rounded,
                size: 64,
                color: isDark ? Colors.grey : AppTheme.darkGold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Packages',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to a package to unlock\npremium PBAK features',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _fetchMyPackages,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.explore_rounded, size: 20),
                  label: const Text('Browse'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAvailablePackages(BuildContext context, ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              'No Packages Available',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new packages',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _fetchAvailablePackages,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.deepRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 56, color: AppTheme.deepRed),
            ),
            const SizedBox(height: 24),
            Text('Oops!', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context, PackageModel package) {
    final user = ref.read(authProvider).value;
    final memberId = user?.memberId.toString();

    SecurePaymentDialog.show(
      context,
      title: 'Package Subscription',
      subtitle: package.packageName ?? 'Package',
      amount: package.price ?? 0,
      description: 'PBAK ${package.packageName ?? 'Package'} Subscription',
      reference: memberId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      packageId: package.packageId,
      memberId: memberId,
      mpesaOnly: true,
    );
  }
}

// My Package Card - Shows subscribed packages
class _MyPackageCard extends StatelessWidget {
  final PackageModel package;
  final bool isDark;

  const _MyPackageCard({required this.package, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = package.isExpired;
    final isExpiringSoon = package.isExpiringSoon;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isExpiringSoon && !isExpired
            ? Border.all(color: AppTheme.warningOrange.withOpacity(0.5), width: 2)
            : isExpired
                ? Border.all(color: AppTheme.deepRed.withOpacity(0.3), width: 1)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isExpired
                    ? [Colors.grey.shade600, Colors.grey.shade500]
                    : [AppTheme.goldAccent, AppTheme.darkGold],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isExpired ? Icons.card_membership_outlined : Icons.card_membership_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.packageName ?? 'Package',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (package.packageType != null)
                        Text(
                          package.packageType!.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                    ],
                  ),
                ),
                _StatusBadge(
                  isExpired: isExpired,
                  isExpiringSoon: isExpiringSoon,
                  status: package.status,
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Days remaining
                if (!isExpired && package.daysRemaining > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isExpiringSoon
                          ? AppTheme.warningOrange.withOpacity(0.1)
                          : AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 20,
                          color: isExpiringSoon ? AppTheme.warningOrange : AppTheme.successGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${package.daysRemaining} days remaining',
                          style: TextStyle(
                            color: isExpiringSoon ? AppTheme.warningOrange : AppTheme.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.deepRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_rounded, size: 20, color: AppTheme.deepRed),
                        SizedBox(width: 8),
                        Text(
                          'Package Expired',
                          style: TextStyle(color: AppTheme.deepRed, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Info rows
                _InfoRow(icon: Icons.payments_rounded, label: 'Price', value: package.formattedPrice, isDark: isDark),
                _InfoRow(icon: Icons.schedule_rounded, label: 'Duration', value: package.durationText, isDark: isDark),
                if (package.maxBikes != null && package.maxBikes! > 0)
                  _InfoRow(icon: Icons.two_wheeler_rounded, label: 'Max Bikes', value: '${package.maxBikes}', isDark: isDark),
                if (package.autoRenew == true)
                  _InfoRow(
                    icon: Icons.autorenew_rounded,
                    label: 'Auto Renew',
                    value: 'Enabled',
                    isDark: isDark,
                    valueColor: AppTheme.successGreen,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Available Package Card
class _AvailablePackageCard extends StatelessWidget {
  final PackageModel package;
  final bool isDark;
  final bool isActive;
  final VoidCallback onSubscribe;

  const _AvailablePackageCard({
    required this.package,
    required this.isDark,
    required this.isActive,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: isActive ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: AppTheme.goldAccent.withOpacity(0.5), width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive
                      ? [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)]
                      : [Colors.grey.shade600, Colors.grey.shade500],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.packageName ?? 'Package',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          package.durationText,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      package.formattedPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  if (package.description != null && package.description!.isNotEmpty) ...[
                    Text(
                      package.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Features
                  if (package.features != null && package.features!.isNotEmpty) ...[
                    Text(
                      'Features',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...package.features!.split(',').take(4).map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: isActive ? AppTheme.successGreen : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature.trim(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                  // Quick stats
                  Row(
                    children: [
                      if (package.maxBikes != null && package.maxBikes! > 0)
                        _QuickStat(icon: Icons.two_wheeler_rounded, value: '${package.maxBikes} bikes', isDark: isDark),
                      if (package.maxMembers != null)
                        _QuickStat(icon: Icons.people_rounded, value: '${package.maxMembers} members', isDark: isDark),
                      if (package.isRenewable == true)
                        _QuickStat(icon: Icons.autorenew_rounded, value: 'Renewable', isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Subscribe button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isActive ? onSubscribe : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${package.packageName} is coming soon!'),
                            backgroundColor: AppTheme.warningOrange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      icon: Icon(isActive ? Icons.shopping_cart_rounded : Icons.lock_clock_rounded, size: 20),
                      label: Text(isActive ? 'Subscribe Now' : 'Coming Soon'),
                      style: FilledButton.styleFrom(
                        backgroundColor: isActive ? theme.colorScheme.primary : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widgets
class _StatusBadge extends StatelessWidget {
  final bool isExpired;
  final bool isExpiringSoon;
  final String? status;

  const _StatusBadge({required this.isExpired, required this.isExpiringSoon, this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String text;

    if (isExpired) {
      bgColor = AppTheme.deepRed;
      text = 'EXPIRED';
    } else if (isExpiringSoon) {
      bgColor = AppTheme.warningOrange;
      text = 'EXPIRING';
    } else {
      bgColor = AppTheme.successGreen;
      text = 'ACTIVE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;

  const _QuickStat({required this.icon, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
