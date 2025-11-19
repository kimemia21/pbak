import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  
  final _registrationController = TextEditingController();
  final _chassisController = TextEditingController();
  final _engineController = TextEditingController();
  final _colorController = TextEditingController();
  final _odometerController = TextEditingController();
  final _experienceYearsController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLoadingMakes = false;
  bool _isLoadingModels = false;
  
  List<BikeMake> _makes = [];
  List<dynamic> _models = [];
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
            break;
          case 'side':
            _photoSideFile = File(pickedFile.path);
            break;
          case 'rear':
            _photoRearFile = File(pickedFile.path);
            break;
          case 'logbook':
            _insuranceLogbookFile = File(pickedFile.path);
            break;
        }
      });

      await _uploadImageImmediately(pickedFile.path, imageType);
    }
  }

  Future<void> _uploadImageImmediately(String filePath, String imageType) async {
    try {
      final uploadService = ref.read(uploadServiceProvider);
      final result = await uploadService.uploadFile(
        filePath: filePath,
        fileField: 'file',
        additionalData: {'doc_type': 'bike_$imageType'},
      );

      if (mounted && result != null) {
        setState(() {
          switch (imageType) {
            case 'front':
              _photoFrontUrl = result.url;
              break;
            case 'side':
              _photoSideUrl = result.url;
              break;
            case 'rear':
              _photoRearUrl = result.url;
              break;
            case 'logbook':
              _insuranceLogbookUrl = result.url;
              break;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getImageTypeLabel(imageType)} uploaded!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _selectedModelId != null;
      case 1:
        return _photoFrontUrl != null && _photoSideUrl != null && _photoRearUrl != null;
      case 2:
        return _formKey.currentState?.validate() ?? false;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _onStepContinue() {
    if (!_validateStep(_currentStep)) {
      String message = '';
      switch (_currentStep) {
        case 0:
          message = 'Please select bike make and model';
          break;
        case 1:
          message = 'Please upload front, side, and rear photos';
          break;
        case 2:
          message = 'Please fill all required fields correctly';
          break;
      }
      _showError(message);
      return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _handleSubmit();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_validateStep(2)) {
      _showError('Please fill all required fields');
      return;
    }

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

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bike added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else if (mounted) {
      _showError('Failed to add bike. Please try again.');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bike'),
        elevation: 0,
      ),
      body: _isLoadingMakes
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading bike makes...'),
                ],
              ),
            )
          : Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: Stepper(
                    currentStep: _currentStep,
                    onStepContinue: _onStepContinue,
                    onStepCancel: _onStepCancel,
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            if (_currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('Back'),
                                ),
                              ),
                            if (_currentStep > 0) const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: CustomButton(
                                text: _currentStep == 3 ? 'Add Bike' : 'Continue',
                                onPressed: details.onStepContinue,
                                isLoading: _isLoading,
                                icon: _currentStep == 3 ? Icons.check : Icons.arrow_forward,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      Step(
                        title: const Text('Make & Model'),
                        subtitle: _selectedModelId != null 
                            ? const Text('Selected ✓', style: TextStyle(color: Colors.green))
                            : null,
                        isActive: _currentStep >= 0,
                        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                        content: _buildMakeModelStep(),
                      ),
                      Step(
                        title: const Text('Upload Photos'),
                        subtitle: (_photoFrontUrl != null && _photoSideUrl != null && _photoRearUrl != null)
                            ? const Text('All uploaded ✓', style: TextStyle(color: Colors.green))
                            : null,
                        isActive: _currentStep >= 1,
                        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                        content: _buildPhotosStep(),
                      ),
                      Step(
                        title: const Text('Bike Details'),
                        subtitle: _validateStep(2)
                            ? const Text('Completed ✓', style: TextStyle(color: Colors.green))
                            : null,
                        isActive: _currentStep >= 2,
                        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                        content: _buildDetailsStep(),
                      ),
                      Step(
                        title: const Text('Additional Info'),
                        isActive: _currentStep >= 3,
                        state: StepState.indexed,
                        content: _buildAdditionalInfoStep(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(25),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
              backgroundColor: Colors.grey[300],
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Step ${_currentStep + 1} of 4',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMakeModelStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
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
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _selectedModelId,
          decoration: InputDecoration(
            labelText: 'Bike Model',
            hintText: _selectedMakeId == null ? 'First select a make' : (_isLoadingModels ? 'Loading...' : 'Select model'),
            prefixIcon: const Icon(Icons.two_wheeler_rounded),
          ),
          items: _models.map((model) {
            final modelMap = model as Map<String, dynamic>;
            return DropdownMenuItem<int>(
              value: modelMap['id'] as int,
              child: Text(modelMap['name'] as String),
            );
          }).toList(),
          onChanged: _selectedMakeId == null || _isLoadingModels ? null : (value) => setState(() => _selectedModelId = value),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Upload at least 3 photos of your bike', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 16),
        _buildPhotoCard('Front View', 'Take a photo from the front', Icons.camera_front, _photoFrontFile, _photoFrontUrl != null, () => _pickAndUploadImage('front')),
        const SizedBox(height: 12),
        _buildPhotoCard('Side View', 'Take a photo from the side', Icons.camera_alt, _photoSideFile, _photoSideUrl != null, () => _pickAndUploadImage('side')),
        const SizedBox(height: 12),
        _buildPhotoCard('Rear View', 'Take a photo from the rear', Icons.camera_rear, _photoRearFile, _photoRearUrl != null, () => _pickAndUploadImage('rear')),
        const SizedBox(height: 12),
        _buildPhotoCard('Insurance/Logbook (Optional)', 'Upload document photo', Icons.description, _insuranceLogbookFile, _insuranceLogbookUrl != null, () => _pickAndUploadImage('logbook')),
      ],
    );
  }

  Widget _buildPhotoCard(String title, String subtitle, IconData icon, File? imageFile, bool isUploaded, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUploaded ? Colors.green.withAlpha(25) : Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(imageFile, fit: BoxFit.cover))
                    : Icon(icon, color: isUploaded ? Colors.green : Colors.grey, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    if (isUploaded) const Text('Uploaded ✓', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Icon(isUploaded ? Icons.check_circle : Icons.add_circle_outline, color: isUploaded ? Colors.green : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          CustomTextField(
            label: 'Registration Number',
            hint: 'e.g., KBZ 456Y',
            controller: _registrationController,
            validator: Validators.validateRegistrationNumber,
            textCapitalization: TextCapitalization.characters,
            prefixIcon: const Icon(Icons.confirmation_number_rounded),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Engine Number',
            hint: 'Enter engine number',
            controller: _engineController,
            validator: Validators.validateEngineNumber,
            textCapitalization: TextCapitalization.characters,
            prefixIcon: const Icon(Icons.settings_rounded),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Chassis Number',
            hint: 'Enter chassis number',
            controller: _chassisController,
            textCapitalization: TextCapitalization.characters,
            prefixIcon: const Icon(Icons.tag_rounded),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Color',
            hint: 'e.g., Blue, Red, Silver',
            controller: _colorController,
            validator: (val) => Validators.validateRequired(val, 'Color'),
            textCapitalization: TextCapitalization.words,
            prefixIcon: const Icon(Icons.palette_rounded),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Odometer Reading (Optional)',
            hint: 'Current mileage',
            controller: _odometerController,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.speed_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        CustomTextField(
          label: 'Riding Experience (Years)',
          hint: 'e.g., 5',
          controller: _experienceYearsController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.emoji_events_rounded),
        ),
        const SizedBox(height: 16),
        _buildDateField('Year of Manufacture', _yom, (date) => setState(() => _yom = date)),
        const SizedBox(height: 16),
        _buildDateField('Purchase Date', _purchaseDate, (date) => setState(() => _purchaseDate = date)),
        const SizedBox(height: 16),
        _buildDateField('Registration Date', _registrationDate, (date) => setState(() => _registrationDate = date)),
        const SizedBox(height: 16),
        _buildDateField('Registration Expiry', _registrationExpiry, (date) => setState(() => _registrationExpiry = date)),
        const SizedBox(height: 16),
        _buildDateField('Insurance Expiry', _insuranceExpiry, (date) => setState(() => _insuranceExpiry = date)),
        const SizedBox(height: 16),
        SwitchListTile(title: const Text('Has Insurance'), value: _hasInsurance, onChanged: (value) => setState(() => _hasInsurance = value)),
        SwitchListTile(title: const Text('Primary Bike'), value: _isPrimary, onChanged: (value) => setState(() => _isPrimary = value)),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime) onDateSelected) {
    return InkWell(
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
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.calendar_today)),
        child: Text(date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Select date', style: TextStyle(color: date != null ? null : Colors.grey[600])),
      ),
    );
  }
}
