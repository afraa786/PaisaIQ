class HoldingPerformanceModel {
  final String holdingId;
  final String coinId;
  final String symbol;
  final double quantity;
  final double currentPriceUsd;
  final double currentValueUsd;
  final double costBasisUsd;
  final double pnlUsd;
  final double pnlPercent;
  final double currentPriceInr;
  final double currentValueInr;
  final double costBasisInr;
  final double pnlInr;
  final double dayChangeInr;
  final double dayChangePercent;

  HoldingPerformanceModel({
    required this.holdingId,
    required this.coinId,
    required this.symbol,
    required this.quantity,
    required this.currentPriceUsd,
    required this.currentValueUsd,
    required this.costBasisUsd,
    required this.pnlUsd,
    required this.pnlPercent,
    required this.currentPriceInr,
    required this.currentValueInr,
    required this.costBasisInr,
    required this.pnlInr,
    required this.dayChangeInr,
    required this.dayChangePercent,
  });

  factory HoldingPerformanceModel.fromJson(Map<String, dynamic> json) =>
      HoldingPerformanceModel(
        holdingId: json['holdingId'] as String,
        coinId: json['coinId'] as String,
        symbol: (json['symbol'] ?? '') as String,
        quantity: (json['quantity'] as num).toDouble(),
        currentPriceUsd: ((json['currentPriceUsd'] ?? 0) as num).toDouble(),
        currentValueUsd: ((json['currentValueUsd'] ?? 0) as num).toDouble(),
        costBasisUsd: ((json['costBasisUsd'] ?? 0) as num).toDouble(),
        pnlUsd: ((json['pnlUsd'] ?? 0) as num).toDouble(),
        pnlPercent: ((json['pnlPercent'] ?? 0) as num).toDouble(),
        currentPriceInr: ((json['currentPriceInr'] ?? 0) as num).toDouble(),
        currentValueInr: ((json['currentValueInr'] ?? 0) as num).toDouble(),
        costBasisInr: ((json['costBasisInr'] ?? 0) as num).toDouble(),
        pnlInr: ((json['pnlInr'] ?? 0) as num).toDouble(),
        dayChangeInr: ((json['dayChangeInr'] ?? 0) as num).toDouble(),
        dayChangePercent: ((json['dayChangePercent'] ?? 0) as num).toDouble(),
      );
}

class PortfolioSummaryModel {
  final String portfolioId;
  final String portfolioName;
  final double totalValueUsd;
  final double totalCostBasisUsd;
  final double totalPnlUsd;
  final double totalPnlPercent;
  final double totalValueInr;
  final double totalCostBasisInr;
  final double totalPnlInr;
  final double dayChangeInr;
  final double dayChangePercent;
  final String? bestPerformer;
  final double bestPerformerGain;
  final String? worstPerformer;
  final double worstPerformerLoss;
  final List<HoldingPerformanceModel> holdings;

  PortfolioSummaryModel({
    required this.portfolioId,
    required this.portfolioName,
    required this.totalValueUsd,
    required this.totalCostBasisUsd,
    required this.totalPnlUsd,
    required this.totalPnlPercent,
    required this.totalValueInr,
    required this.totalCostBasisInr,
    required this.totalPnlInr,
    required this.dayChangeInr,
    required this.dayChangePercent,
    this.bestPerformer,
    required this.bestPerformerGain,
    this.worstPerformer,
    required this.worstPerformerLoss,
    required this.holdings,
  });

  factory PortfolioSummaryModel.fromJson(Map<String, dynamic> json) =>
      PortfolioSummaryModel(
        portfolioId: json['portfolioId'] as String,
        portfolioName: json['portfolioName'] as String,
        totalValueUsd: ((json['totalValueUsd'] ?? 0) as num).toDouble(),
        totalCostBasisUsd: ((json['totalCostBasisUsd'] ?? 0) as num).toDouble(),
        totalPnlUsd: ((json['totalPnlUsd'] ?? 0) as num).toDouble(),
        totalPnlPercent: ((json['totalPnlPercent'] ?? 0) as num).toDouble(),
        totalValueInr: ((json['totalValueInr'] ?? 0) as num).toDouble(),
        totalCostBasisInr: ((json['totalCostBasisInr'] ?? 0) as num).toDouble(),
        totalPnlInr: ((json['totalPnlInr'] ?? 0) as num).toDouble(),
        dayChangeInr: ((json['dayChangeInr'] ?? 0) as num).toDouble(),
        dayChangePercent: ((json['dayChangePercent'] ?? 0) as num).toDouble(),
        bestPerformer: json['bestPerformer'] as String?,
        bestPerformerGain: ((json['bestPerformerGain'] ?? 0) as num).toDouble(),
        worstPerformer: json['worstPerformer'] as String?,
        worstPerformerLoss: ((json['worstPerformerLoss'] ?? 0) as num).toDouble(),
        holdings: ((json['holdings'] ?? []) as List<dynamic>)
            .map((h) => HoldingPerformanceModel.fromJson(
                h as Map<String, dynamic>))
            .toList(),
      );
}
