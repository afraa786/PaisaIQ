import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/compare_model.dart';
import '../models/coin_model.dart';
import '../models/coin_signal_model.dart';
import '../models/ohlc_model.dart';
import '../repositories/coin_repository.dart';
import '../../services/api_client.dart';

final coinRepositoryProvider = Provider<CoinRepository>(
  (ref) => CoinRepository(ref.watch(apiClientProvider)),
);

final trackedCoinsProvider = FutureProvider.autoDispose<List<CoinModel>>(
  (ref) => ref.watch(coinRepositoryProvider).fetchTrackedCoins(),
);

final coinDetailProvider = FutureProvider.family.autoDispose<CoinModel, String>(
  (ref, coinId) => ref.watch(coinRepositoryProvider).fetchCoinDetail(coinId),
);

final coinSignalExplainProvider = FutureProvider.family.autoDispose<CoinSignalModel, String>(
  (ref, coinId) => ref.watch(coinRepositoryProvider).fetchCoinSignalExplain(coinId),
);

final coinHistoryProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>(
  (ref, key) {
    final parts = key.split('|');
    final coinId = parts.first;
    final days = int.tryParse(parts.elementAt(1)) ?? 7;
    return ref.watch(coinRepositoryProvider).fetchCoinHistory(coinId, days);
  },
);

final compareCoinsProvider = FutureProvider.autoDispose.family<List<CompareModel>, String>(
  (ref, joinedIds) => ref.watch(coinRepositoryProvider).compareCoins(joinedIds.split(',')),
);

final ohlcProvider = FutureProvider.autoDispose.family<List<OhlcModel>, String>(
  (ref, key) {
    final parts = key.split('|');
    final coinId = parts.first;
    final days = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 30;
    return ref.watch(coinRepositoryProvider).fetchOhlc(coinId, days: days);
  },
);
