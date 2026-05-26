import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/portfolio_model.dart';
import '../data/providers/portfolio_providers.dart';
import '../data/repositories/portfolio_repository.dart';
import '../widgets/loading_shimmer.dart';
import '../utils/formatters.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  String? expandedPortfolio;
  final _portfolioController = TextEditingController();
  final _coinController = TextEditingController();
  final _quantityController = TextEditingController();
  final _buyPriceController = TextEditingController();

  @override
  void dispose() {
    _portfolioController.dispose();
    _coinController.dispose();
    _quantityController.dispose();
    _buyPriceController.dispose();
    super.dispose();
  }

  Future<void> _createPortfolio(BuildContext context) async {
    final name = _portfolioController.text.trim();
    if (name.isEmpty) return;
    try {
      await ref.read(portfolioRepositoryProvider).createPortfolio(name);
      _portfolioController.clear();
      Navigator.of(context).pop();
      ref.refresh(portfoliosProvider);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _addHolding(BuildContext context, String portfolioId) async {
    final coinId = _coinController.text.trim();
    final quantity = double.tryParse(_quantityController.text.trim());
    final buyPrice = double.tryParse(_buyPriceController.text.trim());
    if (coinId.isEmpty || quantity == null || buyPrice == null) return;
    try {
      await ref.read(portfolioRepositoryProvider).addHolding(
            portfolioId: portfolioId,
            coinId: coinId,
            quantity: quantity,
            buyPrice: buyPrice,
          );
      _coinController.clear();
      _quantityController.clear();
      _buyPriceController.clear();
      Navigator.of(context).pop();
      ref.refresh(portfoliosProvider);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolios = ref.watch(portfoliosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: const Color(0xFF161B22),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('New Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    TextField(controller: _portfolioController, decoration: const InputDecoration(labelText: 'Portfolio Name', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => _createPortfolio(context), child: const Text('Create')),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: portfolios.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No portfolios yet. Tap + to create one.', style: TextStyle(color: Colors.white60)));
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final portfolio = items[index];
                final expanded = expandedPortfolio == portfolio.id;
                return Container(
                  decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(portfolio.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${portfolio.holdings.length} holdings • ${formatCompact(portfolio.totalValueUsd)} USD', style: const TextStyle(color: Colors.white60)),
                        trailing: IconButton(
                          icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, color: Colors.white),
                          onPressed: () => setState(() => expandedPortfolio = expanded ? null : portfolio.id),
                        ),
                      ),
                      if (expanded) ...[
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 12),
                        ...portfolio.holdings.map((holding) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(holding.coinId.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text('Qty ${holding.quantity} • Buy ${formatUsd(holding.buyPrice)}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(formatUsd(holding.currentPriceUsd * holding.quantity), style: const TextStyle(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text(_profitText(holding), style: TextStyle(color: _profitColor(holding), fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddHoldingSheet(context, portfolio.id),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Holding'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const LoadingShimmer(),
          error: (error, stack) => Center(child: Text('Failed to load portfolios: ${error.toString()}', style: const TextStyle(color: Colors.white60))),
        ),
      ),
    );
  }

  void _showAddHoldingSheet(BuildContext context, String portfolioId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Holding', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextField(controller: _coinController, decoration: const InputDecoration(labelText: 'Coin ID', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _buyPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Buy Price', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => _addHolding(context, portfolioId), child: const Text('Add')),
            ],
          ),
        );
      },
    );
  }

  String _profitText(PortfolioHoldingModel holding) {
    final currentValue = holding.currentPriceUsd * holding.quantity;
    final cost = holding.buyPrice * holding.quantity;
    final diff = currentValue - cost;
    final sign = diff >= 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(2)}';
  }

  Color _profitColor(PortfolioHoldingModel holding) {
    final currentValue = holding.currentPriceUsd * holding.quantity;
    final cost = holding.buyPrice * holding.quantity;
    return currentValue >= cost ? const Color(0xFF00C896) : Colors.redAccent;
  }
}
