import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/package_model.dart';
import 'package:pbak/services/package_service.dart';

// Service provider
final packageServiceProvider = Provider((ref) => PackageService());

// Packages provider
final packagesProvider = FutureProvider<List<PackageModel>>((ref) async {
  final packageService = ref.read(packageServiceProvider);
  return await packageService.getAllPackages();
});

// Package detail provider
final packageDetailProvider = FutureProvider.family<PackageModel?, int>((ref, packageId) async {
  final packageService = ref.read(packageServiceProvider);
  return await packageService.getPackageById(packageId);
});
