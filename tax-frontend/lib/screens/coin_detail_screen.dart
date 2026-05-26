import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/coin_providers.dart';
import '../data/models/coin_model.dart';
import '../utils/formatters.dart';
import '../widgets/price_chart.dart';
import '../widgets/risk_score_bar.dart';
import '../widgets/signal_badge.dart';
import '../widgets/stat_card.dart';
import '../widgets/loading_shimmer.dart';

class CoinDetailScreen extends ConsumerStatefulWidget {
  final String coinId;

  const CoinDetailScreen({super.key, required this.coinId});

  @override
  ConsumerState<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends ConsumerState<CoinDetailScreen> {
  int selectedDays = 7;

  @override
  Widget build(BuildContext context) {
    final coinValue = ref.watch(coinDetailProvider(widget.coinId));
    final signalPair = ref.watch(coinSignalExplainProvider(widget.coinId));
    final historyValue = ref.watch(coinHistoryProvider('${widget.coinId}|$selectedDays'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: coinValue.when(
          data: (coin) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(coin),
              const SizedBox(height: 16),
              signalPair.when(
                data: (signal) => _buildSignalCard(signal),
                loading: () => const LoadingShimmer(itemCount: 1),
                error: (error, stack) => _buildErrorCard(error.toString(), () => ref.refresh(coinSignalExplainProvider(widget.coinId))),
              ),
              const SizedBox(height: 16),
              historyValue.when(
                data: (history) => _buildChartCard(history),
                loading: () => const LoadingShimmer(itemCount: 1),
                error: (error, stack) => _buildErrorCard(error.toString(), () => ref.refresh(coinHistoryProvider('${widget.coinId}|$selectedDays'))),
              ),
              const SizedBox(height: 16),
              _buildIndicatorGrid(coin),
              const SizedBox(height: 16),
              _buildBollingerCard(coin),
              const SizedBox(height: 16),
              _buildAthAtlCard(coin),
            ],
          ),
          loading: () => const LoadingShimmer(itemCount: 3),
          error: (error, stack) => _buildErrorCard(error.toString(), () => ref.refresh(coinDetailProvider(widget.coinId))),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(CoinModel coin) {
    final snapshot = coin.priceSnapshot;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${coin.name} (${coin.symbol})', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Text(formatUsd(snapshot.priceUsd), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(formatInr(snapshot.priceInr), style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChangeBadge('24h', snapshot.priceChange24hPercent),
              _buildChangeBadge('7d', snapshot.priceChange7dPercent),
              _buildChangeBadge('30d', snapshot.priceChange30dPercent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeBadge(String label, double change) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 6),
        Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%', style: TextStyle(color: change >= 0 ? const Color(0xFF00C896) : Colors.redAccent, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildSignalCard(dynamic signal) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SignalBadge(signal: signal.signal, strength: signal.strength),
              Text('Risk score ${signal.riskScore}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          RiskScoreBar(score: signal.riskScore),
          const SizedBox(height: 14),
          Text(signal.signalExplanation, style: const TextStyle(color: Colors.white60, fontStyle: FontStyle.italic, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<Map<String, dynamic>> history) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(22)),
      child: PriceChart(history: history, currencyLabel: 'USD'),
    );
  }

  Widget _buildIndicatorGrid(CoinModel coin) {
    final signal = coin.signal;
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        StatCard(label: 'RSI', value: signal.rsi.toStringAsFixed(1), valueColor: signal.rsi > 70 ? Colors.redAccent : signal.rsi < 30 ? const Color(0xFF00C896) : Colors.white),
        StatCard(label: 'MACD', value: signal.macd.toStringAsFixed(2), valueColor: Colors.white),
        StatCard(label: 'SMA7', value: signal.sma7.toStringAsFixed(2), valueColor: Colors.white),
        StatCard(label: 'SMA30', value: signal.sma30.toStringAsFixed(2), valueColor: Colors.white),
        StatCard(label: 'Volatility', value: signal.volatilityScore.toStringAsFixed(1), valueColor: Colors.white),
        StatCard(label: 'Momentum', value: signal.momentumScore.toStringAsFixed(1), valueColor: Colors.white),
      ],
    );
  }

  Widget _buildBollingerCard(CoinModel coin) {
    final signal = coin.signal;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(22)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMiniStat('Upper', signal.bollingerUpper),
          _buildMiniStat('Middle', signal.bollingerMiddle),
          _buildMiniStat('Lower', signal.bollingerLower),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 8),
        Text(formatUsd(value), style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildAthAtlCard(CoinModel coin) {
    final snapshot = coin.priceSnapshot;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(22)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All Time High', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 8),
              Text(formatUsd(snapshot.allTimeHighUsd), style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('All Time Low', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 8),
              Text(formatUsd(snapshot.allTimeLowUsd), style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message, VoidCallback retry) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Error', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: retry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
