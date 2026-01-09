import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/upload_provider.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/providers/kyc_provider.dart';
import 'package:pbak/models/kyc_document_model.dart';
import 'package:pbak/widgets/kyc_document_uploader.dart';
import 'package:pbak/widgets/custom_button.dart';

class EnhancedKycUploadScreen extends ConsumerStatefulWidget {
  const EnhancedKycUploadScreen({super.key});

  @override
  ConsumerState<EnhancedKycUploadScreen> createState() => _EnhancedKycUploadScreenState();
}

class _EnhancedKycUploadScreenState extends ConsumerState<EnhancedKycUploadScreen> {
  bool _isUploading = false;

  Future<void> _handlePhotoUpload(String documentType, String side) async {
    final file = await showImageSourceDialog(context);
    if (file == null) return;

    setState(() => _isUploading = true);

    try {
      final authState = ref.read(authProvider);
      final user = authState.value;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Determine the document type code based on the type and side
      String docTypeCode;
      switch (documentType) {
        case 'national_id':
          docTypeCode = side == 'front' ? 'national_id_front' : 'national_id_back';
          break;
        case 'driving_license':
          docTypeCode = side == 'front' ? 'dl_front' : 'dl_back';
          break;
        default:
          docTypeCode = documentType;
      }

      final result = await ref.read(uploadNotifierProvider.notifier).uploadDocument(
        filePath: file.path,
        documentType: docTypeCode,
        memberId: user.memberId,
      );

      if (result != null) {
        // Update the KYC provider with the new document
        final kycDocument = KycDocument(
          id: int.tryParse(result) ?? 0,
          type: KycDocumentType.fromCode(docTypeCode),
          url: result,
          filename: file.path.split('/').last,
          uploadedAt: DateTime.now(),
        );

        await ref.read(kycNotifierProvider.notifier).updateDocument(kycDocument);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${side.toUpperCase()} side uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _handleSingleDocumentUpload(String documentType) async {
    final file = await showImageSourceDialog(context);
    if (file == null) return;

    setState(() => _isUploading = true);

    try {
      final authState = ref.read(authProvider);
      final user = authState.value;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final result = await ref.read(uploadNotifierProvider.notifier).uploadDocument(
        filePath: file.path,
        documentType: documentType,
        memberId: user.memberId,
      );

      if (result != null) {
        // Update the KYC provider with the new document
        final kycDocument = KycDocument(
          id: int.tryParse(result) ?? 0,
          type: KycDocumentType.fromCode(documentType),
          url: result,
          filename: file.path.split('/').last,
          uploadedAt: DateTime.now(),
        );

        await ref.read(kycNotifierProvider.notifier).updateDocument(kycDocument);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _handleDocumentRemove(KycDocumentType documentType) async {
    try {
      await ref.read(kycNotifierProvider.notifier).removeDocument(documentType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('KYC Document Upload'),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Enhanced KYC capture is not available on web yet.\n\nPlease use the standard Upload Document screen to upload your documents.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.push('/documents/upload'),
                  child: const Text('Go to Upload Document'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final kycState = ref.watch(kycNotifierProvider);
    final uploadState = ref.watch(uploadNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Document Upload'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete Your KYC',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Upload all required documents to verify your identity',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nyumba Kumi: make sure your details are tied to your home location.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Personal Documents Section
            Text(
              'Personal Documents',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Passport Photo
            KycDocumentUploader(
              title: 'Passport Photo',
              description: 'Upload a clear passport-style photo',
              icon: Icons.person,
              document: kycState.kycData?.passportPhoto,
              isRequired: true,
              onTap: () => _handleSingleDocumentUpload('passport'),
              onRemove: () => _handleDocumentRemove(KycDocumentType.passportPhoto),
              isUploading: _isUploading,
            ),
            const SizedBox(height: AppTheme.paddingM),

            // National ID (Front & Back)
            IdPhotoUploader(
              title: 'National ID',
              frontPhoto: kycState.kycData?.nationalIdFront,
              backPhoto: kycState.kycData?.nationalIdBack,
              onCapture: (side) => _handlePhotoUpload('national_id', side),
              onRemoveFront: () => _handleDocumentRemove(KycDocumentType.nationalIdFront),
              onRemoveBack: () => _handleDocumentRemove(KycDocumentType.nationalIdBack),
              isUploading: _isUploading,
              isRequired: true,
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Driving License (Front & Back)
            IdPhotoUploader(
              title: 'Driving License',
              description: 'Upload two photos of your driving license: front and back.',
              uploadingText: 'Uploading driving license photos...',
              frontPhoto: kycState.kycData?.drivingLicenseFront,
              backPhoto: kycState.kycData?.drivingLicenseBack,
              onCapture: (side) => _handlePhotoUpload('driving_license', side),
              onRemoveFront: () => _handleDocumentRemove(KycDocumentType.drivingLicenseFront),
              onRemoveBack: () => _handleDocumentRemove(KycDocumentType.drivingLicenseBack),
              isUploading: _isUploading,
              isRequired: true,
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Bike Documents Section
            Text(
              'Bike Documents',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Bike Photos
            BikePhotoUploader(
              frontPhoto: kycState.kycData?.bikePhotoFront != null ? File('') : null,
              sidePhoto: kycState.kycData?.bikePhotoSide != null ? File('') : null,
              rearPhoto: kycState.kycData?.bikePhotoRear != null ? File('') : null,
              onCapture: (position) async {
                final file = await showImageSourceDialog(context);
                if (file != null) {
                  String docType = 'bike_$position';
                  await _handleSingleDocumentUpload(docType);
                }
              },
              isUploading: _isUploading,
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Insurance Card
            KycDocumentUploader(
              title: 'Insurance Card',
              description: 'Upload your bike insurance document',
              icon: Icons.shield,
              document: kycState.kycData?.insuranceCard,
              onTap: () => _handleSingleDocumentUpload('insurance_card'),
              onRemove: () => _handleDocumentRemove(KycDocumentType.insuranceCard),
              isUploading: _isUploading,
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Logbook
            KycDocumentUploader(
              title: 'Logbook',
              description: 'Upload your bike registration logbook',
              icon: Icons.book,
              document: kycState.kycData?.logbook,
              onTap: () => _handleSingleDocumentUpload('logbook'),
              onRemove: () => _handleDocumentRemove(KycDocumentType.logbook),
              isUploading: _isUploading,
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Payments
            Text(
              'Payments',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Membership Payment',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select a package and pay via M-Pesa (simulated for now).',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/payments/register'),
                      icon: const Icon(Icons.payments_rounded),
                      label: const Text('Open Payment Registration'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Optional Documents Section
            Text(
              'Optional Documents',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Medical Insurance
            KycDocumentUploader(
              title: 'Medical Insurance',
              description: 'Upload your medical insurance card (optional)',
              icon: Icons.local_hospital,
              document: kycState.kycData?.medicalInsurance,
              onTap: () => _handleSingleDocumentUpload('medical_insurance'),
              onRemove: () => _handleDocumentRemove(KycDocumentType.medicalInsurance),
              isUploading: _isUploading,
            ),
            const SizedBox(height: AppTheme.paddingXL),

            // Upload Progress
            if (uploadState.isUploading || _isUploading) ...[
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

            // Completion Status
            if (kycState.kycData?.hasRequiredDocuments == true) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingM),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All required documents uploaded successfully!',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.paddingM),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: uploadState.isUploading || _isUploading ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: AppTheme.paddingM),
                Expanded(
                  child: CustomButton(
                    text: 'Continue',
                    onPressed: kycState.kycData?.hasRequiredDocuments == true
                        ? () {
                            // Navigate to next step or show completion
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('KYC documents submitted for verification!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            context.pop();
                          }
                        : null,
                    isLoading: uploadState.isUploading || _isUploading,
                    icon: Icons.arrow_forward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}