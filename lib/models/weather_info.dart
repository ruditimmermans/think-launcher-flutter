class WeatherInfo {
  final String description;
  final String iconCode;
  final double temperature;
  final int humidity;
  final double windSpeed;

  WeatherInfo({
    required this.description,
    required this.iconCode,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];
    final wind = json['wind'];

    return WeatherInfo(
      description: weather['description'],
      iconCode: weather['icon'],
      temperature: (main['temp'] as num).toDouble(),
      humidity: main['humidity'] as int,
      windSpeed: (wind['speed'] as num).toDouble(),
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
}
