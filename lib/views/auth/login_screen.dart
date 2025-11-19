import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/widgets/custom_text_field.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      print('🚀 LoginScreen: Starting login process');
      print('📧 Email: ${_emailController.text.trim()}');

      final success = await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      print('✅ LoginScreen: Login result: $success');

      setState(() => _isLoading = false);

      if (success && mounted) {
        print('🎉 LoginScreen: Login successful, navigating to home');
        context.go('/');
      } else if (mounted) {
        print('❌ LoginScreen: Login failed, showing error');
        
        // Get error message from provider state
        final authState = ref.read(authProvider);
        String errorMessage = 'Login failed. Please try again.';
        
        authState.whenOrNull(
          error: (error, _) {
            errorMessage = error.toString().replaceAll('Exception: ', '');
          },
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.brightRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }



@override
  void initState() {
    // TODO: implement initState
    super.initState();
    _emailController.text = "evahnce@live.com";
    _passwordController.text = "Abc@1234";}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: size.height * 0.08),
                
                // Logo/Icon
                
                SvgPicture.asset(
  'assets/images/pbak-logo.svg',
  width: 100,
  height: 100,
  colorFilter: null
),

                const SizedBox(height: AppTheme.paddingM),
                
                // Title
                Text(
                  'Welcome Back',
                  style: theme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.paddingS),
                Text(
                  'Sign in to continue to PBAK Kenya',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.paddingXL),
                
                // Email Field
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  prefixIcon: const Icon(Icons.email_rounded),
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                // Password Field
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
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
                const SizedBox(height: AppTheme.paddingL),
                
                // Login Button
                CustomButton(
                  text: 'Login',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text(
                        'Register',
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
