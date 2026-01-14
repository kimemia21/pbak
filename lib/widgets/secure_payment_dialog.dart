import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/providers/payment_provider.dart';
import 'package:pbak/utils/validators.dart';

/// Country code data for phone number input
class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

/// Common country codes for East Africa and international
const List<CountryCode> _countryCodes = [
  CountryCode(name: 'Kenya', code: 'KE', dialCode: '+254', flag: '🇰🇪'),
  CountryCode(name: 'Uganda', code: 'UG', dialCode: '+256', flag: '🇺🇬'),
  CountryCode(name: 'Tanzania', code: 'TZ', dialCode: '+255', flag: '🇹🇿'),
  CountryCode(name: 'Rwanda', code: 'RW', dialCode: '+250', flag: '🇷🇼'),
  CountryCode(name: 'Ethiopia', code: 'ET', dialCode: '+251', flag: '🇪🇹'),
  CountryCode(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
  CountryCode(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
  CountryCode(
    name: 'United Kingdom',
    code: 'GB',
    dialCode: '+44',
    flag: '🇬🇧',
  ),
  CountryCode(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
  CountryCode(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
];

/// Payment dialog phase
enum _DialogPhase {
  phoneInput,
  initiating,
  waitingForUser,
  processing,
  success,
  failed,
  timeout,
}

/// Unified secure payment dialog - handles phone input AND status in one flow
class SecurePaymentDialog extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;
  final double? amount;
  final String? description;
  final String? initialPhone;
  final String reference;
  final bool mpesaOnly;

  // Optional combined payment payload fields for /pay
  final int? eventId;
  final int? packageId;
  final String? memberId;
  final List<int>? eventProductIds;

  const SecurePaymentDialog({
    super.key,
    this.title = 'Secure Payment',
    this.subtitle,
    this.amount,
    this.description,
    this.initialPhone,
    required this.reference,
    this.mpesaOnly = true,
    this.eventId,
    this.packageId,
    this.memberId,
    this.eventProductIds,
  });

  /// Shows the dialog and returns true if payment succeeded
  static Future<bool?> show(
    BuildContext context, {
    required String reference,
    String title = 'Secure Payment',
    String? subtitle,
    double? amount,
    String? description,
    String? initialPhone,
    bool mpesaOnly = true,
    int? eventId,
    int? packageId,
    String? memberId,
    List<int>? eventProductIds,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return SecurePaymentDialog(
          title: title,
          subtitle: subtitle,
          amount: amount,
          description: description,
          initialPhone: initialPhone,
          reference: reference,
          mpesaOnly: mpesaOnly,
          eventId: eventId,
          packageId: packageId,
          memberId: memberId,
          eventProductIds: eventProductIds,
        );
      },
    );
  }

  @override
  ConsumerState<SecurePaymentDialog> createState() =>
      _SecurePaymentDialogState();
}

class _SecurePaymentDialogState extends ConsumerState<SecurePaymentDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  CountryCode _selectedCountry = _countryCodes.first;
  _DialogPhase _phase = _DialogPhase.phoneInput;
  String? _errorMessage;

  Timer? _countdownTimer;
  int _secondsRemaining = 60;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mpesaPaymentProvider.notifier).reset();
      _phoneFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatPhoneForApi(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (_selectedCountry.code == 'KE') {
      if (cleaned.startsWith('0')) {
        cleaned = '254${cleaned.substring(1)}';
      } else if (!cleaned.startsWith('254')) {
        cleaned = '254$cleaned';
      }
    } else {
      final dialDigits = _selectedCountry.dialCode.replaceAll('+', '');
      if (!cleaned.startsWith(dialDigits)) {
        cleaned = '$dialDigits$cleaned';
      }
    }
    return cleaned;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (widget.mpesaOnly || _selectedCountry.code == 'KE') {
      return Validators.validateMpesaPhone(value);
    }
    return null;
  }

  Future<void> _initiatePayment() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _phase = _DialogPhase.initiating);

    final phone = _formatPhoneForApi(_phoneController.text.trim());
    final amount = widget.amount ?? 1;
    final description = widget.description ?? 'PBAK Payment';

    final success = await ref
        .read(mpesaPaymentProvider.notifier)
        .initiatePayment(
          mpesaNo: phone,
          reference: widget.reference,
          amount: amount,
          description: description,
          eventId: widget.eventId,
          packageId: widget.packageId,
          memberId: widget.memberId,
          eventProductIds: widget.eventProductIds,
        );

    if (!mounted) return;

    if (success) {
      setState(() => _phase = _DialogPhase.waitingForUser);
      _startPolling();
    } else {
      final error = ref.read(mpesaPaymentProvider).error;
      setState(() {
        _phase = _DialogPhase.failed;
        _errorMessage = error ?? 'Failed to initiate payment';
      });
    }
  }

  void _startPolling() {
    _secondsRemaining = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining = (60 - timer.tick).clamp(0, 60);
        if (_secondsRemaining <= 45 && _phase == _DialogPhase.waitingForUser) {
          _phase = _DialogPhase.processing;
        }
      });
    });

    ref
        .read(mpesaPaymentProvider.notifier)
        .pollStatus(
          initialDelaySeconds: 3,
          totalTimeoutSeconds: 60,
          onTick: (remaining) {
            if (mounted) setState(() => _secondsRemaining = remaining);
          },
        )
        .then((_) {
          if (!mounted) return;
          final state = ref.read(mpesaPaymentProvider);
          setState(() {
            if (state.isCompleted) {
              _phase = _DialogPhase.success;
            } else if (state.isFailed) {
              _phase = _DialogPhase.failed;
              _errorMessage = state.error ?? 'Payment failed';
            } else if (state.isTimeout) {
              _phase = _DialogPhase.timeout;
            }
          });
          _countdownTimer?.cancel();
        });
  }

  void _retry() {
    setState(() {
      _phase = _DialogPhase.phoneInput;
      _errorMessage = null;
    });
    ref.read(mpesaPaymentProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(theme),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: _buildContent(theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    Color headerColor = const Color(0xFF4CAF50);
    IconData headerIcon = Icons.payment_rounded;
    String headerTitle = 'Secure Payment';

    if (_phase == _DialogPhase.failed) {
      headerColor = const Color(0xFFE53935);
      headerIcon = Icons.error_outline_rounded;
      headerTitle = 'Payment Failed';
    } else if (_phase == _DialogPhase.timeout) {
      headerColor = const Color(0xFFFF9800);
      headerIcon = Icons.timer_off_rounded;
      headerTitle = 'Timeout';
    } else if (_phase == _DialogPhase.success) {
      headerIcon = Icons.check_circle_outline_rounded;
      headerTitle = 'Payment Successful';
    } else if (_phase == _DialogPhase.waitingForUser ||
        _phase == _DialogPhase.processing) {
      headerIcon = Icons.phone_android_rounded;
      headerTitle = 'Complete Payment';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [headerColor, headerColor.withOpacity(0.85)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(headerIcon, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headerTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Secured by M-Pesa',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_phase == _DialogPhase.phoneInput)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (_phase) {
      case _DialogPhase.phoneInput:
        return _buildPhoneInputContent(theme);
      case _DialogPhase.initiating:
        return _buildInitiatingContent(theme);
      case _DialogPhase.waitingForUser:
      case _DialogPhase.processing:
        return _buildWaitingContent(theme);
      case _DialogPhase.success:
        return _buildSuccessContent(theme);
      case _DialogPhase.failed:
      case _DialogPhase.timeout:
        return _buildFailedContent(theme);
    }
  }

  Widget _buildPhoneInputContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Display
            if (widget.amount != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4CAF50).withOpacity(0.08),
                      const Color(0xFF4CAF50).withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Amount',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'KES',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.amount!.toStringAsFixed(2),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2E7D32),
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Phone Input
            Text(
              'M-Pesa Phone Number',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🇰🇪', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          '+254',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: '712 345 678',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: _validatePhone,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'You will receive an M-Pesa prompt on this number',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Pay Button
            FilledButton(
              onPressed: _initiatePayment,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Pay KES ${widget.amount?.toStringAsFixed(0) ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitiatingContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Color(0xFF4CAF50)),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Initiating Payment',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connecting to M-Pesa...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingContent(ThemeData theme) {
    final isProcessing = _phase == _DialogPhase.processing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF4CAF50).withOpacity(0.15),
                        const Color(0xFF4CAF50).withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isProcessing
                        ? Icons.sync_rounded
                        : Icons.phone_android_rounded,
                    color: const Color(0xFF4CAF50),
                    size: 56,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            isProcessing ? 'Processing Payment' : 'Check Your Phone',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isProcessing
                  ? 'Please wait while we confirm your payment'
                  : 'Enter your M-Pesa PIN when prompted',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    value: _secondsRemaining / 60,
                    strokeWidth: 3,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(
                      _secondsRemaining > 15
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF9800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$_secondsRemaining seconds',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              ref.read(mpesaPaymentProvider.notifier).cancel();
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 72,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Successful!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment has been confirmed.\nThank you!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedContent(ThemeData theme) {
    final isTimeout = _phase == _DialogPhase.timeout;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  (isTimeout
                          ? const Color(0xFFFF9800)
                          : const Color(0xFFE53935))
                      .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTimeout ? Icons.timer_off : Icons.error,
              color: isTimeout
                  ? const Color(0xFFFF9800)
                  : const Color(0xFFE53935),
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isTimeout ? 'Taking Too Long' : 'Payment Failed',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTimeout
                  ? const Color(0xFFFF9800)
                  : const Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isTimeout
                ? 'We haven\'t received confirmation yet.\nCheck your M-Pesa messages.'
                : (_errorMessage ?? 'Payment could not be completed.'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
