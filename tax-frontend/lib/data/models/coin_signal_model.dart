class CoinSignalModel {
  final String id;
  final String coinId;
  final double rsi;
  final double macd;
  final double macdSignal;
  final double macdHistogram;
  final double sma7;
  final double sma30;
  final double bollingerUpper;
  final double bollingerMiddle;
  final double bollingerLower;
  final String signal;
  final String strength;
  final double volatilityScore;
  final double momentumScore;
  final String signalExplanation;
  final int riskScore;
  final String computedAt;

  CoinSignalModel({
    required this.id,
    required this.coinId,
    required this.rsi,
    required this.macd,
    required this.macdSignal,
    required this.macdHistogram,
    required this.sma7,
    required this.sma30,
    required this.bollingerUpper,
    required this.bollingerMiddle,
    required this.bollingerLower,
    required this.signal,
    required this.strength,
    required this.volatilityScore,
    required this.momentumScore,
    required this.signalExplanation,
    required this.riskScore,
    required this.computedAt,
  });

  factory CoinSignalModel.fromJson(Map<String, dynamic> json) => CoinSignalModel(
        id: json['id'] as String,
        coinId: json['coinId'] as String,
        rsi: (json['rsi'] as num).toDouble(),
        macd: (json['macd'] as num).toDouble(),
        macdSignal: (json['macdSignal'] as num).toDouble(),
        macdHistogram: (json['macdHistogram'] as num).toDouble(),
        sma7: (json['sma7'] as num).toDouble(),
        sma30: (json['sma30'] as num).toDouble(),
        bollingerUpper: (json['bollingerUpper'] as num).toDouble(),
        bollingerMiddle: (json['bollingerMiddle'] as num).toDouble(),
        bollingerLower: (json['bollingerLower'] as num).toDouble(),
        signal: json['signal'] as String,
        strength: json['strength'] as String,
        volatilityScore: (json['volatilityScore'] as num).toDouble(),
        momentumScore: (json['momentumScore'] as num).toDouble(),
        signalExplanation: json['signalExplanation'] as String,
        riskScore: json['riskScore'] as int,
        computedAt: json['computedAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'coinId': coinId,
        'rsi': rsi,
        'macd': macd,
        'macdSignal': macdSignal,
        'macdHistogram': macdHistogram,
        'sma7': sma7,
        'sma30': sma30,
        'bollingerUpper': bollingerUpper,
        'bollingerMiddle': bollingerMiddle,
        'bollingerLower': bollingerLower,
        'signal': signal,
        'strength': strength,
        'volatilityScore': volatilityScore,
        'momentumScore': momentumScore,
        'signalExplanation': signalExplanation,
        'riskScore': riskScore,
        'computedAt': computedAt,
      };
}
