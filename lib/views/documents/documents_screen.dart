import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/upload_provider.dart';
import 'package:pbak/widgets/animated_card.dart';
import 'package:pbak/widgets/empty_state_widget.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uploadState = ref.watch(uploadNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Document Information',
          ),
        ],
      ),
      body: uploadState.uploadedFiles.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.folder_outlined,
              title: 'No Documents',
              message: 'Upload your documents to keep them safe and accessible.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              itemCount: uploadState.uploadedFiles.length,
              itemBuilder: (context, index) {
                final document = uploadState.uploadedFiles[index];
                return AnimatedCard(
                  margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        _getDocumentIcon(document.mimeType),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      document.filename ?? 'Document ${index + 1}',
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (document.size != null)
                          Text(_formatFileSize(document.size!)),
                        if (document.mimeType != null)
                          Text(
                            document.mimeType!,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'view') {
                          // TODO: View document
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('View document')),
                          );
                        } else if (value == 'download') {
                          // TODO: Download document
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Download document')),
                          );
                        } else if (value == 'delete') {
                          _showDeleteDialog(context, ref, index);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined),
                              SizedBox(width: 8),
                              Text('View'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(Icons.download_outlined),
                              SizedBox(width: 8),
                              Text('Download'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/documents/upload'),
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload Document'),
      ),
    );
  }

  IconData _getDocumentIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file_outlined;

    if (mimeType.contains('pdf')) {
      return Icons.picture_as_pdf_outlined;
    } else if (mimeType.contains('image')) {
      return Icons.image_outlined;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description_outlined;
    } else if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Icons.table_chart_outlined;
    } else {
      return Icons.insert_drive_file_outlined;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Types'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You can upload the following documents:'),
            SizedBox(height: 12),
            Text('• Driving License'),
            Text('• National ID'),
            Text('• Passport Photo'),
            Text('• Insurance Documents'),
            Text('• Bike Registration'),
            Text('• Other relevant documents'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
