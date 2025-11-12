import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/utils/constants.dart';
import 'package:pbak/widgets/custom_text_field.dart';
import 'package:pbak/widgets/custom_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _licenseController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  DateTime? _selectedDate;
  String _selectedRegion = AppConstants.regions.first;
  String _selectedRole = AppConstants.userRoles.first;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _licenseController.dispose();
    _emergencyContactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your date of birth'),
            backgroundColor: AppTheme.brightRed,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'idNumber': _idNumberController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'dateOfBirth': _selectedDate!.toIso8601String(),
        'region': _selectedRegion,
        'role': _selectedRole,
      };

      final success = await ref.read(authProvider.notifier).register(userData);

      setState(() => _isLoading = false);

      if (success && mounted) {
        context.go('/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Please try again.'),
            backgroundColor: AppTheme.brightRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: AppTheme.paddingS),
                Text(
                  'Join the PBAK Kenya community',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.paddingL),
                
                // Personal Information
                Text(
                  'Personal Information',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                CustomTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  validator: (val) => Validators.validateRequired(val, 'Full name'),
                  textCapitalization: TextCapitalization.words,
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  prefixIcon: const Icon(Icons.email_rounded),
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                CustomTextField(
                  label: 'Phone Number',
                  hint: '+254712345678',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  prefixIcon: const Icon(Icons.phone_rounded),
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                CustomTextField(
                  label: 'ID Number',
                  hint: 'Enter your ID number',
                  controller: _idNumberController,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateIdNumber,
                  prefixIcon: const Icon(Icons.badge_rounded),
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                CustomTextField(
                  label: 'Date of Birth',
                  hint: 'Select date',
                  readOnly: true,
                  onTap: _selectDate,
                  controller: TextEditingController(
                    text: _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : '',
                  ),
                  validator: (val) => Validators.validateRequired(val, 'Date of birth'),
                  prefixIcon: const Icon(Icons.calendar_today_rounded),
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                // Region Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: const InputDecoration(
                    labelText: 'Region',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                  items: AppConstants.regions.map((region) {
                    return DropdownMenuItem(
                      value: region,
                      child: Text(region),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRegion = value);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.paddingL),
                
                // License Information
                Text(
                  'License & Emergency',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                CustomTextField(
                  label: 'License Number',
                  hint: 'Enter your license number',
                  controller: _licenseController,
                  validator: (val) => Validators.validateRequired(val, 'License number'),
                  prefixIcon: const Icon(Icons.card_membership_rounded),
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                CustomTextField(
                  label: 'Emergency Contact',
                  hint: '+254722334455',
                  controller: _emergencyContactController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  prefixIcon: const Icon(Icons.emergency_rounded),
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.work_rounded),
                  ),
                  items: AppConstants.userRoles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.paddingL),
                
                // Password
                Text(
                  'Security',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                CustomTextField(
                  label: 'Password',
                  hint: 'Create a password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: (val) => Validators.validateConfirmPassword(
                    val,
                    _passwordController.text,
                  ),
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.paddingXL),
                
                // Register Button
                CustomButton(
                  text: 'Register',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Login',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
