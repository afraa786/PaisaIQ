import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final youtubeApiKeyProvider =
    StateNotifierProvider<YoutubeApiKeyNotifier, String>(
  (ref) => YoutubeApiKeyNotifier(),
);

class YoutubeApiKeyNotifier extends StateNotifier<String> {
  YoutubeApiKeyNotifier() : super('') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('youtubeApiKey') ?? '';
  }

  Future<void> update(String key) async {
    state = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('youtubeApiKey', state);
  }
}
