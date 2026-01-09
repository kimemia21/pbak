import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Cross-platform image widget.
///
/// - Mobile/desktop: uses [Image.file]
/// - Web: reads bytes from the provided [XFile] and uses [Image.memory]
///
/// NOTE: On web, `dart:io` File APIs are not supported. Prefer passing [xFile]
/// if the image came from `image_picker`.
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
    if (kIsWeb) {
      final xf = xFile;
      if (xf == null) {
        // Fallback: if a File was passed on web, we can't read it.
        return const Center(
          child: Text('Image preview not available on web.'),
        );
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

    // Non-web
    return Image.file(
      file!,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
    );
  }
}
