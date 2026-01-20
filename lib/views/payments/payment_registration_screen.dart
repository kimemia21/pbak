import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/package_model.dart';
import 'package:pbak/providers/package_provider.dart';
import 'package:pbak/providers/payment_provider.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/validators.dart';

class PaymentRegistrationScreen extends ConsumerStatefulWidget {
  final int? memberId;

  const PaymentRegistrationScreen({super.key, this.memberId});

  @override
  ConsumerState<PaymentRegistrationScreen> createState() => _PaymentRegistrationScreenState();
}

class _PaymentRegistrationScreenState extends ConsumerState<PaymentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _alreadyPaidMember = false;
  bool _showPackageSelection = false;

  PackageModel? _selectedPackage;
  final _phoneController = TextEditingController();
  final _memberIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.memberId != null) {
      _memberIdController.text = widget.memberId.toString();
    }
    // Reset payment state when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mpesaPaymentProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _memberIdController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    // Remove any spaces, dashes, or plus signs
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    
    // If starts with 0, replace with 254
    if (cleaned.startsWith('0')) {
      cleaned = '254${cleaned.substring(1)}';
    }
    // If starts with +254, remove the +
    if (cleaned.startsWith('+254')) {
      cleaned = cleaned.substring(1);
    }
    
    return cleaned;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_alreadyPaidMember) {
      // Handle already paid member flow
      await _handleAlreadyPaidMember();
      return;
    }

    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a package to subscribe to')),
      );
      return;
    }

    // Initiate M-Pesa payment
    final mpesaNotifier = ref.read(mpesaPaymentProvider.notifier);
    final phone = _formatPhoneNumber(_phoneController.text.trim());
    final reference = _memberIdController.text.trim().isNotEmpty 
        ? _memberIdController.text.trim() 
        : DateTime.now().millisecondsSinceEpoch.toString();
    final amount = _selectedPackage!.price ?? 1;
    final description = 'PBAK ${_selectedPackage!.packageName ?? 'Package'} Subscription';

    final success = await mpesaNotifier.initiatePayment(
      mpesaNo: phone,
      reference: reference,
      amount: amount,
      description: description,
    );

    if (!mounted) return;

    if (success) {
      // Show payment confirmation dialog
      _showPaymentConfirmationDialog();
    } else {
      final error = ref.read(mpesaPaymentProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to initiate payment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAlreadyPaidMember() async {
    // For already paid members, just save the member ID
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Member Verified'),
          content: Text(
            'Member ID ${_memberIdController.text.trim()} has been saved.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentConfirmationDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _MpesaPaymentDialog(),
    ).then((_) {
      // Check final status when dialog closes
      final state = ref.read(mpesaPaymentProvider);
      if (state.isCompleted && mounted) {
        Navigator.of(context).pop(); // Close the registration screen
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packagesAsync = ref.watch(packagesProvider);
    final mpesaState = ref.watch(mpesaPaymentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Payment Registration',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select a package then pay via M-Pesa.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.paddingL),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Already a paid member?'),
                subtitle: const Text('If yes, just enter your member ID number (no package selection).'),
                value: _alreadyPaidMember,
                onChanged: (v) {
                  setState(() {
                    _alreadyPaidMember = v;
                    if (v) {
                      _selectedPackage = null;
                      _phoneController.clear();
                    }
                  });
                },
              ),

              const SizedBox(height: AppTheme.paddingM),
              TextFormField(
                controller: _memberIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Member ID Number',
                  hintText: 'e.g. 12345',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
                validator: (v) {
                  if (_alreadyPaidMember) {
                    return Validators.validateRequired(v, 'Member ID Number');
                  }
                  // If not already-paid, member id is optional.
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.paddingL),

              if (!_alreadyPaidMember) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Subscribe to a package'),
                  subtitle: const Text('Toggle on to select and pay for a membership package.'),
                  value: _showPackageSelection,
                  activeColor: Colors.black,
                  activeTrackColor: Colors.black.withOpacity(0.5),
                  inactiveThumbColor: Colors.black,
                  inactiveTrackColor: Colors.black.withOpacity(0.3),
                  onChanged: (v) {
                    setState(() {
                      _showPackageSelection = v;
                      if (!v) {
                        _selectedPackage = null;
                      }
                    });
                  },
                ),

                if (_showPackageSelection) ...[
                  const SizedBox(height: AppTheme.paddingM),
                  Text(
                    'Select Package',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  packagesAsync.when(
                  data: (packages) {
                    if (packages.isEmpty) {
                      return const Text('No packages available right now.');
                    }

                    return DropdownButtonFormField<int>(
                      value: _selectedPackage?.packageId,
                      decoration: const InputDecoration(
                        labelText: 'Package',
                        prefixIcon: Icon(Icons.inventory_2_rounded),
                      ),
                      items: packages
                          .where((p) => p.packageId != null)
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p.packageId,
                              child: Text('${p.packageName ?? 'Package'} • ${p.formattedPrice} / ${p.durationText}'),
                            ),
                          )
                          .toList(),
                      onChanged: (packageId) {
                        setState(() {
                          _selectedPackage = packages.firstWhere(
                            (p) => p.packageId == packageId,
                            orElse: () => packages.first,
                          );
                        });
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Failed to load packages: $e'),
                ),

                const SizedBox(height: AppTheme.paddingM),

                if (_selectedPackage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingM),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_rounded, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You will pay ${_selectedPackage!.formattedPrice} for ${_selectedPackage!.packageName ?? 'this package'}.',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                ],

                ], // end of _showPackageSelection

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'M-Pesa Phone Number',
                    hintText: '0712345678 or 254712345678',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                  ),
                  validator: (v) {
                    if (_alreadyPaidMember) return null;
                    return Validators.validatePhone(v);
                  },
                ),
              ],

              const SizedBox(height: AppTheme.paddingXL),

              ElevatedButton.icon(
                onPressed: mpesaState.isLoading ? null : _submit,
                icon: mpesaState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payment_rounded),
                label: Text(mpesaState.isLoading ? 'Initiating Payment…' : 'Pay with M-Pesa'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// M-Pesa Payment Confirmation Dialog
/// Shows STK push status and polls for payment confirmation
class _MpesaPaymentDialog extends ConsumerStatefulWidget {
  const _MpesaPaymentDialog();

  @override
  ConsumerState<_MpesaPaymentDialog> createState() => _MpesaPaymentDialogState();
}

class _MpesaPaymentDialogState extends ConsumerState<_MpesaPaymentDialog> {
  bool _isPolling = false;
  bool _hasStartedPolling = false;

  @override
  void initState() {
    super.initState();
    // Start polling after a short delay to allow user to enter PIN
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _startPolling();
      }
    });
  }

  Future<void> _startPolling() async {
    if (_isPolling || _hasStartedPolling) return;
    
    setState(() {
      _isPolling = true;
      _hasStartedPolling = true;
    });

    await ref.read(mpesaPaymentProvider.notifier).pollStatus(
      initialDelaySeconds: 3,
      totalTimeoutSeconds: 60,
    );

    if (mounted) {
      setState(() => _isPolling = false);
    }
  }

  Future<void> _checkStatusManually() async {
    setState(() => _isPolling = true);
    await ref.read(mpesaPaymentProvider.notifier).checkStatus();
    if (mounted) {
      setState(() => _isPolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mpesaState = ref.watch(mpesaPaymentProvider);

    return AlertDialog(
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.jpg',
            width: 32,
            height: 32,
            errorBuilder: (_, __, ___) => const Icon(Icons.payment, size: 32),
          ),
          const SizedBox(width: 12),
          const Text('M-Pesa Payment'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Icon
            _buildStatusIcon(mpesaState),
            const SizedBox(height: 16),
            
            // Status Message
            _buildStatusMessage(mpesaState, theme),
            const SizedBox(height: 16),

            // Payment ID (for reference)
            if (mpesaState.payId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, 
                      size: 20, 
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction ID',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            mpesaState.payId!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Loading indicator while polling
            if (_isPolling || mpesaState.isPolling) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Checking payment status...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Close/Cancel button
        if (!mpesaState.isCompleted)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(mpesaState.isFailed ? 'Close' : 'Cancel'),
          ),
        
        // Check Status button (when not polling)
        if (!_isPolling && !mpesaState.isPolling && !mpesaState.isCompleted && !mpesaState.isFailed)
          TextButton(
            onPressed: _checkStatusManually,
            child: const Text('Check Status'),
          ),

        // Retry button (when failed)
        if (mpesaState.isFailed)
          ElevatedButton(
            onPressed: () {
              ref.read(mpesaPaymentProvider.notifier).reset();
              Navigator.of(context).pop();
            },
            child: const Text('Try Again'),
          ),

        // Done button (when completed)
        if (mpesaState.isCompleted)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
      ],
    );
  }

  Widget _buildStatusIcon(MpesaPaymentState state) {
    if (state.isCompleted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64,
        ),
      );
    }

    if (state.isFailed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error,
          color: Colors.red,
          size: 64,
        ),
      );
    }

    // Pending/Processing state
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.phone_android,
        color: Colors.orange,
        size: 64,
      ),
    );
  }

  Widget _buildStatusMessage(MpesaPaymentState state, ThemeData theme) {
    String title;
    String subtitle;
    Color titleColor;

    if (state.isCompleted) {
      title = 'Payment Successful!';
      subtitle = 'Your M-Pesa payment has been confirmed.';
      titleColor = Colors.green;
    } else if (state.isFailed) {
      title = 'Payment Failed';
      subtitle = state.error ?? state.statusResponse?.message ?? 'The payment was not completed.';
      titleColor = Colors.red;
    } else {
      title = 'Confirm on Your Phone';
      subtitle = 'Please enter your M-Pesa PIN on your phone to complete the payment.';
      titleColor = Colors.orange;
    }

    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
