import 'package:alpharedge_flutter/data/models/compare_model.dart';
import 'package:alpharedge_flutter/data/models/coin_model.dart';
import 'package:alpharedge_flutter/data/models/coin_price_model.dart';
import 'package:alpharedge_flutter/data/models/coin_signal_model.dart';
import 'package:alpharedge_flutter/data/models/ohlc_model.dart';
import 'package:alpharedge_flutter/services/api_client.dart';

class CoinRepository {
  final ApiClient apiClient;

  CoinRepository(this.apiClient);

  Future<List<CoinModel>> fetchTrackedCoins() async {
    final data = await apiClient.get<List<dynamic>>('/coins');
    return data.map((item) => CoinModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<CoinModel> fetchCoinDetail(String coinId) async {
    final data = await apiClient.get<Map<String, dynamic>>('/coins/$coinId');
    return CoinModel.fromJson(data);
  }

  Future<CoinPriceModel> fetchCoinPrice(String coinId) async {
    final data = await apiClient.get<Map<String, dynamic>>('/coins/$coinId/price');
    return CoinPriceModel.fromJson(data);
  }

  Future<CoinSignalModel> fetchCoinSignalExplain(String coinId) async {
    final data = await apiClient.get<Map<String, dynamic>>('/coins/$coinId/signal/explain');
    return CoinSignalModel.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> fetchCoinHistory(String coinId, int days) async {
    final data = await apiClient.get<List<dynamic>>('/coins/$coinId/history', queryParameters: {'days': days});
    return data.map((item) => Map<String, dynamic>.from(item as Map<String, dynamic>)).toList();
  }

  Future<List<CompareModel>> compareCoins(List<String> ids) async {
    final response = await apiClient.get<List<dynamic>>('/coins/compare', queryParameters: {'ids': ids.join(',')});
    return response.map((item) => CompareModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<OhlcModel>> fetchOhlc(String coinId, {int days = 30}) async {
    final data = await apiClient.get<List<dynamic>>(
      '/coins/$coinId/ohlc',
      queryParameters: {'days': days},
    );
    return data
        .map((e) => OhlcModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CoinModel> trackCoin(String coinId) async {
    final data = await apiClient.post<Map<String, dynamic>>('/coins/track', data: {'coinId': coinId});
    return CoinModel.fromJson(data);
  }
}
