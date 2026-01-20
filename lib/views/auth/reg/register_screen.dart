import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbak/models/bike_model.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/providers/package_provider.dart';
import 'package:pbak/providers/event_provider.dart';
import 'package:pbak/widgets/kyc_event_card.dart';
import 'package:pbak/providers/payment_provider.dart';
import 'package:pbak/models/package_model.dart';
import 'package:pbak/models/event_model.dart';
import 'package:intl/intl.dart';
import 'package:pbak/services/bike_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/services/comms/registration_service.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';
import 'package:pbak/services/member_service.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import 'package:pbak/utils/kenyan_plate_parser.dart';
import 'package:pbak/utils/dl_id_ocr_parser.dart';
import 'package:pbak/widgets/ConfirmDialog.dart';
import 'package:pbak/widgets/platform_image.dart';
import 'package:pbak/widgets/secure_payment_dialog.dart';

import 'package:pbak/utils/api_keys.dart';

import '../../../widgets/LocationSearchPage.dart';

import 'steps/account_step.dart';
import 'steps/personal_info_step.dart';
import 'steps/payments_step.dart';
import 'widgets/registration_bottom_bar.dart';
import 'widgets/registration_progress_header.dart';

class DrivingLicenseDetails {
  final String? surname;
  final String? otherNames;
  final String? nationalId;
  final String? licenseNo;
  final String? dateOfBirth;
  final String? dateOfIssue;
  final String? dateOfExpiry;
  final String? sex;
  final String? bloodGroup;
  final String? countyOfResidence;

  DrivingLicenseDetails({
    this.surname,
    this.otherNames,
    this.nationalId,
    this.licenseNo,
    this.dateOfBirth,
    this.dateOfIssue,
    this.dateOfExpiry,
    this.sex,
    this.bloodGroup,
    this.countyOfResidence,
  });
}

Future<(bool, DrivingLicenseDetails?)> _verifyDrivingLicenseImageWithDetails(
  String imagePath,
) async {
  if (kIsWeb) {
    // OCR/MLKit is not supported reliably on web in this app.
    // Fallback to manual entry/verification.
    return (false, null);
  }
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  try {
    final input = InputImage.fromFilePath(imagePath);
    final recognized = await recognizer.processImage(input);
    final text = recognized.text;

    // Extract details using regex patterns
    final details = DrivingLicenseDetails(
      surname: _extractField(text, r'SURNAME\s*([A-Z\s]+)'),
      otherNames: _extractField(text, r'OTHER\s*NAMES\s*([A-Z\s]+)'),
      nationalId: _extractField(text, r'NATIONAL\s*ID\s*NO\s*(\d+)'),
      licenseNo: _extractField(text, r'LICEN[CS]E\s*NO\s*([A-Z0-9]+)'),
      dateOfBirth: _extractField(
        text,
        r'DATE\s*OF\s*BIRTH\s*(\d{2}\.\d{2}\.\d{4})',
      ),
      dateOfIssue: _extractField(
        text,
        r'DATE\s*OF\s*ISSUE\s*(\d{2}\.\d{2}\.\d{4})',
      ),
      dateOfExpiry: _extractField(
        text,
        r'DATE\s*OF\s*EXPIRY\s*(\d{2}\.\d{2}\.\d{4})',
      ),
      sex: _extractField(text, r'SEX\s*(MALE|FEMALE)'),
      bloodGroup: _extractField(text, r'BLOOD\s*GROUP\s*([A-Z]+)'),
      countyOfResidence: _extractField(
        text,
        r'COUNTY\s*OF\s*RESIDENCE\s*([A-Z\s]+)',
      ),
    );

    // Verify it's a valid license (has critical fields)
    final isValid = details.nationalId != null || details.licenseNo != null;

    return (isValid, isValid ? details : null);
  } catch (e) {
    print('OCR Error: $e');
    return (false, null);
  } finally {
    await recognizer.close();
  }
}

