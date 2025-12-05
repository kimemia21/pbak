import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbak/models/bike_model.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/services/bike_service.dart';
import 'dart:io';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/services/comms/registration_service.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';
import 'package:pbak/views/auth/face_verification_screen.dart';
import 'package:pbak/views/bikes/bike_registration_verification_screen.dart';
import 'package:pbak/widgets/google_places_location_picker.dart';
import 'package:pbak/utils/api_keys.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationService = RegistrationService();
  final _imagePicker = ImagePicker();
  LocalStorageService? _localStorage;

  // Page controller for steps
  final _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6; // Extended to 6 steps
  bool _isEditMode = false;

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
  List<BikeModelCatalog> _models = [];

  // State
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  DateTime? _dateOfBirth;
  String? _selectedGender;

  // API Data
  List<Map<String, dynamic>> _clubs = [];
  List<Map<String, dynamic>> _occupations = [];

  // Selected IDs
  int? _selectedClubId;
  int? _selectedOccupationId;

  // Home Location (Google Places)
  String? _homeLatLong;
  String? _homePlaceId;
  String? _homeEstateName;
  String? _homeAddress;

  // Workplace Location (Google Places)
  String? _workplaceLatLong;
  String? _workplacePlaceId;
  String? _workplaceEstateName;
  String? _workplaceAddress;

  // Images - Personal Documents
  File? _dlPicFile;
  File? _passportPhotoFile;
  int? _dlPicId;
  int? _passportPhotoId;
  bool _passportPhotoVerified = false;

  // Bike Details
  final _bikeMakeController = TextEditingController();
  final _bikeModelController = TextEditingController();
  final _bikeYearController = TextEditingController();
  final _bikeColorController = TextEditingController();
  final _bikePlateController = TextEditingController();
  final _insuranceCompanyController = TextEditingController();
  final _insurancePolicyController = TextEditingController();
  bool _hasBikeInsurance = false;
  int? _ridingExperience;
  String? _ridingType;

  // Bike Photos
  File? _bikeFrontPhoto;
  File? _bikeSidePhoto;
  File? _bikeRearPhoto;
  int? _bikeFrontPhotoId;
  int? _bikeSidePhotoId;
  int? _bikeRearPhotoId;
  
  // Insurance Logbook
  File? _insuranceLogbookFile;
  int? _insuranceLogbookId;

  // Emergency Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  String? _emergencyRelationship;

  // Medical Info 
  String? _bloodType;
  final _allergiesController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _medicalProviderController = TextEditingController();
  final _medicalPolicyController = TextEditingController();
  bool _hasMedicalInsurance = false;
  bool _interestedInMedicalCover = false;

  var _selectedModelId;

  int? _selectedMakeId;

  bool _isLoadingModels = false;
  bool _isLoadingMakes = false;
  List<BikeMake> _makes = [];

  @override
  void initState() {
    super.initState();
    _registrationService.initialize();
    _initializeLocalStorage();
    _loadMakes();
  }

  Future<void> _initializeLocalStorage() async {
    _localStorage = await LocalStorageService.getInstance();
    await _loadSavedProgress();
    await _loadInitialData();
  }

  Future<void> _loadMakes() async {
    setState(() => _isLoadingMakes = true);
    try {
      final bikeService = ref.read(bikeServiceProvider);
      final makes = await bikeService.getBikeMakes();
      if (mounted) {
        setState(() {
          _makes = makes;
          _isLoadingMakes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMakes = false);
        _showError('Failed to load bike makes: $e');
      }
    }
  }

  Future<void> loadModels(int makeId) async {
    setState(() {
      _isLoadingModels = true;
      _selectedModelId = null;
      _models = [];
    });

    try {
      final bikeService = ref.read(bikeServiceProvider);
      final models = await bikeService.getBikeModels(makeId);
      if (mounted) {
        setState(() {
          _models = models;
          _isLoadingModels = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingModels = false);
        _showError('Failed to load bike models: $e');
      }
    }
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
    _bikeMakeController.dispose();
    _bikeModelController.dispose();
    _bikeYearController.dispose();
    _bikeColorController.dispose();
    _bikePlateController.dispose();
    _insuranceCompanyController.dispose();
    _insurancePolicyController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _allergiesController.dispose();
    _medicalConditionsController.dispose();
    _medicalProviderController.dispose();
    _medicalPolicyController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedProgress() async {
    if (_localStorage == null) return;

    final savedProgress = _localStorage!.getRegistrationProgress();
    if (savedProgress == null) return;

    if (!mounted) return;

    setState(() {
      // Restore current step
      _currentStep = savedProgress['current_step'] ?? 0;

      // Account info
      _emailController.text = savedProgress['email'] ?? '';
      _passwordController.text = savedProgress['password'] ?? '';
      _confirmPasswordController.text = savedProgress['confirm_password'] ?? '';
      _phoneController.text = savedProgress['phone'] ?? '';
      _alternativePhoneController.text = savedProgress['alternative_phone'] ?? '';

      // Personal info
      _firstNameController.text = savedProgress['first_name'] ?? '';
      _lastNameController.text = savedProgress['last_name'] ?? '';
      _nationalIdController.text = savedProgress['national_id'] ?? '';
      _drivingLicenseController.text = savedProgress['driving_license'] ?? '';
      
      if (savedProgress['date_of_birth'] != null) {
        _dateOfBirth = DateTime.tryParse(savedProgress['date_of_birth']);
      }
      _selectedGender = savedProgress['gender'];
      _selectedOccupationId = savedProgress['occupation_id'];
      _selectedClubId = savedProgress['club_id'];

      // Location
      _homeLatLong = savedProgress['home_lat_long'];
      _homePlaceId = savedProgress['home_place_id'];
      _homeEstateName = savedProgress['home_estate_name'];
      _homeAddress = savedProgress['home_address'];
      _workplaceLatLong = savedProgress['work_lat_long'];
      _workplacePlaceId = savedProgress['work_place_id'];
      _workplaceEstateName = savedProgress['work_estate_name'];
      _workplaceAddress = savedProgress['work_address'];

      // Documents
      _dlPicId = savedProgress['dl_pic_id'];
      _passportPhotoId = savedProgress['passport_photo_id'];
      _passportPhotoVerified = savedProgress['passport_photo_verified'] ?? false;
      
      // Restore image file paths if available
      if (savedProgress['dl_pic_path'] != null) {
        _dlPicFile = File(savedProgress['dl_pic_path']);
      }
      if (savedProgress['passport_photo_path'] != null) {
        _passportPhotoFile = File(savedProgress['passport_photo_path']);
      }

      // Bike details
      _selectedMakeId = savedProgress['bike_make_id'];
      _selectedModelId = savedProgress['bike_model_id'];
      _bikeMakeController.text = savedProgress['bike_make'] ?? '';
      _bikeModelController.text = savedProgress['bike_model'] ?? '';
      _bikeYearController.text = savedProgress['bike_year'] ?? '';
      _bikeColorController.text = savedProgress['bike_color'] ?? '';
      _bikePlateController.text = savedProgress['bike_plate'] ?? '';
      _insuranceCompanyController.text = savedProgress['insurance_company'] ?? '';
      _insurancePolicyController.text = savedProgress['insurance_policy'] ?? '';
      _hasBikeInsurance = savedProgress['has_bike_insurance'] ?? false;
      _ridingExperience = savedProgress['riding_experience'];
      _ridingType = savedProgress['riding_type'];

      // Bike photos
      _bikeFrontPhotoId = savedProgress['bike_front_photo_id'];
      _bikeSidePhotoId = savedProgress['bike_side_photo_id'];
      _bikeRearPhotoId = savedProgress['bike_rear_photo_id'];
      _insuranceLogbookId = savedProgress['insurance_logbook_id'];

      if (savedProgress['bike_front_photo_path'] != null) {
        _bikeFrontPhoto = File(savedProgress['bike_front_photo_path']);
      }
      if (savedProgress['bike_side_photo_path'] != null) {
        _bikeSidePhoto = File(savedProgress['bike_side_photo_path']);
      }
      if (savedProgress['bike_rear_photo_path'] != null) {
        _bikeRearPhoto = File(savedProgress['bike_rear_photo_path']);
      }
      if (savedProgress['insurance_logbook_path'] != null) {
        _insuranceLogbookFile = File(savedProgress['insurance_logbook_path']);
      }

      // Emergency contact
      _emergencyNameController.text = savedProgress['emergency_name'] ?? '';
      _emergencyPhoneController.text = savedProgress['emergency_phone'] ?? '';
      _emergencyRelationship = savedProgress['emergency_relationship'];

      // Medical info
      _bloodType = savedProgress['blood_type'];
      _allergiesController.text = savedProgress['allergies'] ?? '';
      _medicalConditionsController.text = savedProgress['medical_conditions'] ?? '';
      _medicalProviderController.text = savedProgress['medical_provider'] ?? '';
      _medicalPolicyController.text = savedProgress['medical_policy'] ?? '';
      _hasMedicalInsurance = savedProgress['has_medical_insurance'] ?? false;
      _interestedInMedicalCover = savedProgress['interested_in_medical_cover'] ?? false;
    });

    // Navigate to saved step after a small delay to ensure PageView is built
    if (_currentStep > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_currentStep);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back! Resuming from step ${_currentStep + 1}'),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  Future<void> _saveProgress() async {
    if (_localStorage == null) return;

    final progressData = {
      'current_step': _currentStep,
      'last_saved': DateTime.now().toIso8601String(),

      // Account info
      'email': _emailController.text,
      'password': _passwordController.text,
      'confirm_password': _confirmPasswordController.text,
      'phone': _phoneController.text,
      'alternative_phone': _alternativePhoneController.text,

      // Personal info
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'national_id': _nationalIdController.text,
      'driving_license': _drivingLicenseController.text,
      'date_of_birth': _dateOfBirth?.toIso8601String(),
      'gender': _selectedGender,
      'occupation_id': _selectedOccupationId,
      'club_id': _selectedClubId,

      // Location
      'home_lat_long': _homeLatLong,
      'home_place_id': _homePlaceId,
      'home_estate_name': _homeEstateName,
      'home_address': _homeAddress,
      'work_lat_long': _workplaceLatLong,
      'work_place_id': _workplacePlaceId,
      'work_estate_name': _workplaceEstateName,
      'work_address': _workplaceAddress,

      // Documents
      'dl_pic_id': _dlPicId,
      'passport_photo_id': _passportPhotoId,
      'passport_photo_verified': _passportPhotoVerified,
      'dl_pic_path': _dlPicFile?.path,
      'passport_photo_path': _passportPhotoFile?.path,

      // Bike details
      'bike_make_id': _selectedMakeId,
      'bike_model_id': _selectedModelId,
      'bike_make': _bikeMakeController.text,
      'bike_model': _bikeModelController.text,
      'bike_year': _bikeYearController.text,
      'bike_color': _bikeColorController.text,
      'bike_plate': _bikePlateController.text,
      'insurance_company': _insuranceCompanyController.text,
      'insurance_policy': _insurancePolicyController.text,
      'has_bike_insurance': _hasBikeInsurance,
      'riding_experience': _ridingExperience,
      'riding_type': _ridingType,

      // Bike photos
      'bike_front_photo_id': _bikeFrontPhotoId,
      'bike_side_photo_id': _bikeSidePhotoId,
      'bike_rear_photo_id': _bikeRearPhotoId,
      'insurance_logbook_id': _insuranceLogbookId,
      'bike_front_photo_path': _bikeFrontPhoto?.path,
      'bike_side_photo_path': _bikeSidePhoto?.path,
      'bike_rear_photo_path': _bikeRearPhoto?.path,
      'insurance_logbook_path': _insuranceLogbookFile?.path,

      // Emergency contact
      'emergency_name': _emergencyNameController.text,
      'emergency_phone': _emergencyPhoneController.text,
      'emergency_relationship': _emergencyRelationship,

      // Medical info
      'blood_type': _bloodType,
      'allergies': _allergiesController.text,
      'medical_conditions': _medicalConditionsController.text,
      'medical_provider': _medicalProviderController.text,
      'medical_policy': _medicalPolicyController.text,
      'has_medical_insurance': _hasMedicalInsurance,
      'interested_in_medical_cover': _interestedInMedicalCover,
    };

    await _localStorage!.saveRegistrationProgress(progressData);
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _registrationService.fetchClubs(),
        _registrationService.fetchOccupations(),
      ]);

      if (mounted) {
        setState(() {
          _clubs = results[0];
          _occupations = results[1];
          _isLoading = false;
        });

        // Debug logs
        print('Clubs loaded: ${_clubs.length}');
        print('Clubs data: $_clubs');
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

  Future<void> _pickImage(bool isDlPic) async {
    try {
      if (!isDlPic) {
        // For passport photo, use face verification with camera only (no gallery)
        await _capturePassportPhotoWithVerification();
        return;
      }

      // For driving license, allow image selection from gallery
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _dlPicFile = File(pickedFile.path);
          _dlPicId = null; // Reset ID when new file selected
        });

        // Upload immediately after selection
        await _uploadImageImmediately(pickedFile.path, isDlPic);
      }
    } catch (e) {
      if (mounted) {
        print('Error picking image: $e');
        _showError('Failed to pick image. Please check app permissions and try again.');
      }
    }
  }

  Future<void> _capturePassportPhotoWithVerification() async {
    // Use camera only - no gallery uploads
    // Face verification detects if user is human (face detection check)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceVerificationScreen()),
    );

    if (result != null && result is Map<String, dynamic> && mounted) {
      final imagePath = result['image_path'] as String?;
      final verified = result['liveness_verified'] as bool? ?? false;

      if (imagePath != null) {
        setState(() {
          _passportPhotoFile = File(imagePath);
          _passportPhotoVerified = verified;
          _passportPhotoId = null;
        });

        // Upload immediately after capture
        await _uploadImageImmediately(
          imagePath,
          false,
          livenessVerified: verified,
        );
      }
    }
  }

  Future<void> _captureBikePhoto(String position) async {
    // Navigate to bike registration verification screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BikeRegistrationVerificationScreen(imageType: position),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final imagePath = result['image'] as String?;
      final registrationNumber = result['registration_number'] as String?;
      final isMotorcycle = result['is_motorcycle'] as bool?;

      // For front/side: No strict verification needed, just capture the image
      // For rear: Must have registration number (from OCR or manual entry)
      if (position == 'rear') {
        if (registrationNumber == null || registrationNumber.isEmpty) {
          _showError('Registration number is required for rear image');
          return;
        }
      }

      if (imagePath != null && mounted) {
        setState(() {
          switch (position) {
            case 'front':
              _bikeFrontPhoto = File(imagePath);
              _bikeFrontPhotoId = null;
              break;
            case 'side':
              _bikeSidePhoto = File(imagePath);
              _bikeSidePhotoId = null;
              break;
            case 'rear':
              _bikeRearPhoto = File(imagePath);
              _bikeRearPhotoId = null;
              break;
          }
        });

        // Auto-fill registration number if detected (rear image only)
        if (position == 'rear' && registrationNumber != null && registrationNumber.isNotEmpty) {
          if (_bikePlateController.text.isEmpty) {
            _bikePlateController.text = registrationNumber;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Registration number detected: $registrationNumber',
                ),
                backgroundColor: AppTheme.successGreen,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        // Upload immediately
        await _uploadBikePhotoImmediately(imagePath, position);
      }
    }
  }

  Future<void> _uploadImageImmediately(
    String filePath,
    bool isDlPic, {
    bool livenessVerified = false,
  }) async {
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
                    : 'Passport photo uploaded successfully!${livenessVerified ? ' ✓ Verified' : ''}',
              ),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Auto-save progress after image upload
          _saveProgress();
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

  Future<void> _uploadBikePhotoImmediately(
    String filePath,
    String position,
  ) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final imageType = 'bike_$position';
      final uploadedId = await _registrationService.uploadImage(
        filePath,
        imageType,
      );

      if (mounted) {
        if (uploadedId != null) {
          setState(() {
            switch (position) {
              case 'front':
                _bikeFrontPhotoId = uploadedId;
                break;
              case 'side':
                _bikeSidePhotoId = uploadedId;
                break;
              case 'rear':
                _bikeRearPhotoId = uploadedId;
                break;
            }
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bike ${position} photo uploaded successfully!'),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Auto-save progress after bike photo upload
          _saveProgress();
        } else {
          setState(() => _isLoading = false);
          _showError('Failed to upload bike photo. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error uploading bike photo: $e');
      }
    }
  }

  Future<void> _pickInsuranceLogbook() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _insuranceLogbookFile = File(pickedFile.path);
          _insuranceLogbookId = null;
        });

        // Upload immediately after selection
        await _uploadInsuranceLogbookImmediately(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        print('Error picking insurance logbook: $e');
        _showError('Failed to pick image. Please check app permissions and try again.');
      }
    }
  }

  Future<void> _uploadInsuranceLogbookImmediately(String filePath) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final uploadedId = await _registrationService.uploadImage(
        filePath,
        'insurance_logbook',
      );

      if (mounted) {
        if (uploadedId != null) {
          setState(() {
            _insuranceLogbookId = uploadedId;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insurance logbook uploaded successfully!'),
              backgroundColor: AppTheme.successGreen,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Auto-save progress after insurance logbook upload
          _saveProgress();
        } else {
          setState(() => _isLoading = false);
          _showError('Failed to upload insurance logbook. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error uploading insurance logbook: $e');
      }
    }
  }

  Future<bool> _uploadImages() async {
    // Check if images are already uploaded (have IDs)
    if (_dlPicFile != null && _dlPicId == null) {
      _showError(
        'Driving license upload incomplete. Please re-select the image.',
      );
      return false;
    }

    if (_passportPhotoFile != null && _passportPhotoId == null) {
      _showError(
        'Passport photo upload incomplete. Please re-select the image.',
      );
      return false;
    }

    // Both images should be uploaded by now (IDs exist)
    return _dlPicId != null && _passportPhotoId != null;
  }

  bool _isNavigating = false;

  Future<void> _nextStep() async {
    // Prevent rapid navigation
    if (_isNavigating) return;
    
    // Validate current step before proceeding
    if (!_validateCurrentStep()) {
      return;
    }
    
    if (_currentStep < _totalSteps - 1) {
      _isNavigating = true;
      final nextStep = _currentStep + 1;
      
      setState(() => _currentStep = nextStep);
      
      await _pageController.animateToPage(
        nextStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Auto-save progress after animation completes
      await _saveProgress();
      _isNavigating = false;
    }
  }

  Future<void> _previousStep() async {
    // Prevent rapid navigation
    if (_isNavigating) return;
    
    if (_currentStep > 0) {
      _isNavigating = true;
      final prevStep = _currentStep - 1;
      
      setState(() => _currentStep = prevStep);
      
      await _pageController.animateToPage(
        prevStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Auto-save progress after animation completes
      await _saveProgress();
      _isNavigating = false;
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Account step
        if (!_formKey.currentState!.validate()) {
          _showError('Please fill in all required fields correctly');
          return false;
        }
        if (_emailController.text.trim().isEmpty) {
          _showError('Email address is required');
          return false;
        }
        if (_phoneController.text.trim().isEmpty) {
          _showError('Phone number is required');
          return false;
        }
        if (_passwordController.text.isEmpty) {
          _showError('Password is required');
          return false;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          _showError('Passwords do not match');
          return false;
        }
        return true;
        
      case 1: // Personal info step
        if (!_formKey.currentState!.validate()) {
          _showError('Please fill in all required fields correctly');
          return false;
        }
        if (_firstNameController.text.trim().isEmpty) {
          _showError('First name is required');
          return false;
        }
        if (_lastNameController.text.trim().isEmpty) {
          _showError('Last name is required');
          return false;
        }
        if (_dateOfBirth == null) {
          _showError('Please select your date of birth');
          return false;
        }
        if (_selectedGender == null) {
          _showError('Please select your gender');
          return false;
        }
        if (_nationalIdController.text.trim().isEmpty) {
          _showError('National ID is required');
          return false;
        }
        if (_drivingLicenseController.text.trim().isEmpty) {
          _showError('Driving license number is required');
          return false;
        }
        if (_selectedOccupationId == null) {
          _showError('Please select your occupation');
          return false;
        }
        return true;
        
      case 2: // Location step
        if (_homeAddress == null || _homeAddress!.isEmpty) {
          _showError('Please select your home location');
          return false;
        }
        if (_selectedClubId == null) {
          _showError('Please select a club to join');
          return false;
        }
        return true;
        
      case 3: // Documents step
        // Check if DL ID is provided (either uploaded or hardcoded for testing)
        if (_dlPicId == null) {
          _showError('Please upload your driving license photo');
          return false;
        }
        // Check if passport photo ID is provided (either uploaded or hardcoded for testing)
        if (_passportPhotoId == null) {
          _showError('Please upload your passport photo with face verification');
          return false;
        }
        // Only check verification if a file was actually uploaded
        if (_passportPhotoFile != null && !_passportPhotoVerified) {
          _showError('Passport photo must be verified through face detection');
          return false;
        }
        return true;
        
      case 4: // Bike details step
        if (_selectedMakeId == null) {
          _showError('Please select bike make');
          return false;
        }
        if (_selectedModelId == null) {
          _showError('Please select bike model');
          return false;
        }
        if (_bikeColorController.text.trim().isEmpty) {
          _showError('Please enter bike color');
          return false;
        }
        if (_bikePlateController.text.trim().isEmpty) {
          _showError('Please enter bike registration number');
          return false;
        }
        // Check if bike photo IDs are provided (either uploaded or hardcoded for testing)
        if (_bikeFrontPhotoId == null) {
          _showError('Please upload bike front photo');
          return false;
        }
        if (_bikeSidePhotoId == null) {
          _showError('Please upload bike side photo');
          return false;
        }
        if (_bikeRearPhotoId == null) {
          _showError('Please upload bike rear photo');
          return false;
        }
        if (_hasBikeInsurance) {
          if (_insuranceCompanyController.text.trim().isEmpty) {
            _showError('Please enter insurance company name');
            return false;
          }
          // Check if insurance logbook ID is provided (either uploaded or hardcoded for testing)
          if (_insuranceLogbookId == null) {
            _showError('Please upload insurance logbook');
            return false;
          }
        }
        return true;
        
      case 5: // Emergency & Medical info step
        if (_emergencyNameController.text.trim().isEmpty) {
          _showError('Emergency contact name is required');
          return false;
        }
        if (_emergencyPhoneController.text.trim().isEmpty) {
          _showError('Emergency contact phone is required');
          return false;
        }
        if (_emergencyRelationship == null || _emergencyRelationship!.isEmpty) {
          _showError('Please select emergency contact relationship');
          return false;
        }
        if (_bloodType == null || _bloodType!.isEmpty) {
          _showError('Please select your blood type');
          return false;
        }
        return true;
        
      default:
        return true;
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            prefixIcon: Icon(icon, color: AppTheme.mediumGrey, size: 22),
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
            fillColor: enabled
                ? theme.inputDecorationTheme.fillColor
                : AppTheme.lightSilver,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
      // Account Info
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'phone': _phoneController.text.trim(),
      'alternative_phone': _alternativePhoneController.text.trim(),

      // Personal Info
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'date_of_birth': _dateOfBirth!.toIso8601String().split('T')[0],
      'gender': _selectedGender,
      'national_id': _nationalIdController.text.trim(),
      'driving_license_number': _drivingLicenseController.text.trim(),
      'occupation': _selectedOccupationId ?? 'Other',
      'club_id': _selectedClubId ?? 1,

      // Documents
      'dl_pic': _dlPicId,
      'passport_photo': _passportPhotoId,

      // Location - Home (estate_id is required by API)
      'estate_id': 1, // Default value, can be made dynamic if estate selection is added
      if (_homeAddress != null) 'road_name': _homeAddress,
      if (_homeLatLong != null) 'home_lat_long': _homeLatLong,
      if (_homePlaceId != null) 'home_place_id': _homePlaceId,

      // Location - Workplace
      if (_workplaceLatLong != null) 'work_lat_long': _workplaceLatLong,
      if (_workplacePlaceId != null) 'work_place_id': _workplacePlaceId,

      // Employer info (required by API if occupation is employment-related)
      'employer': _selectedOccupationId == 'Employed' ? 'Employer Name' : 'N/A',
      'industry': 'Private', // Default value

      // Bike Details (nested object as per API specification)
      'bike': {
        'model_id': 1, // This should be fetched from bike models API if available
        'registration_number': _bikePlateController.text.trim(),
        'chassis_number': '', // Can be added to form if needed
        'engine_number': '', // Can be added to form if needed
        'capacity_cc': '', // Can be added to form if needed
        'color': _bikeColorController.text.trim(),
        'purchase_date': _bikeYearController.text.isNotEmpty 
            ? '${_bikeYearController.text}-01-01' 
            : DateTime.now().toIso8601String().split('T')[0],
        'registration_date': _bikeYearController.text.isNotEmpty 
            ? '${_bikeYearController.text}-01-01' 
            : DateTime.now().toIso8601String().split('T')[0],
        'registration_expiry': DateTime.now().add(Duration(days: 365)).toIso8601String().split('T')[0],
        'bike_photo_url': 'BIKE/PH${_bikeFrontPhotoId ?? 0}.JPG',
        'odometer_reading': '0', // Can be added to form if needed
        'insurance_expiry': _hasBikeInsurance 
            ? DateTime.now().add(Duration(days: 365)).toIso8601String().split('T')[0]
            : DateTime.now().toIso8601String().split('T')[0],
        'is_primary': 1,
        'yom': _bikeYearController.text.isNotEmpty 
            ? '${_bikeYearController.text}-01-01' 
            : DateTime.now().toIso8601String().split('T')[0],
        'photo_front_id': _bikeFrontPhotoId ?? 1,
        'photo_side_id': _bikeSidePhotoId ?? 1,
        'photo_rear_id': _bikeRearPhotoId ?? 1,
        'insurance_logbook_id': _insuranceLogbookId ?? 1,
        'has_insurance': _hasBikeInsurance ? 1 : 0,
        'experience_years': _ridingExperience != null 
            ? _ridingExperience! ?? 0 
            : 0,
        'commute_route': _workplacePlaceId ?? '', // Using workplace place_id as commute route
        'approx_route_distance': 0, // Can be calculated if needed
      },

      // Emergency Contact (nested object as per API specification)
      'emergency': {
        'contact_name': _emergencyNameController.text.trim(),
        'emergency_contact': _emergencyPhoneController.text.trim(),
        'relationship': _emergencyRelationship ?? 'Other',
        'secondary': _alternativePhoneController.text.trim(),
      },

      // Medical Info (nested object as per API specification)
      'medical': {
        'provider_id': 1, // Default value, can be made dynamic
        'blood_type': _bloodType ?? 'Unknown',
        'allergies': _allergiesController.text.trim(),
        'medical_condition': _medicalConditionsController.text.trim(),
        'have_health_ins': _hasMedicalInsurance ? 1 : 0,
        'insurance_ref': _medicalPolicyController.text.trim(),
        'cover_type': _hasMedicalInsurance 
            ? (_medicalProviderController.text.isNotEmpty 
                ? _medicalProviderController.text.trim() 
                : 'Private')
            : 'None',
        'policy_no': _medicalPolicyController.text.trim(),
        'interested_in_medical_cover': _interestedInMedicalCover ? 1 : 0,
      },
    };

    final response = await _registrationService.registerUser(userData);

    if (mounted) {
      setState(() => _isLoading = false);

      if (response.success) {
        // Save email for auto-fill on login (only for registered users)
        await _localStorage?.saveRegisteredCredentials(_emailController.text.trim());
        
        // Clear saved registration progress after successful registration
        await _localStorage?.clearRegistrationProgress();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
        context.go('/login');
      } else {
        // Show detailed validation errors if available
        String errorMessage = response.message ?? 'Registration failed. Please try again.';
        
        // Check if there are validation errors in the response
        if (response.rawData != null && response.rawData!['stack'] != null) {
          final stack = response.rawData!['stack'];
          
          // Check if stack is a List (validation errors) or String (stack trace)
          if (stack is List && stack.isNotEmpty) {
            // Build detailed error message from validation errors
            final errorList = stack.map((error) {
              if (error is Map<String, dynamic>) {
                final field = error['field'] ?? 'Field';
                final message = error['message'] ?? 'Invalid';
                return '• $field: $message';
              }
              return '• ${error.toString()}';
            }).join('\n');
            
            errorMessage = 'Validation Errors:\n$errorList';
          }
          // If stack is a String (like "Email already registered"), use it as-is
          // The main message already contains the error
        }
        
        _showDetailedError(errorMessage);
      }
    }
  }

  void _showDetailedError(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: AppTheme.brightRed),
              const SizedBox(width: 12),
              const Text('Registration Error'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    // Always save progress before exiting
    await _saveProgress();
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Progress?'),
        content: const Text(
          'Your progress has been saved. You can continue from where you left off when you return.\n\nDo you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brightRed,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _saveAndExit() async {
    await _saveProgress();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress saved! You can continue later.'),
          backgroundColor: AppTheme.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Delay to show the snackbar
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Account'),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                context.pop();
              }
            },
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
                        onPageChanged: (int page) {
                          // Sync the step indicator with PageView
                          if (page != _currentStep) {
                            setState(() {
                              _currentStep = page;
                            });
                          }
                        },
                        children: [
                          _buildAccountStep(),
                          _buildPersonalInfoStep(),
                          _buildLocationStep(),
                          _buildDocumentsStep(),
                          _buildBikeDetailsStep(),
                          _buildEmergencyInfoStep(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final stepTitles = [
      'Account',
      'Personal',
      'Location',
      'Documents',
      'Bike',
      'Emergency',
    ];
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
                          color: isCurrent
                              ? AppTheme.brightRed
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: AppTheme.white,
                                size: 20,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCurrent
                                      ? AppTheme.brightRed
                                      : AppTheme.mediumGrey,
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
                        color: isCurrent
                            ? AppTheme.brightRed
                            : AppTheme.mediumGrey,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.brightRed,
              ),
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
                    side: BorderSide(color: AppTheme.brightRed, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text(
                    'Back',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  _currentStep == _totalSteps - 1
                      ? 'Complete Registration'
                      : 'Continue',
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
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your login credentials',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
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
              label: 'Alternative Phone / WhatsApp Number',
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
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(height: 1.5),
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
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about yourself',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 32),

            _buildTextField(
              label: 'First Name',
              hint: 'John',
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              validator: (val) =>
                  Validators.validateRequired(val, 'First name'),
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
                  enabledBorder: Theme.of(
                    context,
                  ).inputDecorationTheme.enabledBorder,
                  focusedBorder: Theme.of(
                    context,
                  ).inputDecorationTheme.focusedBorder,
                ),
                child: Text(
                  _dateOfBirth != null
                      ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                      : 'Select your date of birth',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _dateOfBirth != null
                        ? Theme.of(context).colorScheme.onSurface
                        : AppTheme.mediumGrey,
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
                    prefixIcon: Icon(
                      Icons.wc_outlined,
                      color: AppTheme.mediumGrey,
                      size: 22,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: Theme.of(context).inputDecorationTheme.border,
                    enabledBorder: Theme.of(
                      context,
                    ).inputDecorationTheme.enabledBorder,
                    focusedBorder: Theme.of(
                      context,
                    ).inputDecorationTheme.focusedBorder,
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
              onChanged: (value) =>
                  setState(() => _selectedOccupationId = value),
              icon: Icons.work_outlined,
            ),
            const SizedBox(height: 24),
            _buildDropdown<int>(
            label: 'Years of Riding Experience',
            hint: 'Select years',
            value: _ridingExperience,
            items: List.generate(30, (index) => index + 1).map((years) {
              return DropdownMenuItem<int>(
                value: years,
                child: Text('$years ${years == 1 ? 'year' : 'years'}'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _ridingExperience = value),
            icon: Icons.motorcycle_sharp,
          ),
          const SizedBox(height: 24),
            _buildDropdown<String>(
            label: 'Type of Riding',
            hint: 'Select riding type',
            value: _ridingType,
            items: const [
              DropdownMenuItem(value: 'commuting', child: Text('Commuting')),
              DropdownMenuItem(value: 'touring', child: Text('Touring')),
              DropdownMenuItem(value: 'sports', child: Text('Sports/Racing')),
              DropdownMenuItem(
                value: 'delivery',
                child: Text('Delivery/Business'),
              ),
              DropdownMenuItem(
                value: 'recreational',
                child: Text('Recreational'),
              ),
              DropdownMenuItem(value: 'mixed', child: Text('Mixed Use')),
            ],
            onChanged: (value) => setState(() => _ridingType = value),
            icon: Icons.sports_motorsports,
          ),

           
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    final theme = Theme.of(context);
    final hasHomeLocation = _homeAddress != null;
    final hasWorkLocation = _workplaceAddress != null;
    final hasClubSelected = _selectedClubId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with progress indicator
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Details',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tell us where you live, work, and ride',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGrey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.brightRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${[hasHomeLocation, hasWorkLocation, hasClubSelected].where((e) => e).length}/3',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brightRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Home Location Section
          _buildLocationCard(
            theme: theme,
            title: 'Home Location',
            subtitle: 'Where do you live?',
            icon: Icons.home_rounded,
            iconColor: AppTheme.brightRed,
            backgroundColor: AppTheme.brightRed,
            isRequired: true,
            isSelected: _homeAddress != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GooglePlacesLocationPicker(
                  apiKey: ApiKeys.googlePlacesApiKey,
                  hintText: 'Search for your home address...',
                  primaryColor: AppTheme.brightRed,
                  onLocationSelected: (locationData) {
                    setState(() {
                      _homeLatLong = locationData.latLongString;
                      _homePlaceId = "locationData.placeId";
                      _homeEstateName = locationData.estateName;
                      _homeAddress = locationData.address;
                    });
                    debugPrint('Home location: ${locationData.address}');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Club Selection Section
          _buildLocationCard(
            theme: theme,
            title: 'Bike Club',
            subtitle: 'Select your preferred riding club',
            icon: Icons.groups_rounded,
            iconColor: Colors.purple,
            backgroundColor: Colors.purple,
            isRequired: true,
            isSelected: _selectedClubId != null,
            child: _buildDropdown<int>(
              label: '',
              hint: 'Select your club',
              value: _selectedClubId,
              items: _clubs.map((club) {
                return DropdownMenuItem<int>(
                  value: club['id'] as int,
                  child: Text(
                    club['name']?.toString() ?? 'Unknown Club',
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedClubId = value);
              },
              icon: Icons.groups_rounded,
            ),
          ),

          const SizedBox(height: 24),

          // Workplace Location Section
          _buildLocationCard(
            theme: theme,
            title: 'Workplace Location',
            subtitle: 'Where do you work?',
            icon: Icons.work_rounded,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue,
            isRequired: true,
            isSelected: _workplaceAddress != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GooglePlacesLocationPicker(
                  apiKey: ApiKeys.googlePlacesApiKey,
                  hintText: 'Search for your workplace address...',
                  primaryColor: Colors.blue,
                  onLocationSelected: (locationData) {
                    setState(() {
                      _workplaceLatLong = locationData.latLongString;
                      _workplacePlaceId = "1";
                      _workplaceEstateName = locationData.estateName;
                      _workplaceAddress = locationData.address;
                    });
                    debugPrint('Workplace location: ${locationData.address}');
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Build reusable location card with consistent styling
  Widget _buildLocationCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required bool isRequired,
    required bool isSelected,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isSelected
              ? backgroundColor.withOpacity(0.4)
              : backgroundColor.withOpacity(0.15),
          width: isSelected ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(
                  icon,
                  color: backgroundColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: backgroundColor,
                          ),
                        ),
                        if (isRequired) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.brightRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Required',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brightRed,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // Status indicator
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppTheme.white,
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          
          // Content
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.darkGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.mediumGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.darkGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
          color: isUploaded
              ? AppTheme.successGreen
              : (hasFile ? AppTheme.warningOrange : AppTheme.silverGrey),
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
                          : (hasFile
                                ? AppTheme.warningOrange.withOpacity(0.1)
                                : AppTheme.brightRed.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isUploaded
                          ? Icons.check_circle
                          : (hasFile ? Icons.cloud_upload : icon),
                      color: isUploaded
                          ? AppTheme.successGreen
                          : (hasFile
                                ? AppTheme.warningOrange
                                : AppTheme.brightRed),
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
                          : (hasFile
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.grey[100]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUploaded
                          ? Icons.edit
                          : (hasFile
                                ? Icons.cloud_upload
                                : Icons.add_photo_alternate),
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
                              isUploaded
                                  ? 'Uploaded (ID: $uploadedId)'
                                  : 'Uploading...',
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
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

  Widget _buildBikeDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bike & Insurance Details',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your motorcycle',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<int>(
            value: _selectedMakeId,
            decoration: const InputDecoration(
              labelText: 'Bike Make',
              hintText: 'Select manufacturer',
              prefixIcon: Icon(Icons.business_rounded),
            ),
            items: _makes.map((make) {
              return DropdownMenuItem<int>(
                value: make.id,
                child: Text(make.name),
              );
            }).toList(),
            onChanged: _isEditMode
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _selectedMakeId = value);
                      loadModels(value);
                    }
                  },
          ),
          const SizedBox(height: 24),
          if (_selectedMakeId != null) ...[
            DropdownButtonFormField<int>(
              value: _selectedModelId,
              decoration: InputDecoration(
                labelText: 'Bike Model',
                hintText: _selectedMakeId == null
                    ? 'First select a make'
                    : (_isLoadingModels ? 'Loading models...' : 'Select model'),
                prefixIcon: const Icon(Icons.two_wheeler_rounded),
              ),
              items: _models.map((model) {
                return DropdownMenuItem<int>(
                  value: model.modelId!,
                  child: Text(model.displayName),
                );
              }).toList(),
              onChanged:
                  _isEditMode || _selectedMakeId == null || _isLoadingModels
                  ? null
                  : (value) => setState(() => _selectedModelId = value),
            ),

            if (_selectedModelId != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: AppTheme.successGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bike make and model selected',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Year',
                  hint: '2020',
                  controller: _bikeYearController,
                  keyboardType: TextInputType.number,
                  icon: Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Color',
                  hint: 'Black',
                  controller: _bikeColorController,
                  icon: Icons.palette,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: 'Registration Plate',
            hint: 'KXX 123X',
            controller: _bikePlateController,
            validator: (val) =>
                Validators.validateRequired(val, 'Registration plate'),
            icon: Icons.credit_card,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 32),

          // Bike Photos Section
          Text(
            'Bike Photos',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBikePhotoSection(),
          const SizedBox(height: 32),

          // Insurance Section
          SwitchListTile(
            title: const Text(
              'Do you have motorcycle insurance?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            value: _hasBikeInsurance,
            onChanged: (value) => setState(() => _hasBikeInsurance = value),
            activeColor: AppTheme.brightRed,
          ),

          if (_hasBikeInsurance) ...[
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Insurance Company',
              hint: 'e.g., AAR, Britam, CIC',
              controller: _insuranceCompanyController,
              icon: Icons.business,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              label: 'Policy Number',
              hint: 'Enter policy number',
              controller: _insurancePolicyController,
              icon: Icons.numbers,
            ),
            const SizedBox(height: 16),

            // Insurance Logbook Upload
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _insuranceLogbookFile != null ? AppTheme.successGreen : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _insuranceLogbookFile != null ? Icons.check_circle : Icons.description,
                        color: _insuranceLogbookFile != null ? AppTheme.successGreen : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Insurance Logbook',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      if (_insuranceLogbookFile != null && _insuranceLogbookId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Uploaded',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_insuranceLogbookFile != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file, color: AppTheme.brightRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _insuranceLogbookFile!.path.split('/').last,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_insuranceLogbookId != null)
                            const Icon(Icons.cloud_done, color: AppTheme.successGreen, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickInsuranceLogbook,
                    icon: Icon(_insuranceLogbookFile != null ? Icons.refresh : Icons.upload_file),
                    label: Text(_insuranceLogbookFile != null ? 'Change Document' : 'Upload Logbook'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brightRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload your insurance certificate or logbook',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Riding Experience
          

          // Riding Type
          
        ],
      ),
    );
  }

  Widget _buildBikePhotoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBikePhotoCard(
                'Front',
                _bikeFrontPhoto,
                () => _captureBikePhoto('front'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBikePhotoCard(
                'Side',
                _bikeSidePhoto,
                () => _captureBikePhoto('side'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          height: 200,
          child: _buildBikePhotoCard(
            'Rear',
            _bikeRearPhoto,
            () => _captureBikePhoto('rear'),
          ),
        ),
      ],
    );
  }

  Widget _buildBikePhotoCard(String label, File? photo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: photo != null ? AppTheme.brightRed : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: photo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(photo, fit: BoxFit.cover),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.grey[400], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmergencyInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency & Medical Info',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'This information could save your life',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 32),

          // Emergency Contact Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.brightRed.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.brightRed.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emergency, color: AppTheme.brightRed),
                    const SizedBox(width: 8),
                    Text(
                      'Emergency Contact',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brightRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  label: 'Contact Name',
                  hint: 'Full name',
                  controller: _emergencyNameController,
                  validator: (val) => Validators.validateRequired(
                    val,
                    'Emergency contact name',
                  ),
                  icon: Icons.person,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  label: 'Contact Phone',
                  hint: '+254712345678',
                  controller: _emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  icon: Icons.phone,
                ),
                const SizedBox(height: 16),

                _buildDropdown<String>(
                  label: 'Relationship',
                  hint: 'Select relationship',
                  value: _emergencyRelationship,
                  items: const [
                    DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
                    DropdownMenuItem(value: 'parent', child: Text('Parent')),
                    DropdownMenuItem(value: 'sibling', child: Text('Sibling')),
                    DropdownMenuItem(value: 'child', child: Text('Child')),
                    DropdownMenuItem(value: 'friend', child: Text('Friend')),
                    DropdownMenuItem(
                      value: 'relative',
                      child: Text('Other Relative'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _emergencyRelationship = value),
                  icon: Icons.family_restroom,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Medical Information Section 
          Text(
            'Medical Information ',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This information helps medical responders in emergencies',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          _buildDropdown<String>(
            label: 'Blood Type ',
            hint: 'Select blood type',
            value: _bloodType,
            items: const [
              DropdownMenuItem(value: 'A+', child: Text('A+')),
              DropdownMenuItem(value: 'A-', child: Text('A-')),
              DropdownMenuItem(value: 'B+', child: Text('B+')),
              DropdownMenuItem(value: 'B-', child: Text('B-')),
              DropdownMenuItem(value: 'AB+', child: Text('AB+')),
              DropdownMenuItem(value: 'AB-', child: Text('AB-')),
              DropdownMenuItem(value: 'O+', child: Text('O+')),
              DropdownMenuItem(value: 'O-', child: Text('O-')),
            ],
            onChanged: (value) => setState(() => _bloodType = value),
            icon: Icons.bloodtype,
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: 'Allergies ',
            hint: 'e.g., Penicillin, Peanuts',
            controller: _allergiesController,
            icon: Icons.warning_amber,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: 'Medical Conditions ',
            hint: 'e.g., Diabetes, Asthma',
            controller: _medicalConditionsController,
            icon: Icons.medical_information,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),

          // Medical Insurance Section
          SwitchListTile(
            title: const Text(
              'Do you have health insurance?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            value: _hasMedicalInsurance,
            onChanged: (value) => setState(() => _hasMedicalInsurance = value),
            activeColor: AppTheme.brightRed,
          ),

          if (_hasMedicalInsurance) ...[
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Medical Insurance Provider',
              hint: 'e.g., NHIF, AAR, Britam',
              controller: _medicalProviderController,
              icon: Icons.local_hospital,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            _buildTextField(
              label: 'Policy Number',
              hint: 'Enter policy number',
              controller: _medicalPolicyController,
              icon: Icons.numbers,
            ),
          ],
          const SizedBox(height: 24),

          // Interested in Medical Cover
          SwitchListTile(
            title: const Text(
              'Interested in negotiated medical cover?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'We can help you get affordable medical insurance',
              style: TextStyle(fontSize: 12),
            ),
            value: _interestedInMedicalCover,
            onChanged: (value) =>
                setState(() => _interestedInMedicalCover = value),
            activeColor: AppTheme.brightRed,
          ),
        ],
      ),
    );
  }
}
