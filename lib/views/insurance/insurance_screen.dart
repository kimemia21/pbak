import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/models/insurance_model.dart';
import 'package:pbak/models/insurance_provider_model.dart';
import 'package:pbak/services/insurance_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class InsuranceScreen extends ConsumerStatefulWidget {
  const InsuranceScreen({super.key});

  @override
  ConsumerState<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends ConsumerState<InsuranceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<InsuranceModel> _myInsurance = [];
  List<InsuranceProviderModel> _providers = [];
  bool _isLoadingInsurance = true;
  bool _isLoadingProviders = true;
  String? _errorInsurance;
  String? _errorProviders;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchMyInsurance(),
      _fetchProviders(),
    ]);
  }

  Future<void> _fetchMyInsurance() async {
    setState(() {
      _isLoadingInsurance = true;
      _errorInsurance = null;
    });

    // For now, we'll show empty state as there's no my-insurance endpoint
    // In future, this would fetch from an actual API
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _myInsurance = [];
        _isLoadingInsurance = false;
      });
    }
  }

  Future<void> _fetchProviders() async {
    setState(() {
      _isLoadingProviders = true;
      _errorProviders = null;
    });

    try {
      final insuranceService = InsuranceService();
      final providers = await insuranceService.getInsuranceProviders();
      if (mounted) {
        setState(() {
          _providers = providers;
          _isLoadingProviders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorProviders = 'Failed to load providers';
          _isLoadingProviders = false;
        });
      }
    }
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
            _buildMyInsuranceTab(context, theme, isDark),
            _buildProvidersTab(context, theme, isDark),
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
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppTheme.successGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
                  : [AppTheme.successGreen, AppTheme.successGreen.withOpacity(0.8)],
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
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Insurance',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Protect your ride',
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
            color: isDark ? const Color(0xFF1A1A1A) : AppTheme.successGreen,
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.goldAccent,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('My Insurance'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Providers'),
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

  Widget _buildMyInsuranceTab(BuildContext context, ThemeData theme, bool isDark) {
    if (_isLoadingInsurance) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your insurance...'),
          ],
        ),
      );
    }

    if (_errorInsurance != null) {
      return _buildErrorState(context, theme, _errorInsurance!, _fetchMyInsurance);
    }

    if (_myInsurance.isEmpty) {
      return _buildEmptyInsuranceState(context, theme, isDark);
    }

    return RefreshIndicator(
      onRefresh: _fetchMyInsurance,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _myInsurance.length,
        itemBuilder: (context, index) {
          return _InsuranceCard(
            insurance: _myInsurance[index],
            isDark: isDark,
          );
        },
      ),
    );
  }

  Widget _buildProvidersTab(BuildContext context, ThemeData theme, bool isDark) {
    if (_isLoadingProviders) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading insurance providers...'),
          ],
        ),
      );
    }

    if (_errorProviders != null) {
      return _buildErrorState(context, theme, _errorProviders!, _fetchProviders);
    }

    if (_providers.isEmpty) {
      return _buildEmptyProvidersState(context, theme, isDark);
    }

    return RefreshIndicator(
      onRefresh: _fetchProviders,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _providers.length,
        itemBuilder: (context, index) {
          return _ProviderCard(
            provider: _providers[index],
            isDark: isDark,
          );
        },
      ),
    );
  }

  Widget _buildEmptyInsuranceState(BuildContext context, ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.successGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 64,
                color: isDark ? Colors.grey : AppTheme.successGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Insurance',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Protect your bike with coverage from\nour trusted insurance partners',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _fetchMyInsurance,
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
                  label: const Text('View Providers'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
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

  Widget _buildEmptyProvidersState(BuildContext context, ThemeData theme, bool isDark) {
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
              child: const Icon(Icons.business_rounded, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              'No Providers Available',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Insurance providers will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _fetchProviders,
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
}

// Insurance Card Widget
class _InsuranceCard extends StatelessWidget {
  final InsuranceModel insurance;
  final bool isDark;

  const _InsuranceCard({required this.insurance, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpiring = insurance.isExpiringSoon;
    final isExpired = insurance.daysRemaining < 0;
    final formatter = NumberFormat('#,##0');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isExpiring
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isExpired
                    ? [Colors.grey.shade600, Colors.grey.shade500]
                    : [AppTheme.successGreen, AppTheme.successGreen.withOpacity(0.8)],
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
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insurance.provider,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        insurance.type,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: insurance.isActive ? Colors.white : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    insurance.status.toUpperCase(),
                    style: TextStyle(
                      color: insurance.isActive ? AppTheme.successGreen : Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
              children: [
                // Expiry warning
                if (isExpiring || isExpired)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? AppTheme.deepRed.withOpacity(0.1)
                          : AppTheme.warningOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 20,
                          color: isExpired ? AppTheme.deepRed : AppTheme.warningOrange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isExpired
                              ? 'Insurance Expired'
                              : 'Expires in ${insurance.daysRemaining} days',
                          style: TextStyle(
                            color: isExpired ? AppTheme.deepRed : AppTheme.warningOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Details
                _DetailRow(label: 'Policy Number', value: insurance.policyNumber),
                _DetailRow(label: 'Premium', value: 'KES ${formatter.format(insurance.price)}'),
                _DetailRow(
                  label: 'Expires',
                  value: DateFormat('MMM dd, yyyy').format(insurance.endDate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Provider Card Widget
class _ProviderCard extends StatelessWidget {
  final InsuranceProviderModel provider;
  final bool isDark;

  const _ProviderCard({required this.provider, required this.isDark});

  Future<void> _launchUrl(String url) async {
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }
    final uri = Uri.parse(formattedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo/Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: provider.logoUrl != null && provider.logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            provider.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.business_rounded,
                              color: AppTheme.successGreen,
                              size: 28,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.business_rounded,
                          color: AppTheme.successGreen,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              provider.providerName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (provider.isVerified)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: AppTheme.successGreen,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      if (provider.city != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              provider.city!,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rating & Contact
          if (provider.rating != null || provider.hasContactInfo)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (provider.rating != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.goldAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: AppTheme.darkGold),
                          const SizedBox(width: 4),
                          Text(
                            provider.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.darkGold,
                            ),
                          ),
                          if (provider.totalReviews != null) ...[
                            Text(
                              ' (${provider.totalReviews})',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  // Contact buttons
                  if (provider.phone != null)
                    _ContactButton(
                      icon: Icons.phone_rounded,
                      onTap: () => _makePhoneCall(provider.phone!),
                      isDark: isDark,
                    ),
                  if (provider.email != null) ...[
                    const SizedBox(width: 8),
                    _ContactButton(
                      icon: Icons.email_rounded,
                      onTap: () => _sendEmail(provider.email!),
                      isDark: isDark,
                    ),
                  ],
                  if (provider.website != null && provider.website!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _ContactButton(
                      icon: Icons.language_rounded,
                      onTap: () => _launchUrl(provider.website!),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          // Address if available
          if (provider.fullAddress.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.fullAddress,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _ContactButton({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppTheme.successGreen),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
