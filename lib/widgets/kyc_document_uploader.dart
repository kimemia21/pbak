import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbak/models/kyc_document_model.dart';

/// Widget for uploading KYC documents
class KycDocumentUploader extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final KycDocument? document;
  final bool isRequired;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool isUploading;

  const KycDocumentUploader({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.document,
    this.isRequired = false,
    required this.onTap,
    this.onRemove,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDocument = document != null && document!.id != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isUploading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasDocument
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasDocument ? Icons.check_circle : icon,
                  color: hasDocument ? Colors.green : Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isRequired) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasDocument ? 'Uploaded ✓' : description,
                      style: TextStyle(
                        fontSize: 14,
                        color: hasDocument ? Colors.green : Colors.grey[600],
                      ),
                    ),
                    if (hasDocument && document!.filename != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        document!.filename!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Loading or action button
              if (isUploading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (hasDocument && onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: onRemove,
                  tooltip: 'Remove',
                )
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for uploading bike photos (front, side, rear)
class BikePhotoUploader extends StatelessWidget {
  /// If a [File] is provided, the card will show a preview image.
  final File? frontPhoto;
  final File? sidePhoto;
  final File? rearPhoto;

  /// If true, the card will show a "Uploaded ✓" success state even if no [File]
  /// is available (useful when the file is already uploaded and you only have a URL/id).
  final bool frontUploaded;
  final bool sideUploaded;
  final bool rearUploaded;

  final Function(String position) onCapture;
  final bool isUploading;

  const BikePhotoUploader({
    super.key,
    this.frontPhoto,
    this.sidePhoto,
    this.rearPhoto,
    this.frontUploaded = false,
    this.sideUploaded = false,
    this.rearUploaded = false,
    required this.onCapture,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.motorcycle, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Bike Photos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 4),
                Text('*', style: TextStyle(color: Colors.red, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Capture 3 photos: Front, Side, Rear (plate visible)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Photo Grid
            Row(
              children: [
                Expanded(
                  child: _buildPhotoCard(
                    context,
                    'Front',
                    Icons.directions_car,
                    frontPhoto,
                    frontUploaded,
                    () => onCapture('front'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhotoCard(
                    context,
                    'Side',
                    Icons.two_wheeler,
                    sidePhoto,
                    sideUploaded,
                    () => onCapture('side'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhotoCard(
                    context,
                    'Rear',
                    Icons.power_input,
                    rearPhoto,
                    rearUploaded,
                    () => onCapture('rear'),
                  ),
                ),
              ],
            ),

            if (isUploading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 4),
              const Text(
                'Uploading bike photos...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(
    BuildContext context,
    String label,
    IconData icon,
    File? photo,
    bool isUploaded,
    VoidCallback onTap,
  ) {
    final hasPreview = photo != null;
    final hasPhoto = hasPreview || isUploaded;

    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: hasPhoto
              ? Colors.green.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasPhoto ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: hasPhoto
            ? Stack(
                children: [
                  if (hasPreview)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        photo!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    // Uploaded but no local preview available
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 28, color: Colors.green.shade700),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Uploaded ✓',
                            style: TextStyle(fontSize: 10, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.add_a_photo, size: 16, color: Colors.grey),
                ],
              ),
      ),
    );
  }
}

/// Widget for uploading ID photos (front and back)
class IdPhotoUploader extends StatelessWidget {
  final String title;
  final String description;
  final String uploadingText;
  final KycDocument? frontPhoto;
  final KycDocument? backPhoto;
  final Function(String side) onCapture; // 'front' or 'back'
  final VoidCallback? onRemoveFront;
  final VoidCallback? onRemoveBack;
  final bool isUploading;
  final bool isRequired;

  const IdPhotoUploader({
    super.key,
    required this.title,
    this.description = 'Upload both front and back sides of your ID',
    this.uploadingText = 'Uploading ID photos...',
    this.frontPhoto,
    this.backPhoto,
    required this.onCapture,
    this.onRemoveFront,
    this.onRemoveBack,
    this.isUploading = false,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.credit_card, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isRequired) ...[
                  const SizedBox(width: 4),
                  const Text('*', style: TextStyle(color: Colors.red, fontSize: 18)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Photo Grid
            Row(
              children: [
                Expanded(
                  child: _buildPhotoCard(
                    context,
                    'Front Side',
                    Icons.credit_card,
                    frontPhoto,
                    () => onCapture('front'),
                    onRemoveFront,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPhotoCard(
                    context,
                    'Back Side',
                    Icons.flip,
                    backPhoto,
                    () => onCapture('back'),
                    onRemoveBack,
                  ),
                ),
              ],
            ),

            if (isUploading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 4),
              Text(
                uploadingText,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(
    BuildContext context,
    String label,
    IconData icon,
    KycDocument? document,
    VoidCallback onTap,
    VoidCallback? onRemove,
  ) {
    final hasPhoto = document != null && document.id != null;

    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: hasPhoto
              ? Colors.green.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasPhoto ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: hasPhoto
            ? Stack(
                children: [
                  // Success state
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.green.withOpacity(0.1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Uploaded ✓',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Remove button
                  if (onRemove != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.add_a_photo, size: 16, color: Colors.grey),
                ],
              ),
      ),
    );
  }
}

/// Enhanced image picker dialog with better UI
Future<File?> showImageSourceDialog(BuildContext context) async {
  return await showDialog<File?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choose Image Source'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.blue),
            title: const Text('Take Photo'),
            subtitle: const Text('Use camera to capture image'),
            onTap: () async {
              final picker = ImagePicker();
              final image = await picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 1920,
                maxHeight: 1080,
                imageQuality: 85,
              );

              if (!context.mounted) return;

              // Pop the dialog exactly once, returning the selected file (or null).
              Navigator.of(context).pop(image == null ? null : File(image.path));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.green),
            title: const Text('Choose from Gallery'),
            subtitle: const Text('Select from photo library'),
            onTap: () async {
              final picker = ImagePicker();
              final image = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1920,
                maxHeight: 1080,
                imageQuality: 85,
              );

              if (!context.mounted) return;

              // Pop the dialog exactly once, returning the selected file (or null).
              Navigator.of(context).pop(image == null ? null : File(image.path));
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}
