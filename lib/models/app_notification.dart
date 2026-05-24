class AppNotification {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'info',
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id:        json['id'] ?? 0,
        title:     json['title'] ?? '-',
        body:      json['body'] ?? '-',
        type:      json['type'] ?? 'info',
        isRead:    json['is_read'] == true,
        createdAt: json['created_at'],
      );
}
