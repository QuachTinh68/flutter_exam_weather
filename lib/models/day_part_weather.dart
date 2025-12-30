class DayPartWeather {
  final String label;
  final int weatherCode;
  final double tempAvg;
  final double? precipProbAvg;
  final double? precipitationAvg;

  const DayPartWeather({
    required this.label,
    required this.weatherCode,
    required this.tempAvg,
    required this.precipProbAvg,
    required this.precipitationAvg,
  });
}
