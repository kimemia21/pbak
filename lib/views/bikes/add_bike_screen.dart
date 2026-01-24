import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/models/bike_model.dart';
import 'dart:io';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/services/bike_service.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/utils/kenyan_plate_parser.dart';
import 'package:intl/intl.dart';
import 'package:pbak/widgets/kyc_document_uploader.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:pbak/widgets/platform_image.dart';
import 'package:pbak/providers/upload_provider.dart';
import 'package:pbak/providers/auth_provider.dart';
// MLKit OCR not used on web.
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
class AddBikeScreen extends ConsumerStatefulWidget {
  final BikeModel? bikeToEdit;
  final String? bikeId; // For fetching bike data in edit mode

  const AddBikeScreen({super.key, this.bikeToEdit, this.bikeId});

  @override
  ConsumerState<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends ConsumerState<AddBikeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _imagePicker = ImagePicker();

  final _registrationController = TextEditingController();
  final _chassisController = TextEditingController();
  final _engineController = TextEditingController();
  final _colorController = TextEditingController();
  // Odometer removed
  // final _odometerController = TextEditingController();
  final _experienceYearsController = TextEditingController();

  // Custom make/model (when user selects "Other")
  final _otherMakeController = TextEditingController();
  final _otherModelController = TextEditingController();

  // Insurance details (UI only; not sent in bike create/update payload)
  final _insurancePolicyNumberController = TextEditingController();
  String? _insuranceType;

  int _currentStep = 0;
  final int _totalSteps = 2;
  bool _isLoading = false;
  bool _isLoadingMakes = false;
  bool _isLoadingModels = false;

  List<BikeMake> _makes = [];
  List<BikeModelCatalog> _models = [];
  static const int _otherOptionId = -1;

  int? _selectedMakeId;
  int? _selectedModelId;

  bool get _isOtherMake => _selectedMakeId == _otherOptionId;
  bool get _isOtherModel => _selectedModelId == _otherOptionId;

  DateTime? _purchaseDate;
  // DateTime? _registrationDate;
  DateTime? _registrationExpiry;
  DateTime? _insuranceExpiry;
  DateTime? _yom;

  File? _photoFrontFile;
  File? _photoSideFile;
  File? _photoRearFile;

  XFile? _photoFrontXFile;
  XFile? _photoSideXFile;
  XFile? _photoRearXFile;
  String? _photoFrontUrl;
  String? _photoSideUrl;
  String? _photoRearUrl;

  bool _isPrimary = false;
  bool _hasInsurance = false;
  BikeModel? _fetchedBike; // Store fetched bike data

  bool get _isEditMode => widget.bikeId != null || widget.bikeToEdit != null;

  @override
  void initState() {
    super.initState();
    _registrationController.addListener(() {
      // Update conditional fields visibility when registration changes.
      if (mounted) setState(() {});
    });

    _loadMakes();
    if (_isEditMode) {
      _fetchBikeData();
    }
  }

  /// Fetch bike data from API if in edit mode
  Future<void> _fetchBikeData() async {
    if (widget.bikeId == null) {
      // If bikeToEdit is provided directly, use it
      if (widget.bikeToEdit != null) {
        _loadBikeData(widget.bikeToEdit!);
      }
      return;
    }

    try {
      final bikeService = ref.read(bikeServiceProvider);
      final bike = await bikeService.getBikeById(int.parse(widget.bikeId!));

      if (bike != null && mounted) {
        setState(() {
          _fetchedBike = bike;
        });
        _loadBikeData(bike);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load bike data: $e');
      }
    }
  }

  /// Load bike data into form fields
  void _loadBikeData(BikeModel bike) {
    _registrationController.text = bike.registrationNumber ?? '';
    _chassisController.text = bike.chassisNumber ?? '';
    _engineController.text = bike.engineNumber ?? '';
    _colorController.text = bike.color ?? '';
    // odometer removed
    _experienceYearsController.text = bike.experienceYears?.toString() ?? '';

    _purchaseDate = bike.purchaseDate;
    // _registrationDate = bike.registrationDate;
    _registrationExpiry = bike.registrationExpiry;
    _insuranceExpiry = bike.insuranceExpiry;
    _yom = bike.yom;

    _photoFrontUrl = bike.bikePhotoUrl;
    _photoSideUrl = bike.photoSideId?.toString();
    _photoRearUrl = bike.photoRearId?.toString();

    _isPrimary = bike.isPrimary ?? false;
    _hasInsurance = bike.hasInsurance ?? false;

    // Store make/model IDs to set after makes are loaded
    final makeId = bike.bikeModel?.makeId ?? bike.bikeModel?.make?.makeId;
    final modelId = bike.modelId;

    // Only set dropdown values after makes are loaded to avoid assertion error
    _setMakeAndModelAfterLoad(makeId, modelId);
  }

