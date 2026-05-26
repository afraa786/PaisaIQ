import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers/coin_providers.dart';
import '../data/providers/market_providers.dart';
import '../data/repositories/coin_repository.dart';
import '../utils/formatters.dart';
import '../widgets/coin_list_tile.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/price_change_chip.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _coinController = TextEditingController();

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  Future<void> _trackCoin(BuildContext context) async {
    final coinId = _coinController.text.trim();
    if (coinId.isEmpty) return;
    try {
      await ref.read(coinRepositoryProvider).trackCoin(coinId);
      _coinController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coin tracking started.')));
      }
      ref.refresh(trackedCoinsProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketValue = ref.watch(marketGlobalProvider);
    final trendingValue = ref.watch(trendingCoinsProvider);
    final watchlistValue = ref.watch(trackedCoinsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AlphaEdge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.goNamed('settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: const Color(0xFF161B22),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Track Coin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _coinController,
                      decoration: const InputDecoration(
                        hintText: 'Enter coin ID',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _trackCoin(context),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () => _trackCoin(context),
                      child: const Text('Start Tracking'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(marketGlobalProvider);
          ref.refresh(trendingCoinsProvider);
          ref.refresh(trackedCoinsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              marketValue.when(
                data: (market) => _buildMarketBanner(market),
                loading: () => const LoadingShimmer(itemCount: 1),
                error: (error, stack) => _buildErrorCard(error.toString(), () => ref.refresh(marketGlobalProvider)),
              ),
              const SizedBox(height: 20),
              const Text('Trending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              trendingValue.when(
                data: (trending) => _buildTrendingRow(trending),
                loading: () => const SizedBox(height: 120, child: LoadingShimmer(itemCount: 1)),
                error: (error, stack) => _buildErrorCard(error.toString(), () => ref.refresh(trendingCoinsProvider)),
              ),
              const SizedBox(height: 24),
              const Text('Watchlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              watchlistValue.when(
                data: (coins) {
                  if (coins.isEmpty) {
                    return _buildEmptyState('No tracked coins yet. Use + to track a coin.');
                  }
                  return Column(
                    children: coins.map((coin) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CoinListTile(
                          name: coin.name,
                          symbol: coin.symbol,
                          priceUsd: coin.priceSnapshot.priceUsd,
                          priceInr: coin.priceSnapshot.priceInr,
                          change24h: coin.priceSnapshot.priceChange24hPercent,
                          onTap: () => context.go('/coin/${coin.coinId}'),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LoadingShimmer(),
                error: (error, stack) => _buildErrorCard(error.toString(), () => ref.refresh(trackedCoinsProvider)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketBanner(dynamic market) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStat('Market Cap', formatCompact(market.totalMarketCapUsd)),
          _buildStat('24h Volume', formatCompact(market.volume24hUsd)),
          _buildStat('BTC Dominance', '${market.btcDominance.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildTrendingRow(List<dynamic> trending) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: trending.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = trending[index];
          return GestureDetector(
            onTap: () => context.go('/coin/${item.coinId}'),
            child: Container(
              width: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(item.symbol.toUpperCase(), style: const TextStyle(color: Colors.white60)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1F17),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('\$${item.priceUsd.toStringAsFixed(item.priceUsd < 1 ? 6 : 2)}',
                        style: const TextStyle(color: Color(0xFF00C896), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorCard(String message, VoidCallback retry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Error', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: retry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white60)),
    );
  }
}
