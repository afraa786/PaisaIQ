import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/portfolio_repository.dart';
import '../models/portfolio_model.dart';
import '../models/portfolio_summary_model.dart';
import '../../services/api_client.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>(
  (ref) => PortfolioRepository(ref.watch(apiClientProvider)),
);

final portfoliosProvider = FutureProvider.autoDispose<List<PortfolioModel>>(
  (ref) => ref.watch(portfolioRepositoryProvider).fetchPortfolios(),
);

final portfolioSummaryProvider =
    FutureProvider.autoDispose.family<PortfolioSummaryModel, String>(
  (ref, portfolioId) =>
      ref.watch(portfolioRepositoryProvider).fetchPortfolioSummary(portfolioId),
);
