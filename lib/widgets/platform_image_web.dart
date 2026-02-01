import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// PlatformImage implementation for Flutter Web.
class PlatformImage extends StatelessWidget {
  final XFile? xFile;
  // `file` is intentionally not supported on web.
  final Object? file;
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
  }) : assert(xFile != null, 'On web, provide xFile to PlatformImage');

  @override
  Widget build(BuildContext context) {
    final xf = xFile;
    if (xf == null) {
      return const Center(child: Text('Image preview not available.'));
    }

    return FutureBuilder<Uint8List>(
      future: xf.readAsBytes(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (!snap.hasData) {
          return const Center(child: Text('Failed to load image.'));
        }

        return Image.memory(
          snap.data!,
          fit: fit,
          width: width,
          height: height,
          alignment: alignment,
        );
      },
    );
  }
}
