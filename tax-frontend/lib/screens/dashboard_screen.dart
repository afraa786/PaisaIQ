import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers/coin_providers.dart';
import '../data/providers/market_providers.dart';
import '../data/repositories/coin_repository.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/loading_shimmer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _coinController = TextEditingController();
  String? _chartCoinId;

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  Future<void> _trackCoin(BuildContext context) async {
    final coinId = _coinController.text.trim().toLowerCase();
    if (coinId.isEmpty) return;
    try {
      await ref.read(coinRepositoryProvider).trackCoin(coinId);
      _coinController.clear();
      if (context.mounted) Navigator.of(context).pop();
      ref.invalidate(trackedCoinsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final market   = ref.watch(marketGlobalProvider);
    final trending = ref.watch(trendingCoinsProvider);
    final watchlist = ref.watch(trackedCoinsProvider);

    // Default chart coin = first tracked coin
    final chartId = _chartCoinId ??
        watchlist.whenOrNull(data: (c) => c.isNotEmpty ? c.first.coinId : null);
    final ohlc = chartId != null
        ? ref.watch(ohlcProvider('$chartId|30'))
        : null;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('ALPHAEDGE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: kWhite),
            onPressed: () => _showTrackSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: kGray1, size: 20),
            onPressed: () => context.goNamed('settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: kWhite,
        backgroundColor: kCard,
        onRefresh: () async {
          ref.invalidate(marketGlobalProvider);
          ref.invalidate(trendingCoinsProvider);
          ref.invalidate(trackedCoinsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Market ticker bar ──────────────────────────────────────────
              market.when(
                data: (m) => _MarketTicker(market: m),
                loading: () => const SizedBox(height: 36, child: LoadingShimmer(itemCount: 1)),
                error: (e, _) => const SizedBox.shrink(),
              ),

              // ── Main candlestick chart ─────────────────────────────────────
              if (chartId != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Text(chartId.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: kWhite)),
                      const SizedBox(width: 8),
                      const Text('/ USD  30D',
                          style: TextStyle(fontSize: 11, color: kGray2)),
                      const Spacer(),
                      // Coin selector chips
                      watchlist.whenOrNull(
                        data: (coins) => coins.length > 1
                            ? SizedBox(
                                height: 24,
                                child: ListView(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  children: coins
                                      .take(4)
                                      .map((c) => GestureDetector(
                                            onTap: () => setState(
                                                () => _chartCoinId = c.coinId),
                                            child: Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _chartCoinId == c.coinId ||
                                                        (chartId == c.coinId)
                                                    ? kWhite
                                                    : kSurface,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: kBorder),
                                              ),
                                              child: Text(
                                                c.symbol.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: _chartCoinId == c.coinId ||
                                                          (chartId == c.coinId)
                                                      ? kBg
                                                      : kGray1,
                                                ),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              )
                            : null,
                      ) ?? const SizedBox.shrink(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: ohlc == null
                      ? const SizedBox(height: 240, child: LoadingShimmer(itemCount: 1))
                      : ohlc.when(
                          loading: () => const SizedBox(
                              height: 240, child: LoadingShimmer(itemCount: 1)),
                          error: (e, _) => SizedBox(
                              height: 80,
                              child: Center(
                                  child: Text('Chart unavailable',
                                      style: TextStyle(color: kGray2, fontSize: 12)))),
                          data: (candles) => CandlestickChart(
                              candles: candles, height: 240),
                        ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Trending ───────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('TRENDING',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: kGray1)),
              ),
              const SizedBox(height: 10),
              trending.when(
                data: (list) => _TrendingRow(coins: list),
                loading: () => const SizedBox(
                    height: 80, child: LoadingShimmer(itemCount: 1)),
                error: (e, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // ── Watchlist ──────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('WATCHLIST',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: kGray1)),
              ),
              const SizedBox(height: 10),
              watchlist.when(
                data: (coins) => coins.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Tap + to track a coin.',
                            style: TextStyle(color: kGray2, fontSize: 13)))
                    : Column(
                        children: coins
                            .map((coin) => _WatchlistTile(
                                  coin: coin,
                                  onTap: () => context.go('/coin/${coin.coinId}'),
                                ))
                            .toList(),
                      ),
                loading: () => const LoadingShimmer(),
                error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(e.toString(),
                        style: const TextStyle(color: kRed, fontSize: 12))),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('TRACK COIN',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
            const SizedBox(height: 16),
            TextField(
              controller: _coinController,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: 'bitcoin, ethereum, solana...',
                  hintStyle: TextStyle(color: kGray2)),
              onSubmitted: (_) => _trackCoin(context),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
                onPressed: () => _trackCoin(context),
                child: const Text('TRACK')),
          ],
        ),
      ),
    );
  }
}

// ── Market ticker ─────────────────────────────────────────────────────────────

class _MarketTicker extends StatelessWidget {
  const _MarketTicker({required this.market});
  final dynamic market;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _item('MCAP', formatCompact(market.totalMarketCapUsd)),
          _item('VOL 24H', formatCompact(market.volume24hUsd)),
          _item('BTC DOM', '${market.btcDominance.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _item(String label, String value) => Row(children: [
        Text('$label ', style: const TextStyle(color: kGray2, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: kWhite, fontSize: 11, fontWeight: FontWeight.w700)),
      ]);
}

// ── Trending row ──────────────────────────────────────────────────────────────

class _TrendingRow extends StatelessWidget {
  const _TrendingRow({required this.coins});
  final List<dynamic> coins;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: coins.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = coins[i];
          return GestureDetector(
            onTap: () => context.go('/coin/${c.coinId}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kBorder)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(c.symbol.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kWhite)),
                  const SizedBox(height: 3),
                  Text(
                    '\$${c.priceUsd < 1 ? c.priceUsd.toStringAsFixed(6) : c.priceUsd.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: kGray1),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Watchlist tile ────────────────────────────────────────────────────────────

class _WatchlistTile extends StatelessWidget {
  const _WatchlistTile({required this.coin, required this.onTap});
  final dynamic coin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final snap = coin.priceSnapshot;
    final change = (snap?.priceChange24hPercent ?? 0.0) as double;
    final isUp = change >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kBorder)),
        child: Row(
          children: [
            // Symbol box
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(
                (coin.symbol as String).substring(0, (coin.symbol as String).length.clamp(0, 3)).toUpperCase(),
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: kWhite),
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coin.name as String,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(coin.symbol.toUpperCase() as String,
                      style:
                          const TextStyle(fontSize: 11, color: kGray2)),
                ],
              ),
            ),
            // Price + change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  snap != null
                      ? '\$${(snap.priceUsd as double) < 1 ? (snap.priceUsd as double).toStringAsFixed(6) : (snap.priceUsd as double).toStringAsFixed(2)}'
                      : '—',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                  style: TextStyle(
                      fontSize: 11,
                      color: isUp ? kGreen : kRed,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
