class CoinPriceModel {
  final String coinId;
  final double priceUsd;
  final double priceInr;

  CoinPriceModel({
    required this.coinId,
    required this.priceUsd,
    required this.priceInr,
  });

  factory CoinPriceModel.fromJson(Map<String, dynamic> json) => CoinPriceModel(
        coinId: json['coinId'] as String,
        priceUsd: (json['priceUsd'] as num).toDouble(),
        priceInr: (json['priceInr'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'coinId': coinId,
        'priceUsd': priceUsd,
        'priceInr': priceInr,
      };
}
