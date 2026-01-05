import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/package_model.dart';
import 'package:pbak/providers/package_provider.dart';
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

  PackageModel? _selectedPackage;
  final _phoneController = TextEditingController();
  final _memberIdController = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.memberId != null) {
      _memberIdController.text = widget.memberId.toString();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _memberIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (!_alreadyPaidMember && _selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a package to subscribe to')),
      );
      return;
    }

    setState(() => _submitting = true);

    // Payment endpoints are not ready yet.
    // Simulate a successful flow.
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _submitting = false);

    final amount = _selectedPackage?.price ?? 0;
    final formattedAmount = NumberFormat('#,###.00').format(amount);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Payment Setup'),
          content: Text(
            _alreadyPaidMember
                ? 'Saved member ID ${_memberIdController.text.trim()} as a paid member.'
                : 'Simulated M-Pesa prompt to ${_phoneController.text.trim()} for KES $formattedAmount.\n\n(Endpoints not ready yet — UI only)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packagesAsync = ref.watch(packagesProvider);

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
                      'Select a package then pay via M-Pesa (simulated for now).',
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
                            'You should pay ${_selectedPackage!.formattedPrice} for ${_selectedPackage!.packageName ?? 'this package'}.',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                ],

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'M-Pesa Phone Number',
                    hintText: '+254712345678',
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
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_submitting ? 'Processing…' : 'Finish'),
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
