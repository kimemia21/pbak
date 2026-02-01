import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// PlatformImage implementation for IO platforms (Android/iOS/desktop).
class PlatformImage extends StatelessWidget {
  final File? file;
  final XFile? xFile;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final AlignmentGeometry alignment;

  const PlatformImage({
    super.key,
    this.file,
    this.xFile,
    this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  }) : assert(file != null || xFile != null,
            'Provide either file or xFile to PlatformImage');

  @override
  Widget build(BuildContext context) {
    final resolvedFile = file ?? (xFile != null ? File(xFile!.path) : null);

    if (resolvedFile == null) {
      return const Center(child: Text('No image selected.'));
    }

    return Image.file(
      resolvedFile,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
    );
  }
}
