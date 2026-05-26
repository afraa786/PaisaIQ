class CompareModel {
  final String coinId;
  final String name;
  final String symbol;
  final double priceUsd;
  final double percentChange24h;
  final double marketCapUsd;
  final double rsi;
  final String signal;
  final double momentumScore;

  CompareModel({
    required this.coinId,
    required this.name,
    required this.symbol,
    required this.priceUsd,
    required this.percentChange24h,
    required this.marketCapUsd,
    required this.rsi,
    required this.signal,
    required this.momentumScore,
  });

  factory CompareModel.fromJson(Map<String, dynamic> json) => CompareModel(
        coinId: json['coinId'] as String,
        name: json['name'] as String,
        symbol: json['symbol'] as String,
        priceUsd: (json['priceUsd'] as num).toDouble(),
        percentChange24h: (json['priceChange24hPercent'] as num).toDouble(),
        marketCapUsd: (json['marketCapUsd'] as num).toDouble(),
        rsi: (json['rsi'] as num).toDouble(),
        signal: json['signal'] as String,
        momentumScore: (json['momentumScore'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'coinId': coinId,
        'name': name,
        'symbol': symbol,
        'priceUsd': priceUsd,
        'priceChange24hPercent': percentChange24h,
        'marketCapUsd': marketCapUsd,
        'rsi': rsi,
        'signal': signal,
        'momentumScore': momentumScore,
      };
}
