import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/services/weather/weather_service.dart';
import 'package:weather/weather.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final currentWeatherProvider = FutureProvider<Weather?>((ref) async {
  final weatherService = ref.watch(weatherServiceProvider);
  try {
    // Try to get real weather, fall back to mock data
    return await weatherService.getCurrentWeather();
  } catch (e) {
    // Return mock weather for testing
    return weatherService.getMockWeather();
  }
});
