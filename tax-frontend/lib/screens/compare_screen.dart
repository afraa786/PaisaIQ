import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/coin_providers.dart';
import '../data/models/compare_model.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/signal_badge.dart';

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  final selectedCoins = <String>[];

  @override
  Widget build(BuildContext context) {
    final trackedCoins = ref.watch(trackedCoinsProvider);
    final compareKey = selectedCoins.join(',');
    final compareResult = compareKey.isNotEmpty ? ref.watch(compareCoinsProvider(compareKey)) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            trackedCoins.when(
              data: (coins) {
                if (coins.isEmpty) {
                  return const Text('No coins tracked yet. Track coins from the dashboard.', style: TextStyle(color: Colors.white60));
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: coins.map((coin) {
                    final isSelected = selectedCoins.contains(coin.coinId);
                    return ChoiceChip(
                      label: Text(coin.symbol.toUpperCase()),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00C896),
                      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedCoins.add(coin.coinId);
                          } else {
                            selectedCoins.remove(coin.coinId);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const LoadingShimmer(itemCount: 2),
              error: (error, stack) => Text('Unable to load coins: ${error.toString()}', style: const TextStyle(color: Colors.white60)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: selectedCoins.isEmpty ? null : () => setState(() {}),
              child: const Text('Compare'),
            ),
            const SizedBox(height: 16),
            if (compareResult == null)
              const Text('Select coins and tap Compare to view results.', style: TextStyle(color: Colors.white60))
            else
              compareResult.when(
                data: (results) => _buildResultsTable(results),
                loading: () => const LoadingShimmer(itemCount: 1),
                error: (error, stack) => Text('Compare failed: ${error.toString()}', style: const TextStyle(color: Colors.white60)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsTable(List<CompareModel> rows) {
    final sortedRows = [...rows]..sort((a, b) => b.momentumScore.compareTo(a.momentumScore));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Coin')),
          DataColumn(label: Text('Price USD')),
          DataColumn(label: Text('24h %')),
          DataColumn(label: Text('Market Cap')),
          DataColumn(label: Text('RSI')),
          DataColumn(label: Text('Signal')),
          DataColumn(label: Text('Momentum')),
        ],
        rows: sortedRows.map((row) {
          return DataRow(cells: [
            DataCell(Text('${row.name} (${row.symbol})')),
            DataCell(Text('\$${row.priceUsd.toStringAsFixed(row.priceUsd < 1 ? 6 : 2)}')),
            DataCell(Text('${row.percentChange24h >= 0 ? '+' : ''}${row.percentChange24h.toStringAsFixed(2)}%')),
            DataCell(Text(_formatCompact(row.marketCapUsd))),
            DataCell(Text(row.rsi.toStringAsFixed(1))),
            DataCell(SignalBadge(signal: row.signal, strength: '')),
            DataCell(Text(row.momentumScore.toStringAsFixed(1))),
          ]);
        }).toList(),
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}K';
    return value.toStringAsFixed(2);
  }
}
