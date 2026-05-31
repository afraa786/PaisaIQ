class YoutubeVideoModel {
  final String videoId;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String publishedAt;
  final String description;

  YoutubeVideoModel({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.publishedAt,
    required this.description,
  });

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';

  factory YoutubeVideoModel.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final id = json['id'] as Map<String, dynamic>? ?? {};
    final thumbs = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final medium = thumbs['medium'] as Map<String, dynamic>? ??
        thumbs['default'] as Map<String, dynamic>? ?? {};

    return YoutubeVideoModel(
      videoId: (id['videoId'] ?? '') as String,
      title: (snippet['title'] ?? 'No title') as String,
      channelName: (snippet['channelTitle'] ?? '') as String,
      thumbnailUrl: (medium['url'] ?? '') as String,
      publishedAt: (snippet['publishedAt'] ?? '') as String,
      description: (snippet['description'] ?? '') as String,
    );
  }
}
