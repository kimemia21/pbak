import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/trip_provider.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/widgets/trip_stats_widget.dart';
import 'package:pbak/widgets/location_picker.dart';
import 'package:pbak/widgets/location_selector_card.dart';

class StartTripScreen extends ConsumerStatefulWidget {
  const StartTripScreen({super.key});

  @override
  ConsumerState<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends ConsumerState<StartTripScreen> 
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  
  late AnimationController _fabAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _statsSlideAnimation;
  
  bool _showingSetup = true;
  String? _selectedBikeId;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _statsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    
    _statsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _requestInitialLocation();
  }
  
  Future<void> _requestInitialLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    _fabAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setMapStyle();
  }
  
  Future<void> _setMapStyle() async {
    // Custom map style for premium look
    const mapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [{"color": "#212121"}]
      },
      {
        "elementType": "labels.icon",
        "stylers": [{"visibility": "off"}]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#757575"}]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#212121"}]
      }
    ]
    ''';
    
    try {
      await _mapController?.setMapStyle(mapStyle);
    } catch (e) {
      // Use default style if custom fails
    }
  }
  
  void _updateMapWithRoute(List<LatLng> points) {
    if (points.isEmpty) return;
    
    setState(() {
      // Create polyline for route
      _polylines = {
        Polyline(
          polylineId: const PolylineId('trip_route'),
          points: points,
          color: AppTheme.deepRed,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      };
      
      // Add markers
      _markers = {};
      
      if (points.isNotEmpty) {
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: points.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Start'),
          ),
        );
        
        if (points.length > 1) {
          _markers.add(
            Marker(
              markerId: const MarkerId('current'),
              position: points.last,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: const InfoWindow(title: 'Current Location'),
            ),
          );
        }
      }
    });
    
    // Adjust camera to fit route
    if (points.length > 1 && _mapController != null) {
      _fitRouteBounds(points);
    }
  }
  
  void _fitRouteBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100, // padding
      ),
    );
  }
  
  Future<void> _startTrip() async {
    final tripNotifier = ref.read(activeTripProvider.notifier);
    
    // Validate inputs
    final state = ref.read(activeTripProvider);
    if (state.startLocation == null || state.startLocation!.isEmpty) {
      _showError('Please select a start location');
      return;
    }
    
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    
    final success = await tripNotifier.startTrip();
    
    if (success) {
      setState(() {
        _showingSetup = false;
      });
      _statsAnimationController.forward();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Trip started! Stay safe on the road.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.deepRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      _showError('Failed to start trip. Please check location permissions.');
    }
  }
  
  Future<void> _stopTrip() async {
    final confirmed = await _showStopConfirmationDialog();
    if (!confirmed) return;
    
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    
    final tripNotifier = ref.read(activeTripProvider.notifier);
    final tripData = await tripNotifier.stopTrip();
    
    if (mounted) {
      _statsAnimationController.reverse();
      
      // Show trip summary
      await _showTripSummaryDialog(tripData);
      
      // Reset and go back to setup
      setState(() {
        _showingSetup = true;
        _polylines.clear();
        _markers.clear();
      });
      
      tripNotifier.reset();
    }
  }
  
  Future<bool> _showStopConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Text(
          'End Trip?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to end this trip? Your trip data will be saved.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppTheme.mediumGrey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
            ),
            child: Text(
              'End Trip',
              style: GoogleFonts.poppins(
                color: AppTheme.white,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
  
  Future<void> _showTripSummaryDialog(Map<String, dynamic> tripData) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.deepRed),
            const SizedBox(width: AppTheme.paddingM),
            Text(
              'Trip Completed!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(
              'Distance',
              '${(tripData['distance'] ?? 0).toStringAsFixed(2)} km',
            ),
            _buildSummaryRow(
              'Duration',
              _formatDuration(tripData['duration'] ?? 0),
            ),
            _buildSummaryRow(
              'Avg Speed',
              '${(tripData['averageSpeed'] ?? 0).toStringAsFixed(1)} km/h',
            ),
            _buildSummaryRow(
              'Max Speed',
              '${(tripData['maxSpeed'] ?? 0).toStringAsFixed(1)} km/h',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.poppins(
                color: AppTheme.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppTheme.mediumGrey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
  
  void _showError(String message) {
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
  Widget build(BuildContext context) {
    final tripState = ref.watch(activeTripProvider);
    final bikesAsync = ref.watch(myBikesProvider);
    
    // Update map when route changes
    if (tripState.isTracking && tripState.stats.routePoints.isNotEmpty) {
      _updateMapWithRoute(tripState.stats.routePoints);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Start Trip',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-1.286389, 36.817223), // Nairobi, Kenya
              zoom: 14,
            ),
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            buildingsEnabled: true,
            trafficEnabled: false,
          ),
          
          // Setup Form (visible before trip starts)
          if (_showingSetup && !tripState.isTracking)
            _buildSetupForm(bikesAsync),
          
          // Stats Panel (visible during trip)
          if (!_showingSetup && tripState.isTracking)
            _buildStatsPanel(tripState),
          
          // Floating Action Button
          Positioned(
            bottom: AppTheme.paddingXL,
            right: AppTheme.paddingL,
            child: _buildActionButton(tripState),
          ),
          
          // My Location Button
          Positioned(
            bottom: tripState.isTracking ? 240 : AppTheme.paddingXL,
            right: AppTheme.paddingL,
            child: _buildMyLocationButton(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSetupForm(AsyncValue bikesAsync) {
    final tripState = ref.watch(activeTripProvider);
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showingSetup ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.all(AppTheme.paddingM),
          padding: const EdgeInsets.all(AppTheme.paddingL),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingS),
                    decoration: BoxDecoration(
                      color: AppTheme.deepRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: const Icon(
                      Icons.route,
                      color: AppTheme.deepRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan Your Ride',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlack,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Set your route and bike',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.paddingL),
              
              // Start Location Card
              LocationSelectorCard(
                label: 'START LOCATION',
                value: tripState.startLocation,
                icon: Icons.radio_button_checked,
                iconColor: AppTheme.deepRed,
                isRequired: true,
                onTap: () {
                  _showLocationPicker(
                    context,
                    'Select Start Location',
                    tripState.startLatLng,
                    (address, lat, lng) {
                      ref.read(activeTripProvider.notifier)
                          .setStartLocation(address, lat, lng);
                    },
                  );
                },
              ),
              
              const SizedBox(height: AppTheme.paddingM),
              
              // End Location Card (Optional)
              LocationSelectorCard(
                label: 'END LOCATION (OPTIONAL)',
                value: tripState.endLocation,
                icon: Icons.location_on,
                iconColor: AppTheme.primaryBlack,
                onTap: () {
                  _showLocationPicker(
                    context,
                    'Select End Location',
                    tripState.endLatLng,
                    (address, lat, lng) {
                      ref.read(activeTripProvider.notifier)
                          .setEndLocation(address, lat, lng);
                    },
                  );
                },
              ),
              
              const SizedBox(height: AppTheme.paddingL),
              
              // Bike Selection
              Text(
                'SELECT BIKE',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mediumGrey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppTheme.paddingS),
              bikesAsync.when(
                data: (bikes) {
                  if (bikes.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(AppTheme.paddingM),
                      decoration: BoxDecoration(
                        color: AppTheme.brightRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                          color: AppTheme.brightRed.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.brightRed,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.paddingM),
                          Expanded(
                            child: Text(
                              'No bikes available. Add a bike first.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.brightRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingM,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightSilver.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: AppTheme.lightSilver,
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBikeId ?? bikes.first.id,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlack),
                        items: bikes.map<DropdownMenuItem<String>>((bike) {
                          return DropdownMenuItem<String>(
                            value: bike.id,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.motorcycle,
                                  size: 20,
                                  color: AppTheme.deepRed,
                                ),
                                const SizedBox(width: AppTheme.paddingM),
                                Text(
                                  '${bike.make} ${bike.model}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedBikeId = value;
                            });
                            ref.read(activeTripProvider.notifier)
                                .setSelectedBike(value);
                          }
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.deepRed,
                  ),
                ),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showLocationPicker(
    BuildContext context,
    String title,
    LatLng? initialLocation,
    Function(String, double, double) onLocationSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPicker(
        title: title,
        initialLocation: initialLocation,
        onLocationSelected: onLocationSelected,
      ),
    );
  }
  
  Widget _buildStatsPanel(ActiveTripState tripState) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _statsSlideAnimation,
        child: Container(
          margin: const EdgeInsets.all(AppTheme.paddingM),
          child: TripStatsWidget(
            distance: tripState.stats.distance,
            currentSpeed: tripState.stats.currentSpeed,
            averageSpeed: tripState.stats.averageSpeed,
            maxSpeed: tripState.stats.maxSpeed,
            duration: _formatDuration(tripState.stats.duration.inMinutes),
            isTracking: tripState.isTracking,
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton(ActiveTripState tripState) {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: tripState.isTracking ? _stopTrip : _startTrip,
        backgroundColor: tripState.isTracking 
            ? AppTheme.brightRed 
            : AppTheme.deepRed,
        elevation: 8,
        icon: Icon(
          tripState.isTracking ? Icons.stop : Icons.play_arrow,
          color: AppTheme.white,
        ),
        label: Text(
          tripState.isTracking ? 'Stop Trip' : 'Start Trip',
          style: GoogleFonts.poppins(
            color: AppTheme.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
  
  Widget _buildMyLocationButton() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.my_location),
        color: AppTheme.primaryBlack,
        onPressed: () async {
          try {
            final position = await Geolocator.getCurrentPosition();
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(position.latitude, position.longitude),
                16,
              ),
            );
          } catch (e) {
            _showError('Could not get current location');
          }
        },
      ),
    );
  }
}
