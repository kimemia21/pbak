import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbak/models/bike_model.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/services/bike_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/services/comms/registration_service.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:pbak/utils/kenyan_plate_parser.dart';
import 'package:pbak/widgets/ConfirmDialog.dart';

import 'package:pbak/utils/api_keys.dart';

import '../../widgets/LocationSearchPage.dart';

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
  //
  // IMPORTANT: this must stay in sync with [_currentStep]. We re-create this
  // controller after loading saved progress so the PageView starts on the
  // correct step even if it gets built later (after async loading).
  late PageController _pageController;
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

  /// Tracks whether we have attempted to load clubs for the user's selected
  /// home location/region. Used to show an empty-state message.
  bool _clubsFetchAttempted = false;
  bool _isLoadingClubs = false;

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

    // Default until we load saved progress.
    _pageController = PageController(initialPage: _currentStep);

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
      _alternativePhoneController.text =
          savedProgress['alternative_phone'] ?? '';

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
      _passportPhotoVerified =
          savedProgress['passport_photo_verified'] ?? false;

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
      _insuranceCompanyController.text =
          savedProgress['insurance_company'] ?? '';
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
      _medicalConditionsController.text =
          savedProgress['medical_conditions'] ?? '';
      _medicalProviderController.text = savedProgress['medical_provider'] ?? '';
      _medicalPolicyController.text = savedProgress['medical_policy'] ?? '';
      _hasMedicalInsurance = savedProgress['has_medical_insurance'] ?? false;
      _interestedInMedicalCover =
          savedProgress['interested_in_medical_cover'] ?? false;

      // Re-create controller so the PageView starts at the restored step.
      // This avoids relying on animate/jump before the PageView is mounted.
      _pageController.dispose();
      _pageController = PageController(initialPage: _currentStep);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back! Resuming from step ${_currentStep + 1}'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _resetRegistrationFormState() {
    // Reset stepper/page
    _currentStep = 0;
    _pageController.dispose();
    _pageController = PageController(initialPage: 0);

    // Clear controllers
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _phoneController.clear();
    _alternativePhoneController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _nationalIdController.clear();
    _drivingLicenseController.clear();

    _bikeMakeController.clear();
    _bikeModelController.clear();
    _bikeYearController.clear();
    _bikeColorController.clear();
    _bikePlateController.clear();
    _insuranceCompanyController.clear();
    _insurancePolicyController.clear();

    _emergencyNameController.clear();
    _emergencyPhoneController.clear();

    _allergiesController.clear();
    _medicalConditionsController.clear();
    _medicalProviderController.clear();
    _medicalPolicyController.clear();

    // Reset selections
    _dateOfBirth = null;
    _selectedGender = null;
    _selectedOccupationId = null;
    _selectedClubId = null;

    _homeLatLong = null;
    _homePlaceId = null;
    _homeEstateName = null;
    _homeAddress = null;
    _workplaceLatLong = null;
    _workplacePlaceId = null;
    _workplaceEstateName = null;
    _workplaceAddress = null;

    _dlPicId = null;
    _passportPhotoId = null;
    _passportPhotoVerified = false;
    _dlPicFile = null;
    _passportPhotoFile = null;

    _selectedMakeId = null;
    _selectedModelId = null;
    _bikeFrontPhotoId = null;
    _bikeSidePhotoId = null;
    _bikeRearPhotoId = null;
    _insuranceLogbookId = null;
    _bikeFrontPhoto = null;
    _bikeSidePhoto = null;
    _bikeRearPhoto = null;
    _insuranceLogbookFile = null;

    _hasBikeInsurance = false;
    _ridingExperience = null;
    _ridingType = null;

    _emergencyRelationship = null;
    _bloodType = null;
    _hasMedicalInsurance = false;
    _interestedInMedicalCover = false;
  }

  Future<void> _saveProgress() async {
    if (_localStorage == null) return;
    print('Saving registration progress... step $_currentStep');


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

  (double, double)? _parseLatLon(String? latLong) {
    if (latLong == null) return null;
    final parts = latLong.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());
    if (lat == null || lon == null) return null;
    return (lat, lon);
  }

  Future<void> _loadClubsForHomeLocation({double distanceKm = 10}) async {
    if (!mounted) return;

    setState(() {
      _isLoadingClubs = true;
    });

    try {
      final coords = _parseLatLon(_homeLatLong);
      final clubs = await _registrationService.fetchClubs(
        lat: coords?.$1,
        lon: coords?.$2,
        distanceKm: coords == null ? null : distanceKm,
      );

      if (!mounted) return;
      setState(() {
        _clubs = clubs;
        _clubsFetchAttempted = true;
        _isLoadingClubs = false;
      });
    } catch (e) {
      // Don’t hard-fail registration if clubs can’t be loaded.
      if (!mounted) return;
      setState(() {
        _clubsFetchAttempted = true;
        _isLoadingClubs = false;
      });
      _showError('Failed to load clubs: $e');
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Load clubs relative to the user's home location if available.
      final results = await Future.wait([
        _registrationService.fetchOccupations(),
        _registrationService.fetchClubs(
          lat: _parseLatLon(_homeLatLong)?.$1,
          lon: _parseLatLon(_homeLatLong)?.$2,
          distanceKm: _parseLatLon(_homeLatLong) == null ? null : 10,
        ),
      ]);

      if (mounted) {
        setState(() {
          _occupations = results[0];
          _clubs = results[1];
          _clubsFetchAttempted = true;
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
    // Persist the step before opening the image picker (app may pause/resume).
    await _saveProgress();
    try {
      // For both DL and passport we now allow uploads (gallery selection).
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      if (isDlPic) {
        setState(() {
          _dlPicFile = File(pickedFile.path);
          _dlPicId = null; // Reset ID when new file selected
        });

        // Upload immediately after selection
        await _uploadImageImmediately(pickedFile.path, true);
        return;
      }

      // Passport: verify the uploaded photo contains a human face.
      final hasFace = await _verifyPassportPhotoHasFace(pickedFile.path);
      if (!hasFace) {
        _showError(
          'No face detected. Please upload a clear passport-style photo showing your face.',
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _passportPhotoFile = File(pickedFile.path);
        _passportPhotoVerified = true;
        _passportPhotoId = null;
      });

      await _uploadImageImmediately(pickedFile.path, false);
    } catch (e) {
      if (mounted) {
        print('Error picking image: $e');
        _showError(
          'Failed to pick image. Please check app permissions and try again.',
        );
      }
    } finally {
      await _saveProgress();
    }
  }

  Future<bool> _verifyPassportPhotoHasFace(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: false,
        enableContours: false,
        enableClassification: false,
        enableTracking: false,
      ),
    );

    try {
      final faces = await detector.processImage(inputImage);
      // We only need a basic "human present" signal: at least one face.
      return faces.isNotEmpty;
    } catch (e) {
      // If detection fails, treat as unverified.
      print('Passport face detection failed: $e');
      return false;
    } finally {
      await detector.close();
    }
  }

  Future<void> _pickBikePhoto(String position) async {
    // Front/Side: upload only (gallery). Rear: allow camera (recommended) + upload.
    await _saveProgress();
    try {
      XFile? picked;

      if (position == 'rear') {
        picked = await _pickRearBikePhotoSource();
      } else {
        picked = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
      }

      if (picked == null || !mounted) return;

      final imagePath = picked.path;

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

      if (position == 'rear') {
        final plate = await _extractPlateFromRearImage(imagePath);

        if (!mounted) return;

        if (plate != null && plate.isNotEmpty) {
          if (_bikePlateController.text.trim().isEmpty) {
            _bikePlateController.text = plate;
          }
          _showSuccess('Registration detected: $plate');
        } else {
          // Fallback: ask user to input plate.
          final manual = await _promptForManualPlate();
          if (manual != null && manual.trim().isNotEmpty) {
            _bikePlateController.text = manual.trim().toUpperCase();
          }
        }

        // Still require a plate before uploading rear.
        if (_bikePlateController.text.trim().isEmpty) {
          _showError(
            'Please enter your motorcycle registration number to continue.',
          );
          return;
        }
      }

      // Upload immediately
      await _uploadBikePhotoImmediately(imagePath, position);
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to select bike photo: $e');
    }
  }

  Future<XFile?> _pickRearBikePhotoSource() async {
   await _saveProgress();
    // Bottom sheet: Camera (recommended) or Upload.
    return showModalBottomSheet<XFile?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        Future<void> pick(ImageSource source) async {
          final result = await _imagePicker.pickImage(
            source: source,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
          if (context.mounted) Navigator.pop(context, result);
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rear photo',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'For the rear photo, please ensure the number plate is sharp and readable (good lighting, no blur).',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: cs.surface,
                  leading: Icon(Icons.photo_camera_rounded, color: cs.primary),
                  title: const Text('Capture with camera (recommended)'),
                  subtitle: const Text('Best for reading the number plate'),
                  onTap: () => pick(ImageSource.camera),
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: cs.surface,
                  leading: Icon(Icons.upload_rounded, color: cs.primary),
                  title: const Text('Upload from gallery'),
                  subtitle: const Text('Choose an existing photo'),
                  onTap: () => pick(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _extractPlateFromRearImage(String imagePath) async {
    // Uses ML Kit text recognition and KenyanPlateParser.
    setState(() => _isLoading = true);
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognized = await recognizer.processImage(inputImage);
      final parsed = KenyanPlateParser.parseMotorcyclePlate(recognized);
      return parsed;
    } catch (e) {
      print('Rear plate OCR failed: $e');
      return null;
    } finally {
      await recognizer.close();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _promptForManualPlate() async {
    final controller = TextEditingController(text: _bikePlateController.text);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter registration number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We could not read the number plate from the photo. Please type your motorcycle registration number (e.g. KMFB 123A).',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Registration number',
                  hintText: 'KMFB 123A',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                Navigator.pop(context, value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
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
                    : 'Passport photo uploaded successfully! ✓ Face detected',
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
        _showError(
          'Failed to pick image. Please check app permissions and try again.',
        );
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

  void _nextStep() {
    // Validate current step before proceeding
    if (!_validateCurrentStep()) {
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // Persist the new step immediately (important if the OS recreates the
      // screen while picking images / switching apps).
      unawaited(_saveProgress());
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      unawaited(_saveProgress());
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
        // _showSuccess('✓ Account details verified');
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
        // _showSuccess('✓ Personal information verified');
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
        // _showSuccess('✓ Location details verified');
        return true;

      case 3: // Documents step
        if (_dlPicFile == null || _dlPicId == null) {
          _showError('Please upload your driving license photo');
          return false;
        }
        if (_passportPhotoFile == null || _passportPhotoId == null) {
          _showError(
            'Please upload your passport photo (upload only) so we can verify a face is present',
          );
          return false;
        }
        if (!_passportPhotoVerified) {
          _showError(
            'Passport photo must contain a clear face (face detection)',
          );
          return false;
        }
        // _showSuccess('✓ Documents uploaded and verified');
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
        if (_bikeFrontPhoto == null || _bikeFrontPhotoId == null) {
          _showError('Please upload bike front photo');
          return false;
        }
        if (_bikeSidePhoto == null || _bikeSidePhotoId == null) {
          _showError('Please upload bike side photo');
          return false;
        }
        if (_bikeRearPhoto == null || _bikeRearPhotoId == null) {
          _showError('Please upload bike rear photo');
          return false;
        }
        if (_hasBikeInsurance) {
          if (_insuranceCompanyController.text.trim().isEmpty) {
            _showError('Please enter insurance company name');
            return false;
          }
          if (_insuranceLogbookFile == null || _insuranceLogbookId == null) {
            _showError('Please upload insurance logbook');
            return false;
          }
        }
        // _showSuccess('✓ Bike details verified');
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
        // _showSuccess('✓ Emergency and medical information verified');
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
      'dl_pic': "1",
      //  _dlPicId,
      'passport_photo': "1",
      //  _passportPhotoId,

      // Location - Home (estate_id is required by API)
      'estate_id':
          1, // Default value, can be made dynamic if estate selection is added
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
        'model_id':
            1, // This should be fetched from bike models API if available
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
        'registration_expiry': DateTime.now()
            .add(Duration(days: 365))
            .toIso8601String()
            .split('T')[0],
        'bike_photo_url': 'BIKE/PH${_bikeFrontPhotoId ?? 0}.JPG',
        'odometer_reading': '0', // Can be added to form if needed
        'insurance_expiry': _hasBikeInsurance
            ? DateTime.now()
                  .add(Duration(days: 365))
                  .toIso8601String()
                  .split('T')[0]
            : DateTime.now().toIso8601String().split('T')[0],
        'is_primary': 1,
        'yom': _bikeYearController.text.isNotEmpty
            ? '${_bikeYearController.text}-01-01'
            : DateTime.now().toIso8601String().split('T')[0],
        'photo_front_id': 1,
        // _bikeFrontPhotoId ?? 1,
        'photo_side_id': 1,
        // _bikeSidePhotoId ?? 1,
        'photo_rear_id': 1,
        // _bikeRearPhotoId ?? 1,
        'insurance_logbook_id': 1,
        //  _insuranceLogbookId ?? 1,
        'has_insurance': _hasBikeInsurance ? 1 : 0,
        'experience_years': _ridingExperience != null
            ? _ridingExperience! ?? 0
            : 0,
        'commute_route':
            _workplacePlaceId ??
            '', // Using workplace place_id as commute route
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
        // Save email and password for auto-fill on login (only for registered users)
        // WARNING: Password stored temporarily, cleared after first login
        await _localStorage?.saveRegisteredCredentials(
          _emailController.text.trim(),
          _passwordController.text,
        );

        // Clear saved registration progress after successful registration
        await _localStorage?.clearRegistrationProgress();

        // Also clear in-memory form state so if user revisits register screen it starts fresh.
        if (mounted) {
          setState(() {
            _resetRegistrationFormState();
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Redirecting to login...'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );

        // Small delay to show the message
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/login');
        }
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Only show dialog on first step
        final result = await ConfirmDialog.show(
          context: context,
          title: 'Save Progress?',
          message:
              'Do you want to save your registration progress before exiting?',
          confirmText: 'Save & Exit',
          cancelText: 'Cancel',
        );

        if (result == true && context.mounted) {
          await _saveProgress();

          if (context.mounted) {
            context.pop();
          }
        }
      },

      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Account'),
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false  ,
          // leading: IconButton(
          //   icon: const Icon(Icons.arrow_back),
          //   onPressed: () => context.pop(),
          // ),
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
                          onPageChanged: (index) {
                            if (!mounted) return;
                            if (_currentStep != index) {
                              setState(() => _currentStep = index);
                              // Keep persisted progress in sync with the UI.
                              unawaited(_saveProgress());
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

  void _goToStep(int targetStep) {
    if (targetStep < 0 || targetStep >= _totalSteps) return;
    if (!mounted) return;

    setState(() => _currentStep = targetStep);
    _pageController.animateToPage(
      targetStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    unawaited(_saveProgress());
  }

  Widget _buildProgressIndicator() {
    final stepTitles = [
      'Account',
      'Personal',
      'Location',
      'Document',
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

              final canNavigateToStep = index <= _currentStep;

              return Expanded(
                child: InkWell(
                  onTap: canNavigateToStep ? () => _goToStep(index) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Opacity(
                    opacity: canNavigateToStep ? 1.0 : 0.45,
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
                            fontSize: 10,
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
                  ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
            child: InkWell(
              onTap: () => _openLocationSearch(
                context: context,
                title: 'Select Home Location',
                subtitle: 'Where do you live?',
                accentColor: AppTheme.brightRed,
                onLocationSelected: (locationData) {
                  setState(() {
                    _homeLatLong = locationData.latLongString;
                    _homePlaceId = "locationData.placeId";
                    _homeEstateName = locationData.estateName;
                    _homeAddress = locationData.address;
                    // Clear selected club if the available options might change.
                    _selectedClubId = null;
                  });
                  // Refresh clubs list based on the selected home coordinates.
                  unawaited(_loadClubsForHomeLocation(distanceKm: 10));
                },
                initialAddress: _homeAddress,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: AppTheme.silverGrey),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.mediumGrey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _homeAddress ??
                            'Tap to search for your home address...',
                        style: TextStyle(
                          color: _homeAddress != null
                              ? AppTheme.darkGrey
                              : AppTheme.mediumGrey,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _homeAddress != null
                          ? Icons.check_circle
                          : Icons.arrow_forward_ios,
                      color: _homeAddress != null
                          ? AppTheme.successGreen
                          : AppTheme.mediumGrey,
                      size: 20,
                    ),
                  ],
                ),
              ),
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
            isRefreashing: true,
            trailing: IconButton(onPressed: _loadClubsForHomeLocation, icon: const Icon(Icons.refresh, size:22, color:AppTheme.mediumGrey,)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdown<int>(
                  label: '',
                  hint: _isLoadingClubs ? 'Loading clubs…' : 'Select your club',
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
                  onChanged: _isLoadingClubs
                      ? null
                      : (value) {
                          setState(() => _selectedClubId = value);
                        },
                  icon: Icons.groups_rounded,
                ),
                if (_homeAddress != null &&
                    _clubsFetchAttempted &&
                    !_isLoadingClubs &&
                    _clubs.isEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'No clubs found in that region.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
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
            child: InkWell(
              onTap: () => _openLocationSearch(
                context: context,
                title: 'Select Workplace',
                subtitle: 'Where do you work?',
                accentColor: Colors.blue,
                onLocationSelected: (locationData) {
                  setState(() {
                    _workplaceLatLong = locationData.latLongString;
                    _workplacePlaceId = "1";
                    _workplaceEstateName = locationData.estateName;
                    _workplaceAddress = locationData.address;
                  });
                },
                initialAddress: _workplaceAddress,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: AppTheme.silverGrey),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.mediumGrey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _workplaceAddress ??
                            'Tap to search for your workplace...',
                        style: TextStyle(
                          color: _workplaceAddress != null
                              ? AppTheme.darkGrey
                              : AppTheme.mediumGrey,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _workplaceAddress != null
                          ? Icons.check_circle
                          : Icons.arrow_forward_ios,
                      color: _workplaceAddress != null
                          ? AppTheme.successGreen
                          : AppTheme.mediumGrey,
                      size: 20,
                    ),
                  ],
                ),
              ),
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
    isRefreashing = false,
    Widget? trailing,
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
                child: Icon(icon, color: backgroundColor, size: 22),
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
              Visibility(
                  visible: isRefreashing,
                
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child:trailing)
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
            description:
                'Upload your passport-style photo (upload only). We will check that a face is present.',
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
            const SizedBox(height: 24),

            _buildTextField(
              label: 'Policy Number',
              hint: 'Enter policy number',
              controller: _insurancePolicyController,
              icon: Icons.numbers,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget infoCard(String text) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: cs.onPrimaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motorbike photos',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload 3 photos: front, side and rear.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        infoCard(
          'Rear photo tip: make sure the number plate is sharp and readable (good lighting, no blur). We\'ll try to read it automatically. If we can\'t, we\'ll ask you to type it in.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildBikePhotoCard(
                label: 'Front',
                subtitle: 'Upload',
                photo: _bikeFrontPhoto,
                onTap: () => _pickBikePhoto('front'),
                highlight: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBikePhotoCard(
                label: 'Side',
                subtitle: 'Upload',
                photo: _bikeSidePhoto,
                onTap: () => _pickBikePhoto('side'),
                highlight: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildBikePhotoCard(
            label: 'Rear',
            subtitle: 'Plate must be visible',
            photo: _bikeRearPhoto,
            onTap: () => _pickBikePhoto('rear'),
            highlight: true,
            tall: true,
          ),
        ),
      ],
    );
  }

  Widget _buildBikePhotoCard({
    required String label,
    required String subtitle,
    required File? photo,
    required VoidCallback onTap,
    bool highlight = false,
    bool tall = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final borderColor = photo != null
        ? cs.tertiary
        : (highlight ? cs.primary : cs.outlineVariant);

    final bg = Color.alphaBlend(
      (highlight ? cs.primary : cs.surfaceVariant).withOpacity(0.08),
      cs.surface,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: tall ? 200 : 132,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: photo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(photo, fit: BoxFit.cover),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: _photoBadge(
                        text: label,
                        color: Colors.black.withOpacity(0.55),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: cs.tertiary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          cs.primary.withOpacity(0.12),
                          cs.surface,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        highlight
                            ? Icons.photo_camera_rounded
                            : Icons.add_photo_alternate_rounded,
                        color: cs.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      highlight ? 'Capture or upload' : 'Tap to upload',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _photoBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
              hint: 'e.g., SHA, AAR, Britam',
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

  Future<void> _openLocationSearch({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Color accentColor,
    required Function(LocationData) onLocationSelected,
    String? initialAddress,
  }) async {
    final result = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSearchPage(
          apiKey: ApiKeys.googlePlacesApiKey,
          title: title,
          subtitle: subtitle,
          accentColor: accentColor,
          initialAddress: initialAddress,
        ),
      ),
    );

    if (result != null) {
      onLocationSelected(result);
    }
  }
}
