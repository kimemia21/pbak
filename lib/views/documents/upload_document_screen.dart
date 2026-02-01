import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/upload_provider.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:pbak/widgets/platform_image.dart';

class UploadDocumentScreen extends ConsumerStatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  ConsumerState<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen> {
  final _imagePicker = ImagePicker();
  String _selectedDocumentType = 'passport';
  XFile? _selectedXFile;
  String? _selectedFilePath;
  String? _selectedFileName;

  final List<DocumentType> _documentTypes = [
    DocumentType('passport', 'Passport Photo', Icons.person_outline_rounded),
    DocumentType('national_id_front', 'National ID - Front', Icons.badge_outlined),
    DocumentType('national_id_back', 'National ID - Back', Icons.flip_to_back_outlined),
    DocumentType('dl_front', 'Driving License - Front', Icons.credit_card_rounded),
    DocumentType('dl_back', 'Driving License - Back', Icons.credit_card_outlined),
    DocumentType('bike_front', 'Bike Photo - Front', Icons.directions_bike_outlined),
    DocumentType('bike_side', 'Bike Photo - Side', Icons.two_wheeler_rounded),
    DocumentType('bike_rear', 'Bike Photo - Rear', Icons.power_input_outlined),
    DocumentType('insurance_card', 'Insurance Card', Icons.shield_outlined),
    DocumentType('logbook', 'Logbook', Icons.book_outlined),
    DocumentType('medical_insurance', 'Medical Insurance', Icons.local_hospital_outlined),
    DocumentType('other', 'Other Document', Icons.description_outlined),
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Web: only gallery/file picker is supported reliably.
      // Also avoid unsupported params like preferredCameraDevice.
      final effectiveSource = kIsWeb ? ImageSource.gallery : source;

      final XFile? image = await _imagePicker.pickImage(
        source: effectiveSource,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedXFile = image;
          _selectedFilePath = image.path;
          _selectedFileName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpload() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file to upload'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final user = authState.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to upload documents'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uploadNotifier = ref.read(uploadNotifierProvider.notifier);

        final result = kIsWeb
            ? await uploadNotifier.uploadDocumentXFile(
                file: _selectedXFile!,
                documentType: _selectedDocumentType,
                memberId: user.memberId,
              )
            : await uploadNotifier.uploadDocument(
                filePath: _selectedFilePath!,
                documentType: _selectedDocumentType,
                memberId: user.memberId,
              );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload document. Please try again.'),
          backgroundColor: AppTheme.brightRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uploadState = ref.watch(uploadNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Document Type Selection
            Text(
              'Document Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _documentTypes.map((type) {
                final isSelected = _selectedDocumentType == type.value;
                return ChoiceChip(
                  avatar: Icon(
                    type.icon,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                    size: 20,
                  ),
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedDocumentType = type.value);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.paddingL),

            // File Selection
            Text(
              'Select File',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),
            InkWell(
              onTap: uploadState.isUploading ? null : _showImageSourceDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.paddingL),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFilePath == null
                          ? Icons.upload_file_rounded
                          : Icons.check_circle_rounded,
                      size: 64,
                      color: _selectedFilePath == null
                          ? theme.colorScheme.primary
                          : Colors.green,
                    ),
                    const SizedBox(height: AppTheme.paddingM),
                    Text(
                      _selectedFilePath == null
                          ? 'Tap to select a file'
                          : _selectedFileName ?? 'File selected',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedFilePath != null) ...[
                      const SizedBox(height: 12),
                      // Preview (web-safe)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: PlatformImage(
                            xFile: _selectedXFile,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: uploadState.isUploading
                            ? null
                            : () {
                                setState(() {
                                  _selectedXFile = null;
                                  _selectedFilePath = null;
                                  _selectedFileName = null;
                                });
                              },
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Remove'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.paddingXL),

            // Upload Progress
            if (uploadState.isUploading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppTheme.paddingM),
              const Text(
                'Uploading document...',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.paddingM),
            ],

            // Error Message
            if (uploadState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingM),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  uploadState.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTheme.paddingM),
            ],

            // Upload Button
            CustomButton(
              text: 'Upload Document',
              onPressed: _handleUpload,
              isLoading: uploadState.isUploading,
              icon: Icons.cloud_upload_rounded,
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Cancel Button
            OutlinedButton(
              onPressed: uploadState.isUploading ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentType {
  final String value;
  final String label;
  final IconData icon;

  DocumentType(this.value, this.label, this.icon);
}
