import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/widgets/custom_text_field.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';
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

  Future<void> _loadSavedCredentials() async {
    _localStorage = await LocalStorageService.getInstance();

    final storage = _localStorage!;
    final firstLaunch = storage.isFirstLaunch();
    if (mounted) {
      setState(() {
        _isFirstLaunch = firstLaunch;
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
                                // TODO: Implement forgot password
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Forgot password feature coming soon'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
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

                          SizedBox(height: isWeb ? 32 : AppTheme.paddingL),

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
                                            Column(
                                              crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                              children: [
                                                SizedBox(
                                                  height: isWeb ? 54 : 52,
                                                  child: FilledButton.icon(
                                                    onPressed: () async {
                                                      final storage =
                                                          await LocalStorageService
                                                              .getInstance();
                                                      await storage
                                                          .setRegisterWithPbak(true);
                                                      if (context.mounted) {
                                                        context.push('/register');
                                                      }
                                                    },
                                                    icon: const Icon(
                                                        Icons.local_offer_rounded),
                                                    label: const Text(
                                                      '50% when you register for Ubuntu with PBAK',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    style:
                                                        FilledButton.styleFrom(
                                                      backgroundColor: promoYellow,
                                                      foregroundColor:
                                                          const Color(0xFF111827),
                                                      elevation: 2,
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
                                                            FontWeight.w900,
                                                        letterSpacing: 0.1,
                                                        height: 1.1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                SizedBox(
                                                  height: isWeb ? 46 : 44,
                                                  child: OutlinedButton(
                                                    onPressed: () async {
                                                      final storage =
                                                          await LocalStorageService
                                                              .getInstance();
                                                      await storage
                                                          .setRegisterWithPbak(false);
                                                      if (context.mounted) {
                                                        context.push('/register');
                                                      }
                                                    },
                                                    style:
                                                        OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.white,
                                                      side: BorderSide(
                                                        color: Colors.white
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
                                                    child:  Text(
                                    
                                                        'Register for Ubuntu',
                                                        style:TextStyle(color:theme.colorScheme.primary),),
                                                  ),
                                                ),
                                              ],
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