import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/place_type.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:pbak/theme/app_theme.dart';

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

  String get latLongString => "$latitude,$longitude";

  @override
  String toString() {
    return 'LocationData(address: $address, lat: $latitude, lng: $longitude, estate: $estateName)';
  }
}

/// A modern, improved location picker widget using Google Places API
/// 
/// Features:
/// - Clean, professional UI
/// - Real-time search with debouncing
/// - Selected location preview card
/// - Error handling and validation
/// - Responsive design
class GooglePlacesLocationPicker extends StatefulWidget {
  final String apiKey;
  final Function(LocationData) onLocationSelected;
  final String? initialValue;
  final String hintText;
  final InputDecoration? decoration;
  final Color? primaryColor;

  const GooglePlacesLocationPicker({
    super.key,
    required this.apiKey,
    required this.onLocationSelected,
    this.initialValue,
    this.hintText = 'Search for your location...',
    this.decoration,
    this.primaryColor,
  });

  @override
  State<GooglePlacesLocationPicker> createState() =>
      _GooglePlacesLocationPickerState();
}

class _GooglePlacesLocationPickerState
    extends State<GooglePlacesLocationPicker> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  LocationData? _selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Extract estate/neighborhood name from address components
  String? _extractEstateName(String fullAddress) {
    // Try to extract neighborhood or estate from address
    final parts = fullAddress.split(',');
    if (parts.length > 1) {
      // Usually the first part is the most specific (street/estate)
      return parts[0].trim();
    }
    return null;
  }

  /// Build custom decoration with improved styling
  InputDecoration _buildDecoration() {
    if (widget.decoration != null) {
      return widget.decoration!;
    }

    final primaryColor = widget.primaryColor ?? AppTheme.brightRed;
    final theme = Theme.of(context);

    return InputDecoration(
      hintText: widget.hintText,
      hintStyle: TextStyle(
        color: AppTheme.mediumGrey,
        fontSize: 15,
      ),
      prefixIcon: Icon(
        Icons.search_rounded,
        color: _selectedLocation != null ? primaryColor : AppTheme.mediumGrey,
        size: 22,
      ),
      suffixIcon: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            )
          : _selectedLocation != null
              ? Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successGreen,
                  size: 22,
                )
              : null,
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor ?? AppTheme.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        borderSide: BorderSide(color: AppTheme.silverGrey, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        borderSide: BorderSide(color: AppTheme.silverGrey, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        borderSide: const BorderSide(color: AppTheme.brightRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        borderSide: const BorderSide(color: AppTheme.brightRed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field with autocomplete
        GooglePlaceAutoCompleteTextField(
          textEditingController: _controller,
          googleAPIKey: widget.apiKey,
          inputDecoration: _buildDecoration(),
          debounceTime: 600, // Faster response
          countries: const ["ke"], // Kenya - change as needed
          isLatLngRequired: true,
          getPlaceDetailWithLatLng: (Prediction prediction) async {
            setState(() {
              _isLoading = true;
            });

            // Extract location data from prediction
            final lat = double.tryParse(prediction.lat ?? '0') ?? 0;
            final lng = double.tryParse(prediction.lng ?? '0') ?? 0;
            final address = prediction.description ?? '';
            final estateName = _extractEstateName(address);

            _selectedLocation = LocationData(
              address: address,
              latitude: lat,
              longitude: lng,
              estateName: estateName,
            );

            setState(() {
              _isLoading = false;
            });

            // Notify parent
            widget.onLocationSelected(_selectedLocation!);
          },
          itemClick: (Prediction prediction) {
            _controller.text = prediction.description ?? '';
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          },
          seperatedBuilder: Divider(
            height: 1,
            thickness: 0.5,
            color: AppTheme.silverGrey,
          ),
          containerHorizontalPadding: 0,
          itemBuilder: (context, index, Prediction prediction) {
            return _buildPredictionItem(prediction);
          },
          isCrossBtnShown: true,
          placeType: PlaceType.address,
        ),
        
        // Selected location preview
        if (_selectedLocation != null) ...[
          const SizedBox(height: 16),
          
          // Error state: coordinates not found
          if (_selectedLocation!.latitude == 0 && _selectedLocation!.longitude == 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: AppTheme.warningOrange.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.warningOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location Coordinates Not Available',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedLocation!.address,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          else
            _buildLocationInfo(),
        ],
      ],
    );
  }

  /// Build prediction item with improved styling
  Widget _buildPredictionItem(Prediction prediction) {
    final mainText = prediction.structuredFormatting?.mainText ?? '';
    final secondaryText = prediction.structuredFormatting?.secondaryText ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.silverGrey.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.brightRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: AppTheme.brightRed,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mainText.isNotEmpty ? mainText : prediction.description ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (secondaryText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    secondaryText,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.mediumGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.north_west_rounded,
            color: AppTheme.mediumGrey,
            size: 16,
          ),
        ],
      ),
    );
  }

  /// Build selected location info card with improved design
  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.successGreen.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppTheme.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Location Selected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Address
          _buildInfoRow(
            icon: Icons.location_on_rounded,
            label: 'Address',
            value: _selectedLocation!.address,
          ),
          
          // Estate/Area
          if (_selectedLocation!.estateName != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.business_rounded,
              label: 'Area/Estate',
              value: _selectedLocation!.estateName!,
            ),
          ],
          
          // Coordinates
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.my_location_rounded,
            label: 'Coordinates',
            value: _selectedLocation!.latLongString,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.mediumGrey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.mediumGrey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.darkGrey,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
