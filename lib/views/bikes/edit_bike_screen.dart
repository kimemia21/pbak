import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/providers/upload_provider.dart';
import 'package:pbak/widgets/kyc_document_uploader.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/models/kyc_document_model.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/utils/constants.dart';
import 'package:pbak/widgets/custom_text_field.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:pbak/widgets/loading_widget.dart';

class EditBikeScreen extends ConsumerStatefulWidget {
  final String bikeId;

  const EditBikeScreen({
    super.key,
    required this.bikeId,
  });

  @override
  ConsumerState<EditBikeScreen> createState() => _EditBikeScreenState();
}

class _EditBikeScreenState extends ConsumerState<EditBikeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _registrationController = TextEditingController();
  final _engineController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();

  File? _photoFrontFile;
  File? _photoSideFile;
  File? _photoRearFile;
  String? _photoFrontUrl;
  String? _photoSideUrl;
  String? _photoRearUrl;
  String? _insuranceLogbookUrl;
  KycDocument? _logbookDocument;

  String _selectedType = AppConstants.motorcycleTypes.first;
  bool _isLoading = false;
  bool _dataLoaded = false;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _registrationController.dispose();
    _engineController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _loadBikeData(bike) {
    if (_dataLoaded) return;

    _makeController.text = bike.makeName;
    _modelController.text = bike.modelName;
    _registrationController.text = bike.registrationNumber ?? '';
    _engineController.text = bike.engineNumber ?? '';
    _yearController.text = bike.yom?.year.toString() ?? '';
    _colorController.text = bike.color ?? '';
    _selectedType = bike.bikeModel?.category ?? AppConstants.motorcycleTypes.first;

    // seed existing urls if any
    _photoFrontUrl = bike.bikePhotoUrl;
    // These are IDs in the API model; for now treat them as "already uploaded".
    _photoSideUrl = bike.photoSideId?.toString();
    _photoRearUrl = bike.photoRearId?.toString();
    _insuranceLogbookUrl = bike.insuranceLogbookId?.toString();
    if (_insuranceLogbookUrl != null) {
      _logbookDocument = KycDocument(
        id: int.tryParse(_insuranceLogbookUrl!) ?? 0,
        type: KycDocumentType.fromCode('logbook'),
        url: _insuranceLogbookUrl,
        filename: null,
        uploadedAt: null,
      );
    }

    _dataLoaded = true;
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final bikeData = <String, dynamic>{
        'color': _colorController.text.trim(),
        'status': 'active',
      };

      // If the user uploaded/updated the main bike photo (front), send it.
      if (_photoFrontUrl != null) {
        bikeData['bike_photo_url'] = _photoFrontUrl;
      }

      final success = await ref.read(bikeNotifierProvider.notifier).updateBike(
            int.parse(widget.bikeId),
            bikeData,
          );

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bike updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update bike. Please try again.'),
            backgroundColor: AppTheme.brightRed,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bikeAsync = ref.watch(bikeByIdProvider(int.parse(widget.bikeId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Bike'),
      ),
      body: bikeAsync.when(
        data: (bike) {
          if (bike == null) {
            return const Center(child: Text('Bike not found'));
          }

          _loadBikeData(bike);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    label: 'Make',
                    hint: 'e.g., Yamaha, Honda, Suzuki',
                    controller: _makeController,
                    validator: (val) => Validators.validateRequired(val, 'Make'),
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: const Icon(Icons.business_rounded),
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  CustomTextField(
                    label: 'Model',
                    hint: 'e.g., MT-07, CB500X',
                    controller: _modelController,
                    validator: (val) => Validators.validateRequired(val, 'Model'),
                    textCapitalization: TextCapitalization.characters,
                    prefixIcon: const Icon(Icons.two_wheeler_rounded),
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: AppConstants.motorcycleTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  CustomTextField(
                    label: 'Registration Number',
                    hint: 'e.g., KBZ 456Y',
                    controller: _registrationController,
                    validator: Validators.validateRegistrationNumber,
                    textCapitalization: TextCapitalization.characters,
                    prefixIcon: const Icon(Icons.confirmation_number_rounded),
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  CustomTextField(
                    label: 'Engine Number',
                    hint: 'Enter engine number',
                    controller: _engineController,
                    validator: Validators.validateEngineNumber,
                    textCapitalization: TextCapitalization.characters,
                    prefixIcon: const Icon(Icons.settings_rounded),
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  CustomTextField(
                    label: 'Year',
                    hint: 'e.g., 2022',
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    validator: Validators.validateYear,
                    prefixIcon: const Icon(Icons.calendar_today_rounded),
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  CustomTextField(
                    label: 'Color',
                    hint: 'e.g., Blue, Red',
                    controller: _colorController,
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: const Icon(Icons.palette_rounded),
                  ),
                  const SizedBox(height: AppTheme.paddingL),

                  // Photos (same UI/logic as KYC registration)
                  Text(
                    'Photos',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload/update your bike photos.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.paddingM),

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

                  const SizedBox(height: AppTheme.paddingXL),

                  CustomButton(
                    text: 'Update Bike',
                    onPressed: _handleSubmit,
                    isLoading: _isLoading,
                    icon: Icons.save_rounded,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading bike details...'),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load bike details'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
