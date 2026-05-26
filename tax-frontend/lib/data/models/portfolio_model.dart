class PortfolioHoldingModel {
  final String id;
  final String coinId;
  final String symbol;
  final double quantity;
  final double buyPrice;
  final double currentPriceUsd;

  PortfolioHoldingModel({
    required this.id,
    required this.coinId,
    required this.symbol,
    required this.quantity,
    required this.buyPrice,
    this.currentPriceUsd = 0.0,
  });

  factory PortfolioHoldingModel.fromJson(Map<String, dynamic> json) =>
      PortfolioHoldingModel(
        id: (json['holdingId'] ?? json['id'] ?? '') as String,
        coinId: json['coinId'] as String,
        symbol: (json['symbol'] ?? json['coinId'] ?? '') as String,
        quantity: (json['quantity'] as num).toDouble(),
        buyPrice: ((json['buyPriceUsd'] ?? json['buyPrice'] ?? 0) as num).toDouble(),
        currentPriceUsd: ((json['currentPriceUsd'] ?? 0) as num).toDouble(),
      );
}

class PortfolioModel {
  final String id;
  final String name;
  final double totalValueUsd;
  final List<PortfolioHoldingModel> holdings;

  PortfolioModel({
    required this.id,
    required this.name,
    this.totalValueUsd = 0.0,
    required this.holdings,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) => PortfolioModel(
        id: json['id'] as String,
        name: json['name'] as String,
        totalValueUsd: ((json['totalValueUsd'] ?? 0) as num).toDouble(),
        holdings: ((json['holdings'] ?? []) as List<dynamic>)
            .map((item) =>
                PortfolioHoldingModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
