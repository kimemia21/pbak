import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:pbak/theme/app_theme.dart';

/// A modern location picker that doesn't require API keys
/// Uses device GPS and reverse geocoding
class LocationPicker extends StatefulWidget {
  final String title;
  final LatLng? initialLocation;
  final Function(String address, double lat, double lng) onLocationSelected;

  const LocationPicker({
    super.key,
    required this.title,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = 'Selecting location...';
  bool _isLoading = false;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _getAddressFromLatLng(widget.initialLocation!);
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showError('Location services are disabled');
        }
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showError('Location permission denied');
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showError('Location permissions are permanently denied');
        }
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = location;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 16),
      );

      await _getAddressFromLatLng(location);
    } catch (e) {
      if (mounted) {
        _showError('Failed to get current location: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    setState(() => _isLoadingAddress = true);
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((part) => part != null && part.isNotEmpty).toList();

        setState(() {
          _selectedAddress = addressParts.join(', ');
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Unable to get address';
      });
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromLatLng(location);
  }

  void _onConfirm() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(
        _selectedAddress,
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppTheme.brightRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppTheme.paddingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightSilver,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingL),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: AppTheme.primaryBlack,
                ),
                const SizedBox(width: AppTheme.paddingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                      Text(
                        'Tap on map to select location',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: AppTheme.deepRed,
                            ),
                            const SizedBox(height: AppTheme.paddingM),
                            Text(
                              'Getting your location...',
                              style: GoogleFonts.poppins(
                                color: AppTheme.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GoogleMap(
                        onMapCreated: (controller) {
                          _mapController = controller;
                          if (_selectedLocation != null) {
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(_selectedLocation!, 16),
                            );
                          }
                        },
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation ?? const LatLng(-1.286389, 36.817223),
                          zoom: 16,
                        ),
                        onTap: _onMapTap,
                        markers: _selectedLocation != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('selected'),
                                  position: _selectedLocation!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                                ),
                              }
                            : {},
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                      ),

                // Center marker indicator
                if (!_isLoading)
                  const Center(
                    child: Icon(
                      Icons.add,
                      size: 32,
                      color: AppTheme.deepRed,
                    ),
                  ),

                // My Location button
                Positioned(
                  bottom: 180,
                  right: AppTheme.paddingL,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.my_location),
                      color: AppTheme.deepRed,
                      onPressed: _getCurrentLocation,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Address Display & Confirm Button
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingL),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Address display
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingM),
                    decoration: BoxDecoration(
                      color: AppTheme.lightSilver.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppTheme.deepRed,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.paddingM),
                        Expanded(
                          child: _isLoadingAddress
                              ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.deepRed,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.paddingM),
                                    Text(
                                      'Getting address...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppTheme.mediumGrey,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _selectedAddress,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryBlack,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingM),

                  // Confirm button
                  ElevatedButton(
                    onPressed: _selectedLocation != null && !_isLoadingAddress
                        ? _onConfirm
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepRed,
                      disabledBackgroundColor: AppTheme.mediumGrey,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.paddingM + 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Location',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
