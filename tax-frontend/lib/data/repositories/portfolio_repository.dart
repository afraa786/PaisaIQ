import 'package:alpharedge_flutter/data/models/portfolio_model.dart';
import 'package:alpharedge_flutter/data/models/portfolio_summary_model.dart';
import 'package:alpharedge_flutter/services/api_client.dart';

const _defaultUserId = 'user-1';

class PortfolioRepository {
  final ApiClient apiClient;

  PortfolioRepository(this.apiClient);

  Future<List<PortfolioModel>> fetchPortfolios() async {
    final data = await apiClient.get<List<dynamic>>(
      '/portfolios',
      headers: {'X-User-Id': _defaultUserId},
    );
    return data
        .map((item) => PortfolioModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PortfolioModel> createPortfolio(String name) async {
    final data = await apiClient.post<Map<String, dynamic>>(
      '/portfolios',
      data: {'name': name},
      headers: {'X-User-Id': _defaultUserId},
    );
    return PortfolioModel.fromJson(data);
  }

  Future<PortfolioModel> addHolding({
    required String portfolioId,
    required String coinId,
    required double quantity,
    required double buyPrice,
  }) async {
    final today = DateTime.now();
    final buyDate =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final data = await apiClient.post<Map<String, dynamic>>(
      '/portfolios/$portfolioId/holdings',
      data: {
        'coinId': coinId,
        'quantity': quantity,
        'buyPriceUsd': buyPrice,
        'buyDate': buyDate,
      },
      headers: {'X-User-Id': _defaultUserId},
    );
    return PortfolioModel.fromJson(data);
  }

  Future<PortfolioSummaryModel> fetchPortfolioSummary(String portfolioId) async {
    final data = await apiClient.get<Map<String, dynamic>>(
      '/portfolios/$portfolioId/summary',
      headers: {'X-User-Id': _defaultUserId},
    );
    return PortfolioSummaryModel.fromJson(data);
  }

  Future<PortfolioModel> removeHolding({
    required String portfolioId,
    required String holdingId,
  }) async {
    final data = await apiClient.delete<Map<String, dynamic>>(
      '/portfolios/$portfolioId/holdings/$holdingId',
      headers: {'X-User-Id': _defaultUserId},
    );
    return PortfolioModel.fromJson(data);
  }
}
