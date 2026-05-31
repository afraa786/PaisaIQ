import 'package:dio/dio.dart';
import '../models/youtube_video_model.dart';

class YoutubeRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://www.googleapis.com/youtube/v3',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<YoutubeVideoModel>> fetchVideos({
    required String query,
    required String apiKey,
    int maxResults = 12,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>('/search', queryParameters: {
      'part': 'snippet',
      'q': query,
      'type': 'video',
      'maxResults': maxResults,
      'relevanceLanguage': 'en',
      'key': apiKey,
    });

    final items = (response.data?['items'] as List<dynamic>?) ?? [];
    return items
        .map((e) => YoutubeVideoModel.fromJson(e as Map<String, dynamic>))
        .where((v) => v.videoId.isNotEmpty)
        .toList();
  }
}
