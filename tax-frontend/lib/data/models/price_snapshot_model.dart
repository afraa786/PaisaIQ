class PriceSnapshotModel {
  final String id;
  final String coinId;
  final double priceUsd;
  final double priceInr;
  final double marketCapUsd;
  final double volume24hUsd;
  final double priceChange24hPercent;
  final double priceChange7dPercent;
  final double priceChange30dPercent;
  final double allTimeHighUsd;
  final double allTimeLowUsd;
  final double circulatingSupply;
  final double totalSupply;
  final int marketCapRank;
  final String fetchedAt;

  PriceSnapshotModel({
    required this.id,
    required this.coinId,
    required this.priceUsd,
    required this.priceInr,
    required this.marketCapUsd,
    required this.volume24hUsd,
    required this.priceChange24hPercent,
    required this.priceChange7dPercent,
    required this.priceChange30dPercent,
    required this.allTimeHighUsd,
    required this.allTimeLowUsd,
    required this.circulatingSupply,
    required this.totalSupply,
    required this.marketCapRank,
    required this.fetchedAt,
  });

  factory PriceSnapshotModel.fromJson(Map<String, dynamic> json) => PriceSnapshotModel(
        id: json['id'] as String,
        coinId: json['coinId'] as String,
        priceUsd: (json['priceUsd'] as num).toDouble(),
        priceInr: (json['priceInr'] as num).toDouble(),
        marketCapUsd: (json['marketCapUsd'] as num).toDouble(),
        volume24hUsd: (json['volume24hUsd'] as num).toDouble(),
        priceChange24hPercent: (json['priceChange24hPercent'] as num).toDouble(),
        priceChange7dPercent: (json['priceChange7dPercent'] as num).toDouble(),
        priceChange30dPercent: (json['priceChange30dPercent'] as num).toDouble(),
        allTimeHighUsd: (json['allTimeHighUsd'] as num).toDouble(),
        allTimeLowUsd: (json['allTimeLowUsd'] as num).toDouble(),
        circulatingSupply: (json['circulatingSupply'] as num).toDouble(),
        totalSupply: (json['totalSupply'] as num).toDouble(),
        marketCapRank: json['marketCapRank'] as int,
        fetchedAt: json['fetchedAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'coinId': coinId,
        'priceUsd': priceUsd,
        'priceInr': priceInr,
        'marketCapUsd': marketCapUsd,
        'volume24hUsd': volume24hUsd,
        'priceChange24hPercent': priceChange24hPercent,
        'priceChange7dPercent': priceChange7dPercent,
        'priceChange30dPercent': priceChange30dPercent,
        'allTimeHighUsd': allTimeHighUsd,
        'allTimeLowUsd': allTimeLowUsd,
        'circulatingSupply': circulatingSupply,
        'totalSupply': totalSupply,
        'marketCapRank': marketCapRank,
        'fetchedAt': fetchedAt,
      };
}
