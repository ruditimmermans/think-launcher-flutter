import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:think_launcher/models/weather_info.dart';

/// Weather service fetches weather data from the OpenWeatherMap API
class WeatherService {
  final String apiKey;
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Cache variables
  WeatherInfo? _cachedWeather;
  DateTime? _lastFetchTime;
  final Duration cacheDuration = const Duration(seconds: 120);

  WeatherService({required this.apiKey});

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<WeatherInfo> getCurrentWeather() async {
    try {
      // Check cache first
      if (_cachedWeather != null && _lastFetchTime != null) {
        final timeSinceFetch = DateTime.now().difference(_lastFetchTime!);
        if (timeSinceFetch < cacheDuration) return _cachedWeather!;
      }

      // Fetch fresh data
      final position = await _getCurrentLocation();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric',
        ),
      );

      if (response.statusCode == 200) {
        final weather = WeatherInfo.fromJson(jsonDecode(response.body));
        _cachedWeather = weather;
        _lastFetchTime = DateTime.now();
        return weather;
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error getting weather: $e');
    }
  }
}
