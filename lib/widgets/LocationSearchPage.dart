import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:pbak/services/location/places_proxy_service.dart';
import 'package:pbak/utils/api_keys.dart';

/// Model to hold selected location data
class LocationData {
  final String address;
  final double latitude;
  final double longitude;
  final String? estateName;
  final String? city;
  final String? country;

  LocationData({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.estateName,
    this.city,
    this.country,
  });

  String get latLongString => '$latitude,$longitude';

  @override
  String toString() {
    return 'LocationData(address: $address, lat: $latitude, lng: $longitude, estate: $estateName)';
  }
}

/// A modern location picker widget using Google Places API.
///
/// Styling is derived from the active app [Theme] (colorScheme/textTheme/etc.).
class LocationSearchPage extends StatefulWidget {
  final String apiKey;
  final String title;
  final String subtitle;

  /// Optional override for the page accent color.
  ///
  /// If null, the theme's [ColorScheme.primary] is used.
  final Color? accentColor;

  final String? initialAddress;

  const LocationSearchPage({
    super.key,
    required this.apiKey,
    required this.title,
    required this.subtitle,
    this.accentColor,
    this.initialAddress,
  });

  @override
  State<LocationSearchPage> createState() => LocationSearchPageState();
}

class _WebPlaceSuggestion {
  final String description;
  final String placeId;

  const _WebPlaceSuggestion({required this.description, required this.placeId});
}

