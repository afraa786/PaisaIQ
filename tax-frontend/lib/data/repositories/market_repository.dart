import 'package:alpharedge_flutter/data/models/market_global_model.dart';
import 'package:alpharedge_flutter/data/models/trending_model.dart';
import 'package:alpharedge_flutter/services/api_client.dart';

class MarketRepository {
  final ApiClient apiClient;

  MarketRepository(this.apiClient);

  Future<MarketGlobalModel> fetchGlobalMarket() async {
    final data = await apiClient.get<Map<String, dynamic>>('/market/summary');
    return MarketGlobalModel.fromJson(data);
  }

  Future<List<TrendingModel>> fetchTrending() async {
    final data = await apiClient.get<List<dynamic>>('/market/trending');
    return data.map((item) => TrendingModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
