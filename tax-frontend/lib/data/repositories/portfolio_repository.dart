import 'package:alpharedge_flutter/data/models/portfolio_model.dart';
import 'package:alpharedge_flutter/services/api_client.dart';

class PortfolioRepository {
  final ApiClient apiClient;

  PortfolioRepository(this.apiClient);

  Future<List<PortfolioModel>> fetchPortfolios() async {
    final data = await apiClient.get<List<dynamic>>('/portfolio');
    return data.map((item) => PortfolioModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<PortfolioModel> createPortfolio(String name) async {
    final data = await apiClient.post<Map<String, dynamic>>('/portfolio', data: {'name': name});
    return PortfolioModel.fromJson(data);
  }

  Future<PortfolioModel> addHolding({
    required String portfolioId,
    required String coinId,
    required double quantity,
    required double buyPrice,
  }) async {
    final data = await apiClient.post<Map<String, dynamic>>(
      '/portfolio/$portfolioId/holdings',
      data: {
        'coinId': coinId,
        'quantity': quantity,
        'buyPrice': buyPrice,
      },
    );
    return PortfolioModel.fromJson(data);
  }
}
