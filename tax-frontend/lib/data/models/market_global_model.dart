class MarketGlobalModel {
  final double totalMarketCapUsd;
  final double volume24hUsd;
  final double btcDominance;

  MarketGlobalModel({
    required this.totalMarketCapUsd,
    required this.volume24hUsd,
    required this.btcDominance,
  });

  factory MarketGlobalModel.fromJson(Map<String, dynamic> json) => MarketGlobalModel(
        totalMarketCapUsd: (json['totalMarketCapUsd'] as num).toDouble(),
        volume24hUsd: (json['volume24hUsd'] as num).toDouble(),
        btcDominance: (json['btcDominance'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'totalMarketCapUsd': totalMarketCapUsd,
        'volume24hUsd': volume24hUsd,
        'btcDominance': btcDominance,
      };
}
