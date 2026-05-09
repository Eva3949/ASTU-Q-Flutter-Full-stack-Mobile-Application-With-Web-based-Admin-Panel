/// Notification Entity
/// Represents a notification in the system
class Notification {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final int? relatedId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? readAt;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.relatedId,
    this.metadata,
    required this.createdAt,
    this.readAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    // Safely parse numeric fields
    int toInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Safely parse string fields
    String toString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      return value.toString();
    }

    // Safely parse boolean fields
    bool toBool(dynamic value, [bool defaultValue = false]) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return defaultValue;
    }

    return Notification(
      id: toInt(json['id'] ?? json['notification_id']),
      title: toString(json['title']),
      message: toString(json['message']),
      type: toString(json['type']),
      isRead: toBool(json['is_read'] ?? json['isRead']),
      relatedId: json['related_id'] != null ? toInt(json['related_id']) : null,
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] : null,
      createdAt: DateTime.tryParse(toString(json['created_at'] ?? json['createdAt'])) ?? DateTime.now(),
      readAt: json['read_at'] != null && json['read_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['read_at'].toString())
          : json['readAt'] != null && json['readAt'].toString().isNotEmpty
              ? DateTime.tryParse(json['readAt'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'relatedId': relatedId,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  Notification copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    int? relatedId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Notification(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}
