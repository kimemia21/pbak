import 'package:flutter/material.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';
import 'package:pbak/widgets/why_we_collect_info_dialog.dart';

/// Shows an informational dialog once per install (first launch only).
class FirstOpenInfoDialogGate extends StatefulWidget {
  final Widget child;

  const FirstOpenInfoDialogGate({super.key, required this.child});

  @override
  State<FirstOpenInfoDialogGate> createState() => _FirstOpenInfoDialogGateState();
}

class _FirstOpenInfoDialogGateState extends State<FirstOpenInfoDialogGate> {
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final storage = await LocalStorageService.getInstance();
      if (!mounted) return;

      // Dedicated flag for this dialog (does not affect onboarding).
      if (!storage.shouldShowFirstOpenInfo()) return;

      await showWhyWeCollectInfoDialog(context);

      // Mark handled whether user dismissed via button or outside.
      await storage.markFirstOpenInfoShown();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
