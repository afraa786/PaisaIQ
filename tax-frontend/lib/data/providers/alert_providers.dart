import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/alert_repository.dart';
import '../models/alert_model.dart';
import '../../services/api_client.dart';

final alertRepositoryProvider = Provider<AlertRepository>(
  (ref) => AlertRepository(ref.watch(apiClientProvider)),
);

final alertsProvider = FutureProvider.autoDispose<List<AlertModel>>(
  (ref) => ref.watch(alertRepositoryProvider).fetchAlerts(),
);
