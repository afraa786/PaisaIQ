import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/market_repository.dart';
import '../models/market_global_model.dart';
import '../models/trending_model.dart';
import '../../services/api_client.dart';

final marketRepositoryProvider = Provider<MarketRepository>(
  (ref) => MarketRepository(ref.watch(apiClientProvider)),
);

final marketGlobalProvider = FutureProvider.autoDispose<MarketGlobalModel>(
  (ref) => ref.watch(marketRepositoryProvider).fetchGlobalMarket(),
);

final trendingCoinsProvider = FutureProvider.autoDispose<List<TrendingModel>>(
  (ref) => ref.watch(marketRepositoryProvider).fetchTrending(),
);
