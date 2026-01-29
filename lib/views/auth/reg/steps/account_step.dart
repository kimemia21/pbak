import 'package:flutter/material.dart';

import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/widgets/premium_ui.dart';
import 'package:pbak/utils/validators.dart';

class AccountStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController alternativePhoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  final Widget Function({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required IconData icon,
    bool obscureText,
    Widget? suffixIcon,
    TextCapitalization textCapitalization,
  }) buildTextField;

  const AccountStep({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.phoneController,
    required this.alternativePhoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.buildTextField,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your login credentials',
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.35,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            PremiumCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTextField(
                    label: 'Email Address',
                    hint: 'your.email@example.com',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    icon: Icons.email_outlined,
                    obscureText: false,
                    suffixIcon: null,
                    textCapitalization: TextCapitalization.none,
                  ),
                  const SizedBox(height: 24),
                  buildTextField(
                    label: 'Phone Number',
                    hint: '+254712345678',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                    icon: Icons.phone_outlined,
                    obscureText: false,
                    suffixIcon: null,
                    textCapitalization: TextCapitalization.none,
                  ),
                  const SizedBox(height: 24),
                  buildTextField(
                    label: 'Alternative Phone (optional)',
                    hint: '+254722334455',
                    controller: alternativePhoneController,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validateOptionalPhone,
                    icon: Icons.phone_android_outlined,
                    obscureText: false,
                    suffixIcon: null,
                    textCapitalization: TextCapitalization.none,
                  ),
                  const SizedBox(height: 24),
                  buildTextField(
                    label: 'Password',
                    hint: 'Create a strong password',
                    controller: passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    validator: Validators.validatePassword,
                    icon: Icons.lock_outlined,
                    obscureText: obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.mediumGrey,
                      ),
                      onPressed: onTogglePassword,
                    ),
                    textCapitalization: TextCapitalization.none,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      '• At least 8 characters\n'
                      '• Include uppercase and lowercase\n'
                      '• Include numbers',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  buildTextField(
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    controller: confirmPasswordController,
                    keyboardType: TextInputType.visiblePassword,
                    validator: (val) => Validators.validateConfirmPassword(
                      val,
                      passwordController.text,
                    ),
                    icon: Icons.lock_outlined,
                    obscureText: obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.mediumGrey,
                      ),
                      onPressed: onToggleConfirmPassword,
                    ),
                    textCapitalization: TextCapitalization.none,
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
