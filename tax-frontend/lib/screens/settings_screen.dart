import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/youtube_key_provider.dart';
import '../utils/theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _ytController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ref.read(apiBaseUrlProvider));
    _ytController  = TextEditingController(text: ref.read(youtubeApiKeyProvider));
  }

  @override
  void dispose() {
    _urlController.dispose();
    _ytController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(apiBaseUrlProvider.notifier).updateBaseUrl(_urlController.text);
    await ref.read(youtubeApiKeyProvider.notifier).update(_ytController.text);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('BACKEND URL'),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                  hintText: 'http://localhost:8080'),
            ),
            const SizedBox(height: 24),

            _label('YOUTUBE API KEY'),
            const SizedBox(height: 4),
            const Text(
              'Required for the Learn screen. Get a free key at console.cloud.google.com → YouTube Data API v3.',
              style: TextStyle(color: kGray2, fontSize: 11),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ytController,
              obscureText: true,
              decoration: const InputDecoration(
                  hintText: 'AIza...'),
            ),
            const SizedBox(height: 28),

            ElevatedButton(onPressed: _save, child: const Text('SAVE')),

            const SizedBox(height: 32),
            const Divider(color: kBorder),
            const SizedBox(height: 16),
            _label('ABOUT'),
            const SizedBox(height: 10),
            const Text(
              'AlphaEdge — Indian crypto intelligence platform.\n'
              'Real-time prices · Technical signals · Tax calculator · Portfolio P&L.',
              style: TextStyle(color: kGray2, fontSize: 12, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: kGray1),
      );
}
