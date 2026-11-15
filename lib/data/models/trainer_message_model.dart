enum MessageSender { user, trainer }

class TrainerSource {
  final String title;
  final String name;
  final String url;

  const TrainerSource({
    required this.title,
    required this.name,
    required this.url,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'name': name,
        'url': url,
      };

  factory TrainerSource.fromMap(Map<String, dynamic> map) => TrainerSource(
        title: map['title'] ?? '',
        name: map['name'] ?? '',
        url: map['url'] ?? '',
      );
}

class TrainerMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isError;
  final List<TrainerSource> sources;
  final bool isPersonalDataBased;

  const TrainerMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isError = false,
    this.sources = const [],
    this.isPersonalDataBased = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'sender': sender.name,
      'timestamp': timestamp.toIso8601String(),
      'isError': isError,
      'sources': sources.map((s) => s.toMap()).toList(),
      'isPersonalDataBased': isPersonalDataBased,
    };
  }

  factory TrainerMessage.fromMap(Map<String, dynamic> map) {
    return TrainerMessage(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      sender:
          map['sender'] == 'user' ? MessageSender.user : MessageSender.trainer,
      timestamp:
          DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      isError: map['isError'] ?? false,
      sources: (map['sources'] as List<dynamic>?)
              ?.map((s) => TrainerSource.fromMap(s as Map<String, dynamic>))
              .toList() ??
          const [],
      isPersonalDataBased: map['isPersonalDataBased'] ?? false,
    );
  }
}
