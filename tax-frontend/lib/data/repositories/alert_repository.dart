import 'package:alpharedge_flutter/data/models/alert_model.dart';
import 'package:alpharedge_flutter/services/api_client.dart';

class AlertRepository {
  final ApiClient apiClient;

  AlertRepository(this.apiClient);

  Future<List<AlertModel>> fetchAlerts() async {
    final data = await apiClient.get<List<dynamic>>('/alerts');
    return data.map((item) => AlertModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<AlertModel> createAlert({
    required String coinId,
    required double targetPrice,
    required String condition,
    required String email,
  }) async {
    final data = await apiClient.post<Map<String, dynamic>>('/alerts', data: {
      'coinId': coinId,
      'targetPrice': targetPrice,
      'condition': condition,
      'email': email,
    });
    return AlertModel.fromJson(data);
  }

  Future<void> deleteAlert(String alertId) async {
    await apiClient.delete<void>('/alerts/$alertId');
  }
}
