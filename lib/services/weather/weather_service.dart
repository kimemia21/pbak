import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weather/weather.dart';
import '../../utils/api_keys.dart';

class WeatherService {
  WeatherFactory? _wf;
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  WeatherService() {
    if (ApiKeys.isOpenWeatherConfigured) {
      _wf = WeatherFactory(ApiKeys.openWeatherApiKey, language: Language.ENGLISH);
    }
  }

  /// Returns weather for current device location.
  /// Falls back to Nairobi if location permission denied.
  Future<Weather?> getCurrentWeather() async {
    debugPrint('🌤️ WeatherService: getCurrentWeather called');
    debugPrint('🌤️ WeatherService: API configured: ${ApiKeys.isOpenWeatherConfigured}');
    
    if (!ApiKeys.isOpenWeatherConfigured) {
      debugPrint('⚠️ Weather API not configured');
      return null;
    }

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('🌤️ WeatherService: Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied - using default city');
          return await getWeatherByCity('Nairobi');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission permanently denied - using default city');
        return await getWeatherByCity('Nairobi');
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services disabled - using default city');
        return await getWeatherByCity('Nairobi');
      }

      // Get current position with timeout
      debugPrint('🌤️ WeatherService: Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
      debugPrint('🌤️ WeatherService: Position: ${position.latitude}, ${position.longitude}');

      // Try with weather package first
      if (_wf != null) {
        try {
          final weather = await _wf!.currentWeatherByLocation(
            position.latitude,
            position.longitude,
          );
          debugPrint('✅ Weather fetched: ${weather.weatherMain}, ${weather.temperature?.celsius?.toStringAsFixed(1)}°C');
          return weather;
        } catch (e) {
          debugPrint('⚠️ Weather package failed: $e, trying HTTP fallback...');
        }
      }

      // Fallback: Direct HTTP call
      return await _fetchWeatherByCoordinatesHttp(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('❌ Weather fetch error: $e');
      // Last resort: try default city
      try {
        debugPrint('🌤️ Falling back to default city...');
        return await getWeatherByCity('Nairobi');
      } catch (_) {
        return null;
      }
    }
  }

  /// Returns weather for a specific city.
  Future<Weather?> getWeatherByCity(String cityName) async {
    debugPrint('🌤️ WeatherService: getWeatherByCity called for: $cityName');
    
    if (!ApiKeys.isOpenWeatherConfigured) {
      debugPrint('⚠️ Weather API not configured');
      return null;
    }

    // Try with weather package first
    if (_wf != null) {
      try {
        final weather = await _wf!.currentWeatherByCityName(cityName);
        debugPrint('✅ Weather for $cityName: ${weather.weatherMain}, ${weather.temperature?.celsius?.toStringAsFixed(1)}°C');
        return weather;
      } catch (e) {
        debugPrint('⚠️ Weather package failed for $cityName: $e, trying HTTP fallback...');
      }
    }

    // Fallback: Direct HTTP call
    return await _fetchWeatherByCityHttp(cityName);
  }

  /// Direct HTTP fallback for coordinates
  Future<Weather?> _fetchWeatherByCoordinatesHttp(double lat, double lon) async {
    try {
      final url = '$_baseUrl?lat=$lat&lon=$lon&appid=${ApiKeys.openWeatherApiKey}&units=metric';
      debugPrint('🌤️ HTTP: Fetching weather for $lat, $lon');
      
      final response = await http.get(Uri.parse(url));
      debugPrint('🌤️ HTTP Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ HTTP Weather: ${data['weather']?[0]?['main']}, ${data['main']?['temp']}°C');
        return Weather(data);
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ HTTP fetch error: $e');
      return null;
    }
  }

  /// Direct HTTP fallback for city
  Future<Weather?> _fetchWeatherByCityHttp(String city) async {
    try {
      final encodedCity = Uri.encodeComponent(city);
      final url = '$_baseUrl?q=$encodedCity&appid=${ApiKeys.openWeatherApiKey}&units=metric';
      debugPrint('🌤️ HTTP: Fetching weather for city: $city');
      
      final response = await http.get(Uri.parse(url));
      debugPrint('🌤️ HTTP Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ HTTP Weather for $city: ${data['weather']?[0]?['main']}, ${data['main']?['temp']}°C');
        return Weather(data);
      } else {
        debugPrint('❌ HTTP Error for $city: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ HTTP fetch error for $city: $e');
      return null;
    }
  }

  /// Get riding condition based on weather - returns a String with emoji
  String getRidingCondition(Weather weather) {
    final condition = weather.weatherMain?.toLowerCase() ?? '';
    final temp = weather.temperature?.celsius ?? 25;
    final windSpeed = weather.windSpeed ?? 0;
    
    // Check for dangerous conditions
    if (condition.contains('thunderstorm') || 
        condition.contains('tornado') ||
        condition.contains('hurricane')) {
      return '⛔ Dangerous - Stay indoors';
    }
    
    // Check for poor conditions
    if (condition.contains('rain') ||
        condition.contains('drizzle') ||
        condition.contains('snow') ||
        condition.contains('sleet') ||
        condition.contains('hail')) {
      return '🌧️ Poor - Ride with caution';
    }
    
    if (condition.contains('fog') || condition.contains('mist')) {
      return '🌫️ Low visibility - Be careful';
    }
    
    if (windSpeed > 15) {
      return '💨 Windy - Ride carefully';
    }
    
    // Check for moderate conditions
    if (condition.contains('cloud') || windSpeed > 10) {
      return '☁️ Moderate - Good for riding';
    }
    
    if (temp < 10) {
      return '🥶 Cold - Dress warmly';
    }
    
    if (temp > 35) {
      return '🥵 Hot - Stay hydrated';
    }
    
    // Good/Excellent conditions
    if (condition.contains('clear') || condition.contains('sun')) {
      return '🏍️ Excellent - Perfect riding weather!';
    }
    
    return '👍 Good - Enjoy your ride!';
  }
}
