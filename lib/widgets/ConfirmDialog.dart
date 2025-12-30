import 'package:flutter/material.dart';

class ConfirmDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) {
    final theme = Theme.of(context);
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          title,
          style: theme.textTheme.headlineSmall,
        ),
        content: Text(
          message,
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: isDangerous 
                ? theme.colorScheme.error 
                : theme.colorScheme.primary,
              foregroundColor: isDangerous
                ? Colors.white
                : theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              confirmText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDangerous 
                  ? Colors.white 
                  : theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// USAGE EXAMPLE:

// Simple usage
void _handleExit(BuildContext context) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: 'Exit Form?',
    message: 'Do you want to save your progress before exiting?',
    confirmText: 'Save & Exit',
    cancelText: 'Cancel',
  );
  
  if (confirmed == true) {
    // Save form data here
    // Navigator.pop(context);
  }
}

// Dangerous action (no save, just exit)
void _handleDiscardExit(BuildContext context) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: 'Discard Changes?',
    message: 'Your progress will be lost if you exit without saving.',
    confirmText: 'Discard',
    cancelText: 'Cancel',
    isDangerous: true,
  );
  
  if (confirmed == true) {
    // Navigator.pop(context);
  }
}

// On WillPopScope (for back button)
class FormPage extends StatelessWidget {
  const FormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final confirmed = await ConfirmDialog.show(
          context: context,
          title: 'Exit Form?',
          message: 'Do you want to save your progress?',
          confirmText: 'Save & Exit',
          cancelText: 'Stay',
        );
        
        if (confirmed == true && context.mounted) {
          // Save data here
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Form')),
        body: const Center(child: Text('Your form here')),
      ),
    );
  }
}