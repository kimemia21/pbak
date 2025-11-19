import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/widgets/custom_text_field.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:pbak/services/comms/registration_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationService = RegistrationService();
  final _imagePicker = ImagePicker();

  // Page controller for steps
  final _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternativePhoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _drivingLicenseController = TextEditingController();
  final _roadNameController = TextEditingController();

  // State
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  DateTime? _dateOfBirth;
  String? _selectedGender;

  // API Data
  List<Map<String, dynamic>> _clubs = [];
  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _towns = [];
  List<Map<String, dynamic>> _estates = [];
  List<Map<String, dynamic>> _occupations = [];

  // Selected IDs
  int? _selectedClubId;
  int? _selectedRegionId;
  int? _selectedTownId;
  int? _selectedEstateId;
  int? _selectedOccupationId;

  // Images
  File? _dlPicFile;
  File? _passportPhotoFile;
  int? _dlPicId;
  int? _passportPhotoId;

  @override
  void initState() {
    super.initState();
    _registrationService.initialize();
    _emailController.text = 'sample@gmail.com';
    _phoneController.text = '+254712345678';
    _alternativePhoneController.text = '+254722334455';
    _passwordController.text = 'Password123!';
    _confirmPasswordController.text = 'Password123!';
    // _registrationService.fetchClubs();
   _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _alternativePhoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nationalIdController.dispose();
    _drivingLicenseController.dispose();
    _roadNameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _registrationService.fetchClubs(),
        _registrationService.fetchRegions(),
        _registrationService.fetchOccupations(),
      ]);

      if (mounted) {
        setState(() {
          _clubs = results[0];
          _regions = results[1];
          _occupations = results[2];
          _isLoading = false;
        });
        
        // Debug logs
        print('Clubs loaded: ${_clubs.length}');
        print('Clubs data: $_clubs');
        print('Regions loaded: ${_regions.length}');
        print('Occupations loaded: ${_occupations.length}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load data: $e');
        print('Error loading data: $e');
      }
    }
  }

  Future<void> _loadTowns(int regionId) async {
    final towns = await _registrationService.fetchTowns(regionId.toString());
    if (mounted) {
      setState(() {
        _towns = towns;
        _selectedTownId = null;
        _estates = [];
        _selectedEstateId = null;
      });
    }
  }

  Future<void> _loadEstates(int regionId, int townId) async {
    final estates = await _registrationService.fetchEstates(
      regionId.toString(),
      townId.toString(),
    );
    if (mounted) {
      setState(() {
        _estates = estates;
        _selectedEstateId = null;
      });
    }
  }

  Future<void> _pickImage(bool isDlPic) async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        if (isDlPic) {
          _dlPicFile = File(pickedFile.path);
          _dlPicId = null; // Reset ID when new file selected
        } else {
          _passportPhotoFile = File(pickedFile.path);
          _passportPhotoId = null; // Reset ID when new file selected
        }
      });

      // Upload immediately after selection
      await _uploadImageImmediately(pickedFile.path, isDlPic);
    }
  }

  Future<void> _uploadImageImmediately(String filePath, bool isDlPic) async {
    if (!mounted) return;

    // Show loading state
    setState(() => _isLoading = true);

    try {
      final imageType = isDlPic ? 'dl' : 'passport';
      final uploadedId = await _registrationService.uploadImage(
        filePath,
        imageType,
      );

      if (mounted) {
        if (uploadedId != null) {
          setState(() {
            if (isDlPic) {
              _dlPicId = uploadedId;
            } else {
              _passportPhotoId = uploadedId;
            }
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isDlPic
                    ? 'Driving license uploaded successfully!'
                    : 'Passport photo uploaded successfully!',
              ),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          setState(() => _isLoading = false);
          _showError('Failed to upload image. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error uploading image: $e');
      }
    }
  }

  Future<bool> _uploadImages() async {
    // Check if images are already uploaded (have IDs)
    if (_dlPicFile != null && _dlPicId == null) {
      _showError('Driving license upload incomplete. Please re-select the image.');
      return false;
    }

    if (_passportPhotoFile != null && _passportPhotoId == null) {
      _showError('Passport photo upload incomplete. Please re-select the image.');
      return false;
    }

    // Both images should be uploaded by now (IDs exist)
    return _dlPicId != null && _passportPhotoId != null;
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Account step
        if (!_formKey.currentState!.validate()) return false;
        return true;
      case 1: // Personal info step
        if (!_formKey.currentState!.validate()) return false;
        if (_dateOfBirth == null) {
          _showError('Please select your date of birth');
          return false;
        }
        if (_selectedGender == null) {
          _showError('Please select your gender');
          return false;
        }
        if (_selectedOccupationId == null) {
          _showError('Please select your occupation');
          return false;
        }
        if (_selectedClubId == null) {
          _showError('Please select a club');
          return false;
        }
        return true;
      case 2: // Location step
        if (_selectedRegionId == null) {
          _showError('Please select a region');
          return false;
        }
        if (_selectedTownId == null) {
          _showError('Please select a town');
          return false;
        }
        if (_selectedEstateId == null) {
          _showError('Please select an estate');
          return false;
        }
        return true;
      case 3: // Documents step
        if (_dlPicFile == null) {
          _showError('Please upload your driving license photo');
          return false;
        }
        if (_passportPhotoFile == null) {
          _showError('Please upload your passport photo');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.brightRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.inputDecorationTheme.hintStyle,
            prefixIcon: Icon(
              icon,
              color: AppTheme.mediumGrey,
              size: 22,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: theme.inputDecorationTheme.border,
            enabledBorder: theme.inputDecorationTheme.enabledBorder,
            focusedBorder: theme.inputDecorationTheme.focusedBorder,
            errorBorder: theme.inputDecorationTheme.errorBorder,
            focusedErrorBorder: theme.inputDecorationTheme.focusedErrorBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: enabled ? colorScheme.onSurface : AppTheme.mediumGrey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.inputDecorationTheme.hintStyle,
            prefixIcon: Icon(icon, color: AppTheme.mediumGrey, size: 22),
            filled: true,
            fillColor: enabled ? theme.inputDecorationTheme.fillColor : AppTheme.lightSilver,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: theme.inputDecorationTheme.border,
            enabledBorder: theme.inputDecorationTheme.enabledBorder,
            focusedBorder: theme.inputDecorationTheme.focusedBorder,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(color: AppTheme.silverGrey),
            ),
          ),
          items: items,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    // Verify images are uploaded
    final imagesValid = await _uploadImages();
    if (!imagesValid) {
      setState(() => _isLoading = false);
      return; // Error message already shown
    }

    // Prepare registration data
    final userData = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'phone': _phoneController.text.trim(),
      'alternative_phone': _alternativePhoneController.text.trim(),
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'date_of_birth': _dateOfBirth!.toIso8601String().split('T')[0],
      'gender': _selectedGender,
      'national_id': _nationalIdController.text.trim(),
      'driving_license_number': _drivingLicenseController.text.trim(),
      'dl_pic': _dlPicId,
      'passport_photo': _passportPhotoId,
      'occupation': _selectedOccupationId,
      'estate_id': _selectedEstateId,
      'road_name': _roadNameController.text.trim(),
      'club_id': _selectedClubId,
    };

    final response = await _registrationService.registerUser(userData);

    if (mounted) {
      setState(() => _isLoading = false);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
        context.go('/login');
      } else {
        _showError(
          response.message ?? 'Registration failed. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading && _clubs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading registration data...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 600 : double.infinity,
                      ),
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildAccountStep(),
                          _buildPersonalInfoStep(),
                          _buildLocationStep(),
                          _buildDocumentsStep(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    final stepTitles = ['Account', 'Personal', 'Location', 'Documents'];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step indicators with icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              final isPending = index > _currentStep;
              
              return Expanded(
                child: Column(
                  children: [
                    // Circle indicator
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppTheme.brightRed
                            : isCurrent
                                ? AppTheme.brightRed.withOpacity(0.2)
                                : AppTheme.lightSilver,
                        border: Border.all(
                          color: isCurrent ? AppTheme.brightRed : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, color: AppTheme.white, size: 20)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCurrent ? AppTheme.brightRed : AppTheme.mediumGrey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Step title
                    Text(
                      stepTitles[index],
                      style: TextStyle(
                        fontSize: 11,
                        color: isCurrent ? AppTheme.brightRed : AppTheme.mediumGrey,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: AppTheme.lightSilver,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brightRed),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: AppTheme.brightRed,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_currentStep == _totalSteps - 1) {
                          _handleRegister();
                        } else {
                          _nextStep();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brightRed,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  elevation: 2,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _currentStep == _totalSteps - 1
                            ? Icons.check_circle
                            : Icons.arrow_forward,
                        size: 20,
                      ),
                label: Text(
                  _currentStep == _totalSteps - 1 ? 'Complete Registration' : 'Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple header
            Text(
              'Account Details',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your login credentials',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

          _buildTextField(
            label: 'Email Address',
            hint: 'your.email@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: 'Phone Number',
            hint: '+254712345678',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: Validators.validatePhone,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: 'Alternative Phone',
            hint: '+254722334455',
            controller: _alternativePhoneController,
            keyboardType: TextInputType.phone,
            validator: Validators.validatePhone,
            icon: Icons.phone_android_outlined,
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: 'Password',
            hint: 'Create a strong password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: Validators.validatePassword,
            icon: Icons.lock_outlined,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.mediumGrey,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '• At least 8 characters\n• Include uppercase and lowercase\n• Include numbers',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            validator: (val) => Validators.validateConfirmPassword(
              val,
              _passwordController.text,
            ),
            icon: Icons.lock_outlined,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.mediumGrey,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about yourself',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

          _buildTextField(
            label: 'First Name',
            hint: 'John',
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            validator: (val) => Validators.validateRequired(val, 'First name'),
            icon: Icons.person_outlined,
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: 'Last Name',
            hint: 'Doe',
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            validator: (val) => Validators.validateRequired(val, 'Last name'),
            icon: Icons.person_outlined,
          ),
          const SizedBox(height: 24),

          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(1990),
                firstDate: DateTime(1950),
                lastDate: DateTime.now().subtract(const Duration(days: 6570)),
              );
              if (picked != null) setState(() => _dateOfBirth = picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                prefixIcon: const Icon(Icons.calendar_today),
                border: Theme.of(context).inputDecorationTheme.border,
                enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
              ),
              child: Text(
                _dateOfBirth != null
                    ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                    : 'Select your date of birth',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _dateOfBirth != null ? Theme.of(context).colorScheme.onSurface : AppTheme.mediumGrey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gender',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  hintText: 'Select your gender',
                  hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                  prefixIcon: Icon(Icons.wc_outlined, color: AppTheme.mediumGrey, size: 22),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: Theme.of(context).inputDecorationTheme.border,
                  enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                  focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: 'National ID',
            hint: '12345678',
            controller: _nationalIdController,
            keyboardType: TextInputType.number,
            validator: Validators.validateIdNumber,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: 'Driving License Number',
            hint: 'DL123456',
            controller: _drivingLicenseController,
            validator: (val) =>
                Validators.validateRequired(val, 'Driving license'),
            icon: Icons.card_membership_outlined,
          ),
          const SizedBox(height: 24),

          _buildDropdown<int>(
            label: 'Occupation',
            hint: 'Select your occupation',
            value: _selectedOccupationId,
            items: _occupations.map((occupation) {
              return DropdownMenuItem<int>(
                value: occupation['id'] as int,
                child: Text(occupation['name'] ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedOccupationId = value),
            icon: Icons.work_outlined,
          ),
          const SizedBox(height: 24),

          _buildDropdown<int>(
            label: 'Club',
            hint: 'Select your club',
            value: _selectedClubId,
            items: _clubs.map((club) {
              return DropdownMenuItem<int>(
                value: club['id'] as int,
                child: Text(club['name'] ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedClubId = value),
            icon: Icons.groups_outlined,
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Details',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Where do you live?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          _buildDropdown<int>(
            label: 'County/Region',
            hint: 'Select your county',
            value: _selectedRegionId,
            items: _regions.map((region) {
              return DropdownMenuItem<int>(
                value: region['id'] as int,
                child: Text(region['name'] ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (value) {
              print('County selected: $value');
              setState(() {
                _selectedRegionId = value;
                // Clear dependent selections
                _selectedTownId = null;
                _selectedEstateId = null;
                _towns = [];
                _estates = [];
              });
              if (value != null) {
                _loadTowns(value);
              }
            },
            icon: Icons.location_city_outlined,
          ),
          const SizedBox(height: 24),

          _buildDropdown<int>(
            label: 'Town/City',
            hint: _selectedRegionId == null 
                ? 'First select a county' 
                : (_towns.isEmpty ? 'Loading towns...' : 'Select your town'),
            value: _selectedTownId,
            items: _towns.isEmpty
                ? []
                : _towns.map((town) {
                    return DropdownMenuItem<int>(
                      value: town['id'] as int,
                      child: Text(town['name'] ?? 'Unknown'),
                    );
                  }).toList(),
            onChanged: _selectedRegionId == null || _towns.isEmpty
                ? null
                : (value) {
                    print('Town selected: $value');
                    setState(() {
                      _selectedTownId = value;
                      // Clear dependent selection
                      _selectedEstateId = null;
                      _estates = [];
                    });
                    if (value != null && _selectedRegionId != null) {
                      _loadEstates(_selectedRegionId!, value);
                    }
                  },
            icon: Icons.location_on_outlined,
            enabled: _selectedRegionId != null && _towns.isNotEmpty,
          ),
          const SizedBox(height: 24),

          _buildDropdown<int>(
            label: 'Estate/Area',
            hint: _selectedTownId == null 
                ? 'First select a town' 
                : (_estates.isEmpty ? 'Loading estates...' : 'Select your estate'),
            value: _selectedEstateId,
            items: _estates.isEmpty
                ? []
                : _estates.map((estate) {
                    return DropdownMenuItem<int>(
                      value: estate['id'] as int,
                      child: Text(estate['name'] ?? 'Unknown'),
                    );
                  }).toList(),
            onChanged: _selectedTownId == null || _estates.isEmpty
                ? null
                : (value) {
                    print('Estate selected: $value');
                    setState(() => _selectedEstateId = value);
                  },
            icon: Icons.home_outlined,
            enabled: _selectedTownId != null && _estates.isNotEmpty,
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: 'Road Name (Optional)',
            hint: 'Enter road name',
            controller: _roadNameController,
            icon: Icons.signpost_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.brightRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.upload_file,
                  color: AppTheme.brightRed,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Documents',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload your identification documents',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildImageUploadCard(
            title: 'Driving License Photo',
            description: 'Upload a clear photo of your driving license',
            icon: Icons.credit_card,
            imageFile: _dlPicFile,
            uploadedId: _dlPicId,
            onTap: () => _pickImage(true),
          ),
          const SizedBox(height: 16),

          _buildImageUploadCard(
            title: 'Passport Photo',
            description: 'Upload your passport-size photo',
            icon: Icons.portrait,
            imageFile: _passportPhotoFile,
            uploadedId: _passportPhotoId,
            onTap: () => _pickImage(false),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make sure your images are clear and legible. Accepted formats: JPG, PNG',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required String description,
    required IconData icon,
    required File? imageFile,
    required int? uploadedId,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUploaded = uploadedId != null;
    final hasFile = imageFile != null;
    
    return Card(
      elevation: isUploaded ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        side: BorderSide(
          color: isUploaded ? AppTheme.successGreen : (hasFile ? AppTheme.warningOrange : AppTheme.silverGrey),
          width: isUploaded ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUploaded
                          ? AppTheme.successGreen.withOpacity(0.1)
                          : (hasFile ? AppTheme.warningOrange.withOpacity(0.1) : AppTheme.brightRed.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isUploaded
                          ? Icons.check_circle
                          : (hasFile ? Icons.cloud_upload : icon),
                      color: isUploaded
                          ? AppTheme.successGreen
                          : (hasFile ? AppTheme.warningOrange : AppTheme.brightRed),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUploaded
                          ? Colors.green.withOpacity(0.1)
                          : (hasFile ? Colors.orange.withOpacity(0.1) : Colors.grey[100]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUploaded
                          ? Icons.edit
                          : (hasFile ? Icons.cloud_upload : Icons.add_photo_alternate),
                      color: isUploaded
                          ? Colors.green
                          : (hasFile ? Colors.orange : Colors.grey[600]),
                      size: 24,
                    ),
                  ),
                ],
              ),
              if (imageFile != null) ...[
                const SizedBox(height: 16),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        imageFile,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isUploaded ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUploaded ? Icons.check : Icons.upload,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isUploaded ? 'Uploaded (ID: $uploadedId)' : 'Uploading...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Change Image'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.brightRed,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select image',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
