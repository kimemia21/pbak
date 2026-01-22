import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/providers/launch_provider.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/widgets/custom_text_field.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';
import 'package:pbak/widgets/terms_and_conditions_dialog.dart';
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
  LocalStorageService? _localStorage;
  bool _isFirstLaunch = false;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // Check if terms are accepted before login
      if (!_termsAccepted) {
        // Show terms dialog and prompt user to accept
        final agreed = await showTermsAndConditionsDialog(context);
        if (agreed) {
          await _localStorage?.setTermsAccepted(true);
          if (mounted) {
            setState(() => _termsAccepted = true);
          }
        } else {
          // User didn't accept terms, show message and don't proceed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Please accept the Terms & Conditions to continue.'),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.brightRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      setState(() => _isLoading = true);

      print('🚀 LoginScreen: Starting login process');
      print('📧 Email: ${_emailController.text.trim()}');

      final success = await ref.read(authProvider.notifier)
       .login(_emailController.text.trim(), _passwordController.text);

      print('✅ LoginScreen: Login result: $success');

      setState(() => _isLoading = false);

      if (success && mounted) {
        print('🎉 LoginScreen: Login successful, navigating to home');

        // Clear the registered flag after successful first login
        await _localStorage?.clearRegisteredCredentials();

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
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
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
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _showTermsDialog() async {
    final agreed = await showTermsAndConditionsDialog(context);
    if (!agreed) return;

    await _localStorage?.setTermsAccepted(true);
    if (mounted) {
      setState(() => _termsAccepted = true);
    }
  }

  Future<void> _loadSavedCredentials() async {
    _localStorage = await LocalStorageService.getInstance();

    final storage = _localStorage!;
    final firstLaunch = storage.isFirstLaunch();
    final termsAccepted = storage.isTermsAccepted();
    if (mounted) {
      setState(() {
        _isFirstLaunch = firstLaunch;
        _termsAccepted = termsAccepted;
      });
    }
    if (firstLaunch) {
      await storage.markFirstLaunchHandled();
    }

    // Check if user just registered
    if (_localStorage!.isUserRegistered()) {
      final savedEmail = _localStorage!.getRegisteredEmail();
      final savedPassword = _localStorage!.getRegisteredPassword();

      if (savedEmail != null && savedEmail.isNotEmpty) {
        setState(() {
          _emailController.text = savedEmail;

          if (savedPassword != null && savedPassword.isNotEmpty) {
            _passwordController.text = savedPassword;
          }
        });

        if (mounted) {
          // Delay the snackbar slightly to ensure UI is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Welcome! Your credentials are ready. Tap Login to continue.',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
        }
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
                          // Logo with animation container
                          Hero(
                            tag: 'app_logo',
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.asset(
                                    'assets/images/logo.jpg',
                                    width: isWeb ? 120 : 100,
                                    height: isWeb ? 120 : 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isWeb ? 40 : 32),

                          // Title with better typography
                          Text(
                            _isFirstLaunch ? 'Welcome' : 'Welcome back',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isWeb ? 36 : 32,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Login to continue to PBAK',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: isWeb ? 16 : 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isWeb ? 48 : 40),

                          // Email Field with better styling
                          CustomTextField(
                            label: 'Email',
                            hint: 'Enter your email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                            prefixIcon: Icon(
                              Icons.email_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: isWeb ? 24 : AppTheme.paddingM),

                          // Password Field
                          CustomTextField(
                            label: 'Password',
                            hint: 'Enter your password',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: Icon(
                              Icons.lock_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            ),
                          ),

                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                context.push('/forgot-password');
                              },
                              child: Text(
                                'Forgot password?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isWeb ? 16 : AppTheme.paddingM),

                          // Terms - Compact and elegant design
                          InkWell(
                            onTap: _showTermsDialog,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _termsAccepted 
                                    ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _termsAccepted
                                      ? theme.colorScheme.primary.withOpacity(0.4)
                                      : theme.colorScheme.outlineVariant.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _termsAccepted,
                                      onChanged: (v) async {
                                        if (_termsAccepted) return;
                                        await _showTermsDialog();
                                      },
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      side: BorderSide(
                                        color: _termsAccepted
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline.withOpacity(0.7),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'I agree to the Terms & Conditions',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _termsAccepted
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  if (_termsAccepted)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isWeb ? 16 : AppTheme.paddingM),

                          // Login Button with better styling
                          CustomButton(
                            text: 'Login',
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                          ),

                          SizedBox(height: isWeb ? 32 : AppTheme.paddingL),

                          // Divider with text
                          Row(
                            children: [
                              Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                            ],
                          ),

                          SizedBox(height: isWeb ? 32 : AppTheme.paddingL),

                          // Ubuntu promo / "ad" + CTA (inlined)
                          Builder(
                            builder: (context) {
                              final theme = Theme.of(context);

                              // Promo colors: red base + white glass + yellow offer.
                              const promoRed1 = Color(0xFFE11D48);
                              const promoRed2 = Color(0xFFB91C1C);
                              const promoYellow = Color(0xFFFACC15);

                              return Semantics(
                                container: true,
                                label:
                                    'Register for Ubuntu with PBAK, save 50 percent off',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              promoRed1,
                                              promoRed2,
                                            ],
                                          ),
                                        ),
                                      ),
                                      BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.10),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.18),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(isWeb ? 20 : 16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            
                                            const SizedBox(height: 14),
                                            // Watch the launch config to determine if discount is allowed
                                            Consumer(
                                              builder: (context, ref, child) {
                                                final allowDiscount = ref.watch(allowDiscountProvider);
                                                
                                                return Column(
                                                  crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                  children: [
                                                    // Show 50% off button only if discount is allowed from server
                                                  
                                                    SizedBox(
                                                      height: isWeb ? 46 : 44,
                                                      child: OutlinedButton(
                                                        onPressed: () async {
                                                          // Check terms before navigating to register
                                                          if (!_termsAccepted) {
                                                            final agreed = await showTermsAndConditionsDialog(context);
                                                            if (agreed) {
                                                              final storage = await LocalStorageService.getInstance();
                                                              await storage.setTermsAccepted(true);
                                                              if (mounted) {
                                                                setState(() => _termsAccepted = true);
                                                              }
                                                            } else {
                                                              // User didn't accept terms, don't navigate
                                                              if (context.mounted) {
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  SnackBar(
                                                                    content: const Row(
                                                                      children: [
                                                                        Icon(Icons.info_outline, color: Colors.white),
                                                                        SizedBox(width: 12),
                                                                        Expanded(
                                                                          child: Text('Please accept the Terms & Conditions to register.'),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    backgroundColor: AppTheme.brightRed,
                                                                    behavior: SnackBarBehavior.floating,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(12),
                                                                    ),
                                                                    duration: const Duration(seconds: 3),
                                                                  ),
                                                                );
                                                              }
                                                              return;
                                                            }
                                                          }
                                                          final storage =
                                                              await LocalStorageService
                                                                  .getInstance();
                                                          // No discount - set registerWithPbak to false
                                                          await storage
                                                              .setRegisterWithPbak(false);
                                                          if (context.mounted) {
                                                            context.push('/register');
                                                          }
                                                        },
                                                        style:
                                                            OutlinedButton.styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          side: BorderSide(
                                                            color: Colors.black
                                                                .withOpacity(0.55),
                                                          ),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    14),
                                                          ),
                                                          textStyle: theme
                                                              .textTheme
                                                              .titleSmall
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            letterSpacing: 0.2,
                                                          ),
                                                        ),
                                                        child: Text(
                                                            // Show different text based on discount availability
                                                           'Register for Ubuntu',
                                                            style: TextStyle(color: theme.colorScheme.primary),),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          if (isWeb) const SizedBox(height: 24),
                          
                          // Powered by TVS sponsors section
                          SizedBox(height: isWeb ? 10 : 10),
                          Column(
                            children: [
                              // Sponsors logo - full width, good height
                              Center(
                                child: Image.asset(
                                  'assets/images/sponsors.jpg',
                                  width: MediaQuery.of(context).size.width * (isWeb ? 0.9 : 0.8),
                                  height: isWeb ? 2000 : 200,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Powered by TVS badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.primary.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Powered by TVS',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}