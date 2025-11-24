import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';

class WeatherService {
  // OpenWeatherMap API key - Replace with your actual API key
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  late WeatherFactory _weatherFactory;

  WeatherService() {
    _weatherFactory = WeatherFactory(_apiKey);
  }

  Future<Weather?> getCurrentWeather() async {
    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Fetch weather data
      Weather weather = await _weatherFactory.currentWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      return weather;
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  Future<Weather?> getWeatherByCity(String cityName) async {
    try {
      Weather weather = await _weatherFactory.currentWeatherByCityName(cityName);
      return weather;
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  String getRidingCondition(Weather weather) {
    final temp = weather.temperature?.celsius ?? 0;
    final windSpeed = weather.windSpeed ?? 0;
    final rainAmount = weather.rainLastHour ?? 0;

    if (rainAmount > 5) {
      return 'Poor - Heavy Rain';
    } else if (rainAmount > 0) {
      return 'Fair - Light Rain';
    } else if (windSpeed > 40) {
      return 'Caution - High Winds';
    } else if (temp < 5) {
      return 'Cold - Ride Carefully';
    } else if (temp > 35) {
      return 'Hot - Stay Hydrated';
    } else if (temp >= 15 && temp <= 25 && windSpeed < 20) {
      return 'Perfect Riding Weather';
    } else {
      return 'Good Riding Conditions';
    }
  }

  String getRidingAdvice(Weather weather) {
    final temp = weather.temperature?.celsius ?? 0;
    final windSpeed = weather.windSpeed ?? 0;
    final rainAmount = weather.rainLastHour ?? 0;

    if (rainAmount > 5) {
      return 'Heavy rain detected. Consider postponing your ride or use rain gear.';
    } else if (rainAmount > 0) {
      return 'Light rain. Reduce speed and increase following distance.';
    } else if (windSpeed > 40) {
      return 'Strong winds. Expect buffeting and reduced stability.';
    } else if (temp < 5) {
      return 'Cold weather. Wear warm layers and watch for ice.';
    } else if (temp > 35) {
      return 'Hot weather. Take breaks and stay hydrated.';
    } else {
      return 'Great conditions! Enjoy your ride safely.';
    }
  }

  // Mock weather data for testing when API key is not available
  Weather getMockWeather() {
    return Weather({
      'coord': {'lon': -0.1257, 'lat': 51.5085},
      'weather': [
        {'id': 800, 'main': 'Clear', 'description': 'clear sky', 'icon': '01d'}
      ],
      'base': 'stations',
      'main': {
        'temp': 20.0,
        'feels_like': 19.5,
        'temp_min': 18.0,
        'temp_max': 22.0,
        'pressure': 1013,
        'humidity': 65
      },
      'visibility': 10000,
      'wind': {'speed': 15.0, 'deg': 180},
      'clouds': {'all': 0},
      'dt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'sys': {
        'type': 1,
        'id': 1414,
        'country': 'GB',
        'sunrise': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'sunset': DateTime.now().millisecondsSinceEpoch ~/ 1000
      },
      'timezone': 0,
      'id': 2643743,
      'name': 'London',
      'cod': 200
    });
  }
}
