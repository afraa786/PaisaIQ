import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/portfolio_model.dart';
import '../data/models/portfolio_summary_model.dart';
import '../data/providers/portfolio_providers.dart';
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
      if (context.mounted) Navigator.of(context).pop();
      ref.invalidate(portfoliosProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
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
      if (context.mounted) Navigator.of(context).pop();
      ref.invalidate(portfoliosProvider);
      ref.invalidate(portfolioSummaryProvider(portfolioId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolios = ref.watch(portfoliosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePortfolioSheet(context),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: portfolios.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                  child: Text('No portfolios yet. Tap + to create one.',
                      style: TextStyle(color: Colors.white60)));
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) =>
                  _PortfolioCard(portfolio: items[index]),
            );
          },
          loading: () => const LoadingShimmer(),
          error: (error, _) => Center(
              child: Text('Failed to load portfolios: $error',
                  style: const TextStyle(color: Colors.white60))),
        ),
      ),
    );
  }

  void _showCreatePortfolioSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New Portfolio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
                controller: _portfolioController,
                decoration: const InputDecoration(
                    labelText: 'Portfolio Name',
                    border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => _createPortfolio(context),
                child: const Text('Create')),
          ],
        ),
      ),
    );
  }

  void _showAddHoldingSheet(BuildContext context, String portfolioId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Holding',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
                controller: _coinController,
                decoration: const InputDecoration(
                    labelText: 'Coin ID (e.g. bitcoin)',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Quantity', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _buyPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Buy Price (USD)',
                    border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => _addHolding(context, portfolioId),
                child: const Text('Add')),
          ],
        ),
      ),
    );
  }
}

// ─── Portfolio card with summary loaded on expand ────────────────────────────

class _PortfolioCard extends ConsumerStatefulWidget {
  const _PortfolioCard({required this.portfolio});
  final PortfolioModel portfolio;

  @override
  ConsumerState<_PortfolioCard> createState() => _PortfolioCardState();
}

class _PortfolioCardState extends ConsumerState<_PortfolioCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final summary = _expanded
        ? ref.watch(portfolioSummaryProvider(widget.portfolio.id))
        : null;

    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.portfolio.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
                '${widget.portfolio.holdings.length} holdings',
                style: const TextStyle(color: Colors.white60)),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded) ...[
            const Divider(color: Colors.white12, height: 1),
            summary == null
                ? const SizedBox.shrink()
                : summary.when(
                    loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator()),
                    error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Error loading summary: $e',
                            style:
                                const TextStyle(color: Colors.redAccent))),
                    data: (s) => _SummaryBody(
                        summary: s, portfolioId: widget.portfolio.id),
                  ),
          ],
        ],
      ),
    );
  }
}

// ─── Summary body ─────────────────────────────────────────────────────────────

class _SummaryBody extends ConsumerWidget {
  const _SummaryBody({required this.summary, required this.portfolioId});
  final PortfolioSummaryModel summary;
  final String portfolioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pnlColor =
        summary.totalPnlInr >= 0 ? const Color(0xFF00C896) : Colors.redAccent;
    final dayColor =
        summary.dayChangeInr >= 0 ? const Color(0xFF00C896) : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Portfolio totals banner ──
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Value',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(formatInr(summary.totalValueInr),
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(children: [
                _StatChip(
                    label: 'P&L',
                    value: formatInr(summary.totalPnlInr),
                    sub: formatChange(summary.totalPnlPercent),
                    color: pnlColor),
                const SizedBox(width: 12),
                _StatChip(
                    label: 'Today',
                    value: formatInr(summary.dayChangeInr),
                    sub: formatChange(summary.dayChangePercent),
                    color: dayColor),
              ]),
              if (summary.bestPerformer != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.trending_up,
                      size: 14, color: Color(0xFF00C896)),
                  const SizedBox(width: 4),
                  Text(
                      'Best: ${summary.bestPerformer} (${formatChange(summary.bestPerformerGain)})',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF00C896))),
                  const SizedBox(width: 16),
                  const Icon(Icons.trending_down,
                      size: 14, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text(
                      'Worst: ${summary.worstPerformer} (${formatChange(summary.worstPerformerLoss)})',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.redAccent)),
                ]),
              ],
            ],
          ),
        ),

        // ── Per-holding rows ──
        ...summary.holdings.map((h) => _HoldingRow(holding: h)),

        // ── Add holding button ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ElevatedButton.icon(
            onPressed: () {
              final screen = context
                  .findAncestorStateOfType<_PortfolioScreenState>();
              screen?._showAddHoldingSheet(context, portfolioId);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Holding'),
          ),
        ),
      ],
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({required this.holding});
  final HoldingPerformanceModel holding;

  @override
  Widget build(BuildContext context) {
    final pnlColor =
        holding.pnlInr >= 0 ? const Color(0xFF00C896) : Colors.redAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(holding.symbol.toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 3),
            Text('${holding.quantity} × ${formatInr(holding.currentPriceInr)}',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatInr(holding.currentValueInr),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 3),
            Text(
                '${holding.pnlInr >= 0 ? '+' : ''}${formatInr(holding.pnlInr)} (${formatChange(holding.pnlPercent)})',
                style: TextStyle(color: pnlColor, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label,
      required this.value,
      required this.sub,
      required this.color});
  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      Text(sub, style: TextStyle(color: color, fontSize: 11)),
    ]);
  }
}
