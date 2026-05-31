import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/youtube_video_model.dart';
import '../repositories/youtube_repository.dart';
import '../../services/youtube_key_provider.dart';

// Queries per category chip
const Map<String, String> learnTopics = {
  'All':      'cryptocurrency investing explained india 2025',
  'Bitcoin':  'bitcoin explained beginner 2025',
  'Ethereum': 'ethereum how it works explained',
  'Tax':      'crypto tax india itr schedule vda 2025',
  'Beginner': 'how to start crypto investing india beginner',
  'DeFi':     'defi decentralized finance explained',
  'Trading':  'crypto trading strategy india technical analysis',
  'NFT':      'nft explained india how to buy',
};

final youtubeRepoProvider = Provider((_) => YoutubeRepository());

// Selected topic chip
final selectedLearnTopicProvider = StateProvider<String>((ref) => 'All');

// Active coin context — set by coin detail screen so Learn tab shows coin videos
final learnCoinContextProvider = StateProvider<String?>((ref) => null);

final youtubeVideosProvider =
    FutureProvider.autoDispose<List<YoutubeVideoModel>>((ref) async {
  final apiKey = ref.watch(youtubeApiKeyProvider);
  if (apiKey.isEmpty) return [];

  final coinCtx = ref.watch(learnCoinContextProvider);
  final topic = ref.watch(selectedLearnTopicProvider);

  // If a coin is in context and topic is All, search for that coin
  final query = (coinCtx != null && topic == 'All')
      ? '$coinCtx cryptocurrency explained india'
      : learnTopics[topic] ?? learnTopics['All']!;

  return ref.watch(youtubeRepoProvider).fetchVideos(
        query: query,
        apiKey: apiKey,
      );
});