class LocationSearchPageState extends State<LocationSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  LocationData? _selectedLocation;
  bool _isLoading = false;

  // Web-only state for proxy-based autocomplete
  Timer? _debounce;
  final List<_WebPlaceSuggestion> _webSuggestions = [];
  String? _webError;
  PlacesProxyService? _placesProxy;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _searchController.text = widget.initialAddress!;
    }

    if (kIsWeb && ApiKeys.isGooglePlacesProxyConfigured) {
      _placesProxy = PlacesProxyService(baseUrl: ApiKeys.googlePlacesProxyBaseUrl);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildWebSearch(
    ThemeData theme,
    Color accent,
    Color effectiveFillColor,
    OutlineInputBorder Function(Color color, {double width}) border,
  ) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    if (!ApiKeys.isGooglePlacesProxyConfigured) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Location search on web requires a backend proxy (CORS).\n'
          'Set GOOGLE_PLACES_PROXY_BASE_URL to your places endpoint, e.g. http://167.99.202.246:5020/api/v1/places',
          style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
        ),
      );
    }

    Future<void> runAutocomplete(String query) async {
      final q = query.trim();
      if (q.isEmpty) {
        setState(() {
          _webSuggestions.clear();
          _webError = null;
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _webError = null;
      });

      try {
        final proxy = _placesProxy;
        if (proxy == null) {
          throw Exception('Places proxy not configured');
        }

        final json = await proxy.autocomplete(
          input: q,
          language: 'en',
          components: 'country:ke',
        );

        final preds = (json['predictions'] as List?) ?? const [];
        final next = preds
            .map((e) => _WebPlaceSuggestion(
                  description: (e['description'] ?? '').toString(),
                  placeId: (e['place_id'] ?? '').toString(),
                ))
            .where((e) => e.description.isNotEmpty && e.placeId.isNotEmpty)
            .toList(growable: false);

        if (!mounted) return;
        setState(() {
          _webSuggestions
            ..clear()
            ..addAll(next);
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _webError = e.toString();
          _webSuggestions.clear();
        });
      } finally {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    }

    Future<void> selectSuggestion(_WebPlaceSuggestion s) async {
      setState(() {
        _isLoading = true;
        _webError = null;
      });

      try {
        final proxy = _placesProxy;
        if (proxy == null) {
          throw Exception('Places proxy not configured');
        }

        // Backend endpoint only returns predictions.
        // Without a /details endpoint we can't resolve lat/lng on web yet.
        final address = s.description;
        final estateName = address.split(',').first.trim();

        _selectedLocation = LocationData(
          address: address,
          latitude: 0,
          longitude: 0,
          estateName: estateName,
        );

        _searchController.text = address;
        if (!mounted) return;
        setState(() {
          _webSuggestions.clear();
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _webError = e.toString();
        });
      } finally {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for a location',
            prefixIcon: Icon(Icons.search_rounded, color: accent),
            suffixIcon: _isLoading
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  )
                : _selectedLocation != null
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: cs.tertiary,
                        size: 22,
                      )
                    : null,
            filled: true,
            fillColor: effectiveFillColor,
            border: border(cs.outlineVariant),
            enabledBorder: border(cs.outlineVariant),
            focusedBorder: border(accent, width: 2),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (value) {
            _debounce?.cancel();
            _debounce = Timer(
              const Duration(milliseconds: 450),
              () => runAutocomplete(value),
            );
          },
        ),
        if (_webError != null) ...[
          const SizedBox(height: 8),
          Text(
            _webError!,
            style: tt.bodySmall?.copyWith(color: cs.error),
          ),
        ],
        if (_webSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _webSuggestions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 0.5,
                color: cs.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final s = _webSuggestions[index];
                return ListTile(
                  leading: Icon(Icons.location_on_rounded, color: accent),
                  title: Text(
                    s.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => selectSuggestion(s),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) { 
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final accent = widget.accentColor ?? cs.primary;

    final effectiveFillColor = theme.inputDecorationTheme.fillColor ?? cs.surface;

    OutlineInputBorder _border(Color color, {double width = 1}) {
      final radius = (theme.inputDecorationTheme.border is OutlineInputBorder)
          ? ((theme.inputDecorationTheme.border! as OutlineInputBorder)
                  .borderRadius)
          : const BorderRadius.all(Radius.circular(12));

      return OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subtitle,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (kIsWeb)
                        _buildWebSearch(theme, accent, effectiveFillColor, _border)
                      else
                        GooglePlaceAutoCompleteTextField(
                          textEditingController: _searchController,
                          googleAPIKey: widget.apiKey,
                          debounceTime: 600,
                          countries: const ['ke'],
                          isLatLngRequired: true,
                        inputDecoration: InputDecoration(
                          hintText: 'Search for a location',
                          prefixIcon: Icon(Icons.search_rounded, color: accent),
                          suffixIcon: _isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        accent,
                                      ),
                                    ),
                                  ),
                                )
                              : _selectedLocation != null
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: cs.tertiary,
                                      size: 22,
                                    )
                                  : null,
                          filled: true,
                          fillColor: effectiveFillColor,
                          border: _border(cs.outlineVariant),
                          enabledBorder: _border(cs.outlineVariant),
                          focusedBorder: _border(accent, width: 2),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        getPlaceDetailWithLatLng: (Prediction prediction) async {
                          setState(() => _isLoading = true);

                          final lat = double.tryParse(prediction.lat ?? '') ?? 0;
                          final lng = double.tryParse(prediction.lng ?? '') ?? 0;
                          final address = prediction.description ?? '';
                          final estateName = address.split(',').first.trim();

                          _selectedLocation = LocationData(
                            address: address,
                            latitude: lat,
                            longitude: lng,
                            estateName: estateName,
                          );

                          setState(() => _isLoading = false);
                        },
                        itemClick: (Prediction prediction) {
                          _searchController.text = prediction.description ?? '';
                          _searchController.selection =
                              TextSelection.fromPosition(
                            TextPosition(offset: _searchController.text.length),
                          );
                        },
                        seperatedBuilder:
                            Divider(height: 1, thickness: 0.5, color: cs.outlineVariant),
                        containerHorizontalPadding: 0,
                        itemBuilder: (context, index, Prediction prediction) {
                          final mainText =
                              prediction.structuredFormatting?.mainText ??
                                  (prediction.description ?? '');
                          final secondaryText =
                              prediction.structuredFormatting?.secondaryText ??
                                  '';

                          return Material(
                            color: cs.surface,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                tileColor: cs.surface,
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color.alphaBlend(
                                      accent.withOpacity(0.12),
                                      cs.surface,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: accent,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  mainText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: secondaryText.isEmpty
                                    ? null
                                    : Text(
                                        secondaryText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: tt.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                        isCrossBtnShown: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_selectedLocation != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Card(
                  color: cs.secondaryContainer,
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.check_rounded, color: cs.onSecondary),
                    ),
                    title: Text(
                      'Location selected',
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      _selectedLocation!.address,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ),

            const Spacer(),

            if (_selectedLocation != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: cs.onPrimary,
                      ),
                      onPressed: () => Navigator.pop(context, _selectedLocation),
                      child: Text(
                        'Confirm location',
                        style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
