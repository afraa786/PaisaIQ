import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    final current = ref.read(apiBaseUrlProvider);
    _urlController.text = current;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    await ref.read(apiBaseUrlProvider.notifier).updateBaseUrl(_urlController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Base URL saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ref.watch(apiBaseUrlProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('API Base URL', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: _saveUrl, child: const Text('Save')),
            const SizedBox(height: 24),
            const Text('About', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text('AlphaEdge is a Flutter cryptocurrency intelligence frontend built for real-time price tracking, signal analysis, price alerts, and portfolio management.', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 24),
            Text('Current base URL: $baseUrl', style: const TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}
