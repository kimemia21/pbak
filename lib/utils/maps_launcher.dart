import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

class MapsLauncher {
  static Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final destination = '$latitude,$longitude';

    // Open actual navigation directions.
    final Uri uri = Platform.isIOS
        ? Uri.parse('http://maps.apple.com/?daddr=$destination')
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
          );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openSearch({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final query = '$latitude,$longitude';
    final Uri uri = Platform.isIOS
        ? Uri.parse(
            'http://maps.apple.com/?q=${Uri.encodeComponent(label ?? query)}&ll=$query',
          )
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
