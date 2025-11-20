import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbak/models/bike_model.dart';
import 'dart:io';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/providers/upload_provider.dart';
import 'package:pbak/services/bike_service.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/widgets/custom_text_field.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class AddBikeScreen extends ConsumerStatefulWidget {
  const AddBikeScreen({super.key});

  @override
  ConsumerState<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends ConsumerState<AddBikeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
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
  File? _insuranceLogbookFile;
  
  String? _photoFrontUrl;
  String? _photoSideUrl;
  String? _photoRearUrl;
  String? _insuranceLogbookUrl;
  
  bool _isPrimary = false;
  bool _hasInsurance = false;

  @override
  void initState() {
    super.initState();
    _loadMakes();
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

  Future<void> _loadModels(int makeId) async {
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

  Future<void> _pickAndUploadImage(String imageType) async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        switch (imageType) {
          case 'front':
            _photoFrontFile = File(pickedFile.path);
            _photoFrontUrl = null; // Reset URL when new file selected
            break;
          case 'side':
            _photoSideFile = File(pickedFile.path);
            _photoSideUrl = null;
            break;
          case 'rear':
            _photoRearFile = File(pickedFile.path);
            _photoRearUrl = null;
            break;
          case 'logbook':
            _insuranceLogbookFile = File(pickedFile.path);
            _insuranceLogbookUrl = null;
            break;
        }
      });

      await _uploadImageImmediately(pickedFile.path, imageType);
    }
  }

  Future<void> _uploadImageImmediately(String filePath, String imageType) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // TODO: TEMPORARY FIX - Using static URLs while server upload is being fixed
      // When server is ready, uncomment the upload code below and remove static URLs
      
      // STATIC URLs for testing (remove when server is fixed)
      String uploadedUrl;
      switch (imageType) {
        case 'front':
          uploadedUrl = 'BIKE/FRONT_${DateTime.now().millisecondsSinceEpoch}.JPG';
          break;
        case 'side':
          uploadedUrl = 'BIKE/SIDE_${DateTime.now().millisecondsSinceEpoch}.JPG';
          break;
        case 'rear':
          uploadedUrl = 'BIKE/REAR_${DateTime.now().millisecondsSinceEpoch}.JPG';
          break;
        case 'logbook':
          uploadedUrl = 'BIKE/LOGBOOK_${DateTime.now().millisecondsSinceEpoch}.JPG';
          break;
        default:
          uploadedUrl = 'BIKE/PHOTO_${DateTime.now().millisecondsSinceEpoch}.JPG';
      }
      
      /* UNCOMMENT THIS WHEN SERVER IS FIXED:
      final uploadService = ref.read(uploadServiceProvider);
      final result = await uploadService.uploadFile(
        filePath: filePath,
        fileField: 'file',
        additionalData: {'doc_type': 'bike_$imageType'},
      );
      final uploadedUrl = result?.url;
      */

      if (mounted && uploadedUrl != null) {
        setState(() {
          switch (imageType) {
            case 'front':
              _photoFrontUrl = uploadedUrl;
              break;
            case 'side':
              _photoSideUrl = uploadedUrl;
              break;
            case 'rear':
              _photoRearUrl = uploadedUrl;
              break;
            case 'logbook':
              _insuranceLogbookUrl = uploadedUrl;
              break;
          }
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getImageTypeLabel(imageType)} uploaded! (Using static URL for testing)'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 2),
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

  String _getImageTypeLabel(String imageType) {
    switch (imageType) {
      case 'front':
        return 'Front photo';
      case 'side':
        return 'Side photo';
      case 'rear':
        return 'Rear photo';
      case 'logbook':
        return 'Insurance/Logbook';
      default:
        return 'Image';
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

  Future<void> _handleSubmit() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    final bikeData = {
      'model_id': _selectedModelId,
      'registration_number': _registrationController.text.trim().toUpperCase(),
      'chassis_number': _chassisController.text.trim().toUpperCase(),
      'engine_number': _engineController.text.trim().toUpperCase(),
      'color': _colorController.text.trim().toUpperCase(),
      'purchase_date': _purchaseDate?.toIso8601String().split('T')[0],
      'registration_date': _registrationDate?.toIso8601String().split('T')[0],
      'registration_expiry': _registrationExpiry?.toIso8601String().split('T')[0],
      'bike_photo_url': _photoFrontUrl ?? 'BIKE/PH${DateTime.now().millisecondsSinceEpoch}.JPG',
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

    final success = await ref.read(bikeNotifierProvider.notifier).addBike(bikeData);

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bike added successfully!'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
        context.pop();
      } else {
        _showError('Failed to add bike. Please try again.');
      }
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Bike'),
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
                              color: isCompleted ? AppTheme.brightRed : AppTheme.lightSilver,
                            ),
                          ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCompleted || isCurrent ? AppTheme.brightRed : AppTheme.lightSilver,
                            shape: BoxShape.circle,
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppTheme.brightRed.withOpacity(0.3),
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
                                      color: isCurrent ? AppTheme.white : AppTheme.mediumGrey,
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
                              color: isCompleted ? AppTheme.brightRed : AppTheme.lightSilver,
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
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                        ),
                      )
                    : Icon(
                        _currentStep == _totalSteps - 1 ? Icons.check : Icons.arrow_forward,
                        size: 20,
                      ),
                label: Text(
                  _currentStep == _totalSteps - 1 ? 'Add Bike' : 'Continue',
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
            'Select Your Bike',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the make and model of your motorcycle',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
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
              return DropdownMenuItem<int>(value: make.id, child: Text(make.name));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedMakeId = value);
                _loadModels(value);
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
            onChanged: _selectedMakeId == null || _isLoadingModels 
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
                border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
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
                      'Upload Photos',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add clear photos of your bike',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          _buildImageUploadCard(
            title: 'Front View',
            description: 'Take a clear photo from the front',
            icon: Icons.camera_front,
            imageFile: _photoFrontFile,
            uploadedUrl: _photoFrontUrl,
            onTap: () => _pickAndUploadImage('front'),
          ),
          const SizedBox(height: 16),
          
          _buildImageUploadCard(
            title: 'Side View',
            description: 'Take a clear photo from the side',
            icon: Icons.camera_alt,
            imageFile: _photoSideFile,
            uploadedUrl: _photoSideUrl,
            onTap: () => _pickAndUploadImage('side'),
          ),
          const SizedBox(height: 16),
          
          _buildImageUploadCard(
            title: 'Rear View',
            description: 'Take a clear photo from the rear',
            icon: Icons.camera_rear,
            imageFile: _photoRearFile,
            uploadedUrl: _photoRearUrl,
            onTap: () => _pickAndUploadImage('rear'),
          ),
          const SizedBox(height: 16),
          
          _buildImageUploadCard(
            title: 'Insurance/Logbook (Optional)',
            description: 'Upload your insurance or logbook document',
            icon: Icons.description,
            imageFile: _insuranceLogbookFile,
            uploadedUrl: _insuranceLogbookUrl,
            onTap: () => _pickAndUploadImage('logbook'),
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

  Widget _buildImageUploadCard({
    required String title,
    required String description,
    required IconData icon,
    required File? imageFile,
    required String? uploadedUrl,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUploaded = uploadedUrl != null;
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
                          : (hasFile 
                              ? AppTheme.warningOrange.withOpacity(0.1)
                              : AppTheme.brightRed.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isUploaded ? Icons.check_circle : icon,
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUploaded
                              ? 'Uploaded successfully'
                              : (hasFile ? 'Uploading...' : description),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isUploaded
                                ? AppTheme.successGreen
                                : (hasFile 
                                    ? AppTheme.warningOrange 
                                    : colorScheme.onSurface.withOpacity(0.7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isUploaded ? Icons.edit : Icons.add_circle_outline,
                    color: isUploaded ? AppTheme.successGreen : AppTheme.brightRed,
                  ),
                ],
              ),
              if (hasFile && imageFile != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  child: Image.file(
                    imageFile,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bike Details',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your motorcycle information',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
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
            
            _buildDateField('Year of Manufacture', _yom, (date) => setState(() => _yom = date)),
            const SizedBox(height: 24),
            
            _buildDateField('Purchase Date (Optional)', _purchaseDate, (date) => setState(() => _purchaseDate = date)),
            const SizedBox(height: 24),
            
            _buildDateField('Registration Date (Optional)', _registrationDate, (date) => setState(() => _registrationDate = date)),
            const SizedBox(height: 24),
            
            _buildDateField('Registration Expiry (Optional)', _registrationExpiry, (date) => setState(() => _registrationExpiry = date)),
            const SizedBox(height: 24),
            
            _buildDateField('Insurance Expiry (Optional)', _insuranceExpiry, (date) => setState(() => _insuranceExpiry = date)),
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
                    subtitle: const Text('Does this bike have active insurance?'),
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
            prefixIcon: Icon(
              icon,
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
            errorBorder: theme.inputDecorationTheme.errorBorder,
            focusedErrorBorder: theme.inputDecorationTheme.focusedErrorBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime) onDateSelected) {
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
              date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Select date',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: date != null ? theme.colorScheme.onSurface : AppTheme.mediumGrey,
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
            'Review Your Bike',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review all information before submitting',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Make & Model Section
          _buildReviewSection(
            title: 'Make & Model',
            icon: Icons.two_wheeler_rounded,
            children: [
              _buildReviewItem(
                'Make',
                _makes.firstWhere((m) => m.id == _selectedMakeId, orElse: () => BikeMake(id: 0, name: 'Unknown')).name,
              ),
              _buildReviewItem(
                'Model',
                _models.firstWhere(
                  (m) => m.modelId == _selectedModelId,
                  orElse: () => BikeModelCatalog(modelName: 'Unknown'),
                ).displayName,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Photos Section
          _buildReviewSection(
            title: 'Photos',
            icon: Icons.photo_library,
            children: [
              _buildReviewItem('Front Photo', _photoFrontUrl != null ? 'Uploaded ✓' : 'Not uploaded'),
              _buildReviewItem('Side Photo', _photoSideUrl != null ? 'Uploaded ✓' : 'Not uploaded'),
              _buildReviewItem('Rear Photo', _photoRearUrl != null ? 'Uploaded ✓' : 'Not uploaded'),
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
              _buildReviewItem('Registration Number', _registrationController.text.toUpperCase()),
              _buildReviewItem('Engine Number', _engineController.text.toUpperCase()),
              if (_chassisController.text.isNotEmpty)
                _buildReviewItem('Chassis Number', _chassisController.text.toUpperCase()),
              _buildReviewItem('Color', _colorController.text),
              if (_odometerController.text.isNotEmpty)
                _buildReviewItem('Odometer', _odometerController.text),
              if (_experienceYearsController.text.isNotEmpty)
                _buildReviewItem('Riding Experience', '${_experienceYearsController.text} years'),
              if (_yom != null)
                _buildReviewItem('Year of Manufacture', DateFormat('yyyy').format(_yom!)),
              if (_purchaseDate != null)
                _buildReviewItem('Purchase Date', DateFormat('MMM dd, yyyy').format(_purchaseDate!)),
              if (_registrationDate != null)
                _buildReviewItem('Registration Date', DateFormat('MMM dd, yyyy').format(_registrationDate!)),
              if (_registrationExpiry != null)
                _buildReviewItem('Registration Expiry', DateFormat('MMM dd, yyyy').format(_registrationExpiry!)),
              if (_insuranceExpiry != null)
                _buildReviewItem('Insurance Expiry', DateFormat('MMM dd, yyyy').format(_insuranceExpiry!)),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