String? _extractField(String text, String pattern) {
  final regex = RegExp(pattern, caseSensitive: false, multiLine: true);
  final match = regex.firstMatch(text);
  return match?.group(1)?.trim();
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Each step that contains a Form must have its own key.
  // PageView keeps multiple pages alive, so reusing the same GlobalKey causes
  // "Multiple widgets used the same GlobalKey".
  final _accountFormKey = GlobalKey<FormState>();
  final _personalFormKey = GlobalKey<FormState>();
  final _registrationService = RegistrationService();
  final _imagePicker = ImagePicker();
  LocalStorageService? _localStorage;
  bool _registerWithPbak = false;

  // Page controller for steps
  //
  // IMPORTANT: this must stay in sync with [_currentStep]. We re-create this
  // controller after loading saved progress so the PageView starts on the
  // correct step even if it gets built later (after async loading).
  late PageController _pageController;
  int _currentStep = 0;
  final int _totalSteps = 7; // Extended to 7 steps (Payments)
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
  String _loadingMessage = 'Loading...'; // Message shown during loading
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
  int? _selectedNyumbaKumiId;
  int? _selectedOccupationId;

  // Home Location (Google Places)
  String? _homeLatLong;
  String? _homePlaceId;
  String? _homeEstateName;
  String? _homeAddress;
  final _homeCoordsController = TextEditingController();

  // Workplace Location (Google Places)
  String? _workplaceLatLong;
  String? _workplacePlaceId;
  String? _workplaceEstateName;
  String? _workplaceAddress;

  // Images - Personal Documents
  File? _dlFrontPicFile;
  File? _dlBackPicFile;
  File? _passportPhotoFile;

  // Web-safe picked images
  XFile? _dlFrontPicXFile;
  XFile? _dlBackPicXFile;
  XFile? _passportPhotoXFile;

  int? _dlFrontPicId;
  int? _dlBackPicId;
  int? _passportPhotoId;

  bool _passportPhotoVerified = false;

  /// DL back (classes section) verification status.
  /// `null` means not checked yet.
  bool? _dlBackPicVerified;

  // OCR status for extracted document numbers
  bool _dlOcrInProgress = false;
  String? _dlOcrStatusMessage;

  // Bike Details
  final _bikeMakeController = TextEditingController();
  final _bikeModelController = TextEditingController();
  final _bikeYearController = TextEditingController();
  final _bikeColorController = TextEditingController();
  final _bikePlateController = TextEditingController();
  final _insuranceCompanyController = TextEditingController();
  final _insurancePolicyController = TextEditingController();

  // New bike fields
  final _bikeChassisNumberController = TextEditingController();
  final _bikeEngineNumberController = TextEditingController();
  final _bikeCapacityCcController = TextEditingController();
  // Odometer removed from registration form
  // final _bikeOdometerController = TextEditingController(text: '0');
  DateTime? _bikeInsuranceExpiry;

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

  // Emergency Contact 1
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  String? _emergencyRelationship;

  // Emergency Contact 2
  final _emergency2NameController = TextEditingController();
  final _emergency2PhoneController = TextEditingController();
  String? _emergency2Relationship;

  // Pillion Information (only shown when _registerWithPbak is false)
  bool _hasPillion = false;
  final _pillionNamesController = TextEditingController();
  final _pillionContactController = TextEditingController();
  final _pillionEmergencyContactController = TextEditingController();
  String? _pillionRelationship;

  // Payments (Step 7)
  bool _paymentAlreadyPaidMember = false; // legacy
  bool?
  _memberHasActivePackage; // null=unknown/not checked, true=linked, false=not linked
  bool _checkingMemberLinkStatus = false;

  /// If true, user was referred by a PBAK member and gets 50% discount (member pricing)
  bool _registerByPbak = false;
  PackageModel? _selectedPaymentPackage;
  final List<EventModel> _selectedPaymentEvents = [];
  final List<int> _selectedPaymentEventProductIds = [];
  bool _payForPackage = false;
  bool _payForEvent = false;
  final _paymentPhoneController = TextEditingController();
  final _paymentMemberIdController = TextEditingController();

  // Medical Info
  String? _bloodType;
  final _allergiesController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _medicalProviderController = TextEditingController();
  final _medicalPolicyController = TextEditingController();
  bool _hasMedicalInsurance = false;
  bool _interestedInMedicalCover = false;

  static const int _otherOptionId = -1;

  var _selectedModelId;

  int? _selectedMakeId;

  bool get _isOtherMake => _selectedMakeId == _otherOptionId;
  bool get _isOtherModel => _selectedModelId == _otherOptionId;

  bool _isLoadingModels = false;
  bool _isLoadingMakes = false;
  List<BikeMake> _makes = [];

  @override
  void initState() {
    super.initState();
    _bikePlateController.addListener(() {
      // Update conditional fields visibility when user types the plate.
      if (mounted) setState(() {});
    });
    _registrationService.initialize();

    // NOTE: Do not read _localStorage here; it is initialized asynchronously.
    // _registerWithPbak will be loaded in _initializeLocalStorage().

    // Default until we load saved progress.
    _pageController = PageController(initialPage: _currentStep);

    _initializeLocalStorage();
    _loadMakes();
  }

  Future<void> _initializeLocalStorage() async {
    _localStorage = await LocalStorageService.getInstance();

    // Load the registration mode flag (set from LoginScreen) *after* storage init.
    // This controls whether we require document/bike photo uploads.
    if (mounted) {
      setState(() {
        _registerWithPbak = _localStorage?.isRegisterWithPbak() ?? false;
        // Sync _registerByPbak with _registerWithPbak for PaymentsStep (50% discount)
        _registerByPbak = _registerWithPbak;
      });
    }

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

        // If we restored a make/model from saved progress, ensure models are loaded.
        if (_selectedMakeId != null && _models.isEmpty) {
          loadModels(_selectedMakeId!, preselectedModelId: _selectedModelId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMakes = false);
        _showError('Failed to load bike makes: $e');
      }
    }
  }

  Widget _buildManualDocumentForm() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.numbers_rounded, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document numbers',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enter your National ID and Driving License numbers manually.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(
            label: 'National ID Number',
            hint: 'Enter your National ID No',
            controller: _nationalIdController,
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            validator: (v) =>
                Validators.validateRequired(v, 'National ID Number'),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Driving License Number',
            hint: 'Enter your Licence No',
            controller: _drivingLicenseController,
            icon: Icons.card_membership_outlined,
            textCapitalization: TextCapitalization.characters,
            validator: (v) =>
                Validators.validateRequired(v, 'Driving License Number'),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure these details are correct before submitting.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadModels(int makeId, {int? preselectedModelId}) async {
    setState(() {
      _isLoadingModels = true;
      // Only reset model selection when user changed make.
      if (preselectedModelId == null) {
        _selectedModelId = null;
        _bikeModelController.clear();
      }
      _models = [];
    });

    try {
      final bikeService = ref.read(bikeServiceProvider);
      final models = await bikeService.getBikeModels(makeId);
      if (!mounted) return;

      setState(() {
        _models = models;
        _isLoadingModels = false;
      });

      // Restore previously selected model if it exists.
      if (preselectedModelId != null) {
        final selected = models.where((m) => m.modelId == preselectedModelId);
        if (selected.isNotEmpty) {
          final model = selected.first;
          setState(() {
            _selectedModelId = preselectedModelId;
            _bikeModelController.text = model.modelName ?? '';
          });
        }
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

    _bikeChassisNumberController.dispose();
    _bikeEngineNumberController.dispose();
    _bikeCapacityCcController.dispose();
    // _bikeOdometerController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergency2NameController.dispose();
    _emergency2PhoneController.dispose();
    _pillionNamesController.dispose();
    _pillionContactController.dispose();
    _pillionEmergencyContactController.dispose();
    _homeCoordsController.dispose();
    _paymentPhoneController.dispose();
    _paymentMemberIdController.dispose();
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
      _selectedNyumbaKumiId =
          savedProgress['nyumba_kumi_id'] ?? savedProgress['club_id'];

      // Location
      _homeLatLong = savedProgress['home_lat_long'];
      _homeCoordsController.text = _homeLatLong ?? '';
      _homePlaceId = savedProgress['home_place_id'];
      _homeEstateName = savedProgress['home_estate_name'];
      _homeAddress = savedProgress['home_address'];
      _workplaceLatLong = savedProgress['work_lat_long'];
      _workplacePlaceId = savedProgress['work_place_id'];
      _workplaceEstateName = savedProgress['work_estate_name'];
      _workplaceAddress = savedProgress['work_address'];

      // Documents
      _dlFrontPicId = savedProgress['dl_front_pic_id'];
      _dlBackPicId = savedProgress['dl_back_pic_id'];
      _passportPhotoId = savedProgress['passport_photo_id'];
      _passportPhotoVerified =
          savedProgress['passport_photo_verified'] ?? false;
      _dlBackPicVerified = savedProgress['dl_back_pic_verified'];

      // Restore image file paths if available
      if (savedProgress['dl_front_pic_path'] != null) {
        _dlFrontPicFile = File(savedProgress['dl_front_pic_path']);
      }
      if (savedProgress['dl_back_pic_path'] != null) {
        _dlBackPicFile = File(savedProgress['dl_back_pic_path']);
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
      _bikeChassisNumberController.text =
          savedProgress['bike_chassis_number'] ?? '';
      _bikeEngineNumberController.text =
          savedProgress['bike_engine_number'] ?? '';
      _bikeCapacityCcController.text = savedProgress['bike_capacity_cc'] ?? '';
      // bike_odometer_reading removed
      if (savedProgress['bike_insurance_expiry'] != null) {
        _bikeInsuranceExpiry = DateTime.tryParse(
          savedProgress['bike_insurance_expiry'],
        );
      }
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

      _emergency2NameController.text = savedProgress['emergency2_name'] ?? '';
      _emergency2PhoneController.text = savedProgress['emergency2_phone'] ?? '';
      _emergency2Relationship = savedProgress['emergency2_relationship'];

      // Pillion information
      _hasPillion = savedProgress['has_pillion'] ?? false;
      _pillionNamesController.text = savedProgress['pillion_names'] ?? '';
      _pillionContactController.text = savedProgress['pillion_contact'] ?? '';
      _pillionEmergencyContactController.text =
          savedProgress['pillion_emergency_contact'] ?? '';
      _pillionRelationship = savedProgress['pillion_relationship'];

      // Payments
      _paymentAlreadyPaidMember = savedProgress['payment_already_paid'] == true;
      _memberHasActivePackage = savedProgress['payment_member_linked'];
      _paymentPhoneController.text = savedProgress['payment_phone'] ?? '';
      _paymentMemberIdController.text =
          savedProgress['payment_member_id'] ?? '';
      // selected package restored later in build step by id
      final pkgId = savedProgress['payment_package_id'];

      // selected event + products
      final savedEventId = savedProgress['payment_event_id'];
      if (savedEventId != null) {
        final id = savedEventId is int
            ? savedEventId
            : int.tryParse(savedEventId.toString());
        if (id != null) {
          _selectedPaymentEvents
            ..clear()
            ..add(
              EventModel(
                id: id.toString(),
                eventId: id,
                title: '',
                description: '',
                dateTime: DateTime.now(),
                location: '',
                hostClubId: '',
                hostClubName: '',
                currentAttendees: 0,
                type: '',
              ),
            );
        }
      }
      final savedProductIds = savedProgress['payment_event_product_ids'];
      _selectedPaymentEventProductIds
        ..clear()
        ..addAll(
          (savedProductIds is List)
              ? savedProductIds
                    .map((e) => int.tryParse(e.toString()))
                    .whereType<int>()
              : const <int>[],
        );
      if (pkgId is int) {
        _selectedPaymentPackage = PackageModel(packageId: pkgId);
      } else if (pkgId is String) {
        _selectedPaymentPackage = PackageModel(packageId: int.tryParse(pkgId));
      }

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

    // If user restored to Payments step (step 6) and membership status is unknown,
    // trigger the check so the Complete button will work.
    if (_currentStep == 6 && _memberHasActivePackage == null) {
      unawaited(_checkMemberLinkStatusInBackground());
    }
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

    _bikeChassisNumberController.clear();
    _bikeEngineNumberController.clear();
    _bikeCapacityCcController.clear();
    // odometer removed
    _bikeInsuranceExpiry = null;

    _emergencyNameController.clear();
    _emergencyPhoneController.clear();
    _emergency2NameController.clear();
    _emergency2PhoneController.clear();

    _allergiesController.clear();
    _medicalConditionsController.clear();
    _medicalProviderController.clear();
    _medicalPolicyController.clear();

    // Reset selections
    _dateOfBirth = null;
    _selectedGender = null;
    _selectedOccupationId = null;
    _selectedNyumbaKumiId = null;

    _homeLatLong = null;
    _homeCoordsController.clear();
    _homePlaceId = null;
    _homeEstateName = null;
    _homeAddress = null;
    _workplaceLatLong = null;
    _workplacePlaceId = null;
    _workplaceEstateName = null;
    _workplaceAddress = null;

    _dlFrontPicId = null;
    _dlBackPicId = null;
    _passportPhotoId = null;
    _passportPhotoVerified = false;
    _dlBackPicVerified = null;
    _dlFrontPicFile = null;
    _dlBackPicFile = null;
    _passportPhotoFile = null;

    _dlOcrInProgress = false;
    _dlOcrStatusMessage = null;

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
    _emergency2Relationship = null;

    _hasPillion = false;
    _pillionNamesController.clear();
    _pillionContactController.clear();
    _pillionEmergencyContactController.clear();
    _pillionRelationship = null;

    _paymentAlreadyPaidMember = false;
    _memberHasActivePackage = null;
    _selectedPaymentPackage = null;
    _paymentPhoneController.clear();
    _paymentMemberIdController.clear();
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
      'nyumba_kumi_id': _selectedNyumbaKumiId,
      'club_id': null,

      // Location
      'home_lat_long': _homeCoordsController.text.trim().isEmpty
          ? _homeLatLong
          : _homeCoordsController.text.trim(),
      'home_place_id': _homePlaceId,
      'home_estate_name': _homeEstateName,
      'home_address': _homeAddress,
      'work_lat_long': _workplaceLatLong,
      'work_place_id': _workplacePlaceId,
      'work_estate_name': _workplaceEstateName,
      'work_address': _workplaceAddress,

      // Documents
      'dl_front_pic_id': _dlFrontPicId,
      'dl_back_pic_id': _dlBackPicId,
      'passport_photo_id': _passportPhotoId,
      'passport_photo_verified': _passportPhotoVerified,
      'dl_back_pic_verified': _dlBackPicVerified,
      'dl_front_pic_path': _dlFrontPicFile?.path,
      'dl_back_pic_path': _dlBackPicFile?.path,
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
      'bike_chassis_number': _bikeChassisNumberController.text,
      'bike_engine_number': _bikeEngineNumberController.text,
      'bike_capacity_cc': _bikeCapacityCcController.text,
      // bike_odometer_reading removed
      'bike_insurance_expiry': _bikeInsuranceExpiry?.toIso8601String().split(
        'T',
      )[0],
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
      'emergency2_name': _emergency2NameController.text,
      'emergency2_phone': _emergency2PhoneController.text,
      'emergency2_relationship': _emergency2Relationship,

      // Pillion information
      'has_pillion': _hasPillion,
      'pillion_names': _pillionNamesController.text,
      'pillion_contact': _pillionContactController.text,
      'pillion_emergency_contact': _pillionEmergencyContactController.text,
      'pillion_relationship': _pillionRelationship,

      // Payments
      'payment_already_paid': _paymentAlreadyPaidMember,
      'payment_member_linked': _memberHasActivePackage,
      'payment_phone': _paymentPhoneController.text,
      // Keep in sync with National ID captured earlier.
      'payment_member_id': _nationalIdController.text.trim(),
      'payment_package_id': _selectedPaymentPackage?.packageId,
      'payment_event_id': _selectedPaymentEvents.isEmpty
          ? null
          : _selectedPaymentEvents.first.eventId,
      // Also store a direct event_id for registration payload (used for free event registration).
      'event_id': _selectedPaymentEvents.isEmpty
          ? null
          : _selectedPaymentEvents.first.eventId,
      'payment_event_product_ids': _selectedPaymentEventProductIds,

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
    // Backwards-compat wrapper: old call sites.
    if (isDlPic) {
      return _pickDlImage(isFront: true);
    }
    return _pickPassportImage();
  }

  Future<void> _pickDlImage({required bool isFront}) async {
    // Persist the step before opening the image picker (app may pause/resume).
    await _saveProgress();
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      // Verify the DL image before accepting it.
      // - FRONT: ensure it's actually a DL (anchors like NATIONAL ID NO / LICENCE NO)
      // - BACK: ensure it includes a motorcycle class row (A1 or A2) with a value
      if (isFront) {
        if (!kIsWeb) {
          final (isValid, details) =
              await _verifyDrivingLicenseImageWithDetails(pickedFile.path);

          if (!isValid || details == null) {
            _showError(
              'Could not verify this as a driving license. Please upload a clear DL FRONT image that shows the text "NATIONAL ID NO" or "LICENCE NO".',
            );
            return;
          }

          // Build verification message with detected fields
          final detectedFields = <String>[];
          if (details.nationalId != null) {
            detectedFields.add('National ID: ${details.nationalId}');
          }
          if (details.licenseNo != null) {
            detectedFields.add('License No: ${details.licenseNo}');
          }
          if (details.surname != null || details.otherNames != null) {
            final name = [
              details.otherNames,
              details.surname,
            ].where((e) => e != null).join(' ');
            if (name.isNotEmpty) detectedFields.add('Name: $name');
          }

          if (detectedFields.isNotEmpty) {
            _showSuccess('Verified DL image. ${detectedFields.join(' | ')}');
          } else {
            _showSuccess('Verified DL image.');
          }

          // Optionally auto-populate form fields if they exist
          _autopopulateFromDlDetails(details);
        }

        // On web we skip OCR verification but still allow upload.
      } else {
        // DL BACK verification: skip on web.
        if (kIsWeb) {
          setState(() {
            _dlBackPicVerified = false;
          });
        } else {
          // DL BACK verification: try to confirm motorcycle class (A1/A2) is present.
          // If verification fails, still allow upload but mark it as not verified.
          final recognizer = TextRecognizer(
            script: TextRecognitionScript.latin,
          );
          try {
            final input = InputImage.fromFilePath(pickedFile.path);
            final recognized = await recognizer.processImage(input);
            final text = recognized.text;

            final hasMotorcycleClass = DlIdOcrParser.hasMotorcycleClassA1OrA2(
              text,
            );
            if (!hasMotorcycleClass) {
              setState(() {
                _dlBackPicVerified = false;
              });
              _showError(
                'Image was not verified (A1/A2 not detected). You can still upload it.',
              );
            } else {
              setState(() {
                _dlBackPicVerified = true;
              });
              _showSuccess(
                'Verified DL back image (A1/A2 motorcycle class detected).',
              );
            }
          } catch (e) {
            setState(() {
              _dlBackPicVerified = false;
            });
            _showError(
              'Image was not verified (could not read A1/A2 section). You can still upload it.',
            );
          } finally {
            await recognizer.close();
          }
        }
      }

      setState(() {
        if (isFront) {
          _dlFrontPicXFile = pickedFile;
          _dlFrontPicFile = kIsWeb ? null : File(pickedFile.path);
          _dlFrontPicId = null;
        } else {
          _dlBackPicXFile = pickedFile;
          _dlBackPicFile = kIsWeb ? null : File(pickedFile.path);
          _dlBackPicId = null;
          // If we haven't set verification status yet (e.g. OCR didn't run), keep it unknown.
          _dlBackPicVerified = _dlBackPicVerified;
        }
      });

      // Upload immediately after selection
      await _uploadDlImageImmediately(
        pickedFile.path,
        isFront: isFront,
        xFile: pickedFile,
      );

      // Attempt OCR extraction once we have at least one side.
      unawaited(_tryExtractDlAndIdNumbersFromDlImages());
    } catch (e) {
      if (mounted) {
        print('Error picking DL image: $e');
        _showError(
          'Failed to pick image. Please check app permissions and try again.',
        );
      }
    } finally {
      await _saveProgress();
    }
  }

  // Optional: Auto-populate form fields from extracted details
  void _autopopulateFromDlDetails(DrivingLicenseDetails details) {
    // Example: If you have TextEditingControllers for these fields
    if (details.nationalId != null && _nationalIdController.text.isEmpty) {
      _nationalIdController.text = details.nationalId!;
    }
    if (details.licenseNo != null && _drivingLicenseController.text.isEmpty) {
      _drivingLicenseController.text = details.licenseNo!;
    }
    // Add more field mappings as needed...
  }

  // Future<(bool, List<String>)> _verifyDrivingLicenseImageWithDetails(
  //   String imagePath,
  // ) async {
  //   final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  //   try {
  //     final input = InputImage.fromFilePath(imagePath);
  //     final recognized = await recognizer.processImage(input);
  //     final text = recognized.text;

  //     // REQUIRED anchors per your spec.
  //     final hasNationalIdAnchor = RegExp(
  //       r'NATIONAL\s*ID\s*NO',
  //       caseSensitive: false,
  //     ).hasMatch(text);
  //     final hasLicenceNoAnchor = RegExp(
  //       r'LICEN[CS]E\s*NO',
  //       caseSensitive: false,
  //     ).hasMatch(text);

  //     final detected = <String>[];
  //     if (hasNationalIdAnchor) detected.add('NATIONAL ID NO');
  //     if (hasLicenceNoAnchor) detected.add('LICENCE NO');

  //     return (hasNationalIdAnchor || hasLicenceNoAnchor, detected);
  //   } catch (_) {
  //     // If OCR fails, reject (prevents dummy photos being uploaded).
  //     return (false, const <String>[]);
  //   } finally {
  //     await recognizer.close();
  //   }
  // }

  Future<void> _pickPassportImage() async {
    await _saveProgress();
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

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
        _passportPhotoXFile = pickedFile;
        _passportPhotoFile = kIsWeb ? null : File(pickedFile.path);
        _passportPhotoVerified = true;
        _passportPhotoId = null;
      });

      await _uploadImageImmediately(pickedFile.path, false, xFile: pickedFile);
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
    if (kIsWeb) {
      // No face detection on web.
      return true;
    }
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

  Future<bool> _verifyBikePhotoHasMotorcycle(String imagePath) async {
    if (kIsWeb) {
      // No image labeling on web.
      return true;
    }
    final inputImage = InputImage.fromFilePath(imagePath);
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.6),
    );

    try {
      final labels = await labeler.processImage(inputImage);
      // Accept common labels for motorcycles/bikes.
      const accepted = {
        'motorcycle',
        'motorbike',
        'moped',
        'scooter',
        'bike',
        'bicycle',
      };

      for (final l in labels) {
        final t = l.label.toLowerCase();
        if (accepted.contains(t)) return true;
      }
      return false;
    } catch (e) {
      // If labeling fails, reject (prevents random uploads).
      debugPrint('Motorcycle label check failed: $e');
      return false;
    } finally {
      await labeler.close();
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

      // Verify that the uploaded image actually contains a motorcycle.
      final isMotorcycle = await _verifyBikePhotoHasMotorcycle(imagePath);
      if (!isMotorcycle) {
        _showError(
          'This photo does not look like a motorcycle. Please upload a clear motorcycle photo.',
        );
        return;
      }

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
          // New plate detected: overwrite old value and clear dependent fields.
          final normalizedPlate = plate.trim().toUpperCase();
          _bikePlateController.text = '';
          _bikeChassisNumberController.clear();
          _bikeEngineNumberController.clear();
          _bikePlateController.text = normalizedPlate;

          if (mounted) setState(() {});
          _showSuccess('Registration detected: $normalizedPlate');
        } else {
          // Fallback: ask user to input plate.
          final manual = await _promptForManualPlate();
          if (manual != null && manual.trim().isNotEmpty) {
            final normalized = manual.trim().toUpperCase();
            _bikePlateController.text = '';
            _bikeChassisNumberController.clear();
            _bikeEngineNumberController.clear();
            _bikePlateController.text = normalized;
            // Refresh conditional fields (engine/chassis visibility).
            if (mounted) setState(() {});
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
      await _uploadBikePhotoImmediately(imagePath, position, xFile: picked);
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
                if (!kIsWeb) ...[
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: cs.surface,
                    leading: Icon(
                      Icons.photo_camera_rounded,
                      color: cs.primary,
                    ),
                    title: const Text('Capture with camera (recommended)'),
                    subtitle: const Text('Best for reading the number plate'),
                    onTap: () => pick(ImageSource.camera),
                  ),
                  const SizedBox(height: 8),
                ],
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

  bool _isKenyanMotorcyclePlate(String plate) {
    final normalized = plate.trim().toUpperCase();
    if (normalized.isEmpty) return false;
    return KenyanPlateParser.isValidMotorcyclePlate(normalized);
  }

  Future<String?> _extractPlateFromRearImage(String imagePath) async {
    if (kIsWeb) {
      // No OCR on web.
      return null;
    }
    // Uses ML Kit text recognition.
    // Priority:
    //  1) Kenyan motorcycle plate (KMxx...)
    //  2) Non-Kenyan plate candidate -> ask user to confirm
    //  3) If nothing reliable -> return null (manual entry)
    setState(() => _isLoading = true);
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognized = await recognizer.processImage(inputImage);

      // 1) Kenyan motorcycle plates
      final kenyan = KenyanPlateParser.parseMotorcyclePlate(recognized);
      if (kenyan != null && kenyan.trim().isNotEmpty) return kenyan;

      // 2) Non-Kenyan candidate
      final candidate = KenyanPlateParser.parseNonKenyanPlateCandidate(
        recognized,
      );
      if (candidate != null && candidate.trim().isNotEmpty) {
        final normalized = candidate.trim().toUpperCase();
        final confirmed = await _confirmNonKenyanPlate(normalized);
        if (confirmed == true) {
          return normalized;
        }
        // User said no/cancel: fall back to manual entry
        return null;
      }

      return null;
    } catch (e) {
      print('Rear plate OCR failed: $e');
      return null;
    } finally {
      await recognizer.close();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _confirmNonKenyanPlate(String detectedPlate) async {
    if (!mounted) return null;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Non-Kenyan plate detected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We detected a non-Kenyan number plate. Please confirm this is your plate number:',
              ),
              const SizedBox(height: 12),
              Text(
                detectedPlate,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
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

  Future<void> _uploadDlImageImmediately(
    String filePath, {
    required bool isFront,
    XFile? xFile,
  }) async {
    if (!mounted) return;

    // Show loading state
    setState(() => _isLoading = true);

    try {
      // Backend expects specific doc_type values.
      // Front: dl_pic_front (notes: "dl image front")
      // Back:  dl_pic_back  (notes: "dl image back")
      final imageType = isFront ? 'dl_pic_front' : 'dl_pic_back';
      final notes = isFront ? 'dl image front' : 'dl image back';

      final uploadedId = kIsWeb && xFile != null
          ? await _registrationService.uploadImageXFile(
              xFile,
              imageType,
              notes: notes,
            )
          : await _registrationService.uploadImage(
              filePath,
              imageType,
              notes: notes,
            );

      if (!mounted) return;

      if (uploadedId != null) {
        setState(() {
          if (isFront) {
            _dlFrontPicId = uploadedId;
          } else {
            _dlBackPicId = uploadedId;
          }
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFront
                  ? 'Driving license front uploaded successfully!'
                  : 'Driving license back uploaded successfully!',
            ),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        _showError('Failed to upload driving license image. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error uploading driving license image: $e');
      }
    }
  }

  Future<void> _uploadImageImmediately(
    String filePath,
    bool isDlPic, {
    XFile? xFile,
  }) async {
    if (!mounted) return;

    // Show loading state
    setState(() => _isLoading = true);

    try {
      if (isDlPic) {
        throw StateError('Legacy DL upload is not supported.');
      }

      final uploadedId = kIsWeb && xFile != null
          ? await _registrationService.uploadImageXFile(xFile, 'passport')
          : await _registrationService.uploadImage(filePath, 'passport');

      if (!mounted) return;

      if (uploadedId != null) {
        setState(() {
          _passportPhotoId = uploadedId;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Passport photo uploaded successfully! ✓ Face detected',
            ),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        _showError('Failed to upload image. Please try again.');
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
    String position, {
    XFile? xFile,
  }) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final imageType = 'bike_$position';
      final uploadedId = kIsWeb && xFile != null
          ? await _registrationService.uploadImageXFile(xFile, imageType)
          : await _registrationService.uploadImage(filePath, imageType);

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
        await _uploadInsuranceLogbookImmediately(
          pickedFile.path,
          xFile: pickedFile,
        );
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

  Future<void> _uploadInsuranceLogbookImmediately(
    String filePath, {
    XFile? xFile,
  }) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final uploadedId = kIsWeb && xFile != null
          ? await _registrationService.uploadImageXFile(
              xFile,
              'insurance_logbook',
            )
          : await _registrationService.uploadImage(
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
    if (_dlFrontPicFile != null && _dlFrontPicId == null) {
      _showError('Driving license front upload incomplete. Please re-select.');
      return false;
    }

    if (_dlBackPicFile != null && _dlBackPicId == null) {
      _showError('Driving license back upload incomplete. Please re-select.');
      return false;
    }

    if (_passportPhotoFile != null && _passportPhotoId == null) {
      _showError(
        'Passport photo upload incomplete. Please re-select the image.',
      );
      return false;
    }

    // Both images should be uploaded by now (IDs exist)
    return _dlFrontPicId != null &&
        _dlBackPicId != null &&
        _passportPhotoId != null;
  }

  void _nextStep() {
    // Validate current step before proceeding.
    if (!_validateCurrentStep()) {
      return;
    }

    // When leaving Documents step, we already have the National ID.
    // Kick off membership/package check in background so Payments step can render correctly.
    if (_currentStep == 3) {
      unawaited(_checkMemberLinkStatusInBackground());
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // When entering Payments step (step 6), ensure membership status is checked.
      // This handles cases where user restored progress directly to this step.
      if (_currentStep == 6 && _memberHasActivePackage == null) {
        unawaited(_checkMemberLinkStatusInBackground());
      }

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

  Future<void> _checkMemberLinkStatusInBackground() async {
    final raw = _nationalIdController.text.trim();
    final id = int.tryParse(raw);
    if (id == null) {
      // Leave as unknown; Payments step will show a message.
      return;
    }

    // Avoid duplicate checks.
    if (_checkingMemberLinkStatus) return;

    setState(() {
      _checkingMemberLinkStatus = true;
    });

    try {
      final service = MemberService();
      final linked = await service.hasActivePackageByIdNumber(
        id,
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _memberHasActivePackage = linked;
        _paymentAlreadyPaidMember = linked;
        if (linked) {
          _selectedPaymentPackage = null;
          _payForPackage = false;
        }
        // Keep payment member id in sync for payload/backwards compat.
        _paymentMemberIdController.text = raw;
        _checkingMemberLinkStatus = false;
      });
      unawaited(_saveProgress());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingMemberLinkStatus = false;
        // keep _memberHasActivePackage as-is/null
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Account step
        if (!(_accountFormKey.currentState?.validate() ?? true)) {
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
        if (!(_personalFormKey.currentState?.validate() ?? true)) {
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
        final coordsToUse = _homeCoordsController.text.trim().isEmpty
            ? _homeLatLong
            : _homeCoordsController.text.trim();
        if (_parseLatLon(coordsToUse) == null) {
          _showError(
            'Please provide valid home coordinates in the format "lat, lon"',
          );
          return false;
        }
        if (_selectedNyumbaKumiId == null) {
          _showError('Please select a club to join');
          return false;
        }
        // _showSuccess('✓ Location details verified');
        return true;

      case 3: // Documents step
        if (_registerWithPbak) {
          // OCR / image-based validation
          final hasDlFrontFile = kIsWeb
              ? _dlFrontPicXFile != null
              : _dlFrontPicFile != null;
          final hasDlBackFile = kIsWeb
              ? _dlBackPicXFile != null
              : _dlBackPicFile != null;

          if (!hasDlFrontFile && _dlFrontPicId == null) {
            _showError('Please upload your driving license FRONT photo');
            return false;
          }
          if (!hasDlBackFile && _dlBackPicId == null) {
            _showError('Please upload your driving license BACK photo');
            return false;
          }

          // Numbers should be extracted from DL images; if not, ask for manual entry.
          if (_nationalIdController.text.trim().isEmpty ||
              _drivingLicenseController.text.trim().isEmpty) {
            _showError(
              'Please verify your ID and DL numbers in the Documents step',
            );
            return false;
          }
          final hasPassportFile = kIsWeb
              ? _passportPhotoXFile != null
              : _passportPhotoFile != null;
          if (!hasPassportFile && _passportPhotoId == null) {
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
        } else {
          // Manual entry mode: only validate text fields
          if (_nationalIdController.text.trim().isEmpty) {
            _showError('Please enter your National ID number');
            return false;
          }
          if (_drivingLicenseController.text.trim().isEmpty) {
            _showError('Please enter your Driving License number');
            return false;
          }
        }

        // Passport validation stays the same

        return true;

      case 4: // Bike details step

        if (_registerWithPbak) {
          if (_selectedMakeId == null) {
            _showError('Please select bike make');
            return false;
          }
          // Validate custom make text field when "Other" is selected
          if (_isOtherMake && _bikeMakeController.text.trim().isEmpty) {
            _showError('Please enter bike make');
            return false;
          }
          if (_selectedModelId == null) {
            _showError('Please select bike model');
            return false;
          }
          // Validate custom model text field when "Other" is selected
          if (_isOtherModel && _bikeModelController.text.trim().isEmpty) {
            _showError('Please enter bike model');
            return false;
          }
          // Note: Chassis validation is skipped - not required for standard make/model selection
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
            // if (_insuranceLogbookFile == null || _insuranceLogbookId == null) {
            //   _showError('Please upload insurance logbook');
            //   return false;
            // }
          }
          // _showSuccess('✓ Bike details verified');
          return true;
        } else {
          // Manual bike registration mode
          if (_bikeMakeController.text.trim().isEmpty) {
            _showError('Please enter bike make');
            return false;
          }
          if (_bikeModelController.text.trim().isEmpty) {
            _showError('Please enter bike model');
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
          if (_hasBikeInsurance) {
            if (_insuranceCompanyController.text.trim().isEmpty) {
              _showError('Please enter insurance company name');
              return false;
            }
          }
          // Photos are optional in manual mode
          return true;
        }

      case 5: // Emergency & Medical info step

        if (_emergencyNameController.text.trim().isEmpty) {
          _showError('Emergency contact 1 name is required');
          return false;
        }
        if (_emergencyPhoneController.text.trim().isEmpty) {
          _showError('Emergency contact 1 phone is required');
          return false;
        }
        if (_emergencyRelationship == null || _emergencyRelationship!.isEmpty) {
          _showError('Please select emergency contact 1 relationship');
          return false;
        }
        if (_registerWithPbak) {
          if (_emergency2NameController.text.trim().isEmpty) {
            _showError('Emergency contact 2 name is required');
            return false;
          }
          if (_emergency2PhoneController.text.trim().isEmpty) {
            _showError('Emergency contact 2 phone is required');
            return false;
          }
          if (_emergency2Relationship == null ||
              _emergency2Relationship!.isEmpty) {
            _showError('Please select emergency contact 2 relationship');
            return false;
          }
        }
        if (_bloodType == null || _bloodType!.isEmpty) {
          _showError('Please select your blood type');
          return false;
        }

        if (_hasPillion) {
          if (_pillionNamesController.text.trim().isEmpty) {
            _showError('Pillion name is required');
            return false;
          }
          if (_pillionContactController.text.trim().isEmpty) {
            _showError('Pillion contact is required');
            return false;
          }
          if (_pillionEmergencyContactController.text.trim().isEmpty) {
            _showError('Pillion emergency contact is required');
            return false;
          }
          if (_pillionRelationship == null || _pillionRelationship!.isEmpty) {
            _showError('Please select pillion relationship');
            return false;
          }
        }
        // _showSuccess('✓ Emergency and medical information verified');
        return true;

      case 6: // Payments step
        // ID number already captured in Documents step.
        if (_nationalIdController.text.trim().isEmpty) {
          _showError(
            'Please enter your National ID number in the Documents step',
          );
          return false;
        }

        // Ensure we have checked membership status.
        if (_memberHasActivePackage == null) {
          _showError('Please wait as we confirm your membership status');
          return false;
        }

        // Package and event selection is OPTIONAL - members can register without selecting either.
        // If they want to pay, they can do so later from the app.
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
            prefixIcon: Icon(icon, color: Colors.black54, size: 22),
            filled: true,
            fillColor: Colors.white,
          ),
          dropdownColor: Colors.white,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
          items: items,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    // print('Submitting registration...');
    //  if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Preparing your registration...';
    });

    // Verify images are uploaded
    // setState(() => _loadingMessage = 'Uploading documents...');

    // final imagesValid = await _uploadImages();
    // if (!imagesValid) {
    //   setState(() {
    //     _isLoading = false;
    //     _loadingMessage = 'Loading...';
    //   });
    //   return; // Error message already shown
    // }

    setState(() => _loadingMessage = 'Submitting your information...');

    // Prepare registration data
    final homeCoords = _homeCoordsController.text.trim().isEmpty
        ? (_homeLatLong ?? '')
        : _homeCoordsController.text.trim();

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
      'nyumba_kumi_id': _selectedNyumbaKumiId ?? 1,

      // Documents
      'dl_front_pic_id': _dlFrontPicId,
      'dl_back_pic_id': _dlBackPicId,
      'passport_photo': _passportPhotoId,

      // Location - Home (estate_id is required by API)
      if (_homeAddress != null) 'road_name': _homeAddress,
      if (homeCoords != null && homeCoords.isNotEmpty)
        'home_lat_long': homeCoords,

      // Location - Workplace
      if (_workplaceLatLong != null) 'work_lat_long': _workplaceLatLong,

      // Employer info (required by API if occupation is employment-related)
      // 'employer': _selectedOccupationId == 'Employed' ? 'Employer Name' : 'N/A',
      'industry': 'Private', // Default value
      //  coz we dont have a list for  industries  yet

      // Event selected in PaymentsStep (used for free event registration without payment)
      if (_selectedPaymentEvents.isNotEmpty)
        'event_id': _selectedPaymentEvents.first.eventId,

      // Bike Details
      'bike': {
        'model_id': _isOtherModel ? 1 : (_selectedModelId ?? 1),
        'registration_number': _bikePlateController.text.trim(),
        if (!_isKenyanMotorcyclePlate(_bikePlateController.text))
          'chassis_number': _bikeChassisNumberController.text.trim(),
        if (!_isKenyanMotorcyclePlate(_bikePlateController.text))
          'engine_number': _bikeEngineNumberController.text.trim(),
        'capacity_cc': _bikeCapacityCcController.text.trim(),
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

        // odometer_reading removed from registration form
        'insurance_expiry':
            (_hasBikeInsurance
                    ? (_bikeInsuranceExpiry ??
                          DateTime.now().add(const Duration(days: 365)))
                    : DateTime.now())
                .toIso8601String()
                .split('T')[0],
        'is_primary': 1,
        'yom': _bikeYearController.text.isNotEmpty
            ? '${_bikeYearController.text}-01-01'
            : DateTime.now().toIso8601String().split('T')[0],
        'photo_front_id': _bikeFrontPhotoId,
        // _bikeFrontPhotoId ?? 1,
        'photo_side_id': _bikeSidePhotoId,
        // _bikeSidePhotoId ?? 1,
        'photo_rear_id': _bikeRearPhotoId,
        // _bikeRearPhotoId ?? 1,
        // 'insurance_logbook_id': 1,
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

      // Emergency Contacts (nested object as per API specification)
      'emergency': {
        'primary': {
          'contact_name': _emergencyNameController.text.trim(),
          'emergency_contact': _emergencyPhoneController.text.trim(),
          'relationship': _emergencyRelationship ?? 'Other',
        },
        if (_registerWithPbak)
          'secondary': {
            'contact_name': _emergency2NameController.text.trim(),
            'emergency_contact': _emergency2PhoneController.text.trim(),
            'relationship': _emergency2Relationship ?? 'Other',
          },
      },

      // Payment info - only include if user paid for a package
      if (_selectedPaymentPackage?.packageId != null)
        'payment': {
          'already_paid': 1,
          'member_id_number': _nationalIdController.text.trim(),
          'package_id': _selectedPaymentPackage!.packageId,
          'phone': _paymentPhoneController.text.trim(),
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

    setState(() => _loadingMessage = 'Finalizing your account...');
    final response = await _registrationService.registerUser(userData);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadingMessage = 'Loading...';
      });

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
    // Defensive: if user toggled the flag on LoginScreen and navigated here,
    // ensure we read the latest value.
    if (_localStorage != null) {
      final latest = _localStorage!.isRegisterWithPbak();
      if (latest != _registerWithPbak) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _registerWithPbak = latest;

            // Keep form state consistent when the flag changes.
            if (_registerWithPbak) {
              // Pillion details are not used when registering with PBAK.
              _hasPillion = false;
              _pillionNamesController.clear();
              _pillionContactController.clear();
              _pillionEmergencyContactController.clear();
              _pillionRelationship = null;
            } else {
              // Emergency contact 2 is only used when registering with PBAK.
              _emergency2NameController.clear();
              _emergency2PhoneController.clear();
              _emergency2Relationship = null;
            }
          });
        });
      }
    }

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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Create Account'),
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        bottomNavigationBar: (_isLoading && _clubs.isEmpty)
            ? null
            : RegistrationBottomBar(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                isLoading: _isLoading,
                onBack: _previousStep,
                onNext: _nextStep,
                onSubmit: _handleRegister,
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
                      _loadingMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  Column(
                    children: [
                      RegistrationProgressHeader(
                        stepTitles: const [
                          'Account',
                          'Personal',
                          'Location',
                          'Documents',
                          'Bike',
                          'Emergency',
                          'Payments',
                        ],
                        currentStep: _currentStep,
                        totalSteps: _totalSteps,
                        onStepTap: (step) {
                          if (step <= _currentStep) _goToStep(step);
                        },
                      ),
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
                                AccountStep(
                                  formKey: _accountFormKey,
                                  emailController: _emailController,
                                  phoneController: _phoneController,
                                  alternativePhoneController:
                                      _alternativePhoneController,
                                  passwordController: _passwordController,
                                  confirmPasswordController:
                                      _confirmPasswordController,
                                  obscurePassword: _obscurePassword,
                                  obscureConfirmPassword:
                                      _obscureConfirmPassword,
                                  onTogglePassword: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  onToggleConfirmPassword: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                                  buildTextField:
                                      ({
                                        required String label,
                                        required String hint,
                                        required TextEditingController
                                        controller,
                                        TextInputType? keyboardType,
                                        String? Function(String?)? validator,
                                        required IconData icon,
                                        bool obscureText = false,
                                        Widget? suffixIcon,
                                        TextCapitalization textCapitalization =
                                            TextCapitalization.none,
                                      }) {
                                        return _buildTextField(
                                          label: label,
                                          hint: hint,
                                          controller: controller,
                                          keyboardType: keyboardType,
                                          validator: validator,
                                          icon: icon,
                                          obscureText: obscureText,
                                          suffixIcon: suffixIcon,
                                          textCapitalization:
                                              textCapitalization,
                                        );
                                      },
                                ),
                                PersonalInfoStep(
                                  formKey: _personalFormKey,
                                  firstNameController: _firstNameController,
                                  lastNameController: _lastNameController,
                                  dateOfBirth: _dateOfBirth,
                                  onDateOfBirthChanged: (d) =>
                                      setState(() => _dateOfBirth = d),
                                  selectedGender: _selectedGender,
                                  onGenderChanged: (g) =>
                                      setState(() => _selectedGender = g),
                                  selectedOccupationId: _selectedOccupationId,
                                  occupations: _occupations,
                                  onOccupationChanged: (v) =>
                                      setState(() => _selectedOccupationId = v),
                                  ridingExperience: _ridingExperience,
                                  onRidingExperienceChanged: (v) =>
                                      setState(() => _ridingExperience = v),
                                  ridingType: _ridingType,
                                  onRidingTypeChanged: (v) =>
                                      setState(() => _ridingType = v),
                                  buildTextField:
                                      ({
                                        required String label,
                                        required String hint,
                                        required TextEditingController
                                        controller,
                                        TextInputType? keyboardType,
                                        String? Function(String?)? validator,
                                        required IconData icon,
                                        bool obscureText = false,
                                        Widget? suffixIcon,
                                        TextCapitalization textCapitalization =
                                            TextCapitalization.none,
                                      }) {
                                        return _buildTextField(
                                          label: label,
                                          hint: hint,
                                          controller: controller,
                                          keyboardType: keyboardType,
                                          validator: validator,
                                          icon: icon,
                                          obscureText: obscureText,
                                          suffixIcon: suffixIcon,
                                          textCapitalization:
                                              textCapitalization,
                                        );
                                      },
                                  buildDropdown:
                                      <T>({
                                        required String label,
                                        required String hint,
                                        required T? value,
                                        required List<DropdownMenuItem<T>>
                                        items,
                                        required void Function(T?)? onChanged,
                                        required IconData icon,
                                        bool enabled = true,
                                      }) {
                                        return _buildDropdown<T>(
                                          label: label,
                                          hint: hint,
                                          value: value,
                                          items: items,
                                          onChanged: onChanged,
                                          icon: icon,
                                          enabled: enabled,
                                        );
                                      },
                                ),
                                _buildLocationStep(),
                                _buildDocumentsStep(),
                                _buildBikeDetailsStep(),
                                _buildEmergencyInfoStep(),
                                PaymentsStep(
                                  paymentAlreadyPaidMember:
                                      _paymentAlreadyPaidMember,
                                  selectedPackage: _selectedPaymentPackage,
                                  selectedEvents: _selectedPaymentEvents,
                                  selectedEventProductIds:
                                      _selectedPaymentEventProductIds,
                                  paymentPhoneController:
                                      _paymentPhoneController,
                                  memberIdController: _nationalIdController,
                                  // Pass ID number to fetch member-specific event pricing from API
                                  idNumber: _nationalIdController.text.trim(),
                                  // Pass email for payment payload
                                  email: _emailController.text.trim(),
                                  onAlreadyPaidChanged: (_) {
                                    // Legacy (switch removed from PaymentsStep UI).
                                  },
                                  onMemberLinkStatusChanged: (_) {
                                    // No-op: membership status is checked in background when leaving Documents step.
                                  },
                                  registerByPbak: _registerByPbak,
                                  onRegisterByPbakChanged: (value) {
                                    setState(() => _registerByPbak = value);
                                    _saveProgress();
                                  },
                                  onPackageSelected: (pkg) {
                                    setState(() {
                                      _selectedPaymentPackage = pkg;
                                      _payForPackage = pkg != null;
                                    });
                                  },
                                  onEventsChanged: (events) {
                                    setState(() {
                                      _selectedPaymentEvents.clear();
                                      _selectedPaymentEvents.addAll(
                                        events.take(1),
                                      );
                                      _payForEvent =
                                          _selectedPaymentEvents.isNotEmpty;
                                      if (_selectedPaymentEvents.isEmpty) {
                                        _selectedPaymentEventProductIds.clear();
                                      }
                                    });
                                  },
                                  onEventProductIdsChanged: (ids) {
                                    setState(() {
                                      _selectedPaymentEventProductIds
                                        ..clear()
                                        ..addAll(ids);
                                    });
                                  },
                                  memberHasActivePackage:
                                      _memberHasActivePackage,
                                  checkingMemberStatus:
                                      _checkingMemberLinkStatus,
                                  onRefreshMemberStatus:
                                      _checkMemberLinkStatusInBackground,
                                  onSaveProgress: _saveProgress,
                                  buildTextField: _buildTextField,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                  // Loading overlay - shown when submitting registration
                  if (_isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _loadingMessage,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please wait...',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
      'Payments',
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

  // Legacy inline step builders were removed after extracting step widgets.

  Widget _buildLocationStep() {
    final theme = Theme.of(context);

    // Softer, more playful accents for this step (avoid harsh error-red/purple).
    const homeAccent = Color(0xFF00A6A6); // teal
    const clubAccent = Color(0xFF5C6BC0); // indigo

    final hasHomeLocation = _homeAddress != null;
    final hasWorkLocation = _workplaceAddress != null;
    final hasNyumbaKumiSelected = _selectedNyumbaKumiId != null;

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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppTheme.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tell us where you live, work, and ride',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
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
                  color: AppTheme.goldAccent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${[hasHomeLocation, hasWorkLocation, hasNyumbaKumiSelected].where((e) => e).length}/3',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGold,
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
            iconColor: homeAccent,
            backgroundColor: homeAccent,
            isRequired: true,
            isSelected: _homeAddress != null,
            child: InkWell(
              onTap: () => _openLocationSearch(
                context: context,
                title: 'Select Home Location',
                subtitle: 'Where do you live?',
                accentColor: homeAccent,
                onLocationSelected: (locationData) {
                  setState(() {
                    _homeLatLong = locationData.latLongString;
                    _homeCoordsController.text = locationData.latLongString;
                    _homePlaceId = "locationData.placeId";
                    _homeEstateName = locationData.estateName;
                    _homeAddress = locationData.address;
                    // Clear selected club if the available options might change.
                    _selectedNyumbaKumiId = null;
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

          const SizedBox(height: 12),

          const SizedBox(height: 24),

          // Club Selection Section
          _buildLocationCard(
            theme: theme,
            title: 'PBAK Nyumba Kumi',
            subtitle: 'Select your PBAK Nyumba Kumi group',
            icon: Icons.groups_rounded,
            iconColor: clubAccent,
            backgroundColor: clubAccent,
            isRequired: true,
            isSelected: _selectedNyumbaKumiId != null,
            isRefreashing: true,
            trailing: IconButton(
              onPressed: _loadClubsForHomeLocation,
              icon: const Icon(
                Icons.refresh,
                size: 22,
                color: AppTheme.mediumGrey,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdown<int>(
                  label: '',
                  hint: _isLoadingClubs ? 'Loading clubs…' : 'Select your club',
                  value: _selectedNyumbaKumiId,
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
                          setState(() => _selectedNyumbaKumiId = value);
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
        color: backgroundColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: isSelected
              ? backgroundColor.withOpacity(0.45)
              : AppTheme.lightSilver,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
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
                  gradient: LinearGradient(
                    colors: [
                      backgroundColor.withOpacity(0.18),
                      backgroundColor.withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
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
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                        if (isRequired) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.goldAccent.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Required',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkGold,
                                letterSpacing: 0.2,
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

                child: SizedBox(width: 16, height: 16, child: trailing),
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
                      _registerWithPbak ? 'Upload Documents' : 'Documents',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Visibility(
                      visible: _registerWithPbak,
                      child: Text(
                        'Upload your identification documents',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildImageUploadCard(
            title: 'Driving License (Front)',
            description: 'Upload a clear photo of the FRONT side',
            icon: Icons.credit_card,
            imageFile: _dlFrontPicFile,
            xFile: _dlFrontPicXFile,
            uploadedId: _dlFrontPicId,
            onTap: () => _pickDlImage(isFront: true),
          ),
          const SizedBox(height: 16),

          _buildImageUploadCard(
            title: 'Driving License (Back)',
            description: 'Upload a clear photo of the BACK side',
            icon: Icons.credit_card,
            imageFile: _dlBackPicFile,
            xFile: _dlBackPicXFile,
            uploadedId: _dlBackPicId,
            verificationMessage: _dlBackPicVerified == null
                ? null
                : (_dlBackPicVerified == true
                      ? 'Verified (A1/A2 detected)'
                      : 'Image was not verified'),
            isVerified: _dlBackPicVerified,
            onTap: () => _pickDlImage(isFront: false),
          ),
          const SizedBox(height: 16),

          _registerWithPbak
              ? _buildDocumentNumbersCard()
              : _buildManualDocumentForm(),

          const SizedBox(height: 16),

          _buildImageUploadCard(
            title: 'Passport Photo',
            description:
                'Upload your passport-style photo (upload only). We will check that a face is present.',
            icon: Icons.portrait,
            imageFile: _passportPhotoFile,
            xFile: _passportPhotoXFile,
            uploadedId: _passportPhotoId,
            onTap: () => _pickImage(false),
          ),
          const SizedBox(height: 24),

          Visibility(
            visible: _registerWithPbak,
            child: Container(
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
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentNumbersCard() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final missingId = _nationalIdController.text.trim().isEmpty;
    final missingDl = _drivingLicenseController.text.trim().isEmpty;

    final message = _dlOcrInProgress
        ? 'Scanning your DL images…'
        : (_dlOcrStatusMessage ??
              'We will try to auto-detect your National ID and DL number from your uploaded driving license images.');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.numbers_rounded, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document numbers',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (_dlOcrInProgress)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // These fields are ALWAYS editable. OCR is only a helper.
          _buildTextField(
            label: 'National ID Number',
            hint: 'Enter your National ID No',
            controller: _nationalIdController,
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            validator: (v) =>
                Validators.validateRequired(v, 'National ID Number'),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Driving License Number',
            hint: 'Enter your Licence No',
            controller: _drivingLicenseController,
            icon: Icons.card_membership_outlined,
            textCapitalization: TextCapitalization.characters,
            validator: (v) =>
                Validators.validateRequired(v, 'Driving License Number'),
          ),
          const SizedBox(height: 8),
          Text(
            'If these values are wrong or not detected, you can edit them manually.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          if (missingId || missingDl) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _dlOcrInProgress
                        ? null
                        : () => _tryExtractDlAndIdNumbersFromDlImages(
                            forceDialogOnFailure: true,
                          ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _dlOcrInProgress
                        ? null
                        : () => _promptForManualDlAndId(
                            missingId: missingId,
                            missingDl: missingDl,
                          ),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Enter manually'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required String description,
    required IconData icon,
    required File? imageFile,
    XFile? xFile,
    required int? uploadedId,
    String? verificationMessage,
    bool? isVerified,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUploaded = uploadedId != null;
    final hasFile = kIsWeb ? xFile != null : imageFile != null;

    return Visibility(
      visible: _registerWithPbak,
      child: Card(
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
                          if (verificationMessage != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '"$verificationMessage"',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isVerified == true
                                    ? AppTheme.successGreen
                                    : AppTheme.warningOrange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
                if (hasFile) ...[
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? (xFile != null
                                  ? PlatformImage(
                                      file: null,
                                      xFile: xFile,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 180,
                                      width: double.infinity,
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: Text('Preview not available'),
                                      ),
                                    ))
                            : PlatformImage(
                                file: imageFile,
                                xFile: null,
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
                                    ? 'Uploaded (doc_id: $uploadedId)'
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.black12,
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
      ),
    );
  }

  /// Get the currently selected model object
  BikeModelCatalog? get _selectedBikeModel {
    if (_selectedModelId == null) return null;
    try {
      return _models.firstWhere((m) => m.modelId == _selectedModelId);
    } catch (_) {
      return null;
    }
  }

  /// Build info card showing selected bike details (make, model, CC, category, fuel type)
  Widget _buildSelectedBikeInfoCard() {
    final model = _selectedBikeModel;
    if (model == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final details = <String>[];
    if (model.make?.makeName != null) {
      details.add('Make: ${model.make!.makeName}');
    }
    if (model.modelName != null) {
      details.add('Model: ${model.modelName}');
    }
    if (model.engineCapacity != null && model.engineCapacity!.isNotEmpty) {
      details.add('Engine: ${model.engineCapacity}cc');
    }
    if (model.category != null && model.category!.isNotEmpty) {
      details.add('Category: ${model.category}');
    }
    if (model.fuelType != null && model.fuelType!.isNotEmpty) {
      details.add('Fuel: ${model.fuelType}');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.successGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bike Selected',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: details.map((detail) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tell us about your motorcycle',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.35,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            value: _selectedMakeId,
            decoration: const InputDecoration(
              labelText: 'Bike Make',
              hintText: 'Select manufacturer',
              prefixIcon: Icon(Icons.business_rounded),
            ),
            items: [
              ..._makes.map((make) {
                return DropdownMenuItem<int>(
                  value: make.id,
                  child: Text(make.name),
                );
              }),
              const DropdownMenuItem<int>(
                value: _otherOptionId,
                child: Text('Other'),
              ),
            ].toList(),
            onChanged: _isEditMode
                ? null
                : (value) {
                    if (value == null) return;

                    // Handle "Other" selection specially
                    if (value == _otherOptionId) {
                      setState(() {
                        _selectedMakeId = value;
                        _selectedModelId = _otherOptionId;
                        _bikeMakeController.clear();
                        _bikeModelController.clear();
                        _models = [];
                      });
                      return;
                    }

                    final selectedMake = _makes.where((m) => m.id == value);
                    setState(() {
                      _selectedMakeId = value;
                      _bikeMakeController.text = selectedMake.isNotEmpty
                          ? selectedMake.first.name
                          : '';
                      // Changing make invalidates model.
                      _selectedModelId = null;
                      _bikeModelController.clear();
                    });

                    loadModels(value);
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
              items: [
                ..._models.map((model) {
                  final cc = model.engineCapacity;
                  final label = cc != null && cc.isNotEmpty
                      ? '${model.modelName ?? 'Unknown'} (${cc}cc)'
                      : model.modelName ?? 'Unknown';
                  return DropdownMenuItem<int>(
                    value: model.modelId!,
                    child: Text(label),
                  );
                }),
                const DropdownMenuItem<int>(
                  value: _otherOptionId,
                  child: Text('Other'),
                ),
              ].toList(),
              onChanged:
                  _isEditMode || _selectedMakeId == null || _isLoadingModels
                  ? null
                  : (value) {
                      if (value == null) return;

                      // Handle "Other" selection specially
                      if (value == _otherOptionId) {
                        setState(() {
                          _selectedModelId = value;
                          _bikeModelController.clear();
                        });
                        return;
                      }

                      final selectedModel = _models.where(
                        (m) => m.modelId == value,
                      );
                      setState(() {
                        _selectedModelId = value;
                        _bikeModelController.text = selectedModel.isNotEmpty
                            ? (selectedModel.first.modelName ?? '')
                            : '';
                      });
                    },
            ),

            // Show "Other Make" text field when user selects Other
            if (_isOtherMake) ...[
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Other Make',
                hint: 'Enter bike manufacturer name',
                controller: _bikeMakeController,
                icon: Icons.edit_rounded,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.validateRequired(v, 'Bike make'),
              ),
            ],

            if (_selectedModelId != null) ...[
              const SizedBox(height: 24),
              // Show "Other Model" text field when user selects Other
              if (_isOtherModel) ...[
                _buildTextField(
                  label: 'Other Model',
                  hint: 'Enter bike model name',
                  controller: _bikeModelController,
                  icon: Icons.edit_rounded,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      Validators.validateRequired(v, 'Bike model'),
                ),
              ] else ...[
                _buildSelectedBikeInfoCard(),
              ],
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
          const SizedBox(height: 20),

          Visibility(
            visible: _registerWithPbak,
            child: Text(
              'Bike Photos',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Visibility(
            visible: _registerWithPbak,
            child: _buildBikePhotoSection(),
          ),
          const SizedBox(height: 32),

          if (_registerWithPbak && _bikeRearPhotoId != null) ...[
            _buildTextField(
              label: 'Registration Plate',
              hint: 'KXXX 123',
              controller: _bikePlateController,
              validator: (val) =>
                  Validators.validateRequired(val, 'Registration plate'),
              icon: Icons.credit_card,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),
          ] else if (_registerWithPbak && _bikeRearPhotoId == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Upload the REAR bike photo first, then we will show the registration number section.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else if (!_registerWithPbak) ...[
            _buildTextField(
              label: 'Registration Plate',
              hint: 'KXXX 123',
              controller: _bikePlateController,
              validator: (val) =>
                  Validators.validateRequired(val, 'Registration plate'),
              icon: Icons.credit_card,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),
          ],

          if (_bikePlateController.text.isNotEmpty &&
              !_isKenyanMotorcyclePlate(_bikePlateController.text)) ...[
            _buildTextField(
              label: 'Chassis Number (optional)',
              hint: 'Enter chassis number',
              controller: _bikeChassisNumberController,
              validator: (val) =>
                  Validators.validateRequired(val, 'Chassis number'),
              icon: Icons.confirmation_number_rounded,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),

            _buildTextField(
              label: 'Engine Number (optional)',
              hint: 'Enter engine number',
              controller: _bikeEngineNumberController,
              validator: Validators.validateEngineNumber,
              icon: Icons.settings_rounded,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 32),
          ],

          // Bike Photos Section

          // Insurance Section
          SwitchListTile(
            title: const Text(
              'Do you have motorcycle insurance?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            value: _hasBikeInsurance,
            onChanged: (value) => setState(() {
              _hasBikeInsurance = value;
              if (!value) {
                _bikeInsuranceExpiry = null;
              }
            }),
            activeColor: AppTheme.brightRed,
          ),

          if (_hasBikeInsurance) ...[
            const SizedBox(height: 16),

            InkWell(
              onTap: () async {
                final initial =
                    _bikeInsuranceExpiry ??
                    DateTime.now().add(const Duration(days: 365));
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );

                if (picked != null) {
                  setState(() => _bikeInsuranceExpiry = picked);
                  unawaited(_saveProgress());
                }
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Insurance Expiry Date',
                  prefixIcon: Icon(Icons.event_available_rounded),
                ),
                child: Text(
                  _bikeInsuranceExpiry == null
                      ? 'Select expiry date'
                      : _bikeInsuranceExpiry!.toIso8601String().split('T')[0],
                ),
              ),
            ),
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

    final showPreview = !kIsWeb && photo != null;

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
        child: showPreview
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    kIsWeb
                        ? Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Text(
                                'Preview not available on web',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Image.file(photo!, fit: BoxFit.cover),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This information could save your life',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.35,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

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
              DropdownMenuItem(value: 'NOT SURE', child: Text('NOT SURE')),
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
                      'Emergency Contact 1',
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

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Pillion toggle - only shown when NOT registering with PBAK
                if (!_registerWithPbak) ...[
                  SwitchListTile(
                    title: const Text(
                      'Riding with a pillion?',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Add your pillion\'s details for safety',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _hasPillion,
                    onChanged: (value) => setState(() => _hasPillion = value),
                    activeColor: AppTheme.brightRed,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                ],

                // Pillion section: only available when NOT registering with PBAK,
                // and only shown when the toggle is active.
                if (!_registerWithPbak && _hasPillion) ...[
                  Row(
                    children: [
                      Icon(Icons.person_add, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Pillion Information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    label: 'Pillion Full Name',
                    hint: 'Jane Doe',
                    controller: _pillionNamesController,
                    validator: (val) =>
                        Validators.validateRequired(val, 'Pillion Name'),
                    icon: Icons.person_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    label: 'Pillion Phone Number',
                    hint: '+254712345678',
                    controller: _pillionContactController,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                    icon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    label: 'Pillion Emergency Contact',
                    hint: '+254712345678',
                    controller: _pillionEmergencyContactController,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                    icon: Icons.emergency_outlined,
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown<String>(
                    label: 'Relationship to You',
                    hint: 'Select relationship',
                    value: _pillionRelationship,
                    items: const [
                      DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
                      DropdownMenuItem(
                        value: 'partner',
                        child: Text('Partner'),
                      ),
                      DropdownMenuItem(
                        value: 'family',
                        child: Text('Family Member'),
                      ),
                      DropdownMenuItem(value: 'friend', child: Text('Friend')),
                      DropdownMenuItem(
                        value: 'colleague',
                        child: Text('Colleague'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) =>
                        setState(() => _pillionRelationship = value),
                    icon: Icons.family_restroom,
                  ),
                ],

                // Emergency Contact 2: only shown/required when registering with PBAK.
                if (_registerWithPbak) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.emergency,
                        color: AppTheme.brightRed.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Emergency Contact 2',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
                    controller: _emergency2NameController,
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
                    controller: _emergency2PhoneController,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                    icon: Icons.phone,
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown<String>(
                    label: 'Relationship',
                    hint: 'Select relationship',
                    value: _emergency2Relationship,
                    items: const [
                      DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
                      DropdownMenuItem(value: 'parent', child: Text('Parent')),
                      DropdownMenuItem(
                        value: 'sibling',
                        child: Text('Sibling'),
                      ),
                      DropdownMenuItem(value: 'child', child: Text('Child')),
                      DropdownMenuItem(value: 'friend', child: Text('Friend')),
                      DropdownMenuItem(
                        value: 'relative',
                        child: Text('Other Relative'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _emergency2Relationship = value),
                    icon: Icons.family_restroom,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsStep() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final packagesAsync = ref.watch(packagesProvider);
    final currentEventsAsync = ref.watch(upcomingEventsProvider);

    // If we restored only the packageId, replace it with the full package once loaded.
    void ensureSelectedPackage(List<PackageModel> packages) {
      final selectedId = _selectedPaymentPackage?.packageId;
      if (selectedId == null) return;
      final full = packages.where((p) => p.packageId == selectedId).toList();
      if (full.isNotEmpty && full.first != _selectedPaymentPackage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _selectedPaymentPackage = full.first);
        });
      }
    }

    final amount = _selectedPaymentPackage?.price ?? 0;
    final formattedAmount = NumberFormat('#,###.00').format(amount);

    Widget sectionTitle(String text, {String? subtitle}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget card({required Widget child}) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payments',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick a package or pay for an event via M-Pesa.',
            style: theme.textTheme.bodySmall?.copyWith(
              // height: 1.35,
              color: cs.onSurfaceVariant,
            ),
          ),

          sectionTitle(
            'Pay for an event',
            subtitle:
                'If you are registering for a ride/event that requires payment, select it here.',
          ),
          currentEventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return Text(
                  'No current events available right now.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                );
              }

              return SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 6),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final e = events[index];
                    final feeText = e.fee == null
                        ? 'Free'
                        : 'KES ${e.fee!.toStringAsFixed(2)}';
                    final deadline = e.registrationDeadline;
                    final deadlineText = deadline == null
                        ? null
                        : DateFormat(
                            'MMM d • HH:mm',
                          ).format(deadline.toLocal());

                    return KycEventCard(
                      is50off: _registerWithPbak,
                      event: e,
                      selected: _selectedPaymentEvents.any(
                        (x) => x.eventId == e.eventId,
                      ),
                      onTap: () async {
                        final enteredPhone = await showModalBottomSheet<String?>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (context) {
                            final theme = Theme.of(context);
                            final cs = theme.colorScheme;
                            final bottomInset = MediaQuery.of(
                              context,
                            ).viewInsets.bottom;
                            final screenWidth = MediaQuery.of(
                              context,
                            ).size.width;
                            final screenHeight = MediaQuery.of(
                              context,
                            ).size.height;
                            final isWeb = screenWidth > 600;

                            final dateText = DateFormat(
                              'EEE, MMM d, yyyy • HH:mm',
                            ).format(e.dateTime.toLocal());
                            final clubName = (e.hostClubName ?? '').trim();

                            Widget infoRow({
                              required IconData icon,
                              required String label,
                              required String value,
                            }) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(icon, size: 20, color: cs.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: isWeb ? 2 : 3,
                                      child: Text(
                                        label,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: isWeb ? 5 : 7,
                                      child: Text(
                                        value,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              height: 1.4,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final phoneController = TextEditingController(
                              text: _paymentPhoneController.text,
                            );
                            String? phoneError;

                            return StatefulBuilder(
                              builder: (context, setModalState) {
                                Future<void> onPayNow() async {
                                  final raw = phoneController.text.trim();
                                  final err = Validators.validatePhone(raw);
                                  if (err != null) {
                                    setModalState(() => phoneError = err);
                                    return;
                                  }
                                  Navigator.pop(context, raw);
                                }

                                return SafeArea(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: bottomInset,
                                    ),
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: isWeb
                                              ? 600
                                              : double.infinity,
                                          maxHeight: screenHeight * 0.9,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            isWeb ? 24 : 16,
                                            isWeb ? 16 : 8,
                                            isWeb ? 24 : 16,
                                            isWeb ? 24 : 16,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              // Image Section
                                              if ((e.imageUrl ?? '')
                                                  .isNotEmpty) ...[
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: AspectRatio(
                                                    aspectRatio: 16 / 9,
                                                    child: Image.network(
                                                      e.imageUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => Container(
                                                            color: cs
                                                                .surfaceContainerHighest,
                                                            child: Center(
                                                              child: Icon(
                                                                Icons
                                                                    .event_rounded,
                                                                size: 48,
                                                                color: cs
                                                                    .onSurfaceVariant,
                                                              ),
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                              ],

                                              // Title Section
                                              Text(
                                                e.title,
                                                style: theme
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: isWeb ? 24 : 20,
                                                    ),
                                              ),
                                              if (clubName.isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Hosted by $clubName',
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            cs.onSurfaceVariant,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ],

                                              const SizedBox(height: 20),
                                              Divider(
                                                height: 1,
                                                color: cs.outlineVariant,
                                              ),
                                              const SizedBox(height: 20),

                                              // Scrollable Content
                                              Flexible(
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Event Details
                                                      infoRow(
                                                        icon: Icons
                                                            .calendar_month_rounded,
                                                        label: 'Date',
                                                        value: dateText,
                                                      ),
                                                      infoRow(
                                                        icon: Icons
                                                            .payments_rounded,
                                                        label: 'Fee',
                                                        value: feeText,
                                                      ),
                                                      infoRow(
                                                        icon: Icons
                                                            .location_on_rounded,
                                                        label: 'Location',
                                                        value:
                                                            e.location.isEmpty
                                                            ? 'Location TBD'
                                                            : e.location,
                                                      ),
                                                      if (deadlineText != null)
                                                        infoRow(
                                                          icon: Icons
                                                              .timer_rounded,
                                                          label: 'Deadline',
                                                          value: deadlineText,
                                                        ),

                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      Divider(
                                                        height: 1,
                                                        color:
                                                            cs.outlineVariant,
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),

                                                      // Description
                                                      Text(
                                                        'Description',
                                                        style: theme
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Text(
                                                        e.description.isEmpty
                                                            ? 'No description available.'
                                                            : e.description,
                                                        style: theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              color: cs
                                                                  .onSurfaceVariant,
                                                              height: 1.5,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 20),
                                              Divider(
                                                height: 1,
                                                color: cs.outlineVariant,
                                              ),
                                              const SizedBox(height: 20),

                                              // Phone Input Section
                                              Text(
                                                'Phone number',
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 10),
                                              TextField(
                                                controller: phoneController,
                                                keyboardType:
                                                    TextInputType.phone,
                                                decoration: InputDecoration(
                                                  prefixIcon: const Icon(
                                                    Icons.phone_iphone_rounded,
                                                  ),
                                                  labelText:
                                                      'Enter phone number',
                                                  hintText: '+254712345678',
                                                  errorText: phoneError,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                onChanged: (_) {
                                                  if (phoneError != null) {
                                                    setModalState(
                                                      () => phoneError = null,
                                                    );
                                                  }
                                                },
                                                onSubmitted: (_) => onPayNow(),
                                              ),

                                              SizedBox(height: isWeb ? 24 : 16),

                                              // Action Buttons
                                              if (isWeb)
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    OutlinedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                      style: OutlinedButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 32,
                                                              vertical: 16,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        'Close',
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    FilledButton.icon(
                                                      onPressed: onPayNow,
                                                      icon: const Icon(
                                                        Icons.payments_rounded,
                                                      ),
                                                      label: const Text(
                                                        'Register',
                                                      ),
                                                      style: FilledButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 32,
                                                              vertical: 16,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              else
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        style: OutlinedButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 14,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          'Close',
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      flex: 2,
                                                      child: FilledButton.icon(
                                                        onPressed: onPayNow,
                                                        icon: const Icon(
                                                          Icons
                                                              .payments_rounded,
                                                        ),
                                                        label: const Text(
                                                          'Pay now',
                                                        ),
                                                        style: FilledButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 14,
                                                              ),
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
                                );
                              },
                            );
                          },
                        );

                        if (!mounted) return;
                        final normalizedPhone = enteredPhone?.trim();
                        if (normalizedPhone == null ||
                            normalizedPhone.isEmpty) {
                          return;
                        }

                        setState(() {
                          _paymentPhoneController.text = normalizedPhone;

                          final idx = _selectedPaymentEvents.indexWhere(
                            (x) => x.eventId == e.eventId,
                          );
                          if (idx >= 0) {
                            _selectedPaymentEvents.removeAt(idx);
                          } else {
                            _selectedPaymentEvents.add(e);
                          }

                          _payForEvent = _selectedPaymentEvents.isNotEmpty;
                        });
                        unawaited(_saveProgress());

                        _showSuccess(
                          'Phone captured ($normalizedPhone). Payment flow will be added next.',
                        );
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              'Failed to load current events: $e',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ),

          const SizedBox(height: 18),

          sectionTitle(
            'Membership status',
            subtitle:
                'If you have already paid, toggle this on and provide your member ID. Otherwise pick a package below.',
          ),
          card(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Already a paid member',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Skip payment and enter your member ID number.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              value: _paymentAlreadyPaidMember,
              onChanged: (v) {
                setState(() {
                  _paymentAlreadyPaidMember = v;
                  if (v) {
                    _selectedPaymentPackage = null;
                    _paymentPhoneController.clear();
                  }
                });
                unawaited(_saveProgress());
              },
            ),
          ),

          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _paymentAlreadyPaidMember
                ? Column(
                    key: const ValueKey('paid_member'),
                    children: [
                      _buildTextField(
                        label: 'ID Number',
                        hint: 'e.g. 12345',
                        controller: _paymentMemberIdController,
                        icon: Icons.badge_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (_paymentAlreadyPaidMember) {
                            return Validators.validateRequired(
                              v,
                              'Member ID Number',
                            );
                          }
                          return null;
                        },
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('pay_now'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      sectionTitle(
                        'Select a package',
                        subtitle:
                            'Choose what works for you. You can upgrade later.',
                      ),
                      packagesAsync.when(
                        data: (packages) {
                          ensureSelectedPackage(packages);

                          if (packages.isEmpty) {
                            return Text(
                              'No packages available right now.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            );
                          }

                          final dropdownTextStyle =
                              theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                height: 1.2,
                              ) ??
                              const TextStyle(fontSize: 14, height: 1.2);

                          String packageLabel(PackageModel p) {
                            return '${p.packageName ?? 'Package'} • ${p.formattedPrice} / ${p.durationText}';
                          }

                          final packageItems = packages
                              .where((p) => p.packageId != null)
                              .toList();

                          return card(
                            child: DropdownButtonFormField<int>(
                              value: _selectedPaymentPackage?.packageId,
                              isExpanded: true,
                              menuMaxHeight: 360,
                              decoration: const InputDecoration(
                                labelText: 'Package',
                                prefixIcon: Icon(Icons.inventory_2_rounded),
                              ),
                              selectedItemBuilder: (context) => packageItems
                                  .map(
                                    (p) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        packageLabel(p),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: dropdownTextStyle,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              items: packageItems
                                  .map(
                                    (p) => DropdownMenuItem<int>(
                                      value: p.packageId,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 520,
                                        ),
                                        child: Text(
                                          packageLabel(p),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: dropdownTextStyle,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (packageId) {
                                setState(() {
                                  _selectedPaymentPackage = packages.firstWhere(
                                    (p) => p.packageId == packageId,
                                    orElse: () => packages.first,
                                  );
                                });
                                unawaited(_saveProgress());
                              },
                            ),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text('Failed to load packages: $e'),
                      ),

                      const SizedBox(height: 14),
                      if (_selectedPaymentPackage?.packageId != null) ...[
                        card(
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: cs.primary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payment summary',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_selectedPaymentPackage?.packageName ?? 'Package'} • KES $formattedAmount',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'You will receive an M-Pesa prompt to confirm this payment.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            height: 1.3,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),
                      sectionTitle(
                        'M-Pesa phone',
                        subtitle:
                            'Use the phone number that will receive the payment prompt.',
                      ),
                      _buildTextField(
                        label: 'M-Pesa Phone Number',
                        hint: '+254712345678',
                        controller: _paymentPhoneController,
                        icon: Icons.phone_iphone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (_paymentAlreadyPaidMember) return null;
                          return Validators.validatePhone(v);
                        },
                      ),

                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _paySelectedItems,
                          icon: const Icon(Icons.lock_clock_rounded),
                          label: const Text('Pay now (STK Push)'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptForStkPhone({String? initial}) async {
    final controller = TextEditingController(
      text: initial ?? _paymentPhoneController.text,
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final phone = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('M-Pesa STK Push'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the phone number that will receive the payment prompt.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+254712345678',
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
                final err = Validators.validatePhone(value);
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: AppTheme.brightRed,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, value);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return phone;
  }

  // Future<void> _initiateStkPayment({
  //   required String purpose,
  //   required double amount,
  //   required String phone,
  //   String? reference,
  // }) async {
  //   final ok = await ref
  //       .read(paymentNotifierProvider.notifier)
  //       .initiatePayment({
  //         'amount': amount,
  //         'method': 'mpesa',
  //         'purpose': purpose,
  //         'reference': reference,
  //         'phone': phone,
  //       });

  //   if (!mounted) return;

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       behavior: SnackBarBehavior.floating,
  //       backgroundColor: ok ? AppTheme.successGreen : AppTheme.brightRed,
  //       content: Text(
  //         ok
  //             ? 'STK push initiated. Check your phone to complete payment.'
  //             : 'Failed to initiate payment. Please try again.',
  //       ),
  //     ),
  //   );
  // }

  Future<void> _paySelectedItems() async {
    if (!_validateCurrentStep()) return;

    // Calculate total amount
    final packageAmount = (_payForPackage
        ? (_selectedPaymentPackage?.price ?? 0)
        : 0);
    final eventAmount = _payForEvent
        ? _selectedPaymentEvents.fold<double>(0, (sum, e) => sum + (e.fee ?? 0))
        : 0;
    final total = packageAmount + eventAmount;

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No payment required for selected items.'),
        ),
      );
      return;
    }

    // Build description for payment
    final subtitle = _payForPackage && _payForEvent
        ? '${_selectedPaymentPackage?.description ?? 'Package'} + Events'
        : _payForPackage
        ? _selectedPaymentPackage?.description ?? 'Package'
        : _selectedPaymentEvents.map((e) => e.title).join(', ');

    // Use the user's National ID number as the payment reference
    final nationalId = _nationalIdController.text.trim();
    if (nationalId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.brightRed,
          content: Text(
            'Please enter your National ID number in the Personal Info step before making a payment.',
          ),
        ),
      );
      return;
    }

    // Show the unified SecurePaymentDialog - handles phone input AND status
    final success = await SecurePaymentDialog.show(
      context,
      reference: nationalId,
      title: 'Registration Payment',
      subtitle: subtitle,
      amount: total.toDouble(),
      description: 'PBAK Registration: $subtitle',
      initialPhone: _paymentPhoneController.text.isNotEmpty
          ? _paymentPhoneController.text
          : null,
      mpesaOnly: true,
    );

    if (!mounted) return;

    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.successGreen,
          content: Text(
            'Payment successful! Your registration payment has been received.',
          ),
        ),
      );
    }
  }

  Future<void> _tryExtractDlAndIdNumbersFromDlImages({
    bool forceDialogOnFailure = false,
  }) async {
    if (kIsWeb) {
      // No OCR/MLKit on web.
      return;
    }
    if (_dlOcrInProgress) return;

    final front = _dlFrontPicFile;
    final back = _dlBackPicFile;

    if (front == null && back == null) {
      if (forceDialogOnFailure) {
        await _promptForManualDlAndId(missingId: true, missingDl: true);
      }
      return;
    }

    setState(() {
      _dlOcrInProgress = true;
      _dlOcrStatusMessage = 'Scanning driving license for numbers…';
    });

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      Future<String> scan(File file) async {
        final input = InputImage.fromFile(file);
        final recognized = await recognizer.processImage(input);
        return recognized.text;
      }

      final frontText = front != null ? await scan(front) : '';
      final backText = back != null ? await scan(back) : '';

      // Anchor-based parsing (required):
      // - Find "NATIONAL ID NO" then take number on the line below.
      // - Find "LICENCE NO" then take DL number on the line below.
      final detectedId =
          DlIdOcrParser.extractNationalIdFromDlAnchors(frontText) ??
          DlIdOcrParser.extractNationalIdFromDlAnchors(backText);

      final detectedDl =
          DlIdOcrParser.extractDrivingLicenceFromDlAnchors(frontText) ??
          DlIdOcrParser.extractDrivingLicenceFromDlAnchors(backText);

      if (!mounted) return;

      final beforeId = _nationalIdController.text.trim();
      final beforeDl = _drivingLicenseController.text.trim();

      // Only auto-fill if the user has not already typed something.
      // OCR is a helper and should not overwrite manual edits.
      if (detectedId != null && beforeId.isEmpty) {
        _nationalIdController.text = detectedId;
      }
      if (detectedDl != null && beforeDl.isEmpty) {
        _drivingLicenseController.text = detectedDl;
      }

      final afterId = _nationalIdController.text.trim();
      final afterDl = _drivingLicenseController.text.trim();

      final idChanged = beforeId != afterId && afterId.isNotEmpty;
      final dlChanged = beforeDl != afterDl && afterDl.isNotEmpty;

      if (idChanged || dlChanged) {
        final parts = <String>[];
        if (afterId.isNotEmpty) parts.add('National ID: $afterId');
        if (afterDl.isNotEmpty) parts.add('Licence No: $afterDl');
        _showSuccess('Extracted ${parts.join(' • ')}');
      }

      final missingId = _nationalIdController.text.trim().isEmpty;
      final missingDl = _drivingLicenseController.text.trim().isEmpty;

      setState(() {
        if (!missingId && !missingDl) {
          _dlOcrStatusMessage = 'Detected document numbers successfully.';
        } else if (missingId && missingDl) {
          _dlOcrStatusMessage =
              'Not able to extract National ID No and Licence No. Please type them manually below.';
        } else if (missingId) {
          _dlOcrStatusMessage =
              'Not able to extract National ID No. Please type it manually below.';
        } else {
          _dlOcrStatusMessage =
              'Not able to extract Licence No. Please type it manually below.';
        }
      });

      if (forceDialogOnFailure && (missingId || missingDl)) {
        await _promptForManualDlAndId(
          missingId: missingId,
          missingDl: missingDl,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dlOcrStatusMessage =
            'Failed to scan images. Please enter or edit the numbers manually below.';
      });
      if (forceDialogOnFailure) {
        await _promptForManualDlAndId(
          missingId: _nationalIdController.text.trim().isEmpty,
          missingDl: _drivingLicenseController.text.trim().isEmpty,
        );
      }
    } finally {
      await recognizer.close();
      if (mounted) {
        setState(() {
          _dlOcrInProgress = false;
        });
      }
      unawaited(_saveProgress());
    }
  }

  Future<void> _promptForManualDlAndId({
    required bool missingId,
    required bool missingDl,
  }) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final idController = TextEditingController(
      text: _nationalIdController.text,
    );
    final dlController = TextEditingController(
      text: _drivingLicenseController.text,
    );

    final result = await showModalBottomSheet<(String?, String?)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter document numbers',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We could not detect ${missingId && missingDl
                      ? 'your ID and DL numbers'
                      : missingId
                      ? 'your ID number'
                      : 'your DL number'} from the uploaded images. Please enter them manually.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                if (missingId)
                  TextField(
                    controller: idController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'National ID number',
                      hintText: '12345678',
                    ),
                  ),
                if (missingId) const SizedBox(height: 12),
                if (missingDl)
                  TextField(
                    controller: dlController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Driving license number',
                      hintText: 'DL123456',
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context, (
                            idController.text.trim(),
                            dlController.text.trim(),
                          ));
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    idController.dispose();
    dlController.dispose();

    if (!mounted || result == null) return;

    final id = result.$1;
    final dl = result.$2;

    if (missingId && id != null && id.isNotEmpty) {
      _nationalIdController.text = id;
    }
    if (missingDl && dl != null && dl.isNotEmpty) {
      _drivingLicenseController.text = dl.toUpperCase();
    }

    setState(() {
      _dlOcrStatusMessage = 'Document numbers saved.';
    });

    unawaited(_saveProgress());
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
