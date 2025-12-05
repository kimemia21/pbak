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
  final File? frontPhoto;
  final File? sidePhoto;
  final File? rearPhoto;
  final Function(String position) onCapture;
  final bool isUploading;

  const BikePhotoUploader({
    super.key,
    this.frontPhoto,
    this.sidePhoto,
    this.rearPhoto,
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
    VoidCallback onTap,
  ) {
    final hasPhoto = photo != null;

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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      photo,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
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

/// Helper function to show image picker dialog
Future<File?> showImageSourceDialog(BuildContext context) async {
  return await showDialog<File?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choose Image Source'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () async {
              Navigator.pop(context);
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.camera);
              if (image != null && context.mounted) {
                Navigator.pop(context, File(image.path));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () async {
              Navigator.pop(context);
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null && context.mounted) {
                Navigator.pop(context, File(image.path));
              }
            },
          ),
        ],
      ),
    ),
  );
}
