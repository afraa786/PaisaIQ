class PortfolioHoldingModel {
  final String id;
  final String coinId;
  final double quantity;
  final double buyPrice;
  final double currentPriceUsd;

  PortfolioHoldingModel({
    required this.id,
    required this.coinId,
    required this.quantity,
    required this.buyPrice,
    required this.currentPriceUsd,
  });

  factory PortfolioHoldingModel.fromJson(Map<String, dynamic> json) => PortfolioHoldingModel(
        id: json['id'] as String,
        coinId: json['coinId'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        buyPrice: (json['buyPrice'] as num).toDouble(),
        currentPriceUsd: (json['currentPriceUsd'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'coinId': coinId,
        'quantity': quantity,
        'buyPrice': buyPrice,
        'currentPriceUsd': currentPriceUsd,
      };
}

class PortfolioModel {
  final String id;
  final String name;
  final double totalValueUsd;
  final List<PortfolioHoldingModel> holdings;

  PortfolioModel({
    required this.id,
    required this.name,
    required this.totalValueUsd,
    required this.holdings,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) => PortfolioModel(
        id: json['id'] as String,
        name: json['name'] as String,
        totalValueUsd: (json['totalValueUsd'] as num).toDouble(),
        holdings: (json['holdings'] as List<dynamic>)
            .map((item) => PortfolioHoldingModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalValueUsd': totalValueUsd,
        'holdings': holdings.map((item) => item.toJson()).toList(),
      };
}
