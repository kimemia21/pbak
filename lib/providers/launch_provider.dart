import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/services/launch_service.dart';

/// Launch service provider (singleton)
final launchServiceProvider = Provider((ref) => LaunchService());

/// Launch config provider - fetches config from server
final launchConfigProvider = FutureProvider<LaunchConfig>((ref) async {
  final launchService = ref.read(launchServiceProvider);
  return await launchService.fetchLaunchConfig();
});

/// Quick access to whether discount is allowed
/// Returns false while loading or on error
final allowDiscountProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(launchConfigProvider);
  return configAsync.whenOrNull(
    data: (config) => config.allowDiscount,
  ) ?? false;
});

/// Async version that shows loading state
final allowDiscountAsyncProvider = Provider<AsyncValue<bool>>((ref) {
  final configAsync = ref.watch(launchConfigProvider);
  return configAsync.whenData((config) => config.allowDiscount);
});
