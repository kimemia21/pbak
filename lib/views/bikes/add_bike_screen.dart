import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/models/bike_model.dart';
import 'dart:io';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/services/bike_service.dart';
import 'package:pbak/utils/validators.dart';
import 'package:intl/intl.dart';
import 'package:pbak/widgets/kyc_document_uploader.dart';
import 'package:pbak/providers/upload_provider.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/models/kyc_document_model.dart';

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

  final _registrationController = TextEditingController();
  final _chassisController = TextEditingController();
  final _engineController = TextEditingController();
  final _colorController = TextEditingController();
  final _odometerController = TextEditingController();
  final _experienceYearsController = TextEditingController();

  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isLoading = false;
  bool _isLoadingMakes = false;
  bool _isLoadingModels = false;

  List<BikeMake> _makes = [];
  List<BikeModelCatalog> _models = [];
  int? _selectedMakeId;
  int? _selectedModelId;

  DateTime? _purchaseDate;
  DateTime? _registrationDate;
  DateTime? _registrationExpiry;
  DateTime? _insuranceExpiry;
  DateTime? _yom;

  File? _photoFrontFile;
  File? _photoSideFile;
  File? _photoRearFile;
  String? _photoFrontUrl;
  String? _photoSideUrl;
  String? _photoRearUrl;
  String? _insuranceLogbookUrl;

  KycDocument? _logbookDocument;

  bool _isPrimary = false;
  bool _hasInsurance = false;
  BikeModel? _fetchedBike; // Store fetched bike data

  bool get _isEditMode => widget.bikeId != null || widget.bikeToEdit != null;

  @override
  void initState() {
    super.initState();
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
    _odometerController.text = bike.odometerReading ?? '';
    _experienceYearsController.text = bike.experienceYears?.toString() ?? '';

    _purchaseDate = bike.purchaseDate;
    _registrationDate = bike.registrationDate;
    _registrationExpiry = bike.registrationExpiry;
    _insuranceExpiry = bike.insuranceExpiry;
    _yom = bike.yom;

    _photoFrontUrl = bike.bikePhotoUrl;
    _photoSideUrl = bike.photoSideId?.toString();
    _photoRearUrl = bike.photoRearId?.toString();
    _insuranceLogbookUrl = bike.insuranceLogbookId?.toString();

    _isPrimary = bike.isPrimary ?? false;
    _hasInsurance = bike.hasInsurance ?? false;

    _selectedModelId = bike.modelId;

    // Load models if we have a make
    if (bike.bikeModel?.makeId != null) {
      _selectedMakeId = bike.bikeModel!.makeId;
      loadModels(bike.bikeModel!.makeId!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _registrationController.dispose();
    _chassisController.dispose();
    _engineController.dispose();
    _colorController.dispose();
    _odometerController.dispose();
    _experienceYearsController.dispose();
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

  Future<void> _handleBikePhotoCapture(String position) async {
    final file = await showImageSourceDialog(context);
    if (file == null || !mounted) return;

    setState(() {
      switch (position) {
        case 'front':
          _photoFrontFile = file;
          _photoFrontUrl = null;
          break;
        case 'side':
          _photoSideFile = file;
          _photoSideUrl = null;
          break;
        case 'rear':
          _photoRearFile = file;
          _photoRearUrl = null;
          break;
      }
    });

    final user = ref.read(authProvider).value;
    if (user == null) {
      _showError('User not logged in');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ref.read(uploadNotifierProvider.notifier).uploadDocument(
            filePath: file.path,
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
        setState(() => _isLoading = false);
        _showError('Upload failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Upload failed: $e');
      }
    }
  }

  Future<void> _handleLogbookUpload() async {
    final file = await showImageSourceDialog(context);
    if (file == null || !mounted) return;

    setState(() {
      // _insuranceLogbookFile = file;
      _insuranceLogbookUrl = null;
    });

    final user = ref.read(authProvider).value;
    if (user == null) {
      _showError('User not logged in');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ref.read(uploadNotifierProvider.notifier).uploadDocument(
            filePath: file.path,
            documentType: 'logbook',
            memberId: user.memberId,
          );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _insuranceLogbookUrl = result;
          _logbookDocument = KycDocument(
            id: int.tryParse(result) ?? 0,
            type: KycDocumentType.fromCode('logbook'),
            url: result,
            filename: file.path.split('/').last,
            uploadedAt: DateTime.now(),
          );
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        _showError('Upload failed');
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
      case 0: // Make & Model
        if (_selectedMakeId == null) {
          _showError('Please select a bike make');
          return false;
        }
        if (_selectedModelId == null) {
          _showError('Please select a bike model');
          return false;
        }
        return true;
      case 1: // Photos
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
        return true;
      case 2: // Details
        if (!_formKey.currentState!.validate()) return false;
        return true;
      case 3: // Review
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    // In edit mode, skip validation
    if (!_isEditMode && !_validateCurrentStep()) {
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
    // In edit mode, skip validation since we only update changed fields
    if (!_isEditMode && !_validateCurrentStep()) return;

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
                  ? 'Bike updated successfully!'
                  : 'Bike added successfully!',
            ),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 3),
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
    final bikeData = {
      'model_id': _selectedModelId,
      'registration_number': _registrationController.text.trim().toUpperCase(),
      'chassis_number': _chassisController.text.trim().toUpperCase(),
      'engine_number': _engineController.text.trim().toUpperCase(),
      'color': _colorController.text.trim().toUpperCase(),
      'purchase_date': _purchaseDate?.toIso8601String().split('T')[0],
      'registration_date': _registrationDate?.toIso8601String().split('T')[0],
      'registration_expiry': _registrationExpiry?.toIso8601String().split(
        'T',
      )[0],
      'bike_photo_url': _photoFrontUrl,
      'odometer_reading': _odometerController.text.trim(),
      'insurance_expiry': _insuranceExpiry?.toIso8601String().split('T')[0],
      'is_primary': _isPrimary,
      'yom': _yom?.toIso8601String().split('T')[0],
      'has_insurance': _hasInsurance ? 1 : 0,
      'experience_years': _experienceYearsController.text.trim().isEmpty
          ? null
          : int.tryParse(_experienceYearsController.text.trim()),
    };

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

    final currentOdometer = _odometerController.text.trim();
    if (currentOdometer != (bike.odometerReading ?? '') &&
        currentOdometer.isNotEmpty) {
      bikeData['odometer_reading'] = currentOdometer;
    }

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
                          _buildMakeModelStep(),
                          _buildPhotosStep(),
                          _buildDetailsStep(),
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
    final stepTitles = ['Make/Model', 'Photos', 'Details', 'Review'];
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
                          _handleSubmit();
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
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.white,
                          ),
                        ),
                      )
                    : Icon(
                        _currentStep == _totalSteps - 1
                            ? Icons.check
                            : Icons.arrow_forward,
                        size: 20,
                      ),
                label: Text(
                  _currentStep == _totalSteps - 1
                      ? (_isEditMode ? 'Update Bike' : 'Add Bike')
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

  Widget _buildMakeModelStep() {
    return SingleChildScrollView(
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
                  const Icon(Icons.check_circle, color: AppTheme.successGreen),
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
      ),
    );
  }

  Widget _buildPhotosStep() {
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
                  Icons.add_a_photo,
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
                      _isEditMode ? 'Update Photos' : 'Upload Photos',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditMode
                          ? 'Update bike photos (optional)'
                          : 'Add clear photos of your bike',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Same UI/logic as KYC registration
          BikePhotoUploader(
            frontPhoto: _photoFrontFile,
            sidePhoto: _photoSideFile,
            rearPhoto: _photoRearFile,
            frontUploaded: _photoFrontUrl != null,
            sideUploaded: _photoSideUrl != null,
            rearUploaded: _photoRearUrl != null,
            onCapture: (position) => _handleBikePhotoCapture(position),
            isUploading: _isLoading,
          ),
          const SizedBox(height: AppTheme.paddingM),

          KycDocumentUploader(
            title: 'Logbook',
            description: 'Upload your bike registration logbook',
            icon: Icons.book,
            document: _logbookDocument,
            onTap: _handleLogbookUpload,
            isUploading: _isLoading,
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
                    'Make sure your photos are clear and well-lit. First 3 photos are required.',
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

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
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
              textCapitalization: TextCapitalization.characters,
              icon: Icons.tag_rounded,
            ),
            const SizedBox(height: 24),

            _buildTextField(
              label: 'Color',
              hint: 'e.g., Blue, Red, Silver',
              controller: _colorController,
              validator: (val) => Validators.validateRequired(val, 'Color'),
              textCapitalization: TextCapitalization.words,
              icon: Icons.palette_rounded,
            ),
            const SizedBox(height: 24),

            _buildTextField(
              label: 'Odometer Reading (Optional)',
              hint: 'Current mileage',
              controller: _odometerController,
              keyboardType: TextInputType.number,
              icon: Icons.speed_rounded,
            ),
            const SizedBox(height: 24),

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

            _buildDateField(
              'Registration Date (Optional)',
              _registrationDate,
              (date) => setState(() => _registrationDate = date),
            ),
            const SizedBox(height: 24),

            _buildDateField(
              'Registration Expiry (Optional)',
              _registrationExpiry,
              (date) => setState(() => _registrationExpiry = date),
            ),
            const SizedBox(height: 24),

            _buildDateField(
              'Insurance Expiry (Optional)',
              _insuranceExpiry,
              (date) => setState(() => _insuranceExpiry = date),
            ),
            const SizedBox(height: 24),

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
                    onChanged: (value) => setState(() => _hasInsurance = value),
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
              if (_insuranceLogbookUrl != null)
                _buildReviewItem('Insurance/Logbook', 'Uploaded ✓'),
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
              if (_odometerController.text.isNotEmpty)
                _buildReviewItem('Odometer', _odometerController.text),
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
              if (_registrationDate != null)
                _buildReviewItem(
                  'Registration Date',
                  DateFormat('MMM dd, yyyy').format(_registrationDate!),
                ),
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

    final currentOdometer = _odometerController.text.trim();
    if (currentOdometer != (bike.odometerReading ?? '') &&
        currentOdometer.isNotEmpty) {
      editedFields.add(
        _buildEditedFieldItem(
          'Odometer Reading',
          bike.odometerReading ?? 'Not set',
          currentOdometer,
        ),
      );
    }

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
