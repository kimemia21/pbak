import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/services/auth_service.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/widgets/custom_text_field.dart';
import 'package:pbak/widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await AuthService().forgotPassword(_emailController.text.trim());

      setState(() => _isLoading = false);

      if (success && mounted) {
        // Navigate to OTP verification screen
        context.push('/verify-otp', extra: {'email': _emailController.text.trim()});
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to send OTP. Please check your email and try again.'),
                ),
              ],
            ),
            backgroundColor: AppTheme.brightRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWeb ? 48 : AppTheme.paddingL),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWeb ? 480 : double.infinity,
                ),
                child: Card(
                  elevation: isWeb ? 8 : 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isWeb ? 24 : 0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isWeb ? 48 : 0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_reset_rounded,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),

                          SizedBox(height: isWeb ? 32 : 24),

                          // Title
                          Text(
                            'Forgot Password?',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isWeb ? 28 : 24,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter your email address and we\'ll send you a verification code.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: isWeb ? 40 : 32),

                          // Email Field
                          CustomTextField(
                            label: 'Email',
                            hint: 'Enter your registered email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                            prefixIcon: Icon(
                              Icons.email_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),

                          SizedBox(height: isWeb ? 32 : 24),

                          // Send OTP Button
                          CustomButton(
                            text: 'Send Code',
                            onPressed: _handleSendOTP,
                            isLoading: _isLoading,
                          ),

                          SizedBox(height: isWeb ? 24 : 16),

                          // Back to login link
                          TextButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              'Back to Login',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
