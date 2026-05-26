import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/alert_providers.dart';
import '../data/repositories/alert_repository.dart';
import '../data/models/alert_model.dart';
import '../widgets/loading_shimmer.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final _coinController = TextEditingController();
  final _priceController = TextEditingController();
  final _emailController = TextEditingController();
  String _condition = 'ABOVE';

  @override
  void dispose() {
    _coinController.dispose();
    _priceController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createAlert(BuildContext context) async {
    final coinId = _coinController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final email = _emailController.text.trim();
    if (coinId.isEmpty || price == null || email.isEmpty) return;

    try {
      await ref.read(alertRepositoryProvider).createAlert(
            coinId: coinId,
            condition: _condition,
            targetPrice: price,
            email: email,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert created.')));
      }
      ref.refresh(alertsProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _deleteAlert(String id) async {
    try {
      await ref.read(alertRepositoryProvider).deleteAlert(id);
      ref.refresh(alertsProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Create Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    TextField(controller: _coinController, decoration: const InputDecoration(labelText: 'Coin ID', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Price', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _condition,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'ABOVE', child: Text('ABOVE')),
                        DropdownMenuItem(value: 'BELOW', child: Text('BELOW')),
                      ],
                      onChanged: (value) => setState(() => _condition = value ?? 'ABOVE'),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => _createAlert(context), child: const Text('Save Alert')),
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
        child: alerts.when(
          data: (items) {
            if (items.isEmpty) {
              return _buildEmptyState('No alerts configured. Create one with the + button.');
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alert = items[index];
                return Dismissible(
                  key: ValueKey(alert.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteAlert(alert.id),
                  background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete, color: Colors.white)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert.coinId.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text('${alert.condition} ${alert.targetPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white60)),
                          ],
                        ),
                        IconButton(onPressed: () => _deleteAlert(alert.id), icon: const Icon(Icons.delete_outline, color: Colors.white54)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const LoadingShimmer(),
          error: (error, stack) => _buildErrorCard(error.toString()),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Text(message, style: const TextStyle(color: Colors.white60), textAlign: TextAlign.center));
  }

  Widget _buildErrorCard(String message) {
    return Center(child: Text(message, style: const TextStyle(color: Colors.white60), textAlign: TextAlign.center));
  }
}
