import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../data/providers/youtube_providers.dart';
import '../data/models/youtube_video_model.dart';
import '../services/youtube_key_provider.dart';
import '../widgets/loading_shimmer.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiKey = ref.watch(youtubeApiKeyProvider);
    final coinCtx = ref.watch(learnCoinContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Learn'),
            if (coinCtx != null)
              Text('Showing: $coinCtx videos',
                  style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
        actions: [
          if (coinCtx != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Clear coin filter',
              onPressed: () =>
                  ref.read(learnCoinContextProvider.notifier).state = null,
            ),
        ],
      ),
      body: apiKey.isEmpty
          ? _NoKeyBanner()
          : const _VideoContent(),
    );
  }
}

// ── No API key state ──────────────────────────────────────────────────────────

class _NoKeyBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_outline,
                size: 64, color: Colors.white24),
            const SizedBox(height: 20),
            const Text('Add YouTube API Key to load videos',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 10),
            const Text(
                'Go to Settings → paste your YouTube Data API v3 key.\n'
                'Get a free key at console.cloud.google.com\n'
                '(free tier: 100 searches/day)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => html.window
                  .open('https://console.cloud.google.com/apis/library/youtube.googleapis.com', '_blank'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open Google Cloud Console'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main video content ────────────────────────────────────────────────────────

class _VideoContent extends ConsumerWidget {
  const _VideoContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTopic = ref.watch(selectedLearnTopicProvider);
    final videos = ref.watch(youtubeVideosProvider);

    return Column(
      children: [
        // Topic chips
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: learnTopics.keys.map((topic) {
              final selected = topic == selectedTopic;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(topic),
                  selected: selected,
                  onSelected: (_) {
                    ref.read(selectedLearnTopicProvider.notifier).state = topic;
                    // Clear coin context when user picks a specific topic
                    if (topic != 'All') {
                      ref.read(learnCoinContextProvider.notifier).state = null;
                    }
                  },
                  selectedColor: const Color(0xFF00C896),
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: const Color(0xFF161B22),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  side: BorderSide(
                      color: selected
                          ? const Color(0xFF00C896)
                          : Colors.white12),
                ),
              );
            }).toList(),
          ),
        ),

        // Video grid
        Expanded(
          child: videos.when(
            loading: () => const LoadingShimmer(),
            error: (e, _) => Center(
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 40),
                const SizedBox(height: 12),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 16),
                const Text(
                    'Check your YouTube API key in Settings.\n'
                    'Make sure YouTube Data API v3 is enabled.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ]),
            )),
            data: (list) {
              if (list.isEmpty) {
                return const Center(
                    child: Text('No videos found.',
                        style: TextStyle(color: Colors.white54)));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) => _VideoCard(video: list[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Video card ────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});
  final YoutubeVideoModel video;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => html.window.open(video.youtubeUrl, '_blank'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  video.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          video.thumbnailUrl,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 110,
                            color: const Color(0xFF0D1117),
                            child: const Icon(Icons.video_library,
                                color: Colors.white24, size: 36),
                          ),
                        )
                      : Container(
                          height: 110,
                          color: const Color(0xFF0D1117),
                          child: const Icon(Icons.video_library,
                              color: Colors.white24, size: 36),
                        ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            // Title + channel
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video.channelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF00C896)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
