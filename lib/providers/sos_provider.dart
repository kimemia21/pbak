import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/sos_model.dart';
import 'package:pbak/services/sos_service.dart';

// Service provider
final sosServiceProvider = Provider((ref) => SOSService());

// All SOS alerts provider
final sosAlertsProvider = FutureProvider<List<SOSModel>>((ref) async {
  final service = ref.read(sosServiceProvider);
  return await service.getMySOS();
});

// SOS by ID provider
final sosByIdProvider = FutureProvider.family<SOSModel?, int>((ref, sosId) async {
  final service = ref.read(sosServiceProvider);
  return await service.getSOSById(sosId);
});

// Service providers provider
final serviceProvidersProvider = FutureProvider.family<List<ServiceProvider>, LocationParams>(
  (ref, params) async {
    final service = ref.read(sosServiceProvider);
    return await service.getNearestProviders(
      latitude: params.latitude,
      longitude: params.longitude,
      serviceType: params.serviceType,
    );
  },
);

// SOS state notifier for managing SOS operations
class SOSNotifier extends StateNotifier<AsyncValue<List<SOSModel>>> {
  final SOSService _sosService;

  SOSNotifier(this._sosService) : super(const AsyncValue.loading()) {
    loadSOSAlerts();
  }

  Future<void> loadSOSAlerts() async {
    state = const AsyncValue.loading();
    try {
      final alerts = await _sosService.getMySOS();
      state = AsyncValue.data(alerts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<SOSModel?> sendSOS({
    required double latitude,
    required double longitude,
    required String type,
    String? description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final sos = await _sosService.sendSOS(
        latitude: latitude,
        longitude: longitude,
        type: type,
        description: description,
        additionalData: additionalData,
      );

      if (sos != null) {
        // Reload alerts after sending
        await loadSOSAlerts();
      }

      return sos;
    } catch (e) {
      return null;
    }
  }

  Future<bool> cancelSOS(int sosId) async {
    try {
      final success = await _sosService.cancelSOS(sosId);
      
      if (success) {
        // Reload alerts after canceling
        await loadSOSAlerts();
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  void refresh() {
    loadSOSAlerts();
  }
}

// SOS state provider
final sosNotifierProvider = StateNotifierProvider<SOSNotifier, AsyncValue<List<SOSModel>>>((ref) {
  return SOSNotifier(ref.read(sosServiceProvider));
});

// Location params for service providers
class LocationParams {
  final double latitude;
  final double longitude;
  final String? serviceType;

  LocationParams({
    required this.latitude,
    required this.longitude,
    this.serviceType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationParams &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          serviceType == other.serviceType;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode ^ serviceType.hashCode;
}