  /// Set make and model dropdown values after makes list is loaded
  Future<void> _setMakeAndModelAfterLoad(int? makeId, int? modelId) async {
    // Wait for makes to load if still loading
    while (_isLoadingMakes && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    // Check if the makeId exists in the loaded makes list
    final makeExists = makeId != null && _makes.any((m) => m.id == makeId);

    if (makeExists) {
      setState(() {
        _selectedMakeId = makeId;
        // Don't set _selectedModelId here - it will be set after models load
      });
      // Load models for this make - model will be selected after load
      loadModels(makeId, preselectedModelId: modelId);
    } else if (makeId != null) {
      // Make not found in list - treat as "Other"
      setState(() {
        _selectedMakeId = _otherOptionId;
        _selectedModelId = _otherOptionId;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _registrationController.dispose();
    _chassisController.dispose();
    _engineController.dispose();
    _colorController.dispose();
    // _odometerController.dispose();
    _experienceYearsController.dispose();
    _insurancePolicyNumberController.dispose();
    _otherMakeController.dispose();
    _otherModelController.dispose();
    super.dispose();
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

  Future<void> loadModels(int makeId, {int? preselectedModelId}) async {
    setState(() {
      _isLoadingModels = true;
      // Only reset model selection if not preselecting (i.e., user changed make)
      if (preselectedModelId == null) {
        _selectedModelId = null;
      }
      _models = [];
    });

    try {
      final bikeService = ref.read(bikeServiceProvider);
      final models = await bikeService.getBikeModels(makeId);
      if (mounted) {
        setState(() {
          _models = models;
          _isLoadingModels = false;
          // If we have a preselected model ID (edit mode), set it after models load
          if (preselectedModelId != null) {
            // Verify the model exists in the loaded list
            final modelExists = models.any((m) => m.modelId == preselectedModelId);
            if (modelExists) {
              _selectedModelId = preselectedModelId;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingModels = false);
        _showError('Failed to load bike models: $e');
      }
    }
  }

  Future<String?> _extractPlateFromRearImage(String imagePath) async {
    if (kIsWeb) {
      return null;
    }
    // Same behavior as registration: try Kenyan plate first, then non-Kenyan candidate.
    setState(() => _isLoading = true);
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognized = await recognizer.processImage(inputImage);

      final kenyan = KenyanPlateParser.parseMotorcyclePlate(recognized);
      if (kenyan != null && kenyan.trim().isNotEmpty) return kenyan;

      final candidate = KenyanPlateParser.parseNonKenyanPlateCandidate(recognized);
      if (candidate != null && candidate.trim().isNotEmpty) {
        final normalized = candidate.trim().toUpperCase();
        final confirmed = await _confirmNonKenyanPlate(normalized);
        if (confirmed == true) return normalized;
      }

      return null;
    } catch (_) {
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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

  Future<XFile?> _pickBikePhotoSource(String position) async {
    // Use the same bottom-sheet look/feel as registration/KYC.
    return showModalBottomSheet<XFile?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        Future<void> pick(ImageSource source) async {
          final result = await _imagePicker.pickImage(
            source: source,
            // Match KYC picker settings to avoid oversized uploads.
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
          if (context.mounted) Navigator.pop(context, result);
        }

        final label = position == 'rear'
            ? 'Rear photo'
            : position == 'front'
                ? 'Front photo'
                : 'Side photo';

        final description = position == 'rear'
            ? 'For the rear photo, please ensure the number plate is sharp and readable (good lighting, no blur).'
            : 'Take a clear photo in good lighting.';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
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
                    leading: Icon(Icons.photo_camera_rounded, color: cs.primary),
                    title: const Text('Capture with camera (recommended)'),
                    subtitle: const Text('Best quality photo'),
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

  Future<String?> _promptForManualPlate() async {
    final controller = TextEditingController(text: _registrationController.text);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter registration number'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'e.g., KMBZ 456Y',
              prefixIcon: Icon(Icons.confirmation_number_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<void> _pickBikePhoto(String position) async {
    final picked = await _pickBikePhotoSource(position);
    if (picked == null || !mounted) return;

    // On web we keep the picked XFile for preview.
    // On non-web we convert to dart:io File for downstream usage.
    final file = kIsWeb ? null : File(picked.path);

    setState(() {
      switch (position) {
        case 'front':
          _photoFrontXFile = picked;
          _photoFrontFile = file;
          _photoFrontUrl = null;
          break;
        case 'side':
          _photoSideXFile = picked;
          _photoSideFile = file;
          _photoSideUrl = null;
          break;
        case 'rear':
          _photoRearXFile = picked;
          _photoRearFile = file;
          _photoRearUrl = null;
          break;
      }
    });

    // Registration/KYC behavior: rear photo is used to extract plate.
    // On web, we skip camera/OCR-based extraction and ask for manual entry.
    if (position == 'rear') {
      final plate = kIsWeb || file == null
          ? null
          : await _extractPlateFromRearImage(file.path);

      if (plate != null && plate.trim().isNotEmpty) {
        setState(() {
          _registrationController.text = plate.trim().toUpperCase();
        });
      } else {
        // Fallback: ask user to input plate.
        final manual = await _promptForManualPlate();
        if (manual != null && manual.trim().isNotEmpty) {
          final normalized = manual.trim().toUpperCase();
          setState(() {
            _registrationController.text = normalized;
            _chassisController.clear();
            _engineController.clear();
          });
        }
      }

      // Still require a plate before uploading rear.
      if (_registrationController.text.trim().isEmpty) {
        _showError('Please enter your motorcycle registration number to continue.');
        return;
      }
    }

    final user = ref.read(authProvider).value;
    if (user == null) {
      _showError('User not logged in');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uploadNotifier = ref.read(uploadNotifierProvider.notifier);

      final result = kIsWeb
          ? await uploadNotifier.uploadDocumentXFile(
              file: picked,
              documentType: 'bike_$position',
              memberId: user.memberId,
            )
          : await uploadNotifier.uploadDocument(
              filePath: file!.path,
              documentType: 'bike_$position',
              memberId: user.memberId,
            );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          switch (position) {
            case 'front':
              _photoFrontUrl = result;
              break;
            case 'side':
              _photoSideUrl = result;
              break;
            case 'rear':
              _photoRearUrl = result;
              break;
          }
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bike photo uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final uploadError = ref.read(uploadNotifierProvider).error;
        setState(() => _isLoading = false);
        _showError(uploadError?.isNotEmpty == true ? uploadError! : 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Upload failed: $e');
      }
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Bike (all fields + photos)
        if (_selectedMakeId == null) {
          _showError('Please select a bike make');
          return false;
        }
        if (_isOtherMake && _otherMakeController.text.trim().isEmpty) {
          _showError('Please enter your bike make');
          return false;
        }
        if (_selectedModelId == null) {
          _showError('Please select a bike model');
          return false;
        }
        if (_isOtherModel && _otherModelController.text.trim().isEmpty) {
          _showError('Please enter your bike model');
          return false;
        }

        // In edit mode, skip photo validation if photos are empty
        // (user may not want to change photos)
        if (!_isEditMode) {
          if (_photoFrontUrl == null) {
            _showError('Please upload front photo');
            return false;
          }
          if (_photoSideUrl == null) {
            _showError('Please upload side photo');
            return false;
          }
          if (_photoRearUrl == null) {
            _showError('Please upload rear photo');
            return false;
          }
        }

        if (!_formKey.currentState!.validate()) return false;
        if (_hasInsurance && _insuranceExpiry == null) {
          _showError('Please select insurance expiry date');
          return false;
        }

        return true;
      case 1: // Review
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    // Always validate the current step before proceeding.
    if (!_validateCurrentStep()) {
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
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

  Future<void> _handleSubmit() async {
    // Validate bike step before submit.
    if (_currentStep != _totalSteps - 1) return;
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    bool success;

    if (_isEditMode) {
      // Edit mode - only send edited fields
      final bikeData = _buildEditedBikeData();
      final bikeId = widget.bikeId != null
          ? int.parse(widget.bikeId!)
          : (widget.bikeToEdit?.bikeId ?? _fetchedBike?.bikeId);

      if (bikeId == null) {
        _showError('Unable to update bike: missing bike ID');
        setState(() => _isLoading = false);
        return;
      }

      success = await ref
          .read(bikeNotifierProvider.notifier)
          .updateBike(bikeId, bikeData);
    } else {
      // Create mode - send all fields
      final bikeData = _buildFullBikeData();
      success = await ref.read(bikeNotifierProvider.notifier).addBike(bikeData);
    }

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Bike details submitted for verification!'
                  : 'Bike details submitted for verification!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        _showError(
          _isEditMode
              ? 'Failed to update bike. Please try again.'
              : 'Failed to add bike. Please try again.',
        );
      }
    }
  }

  /// Build full bike data for create mode
  Map<String, dynamic> _buildFullBikeData() {
    final makeName = _isOtherMake
        ? _otherMakeController.text.trim()
        : _makes
            .where((m) => m.id == _selectedMakeId)
            .map((m) => m.name)
            .cast<String>()
            .firstOrNull;

    final modelName = _isOtherModel
        ? _otherModelController.text.trim()
        : _models
            .where((m) => m.modelId == _selectedModelId)
            .map((m) => m.modelName ?? '')
            .cast<String>()
            .firstOrNull;

    final bikeData = {
      // Keep model_id for backward compatibility, but also send names when user selected "Other".
      'model_id': _isOtherModel ? null : _selectedModelId,
      if (makeName != null && makeName.isNotEmpty) 'make_name': makeName,
      if (modelName != null && modelName.isNotEmpty) 'model_name': modelName,
      'registration_number': _registrationController.text.trim().toUpperCase(),
      if (!_isKenyanMotorcyclePlate(_registrationController.text))
        'chassis_number': _chassisController.text.trim().toUpperCase(),
      if (!_isKenyanMotorcyclePlate(_registrationController.text))
        'engine_number': _engineController.text.trim().toUpperCase(),
      'color': _colorController.text.trim().toUpperCase(),
      'purchase_date': _purchaseDate?.toIso8601String().split('T')[0],
      // 'registration_date': _registrationDate?.toIso8601String().split('T')[0],
      'registration_expiry': _registrationExpiry?.toIso8601String().split(
        'T',
      )[0],
      'bike_photo_url': _photoFrontUrl,
      // odometer_reading removed
      'insurance_expiry': _insuranceExpiry?.toIso8601String().split('T')[0],
      'is_primary': _isPrimary,
      'yom': _yom?.toIso8601String().split('T')[0],
      'has_insurance': _hasInsurance ? 1 : 0,
      'experience_years': _experienceYearsController.text.trim().isEmpty
          ? null
          : int.tryParse(_experienceYearsController.text.trim()),
    };

    // Some backends require a model_id; if user selected Other, fall back to 1.
    // (We still send make_name/model_name for review/verification workflows.)
    if ((bikeData['model_id'] == null) && (makeName != null || modelName != null)) {
      bikeData['model_id'] = 1;
    }

    bikeData.removeWhere((key, value) => value == null);
    return bikeData;
  }

  /// Build only edited fields for update mode
  Map<String, dynamic> _buildEditedBikeData() {
    final bike = _fetchedBike ?? widget.bikeToEdit;

    if (bike == null) {
      // If no original data, return empty map
      return {};
    }

    final bikeData = <String, dynamic>{};

    // Check and add only edited fields based on API endpoint requirements
    final currentRegistration = _registrationController.text
        .trim()
        .toUpperCase();
    if (currentRegistration != (bike.registrationNumber ?? '').toUpperCase() &&
        currentRegistration.isNotEmpty) {
      bikeData['registration_number'] = currentRegistration;
    }

    final currentColor = _colorController.text.trim().toUpperCase();
    if (currentColor != (bike.color ?? '').toUpperCase() &&
        currentColor.isNotEmpty) {
      bikeData['color'] = currentColor;
    }

    final currentRegExpiry = _registrationExpiry?.toIso8601String().split(
      'T',
    )[0];
    final originalRegExpiry = bike.registrationExpiry?.toIso8601String().split(
      'T',
    )[0];
    if (currentRegExpiry != originalRegExpiry && currentRegExpiry != null) {
      bikeData['registration_expiry'] = currentRegExpiry;
    }

    // Odometer removed

    final currentInsExpiry = _insuranceExpiry?.toIso8601String().split('T')[0];
    final originalInsExpiry = bike.insuranceExpiry?.toIso8601String().split(
      'T',
    )[0];
    if (currentInsExpiry != originalInsExpiry && currentInsExpiry != null) {
      bikeData['insurance_expiry'] = currentInsExpiry;
    }

    if (_isPrimary != (bike.isPrimary ?? false)) {
      bikeData['is_primary'] = _isPrimary;
    }

    // Check if bike photo URL changed
    if (_photoFrontUrl != null && _photoFrontUrl != bike.bikePhotoUrl) {
      bikeData['bike_photo_url'] = _photoFrontUrl;
    }

    // Status is always active for updates
    bikeData['status'] = 'active';

    return bikeData;
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Bike' : 'Add New Bike'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingMakes
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading bike data...',
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
                          _buildBikeStep(),
                          _buildReviewStep(),
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
    final stepTitles = ['Bike', 'Review'];
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
          // Step indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Column(
                  children: [
                    // Step circle with connecting line
                    Row(
                      children: [
                        if (index > 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isCompleted
                                  ? AppTheme.brightRed
                                  : AppTheme.lightSilver,
                            ),
                          ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCompleted || isCurrent
                                ? AppTheme.brightRed
                                : AppTheme.lightSilver,
                            shape: BoxShape.circle,
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppTheme.brightRed.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
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
                                          ? AppTheme.white
                                          : AppTheme.mediumGrey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        if (index < _totalSteps - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isCompleted
                                  ? AppTheme.brightRed
                                  : AppTheme.lightSilver,
                            ),
                          ),
                      ],
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
    final uploadState = ref.watch(uploadNotifierProvider);
    final isBusy = _isLoading || uploadState.isUploading;

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
                child: OutlinedButton(
                  onPressed: isBusy ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: AppTheme.paddingM),
            ],
            Expanded(
              child: CustomButton(
                text: 'Continue',
                icon: Icons.arrow_forward,
                isLoading: isBusy,
                onPressed: isBusy
                    ? null
                    : () {
                        if (_currentStep == _totalSteps - 1) {
                          _handleSubmit();
                        } else {
                          _nextStep();
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBikeStep() {
    // One-step bike section (KYC-like): make/model + photos + details.
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMakeModelStep(),
          _buildPhotosStep(),
          _buildDetailsStep(),
        ],
      ),
    );
  }

  /// Get the currently selected model object
  BikeModelCatalog? get _selectedModel {
    if (_selectedModelId == null) return null;
    try {
      return _models.firstWhere((m) => m.modelId == _selectedModelId);
    } catch (_) {
      return null;
    }
  }

  /// Build info card showing selected bike details (make, model, CC, category, fuel type)
  Widget _buildSelectedBikeInfo() {
    final model = _selectedModel;
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
        border: Border.all(
          color: AppTheme.successGreen.withOpacity(0.3),
        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  Widget _buildMakeModelStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditMode ? 'Bike Information' : 'Select Your Bike',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _isEditMode
                ? 'View your bike\'s make and model (cannot be changed)'
                : 'Choose the make and model of your motorcycle',
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
                    if (value == _otherOptionId) {
                      setState(() {
                        _selectedMakeId = value;
                        _selectedModelId = _otherOptionId;
                        _models = [];
                        _otherMakeController.clear();
                        _otherModelController.clear();
                      });
                      return;
                    }

                    setState(() {
                      _selectedMakeId = value;
                      _selectedModelId = null;
                      _otherMakeController.clear();
                      _otherModelController.clear();
                    });
                    loadModels(value);
                  },
          ),
          const SizedBox(height: 24),

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
                // Show model name with engine capacity if available
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
                    setState(() {
                      _selectedModelId = value;
                      if (value == _otherOptionId) {
                        _otherModelController.clear();
                      }
                    });
                  },
          ),

          if (_isOtherMake) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _otherMakeController,
              decoration: const InputDecoration(
                labelText: 'Other Make',
                hintText: 'Enter manufacturer name',
                prefixIcon: Icon(Icons.edit_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.validateRequired(v, 'Bike make'),
            ),
          ],

          if (_selectedModelId != null) ...[
            const SizedBox(height: 24),
            if (_isOtherModel) ...[
              TextFormField(
                controller: _otherModelController,
                decoration: const InputDecoration(
                  labelText: 'Other Model',
                  hintText: 'Enter model name',
                  prefixIcon: Icon(Icons.edit_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.validateRequired(v, 'Bike model'),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Show selected bike details with auto-filled engine capacity
              _buildSelectedBikeInfo(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    // Replicate registration/KYC "motorbike photos" flow & styling.
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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
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
            'Rear photo tip: make sure the number plate is sharp and readable (good lighting, no blur). We\'ll try to read it automatically. If we can\'t, you can type it in on the next step.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBikePhotoCard(
                  label: 'Front',
                  subtitle: 'Upload',
                  photo: _photoFrontFile,
                  xPhoto: _photoFrontXFile,
                  uploaded: _photoFrontUrl != null,
                  onTap: () => _pickBikePhoto('front'),
                  highlight: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBikePhotoCard(
                  label: 'Side',
                  subtitle: 'Upload',
                  photo: _photoSideFile,
                  xPhoto: _photoSideXFile,
                  uploaded: _photoSideUrl != null,
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
              photo: _photoRearFile,
              xPhoto: _photoRearXFile,
              uploaded: _photoRearUrl != null,
              onTap: () => _pickBikePhoto('rear'),
              highlight: true,
              tall: true,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // (Photo upload UI now uses BikePhotoUploader + KycDocumentUploader from KYC)
  /* Widget _buildImageUploadCard({
    required String title,
    required String description,
    required IconData icon,
    required File? imageFile,
    required String? uploadedUrl,
    required VoidCallback onTap,
  }) {
    // removed
  } */

  Widget _buildBikePhotoCard({
    required String label,
    required String subtitle,
    required File? photo,
    XFile? xPhoto,
    required bool uploaded,
    required VoidCallback onTap,
    bool highlight = false,
    bool tall = false,
  }) {
    // Same look/feel as registration.
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasValidPreview = kIsWeb
        ? (xPhoto != null && xPhoto.path.isNotEmpty)
        : (photo != null && photo.path.isNotEmpty);

    final borderColor = (hasValidPreview || uploaded)
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
        child: hasValidPreview
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlatformImage(
                      file: kIsWeb ? null : photo,
                      xFile: kIsWeb ? xPhoto : null,
                      fit: BoxFit.cover,
                    ),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_a_photo_rounded,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      uploaded ? 'Uploaded ✓' : subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _photoBadge({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  bool _isKenyanMotorcyclePlate(String plate) {
    final normalized = plate.trim().toUpperCase();
    if (normalized.isEmpty) return false;
    return KenyanPlateParser.isValidMotorcyclePlate(normalized);
  }

  Widget _buildDetailsStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditMode ? 'Update Bike Details' : 'Bike Details',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _isEditMode
                  ? 'Update motorcycle information as needed'
                  : 'Enter your motorcycle information',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 32),

            _buildTextField(
              label: 'Registration Number',
              hint: 'e.g., KBZ 456Y',
              controller: _registrationController,
              validator: Validators.validateRegistrationNumber,
              textCapitalization: TextCapitalization.characters,
              icon: Icons.confirmation_number_rounded,
            ),
            const SizedBox(height: 24),

            if (!_isKenyanMotorcyclePlate(_registrationController.text)) ...[
              _buildTextField(
                label: 'Engine Number',
                hint: 'Enter engine number',
                controller: _engineController,
                validator: Validators.validateEngineNumber,
                textCapitalization: TextCapitalization.characters,
                icon: Icons.settings_rounded,
              ),
              const SizedBox(height: 24),

              _buildTextField(
                label: 'Chassis Number',
                hint: 'Enter chassis number',
                controller: _chassisController,
                validator: (val) => Validators.validateRequired(val, 'Chassis number'),
                textCapitalization: TextCapitalization.characters,
                icon: Icons.tag_rounded,
              ),
              const SizedBox(height: 24),
            ],

            _buildTextField(
              label: 'Color',
              hint: 'e.g., Blue, Red, Silver',
              controller: _colorController,
              validator: (val) => Validators.validateRequired(val, 'Color'),
              textCapitalization: TextCapitalization.words,
              icon: Icons.palette_rounded,
            ),
            const SizedBox(height: 24),

            // Odometer removed
            

            _buildTextField(
              label: 'Riding Experience (Years)',
              hint: 'e.g., 5',
              controller: _experienceYearsController,
              keyboardType: TextInputType.number,
              icon: Icons.emoji_events_rounded,
            ),
            const SizedBox(height: 24),

            _buildDateField(
              'Year of Manufacture',
              _yom,
              (date) => setState(() => _yom = date),
            ),
            const SizedBox(height: 24),

            _buildDateField(
              'Purchase Date (Optional)',
              _purchaseDate,
              (date) => setState(() => _purchaseDate = date),
            ),
            const SizedBox(height: 24),

            // _buildDateField(
            //   'Registration Date (Optional)',
            //   _registrationDate,
            //   (date) => setState(() => _registrationDate = date),
            // ),
            // const SizedBox(height: 24),

            // _buildDateField(
            //   'Registration Expiry (Optional)',
            //   _registrationExpiry,
            //   (date) => setState(() => _registrationExpiry = date),
            // ),
            const SizedBox(height: 24),

            if (_hasInsurance) ...[
              _buildDateField(
                'Insurance Expiry',
                _insuranceExpiry,
                (date) => setState(() => _insuranceExpiry = date),
              ),
              const SizedBox(height: 24),

              // Match registration/KYC: policy number + type (UI only)
              _buildTextField(
                label: 'Policy Number',
                hint: 'Enter policy number',
                controller: _insurancePolicyNumberController,
                icon: Icons.numbers,
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _insuranceType,
                decoration: const InputDecoration(
                  labelText: 'Insurance Type',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Third Party',
                    child: Text('Third Party'),
                  ),
                  DropdownMenuItem(
                    value: 'Comprehensive',
                    child: Text('Comprehensive'),
                  ),
                ],
                onChanged: (value) => setState(() => _insuranceType = value),
              ),
              const SizedBox(height: 24),
            ],

            // Switches
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Has Insurance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Does this bike have active insurance?',
                    ),
                    value: _hasInsurance,
                    activeColor: AppTheme.brightRed,
                    onChanged: (value) => setState(() {
                      _hasInsurance = value;
                      if (!value) {
                        _insuranceExpiry = null;
                        _insurancePolicyNumberController.clear();
                        _insuranceType = null;
                      }
                    }),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      'Primary Bike',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('Set as your primary motorcycle'),
                    value: _isPrimary,
                    activeColor: AppTheme.brightRed,
                    onChanged: (value) => setState(() => _isPrimary = value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final theme = Theme.of(context);

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
          textCapitalization: textCapitalization,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.inputDecorationTheme.hintStyle,
            prefixIcon: Icon(icon, color: AppTheme.mediumGrey, size: 22),
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

  Widget _buildDateField(
    String label,
    DateTime? date,
    Function(DateTime) onDateSelected,
  ) {
    final theme = Theme.of(context);

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
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(1990),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (picked != null) onDateSelected(picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select date',
              hintStyle: theme.inputDecorationTheme.hintStyle,
              prefixIcon: const Icon(
                Icons.calendar_today,
                color: AppTheme.mediumGrey,
                size: 22,
              ),
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: theme.inputDecorationTheme.border,
              enabledBorder: theme.inputDecorationTheme.enabledBorder,
              focusedBorder: theme.inputDecorationTheme.focusedBorder,
            ),
            child: Text(
              date != null
                  ? DateFormat('MMM dd, yyyy').format(date)
                  : 'Select date',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: date != null
                    ? theme.colorScheme.onSurface
                    : AppTheme.mediumGrey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditMode ? 'Review Changes' : 'Review Your Bike',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _isEditMode
                ? 'Review the changes you made before updating'
                : 'Please review all information before submitting',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 32),

          // Show edited fields summary in edit mode
          if (_isEditMode) ...[
            _buildEditedFieldsSummary(),
            const SizedBox(height: 24),
          ],

          // Make & Model Section
          _buildReviewSection(
            title: 'Make & Model',
            icon: Icons.two_wheeler_rounded,
            children: [
              _buildReviewItem(
                'Make',
                _makes
                    .firstWhere(
                      (m) => m.id == _selectedMakeId,
                      orElse: () => BikeMake(id: 0, name: 'Unknown'),
                    )
                    .name,
              ),
              _buildReviewItem(
                'Model',
                _models
                    .firstWhere(
                      (m) => m.modelId == _selectedModelId,
                      orElse: () => BikeModelCatalog(modelName: 'Unknown'),
                    )
                    .displayName,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Photos Section
          _buildReviewSection(
            title: 'Photos',
            icon: Icons.photo_library,
            children: [
              _buildReviewItem(
                'Front Photo',
                _photoFrontUrl != null ? 'Uploaded ✓' : 'Not uploaded',
              ),
              _buildReviewItem(
                'Side Photo',
                _photoSideUrl != null ? 'Uploaded ✓' : 'Not uploaded',
              ),
              _buildReviewItem(
                'Rear Photo',
                _photoRearUrl != null ? 'Uploaded ✓' : 'Not uploaded',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Details Section
          _buildReviewSection(
            title: 'Bike Details',
            icon: Icons.info_outline,
            children: [
              _buildReviewItem(
                'Registration Number',
                _registrationController.text.toUpperCase(),
              ),
              _buildReviewItem(
                'Engine Number',
                _engineController.text.toUpperCase(),
              ),
              if (_chassisController.text.isNotEmpty)
                _buildReviewItem(
                  'Chassis Number',
                  _chassisController.text.toUpperCase(),
                ),
              _buildReviewItem('Color', _colorController.text),
              // Odometer removed
              if (_experienceYearsController.text.isNotEmpty)
                _buildReviewItem(
                  'Riding Experience',
                  '${_experienceYearsController.text} years',
                ),
              if (_yom != null)
                _buildReviewItem(
                  'Year of Manufacture',
                  DateFormat('yyyy').format(_yom!),
                ),
              if (_purchaseDate != null)
                _buildReviewItem(
                  'Purchase Date',
                  DateFormat('MMM dd, yyyy').format(_purchaseDate!),
                ),
              // if (_registrationDate != null)
              //   _buildReviewItem(
              //     'Registration Date',
              //     DateFormat('MMM dd, yyyy').format(_registrationDate!),
              //   ),
              if (_registrationExpiry != null)
                _buildReviewItem(
                  'Registration Expiry',
                  DateFormat('MMM dd, yyyy').format(_registrationExpiry!),
                ),
              if (_insuranceExpiry != null)
                _buildReviewItem(
                  'Insurance Expiry',
                  DateFormat('MMM dd, yyyy').format(_insuranceExpiry!),
                ),
              _buildReviewItem('Has Insurance', _hasInsurance ? 'Yes' : 'No'),
              _buildReviewItem('Primary Bike', _isPrimary ? 'Yes' : 'No'),
            ],
          ),
          const SizedBox(height: 32),

          // Information box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.brightRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(color: AppTheme.brightRed.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.brightRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make sure all information is correct. You can edit your bike details later from the bikes screen.',
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

  Widget _buildReviewSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brightRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.brightRed, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Build summary of edited fields in edit mode
  Widget _buildEditedFieldsSummary() {
    final bike = _fetchedBike ?? widget.bikeToEdit;
    if (bike == null) {
      return const SizedBox.shrink();
    }

    final List<Widget> editedFields = [];

    // Check each field for changes
    final currentRegistration = _registrationController.text
        .trim()
        .toUpperCase();
    if (currentRegistration != (bike.registrationNumber ?? '').toUpperCase() &&
        currentRegistration.isNotEmpty) {
      editedFields.add(
        _buildEditedFieldItem(
          'Registration Number',
          bike.registrationNumber ?? 'Not set',
          currentRegistration,
        ),
      );
    }

    final currentColor = _colorController.text.trim().toUpperCase();
    if (currentColor != (bike.color ?? '').toUpperCase() &&
        currentColor.isNotEmpty) {
      editedFields.add(
        _buildEditedFieldItem('Color', bike.color ?? 'Not set', currentColor),
      );
    }

    final currentRegExpiry = _registrationExpiry?.toIso8601String().split(
      'T',
    )[0];
    final originalRegExpiry = bike.registrationExpiry?.toIso8601String().split(
      'T',
    )[0];
    if (currentRegExpiry != originalRegExpiry && currentRegExpiry != null) {
      editedFields.add(
        _buildEditedFieldItem(
          'Registration Expiry',
          originalRegExpiry != null
              ? DateFormat('MMM dd, yyyy').format(bike.registrationExpiry!)
              : 'Not set',
          DateFormat('MMM dd, yyyy').format(_registrationExpiry!),
        ),
      );
    }

    // Odometer removed

    final currentInsExpiry = _insuranceExpiry?.toIso8601String().split('T')[0];
    final originalInsExpiry = bike.insuranceExpiry?.toIso8601String().split(
      'T',
    )[0];
    if (currentInsExpiry != originalInsExpiry && currentInsExpiry != null) {
      editedFields.add(
        _buildEditedFieldItem(
          'Insurance Expiry',
          originalInsExpiry != null
              ? DateFormat('MMM dd, yyyy').format(bike.insuranceExpiry!)
              : 'Not set',
          DateFormat('MMM dd, yyyy').format(_insuranceExpiry!),
        ),
      );
    }

    if (_isPrimary != (bike.isPrimary ?? false)) {
      editedFields.add(
        _buildEditedFieldItem(
          'Primary Bike',
          bike.isPrimary == true ? 'Yes' : 'No',
          _isPrimary ? 'Yes' : 'No',
        ),
      );
    }

    if (_photoFrontUrl != null && _photoFrontUrl != bike.bikePhotoUrl) {
      editedFields.add(
        _buildEditedFieldItem('Bike Photo', 'Updated', 'New photo uploaded'),
      );
    }

    if (editedFields.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No changes detected. Update any field to save changes.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppTheme.successGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Changes Summary (${editedFields.length})',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...editedFields,
          ],
        ),
      ),
    );
  }

  Widget _buildEditedFieldItem(
    String fieldName,
    String oldValue,
    String newValue,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    oldValue,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    newValue,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
