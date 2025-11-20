import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/sos_provider.dart';
import 'package:pbak/services/location/location_service.dart';
import 'package:pbak/widgets/custom_text_field.dart';
import 'package:pbak/widgets/custom_button.dart';

class SendSOSScreen extends ConsumerStatefulWidget {
  const SendSOSScreen({super.key});

  @override
  ConsumerState<SendSOSScreen> createState() => _SendSOSScreenState();
}

class _SendSOSScreenState extends ConsumerState<SendSOSScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationService = LocationService();

  String _selectedType = 'accident';
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  bool _locationFetched = false;

  final List<SOSType> _sosTypes = [
    SOSType('accident', 'Accident', Icons.car_crash_rounded, AppTheme.brightRed),
    SOSType('breakdown', 'Breakdown', Icons.build_circle_rounded, Colors.grey[700]!),
    SOSType('medical', 'Medical', Icons.medical_services_rounded, AppTheme.brightRed),
    SOSType('security', 'Security', Icons.security_rounded, Colors.grey[700]!),
    SOSType('other', 'Other', Icons.crisis_alert_rounded, Colors.grey[700]!),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationFetched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location not available. Please wait or enable location services.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final sos = await ref.read(sosNotifierProvider.notifier).sendSOS(
            latitude: _latitude!,
            longitude: _longitude!,
            type: _selectedType,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );

      setState(() => _isLoading = false);

      if (sos != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS alert sent successfully! Help is on the way.'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send SOS. Please try again.'),
            backgroundColor: AppTheme.brightRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send SOS Alert'),
        backgroundColor: AppTheme.brightRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning Banner
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingL),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.brightRed.withAlpha(100),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.brightRed.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.brightRed,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppTheme.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Alert',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This will notify emergency services and nearby members.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.paddingL),

              // Location Status
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _locationFetched ? Colors.green : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _locationFetched
                            ? Colors.green.withAlpha(25)
                            : Colors.grey.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _locationFetched
                            ? Icons.location_on_rounded
                            : Icons.location_searching_rounded,
                        color: _locationFetched ? Colors.green : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _locationFetched ? 'Location Detected' : 'Detecting Location',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _locationFetched
                                ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                                : 'Please wait...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.paddingL),

              // Emergency Type Selection
              Text(
                'Emergency Type',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.paddingM),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _sosTypes.map((type) {
                  final isSelected = _selectedType == type.value;
                  final isEmergency = type.value == 'accident' || type.value == 'medical';
                  return ChoiceChip(
                    avatar: Icon(
                      type.icon,
                      color: isSelected ? Colors.white : type.color,
                      size: 20,
                    ),
                    label: Text(type.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = type.value);
                      }
                    },
                    selectedColor: isEmergency ? AppTheme.brightRed : Colors.grey[700],
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(
                      color: isSelected
                          ? (isEmergency ? AppTheme.brightRed : Colors.grey[700]!)
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.paddingL),

              // Description
              CustomTextField(
                label: 'Description (Optional)',
                hint: 'Provide additional details about the emergency...',
                controller: _descriptionController,
                maxLines: 4,
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              const SizedBox(height: AppTheme.paddingXL),

              // Submit Button
              CustomButton(
                text: 'Send SOS Alert',
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                icon: Icons.add_alert_rounded,
                backgroundColor: AppTheme.brightRed,
              ),
              const SizedBox(height: AppTheme.paddingM),

              // Cancel Button
              OutlinedButton(
                onPressed: _isLoading ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SOSType {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  SOSType(this.value, this.label, this.icon, this.color);
}
