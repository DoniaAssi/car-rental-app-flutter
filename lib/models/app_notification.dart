class AppNotification {
  final String id; // ✅ unique key (dedup)
  final String title;
  final String body;
  final String type; // REMINDER / RENT_END / STATUS / SYSTEM
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.read,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    return AppNotification(
      id: (j["id"] ?? "").toString(),
      title: (j["title"] ?? "").toString(),
      body: (j["body"] ?? "").toString(),
      type: (j["type"] ?? "").toString(),
      createdAt: DateTime.tryParse((j["createdAt"] ?? "").toString()) ?? DateTime.now(),
      read: (j["read"] ?? false) == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "body": body,
      "type": type,
      "createdAt": createdAt.toIso8601String(),
      "read": read,
    };
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }
}
