import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/services/weather/weather_service.dart';
import 'package:weather/weather.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final currentWeatherProvider = FutureProvider<Weather?>((ref) async {
  final weatherService = ref.watch(weatherServiceProvider);
  // Live mode: only real weather. If unavailable, return null.
  return weatherService.getCurrentWeather();
});

/// Fetch current weather by a known city/region name.
/// Falls back to mock data if the API key is not configured.
final weatherByCityProvider = FutureProvider.family<Weather?, String>((
  ref,
  cityName,
) async {
  final weatherService = ref.watch(weatherServiceProvider);
  try {
    return weatherService.getWeatherByCity(cityName);
  } catch (_) {
    return null;
  }
});
