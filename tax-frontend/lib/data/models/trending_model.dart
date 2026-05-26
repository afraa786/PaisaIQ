class TrendingModel {
  final String coinId;
  final String name;
  final String symbol;
  final double priceUsd;
  final double priceInr;

  TrendingModel({
    required this.coinId,
    required this.name,
    required this.symbol,
    required this.priceUsd,
    required this.priceInr,
  });

  factory TrendingModel.fromJson(Map<String, dynamic> json) => TrendingModel(
        coinId: json['coinId'] as String,
        name: json['name'] as String,
        symbol: json['symbol'] as String,
        priceUsd: (json['priceUsd'] as num).toDouble(),
        priceInr: (json['priceInr'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'coinId': coinId,
        'name': name,
        'symbol': symbol,
        'priceUsd': priceUsd,
        'priceInr': priceInr,
      };
}
