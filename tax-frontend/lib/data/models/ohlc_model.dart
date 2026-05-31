class OhlcModel {
  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;

  OhlcModel({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  bool get isBullish => close >= open;

  factory OhlcModel.fromJson(Map<String, dynamic> json) => OhlcModel(
        timestamp: (json['timestamp'] as num).toInt(),
        open: (json['open'] as num).toDouble(),
        high: (json['high'] as num).toDouble(),
        low: (json['low'] as num).toDouble(),
        close: (json['close'] as num).toDouble(),
      );
}
