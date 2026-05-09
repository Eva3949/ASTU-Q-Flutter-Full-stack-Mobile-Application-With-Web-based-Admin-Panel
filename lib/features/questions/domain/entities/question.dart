import 'package:equatable/equatable.dart';

/// Question Entity
/// Represents a question in the system
class Question extends Equatable {
  final int id;
  final String title;
  final String content;
  final String subject;
  final String authorId;
  final String authorName;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int viewCount;
  final int answerCount;
  final bool isResolved;
  final List<String> tags;
  final String? acceptedAnswerId;
  final String? authorAvatarUrl;
  final bool authorIsVerified;
  final int upvotes;
  final int downvotes;
  final bool isUpvoted;
  final bool isDownvoted;
  final bool isBookmarked;
  final String status;

  const Question({
    required this.id,
    required this.title,
    required this.content,
    required this.subject,
    required this.authorId,
    required this.authorName,
    this.images = const [],
    required this.createdAt,
    this.updatedAt,
    this.viewCount = 0,
    this.answerCount = 0,
    this.isResolved = false,
    this.tags = const [],
    this.acceptedAnswerId,
    this.authorAvatarUrl,
    this.authorIsVerified = false,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isUpvoted = false,
    this.isDownvoted = false,
    this.isBookmarked = false,
    this.status = 'pending',
  });

  /// Create a copy of this Question with updated fields
  Question copyWith({
    int? id,
    String? title,
    String? content,
    String? subject,
    String? authorId,
    String? authorName,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    int? answerCount,
    bool? isResolved,
    List<String>? tags,
    String? acceptedAnswerId,
    String? authorAvatarUrl,
    bool? authorIsVerified,
    int? upvotes,
    int? downvotes,
    bool? isUpvoted,
    bool? isDownvoted,
    bool? isBookmarked,
    String? status,
  }) {
    return Question(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      subject: subject ?? this.subject,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      answerCount: answerCount ?? this.answerCount,
      isResolved: isResolved ?? this.isResolved,
      tags: tags ?? this.tags,
      acceptedAnswerId: acceptedAnswerId ?? this.acceptedAnswerId,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorIsVerified: authorIsVerified ?? this.authorIsVerified,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      isDownvoted: isDownvoted ?? this.isDownvoted,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      status: status ?? this.status,
    );
  }

  /// Convert Question to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'subject': subject,
      'author_id': authorId,
      'author_name': authorName,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'view_count': viewCount,
      'answer_count': answerCount,
      'is_resolved': isResolved,
      'tags': tags,
      'accepted_answer_id': acceptedAnswerId,
      'author_avatar_url': authorAvatarUrl,
      'author_is_verified': authorIsVerified,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'is_upvoted': isUpvoted,
      'is_downvoted': isDownvoted,
      'is_bookmarked': isBookmarked,
      'status': status,
    };
  }

  /// Create Question from JSON
  factory Question.fromJson(Map<String, dynamic> json) {
    // Safely parse numeric fields that might come as strings or be null
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

    return Question(
      id: toInt(json['id'] ?? json['question_id']),
      title: toString(json['title']),
      content: toString(json['content']),
      subject: toString(json['subject']),
      authorId: toString(json['author_id']),
      authorName: toString(json['author_name']),
      images: json['images'] is List ? List<String>.from(json['images']) : [],
      createdAt:
          DateTime.tryParse(toString(json['created_at'])) ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(toString(json['updated_at']))
          : null,
      viewCount: toInt(json['view_count']),
      answerCount: toInt(json['answer_count']),
      isResolved: toBool(json['is_resolved']),
      tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
      acceptedAnswerId: json['accepted_answer_id']?.toString(),
      authorAvatarUrl: json['author_avatar_url']?.toString(),
      authorIsVerified: toBool(json['author_is_verified']),
      upvotes: toInt(json['upvotes']),
      downvotes: toInt(json['downvotes']),
      isUpvoted: toBool(json['is_upvoted']),
      isDownvoted: toBool(json['is_downvoted']),
      isBookmarked: toBool(json['is_bookmarked']),
      status: toString(json['status'], 'pending'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    subject,
    authorId,
    authorName,
    images,
    createdAt,
    updatedAt,
    viewCount,
    answerCount,
    isResolved,
    tags,
    acceptedAnswerId,
    authorAvatarUrl,
    authorIsVerified,
    upvotes,
    downvotes,
    isUpvoted,
    isDownvoted,
    isBookmarked,
    status,
  ];

  /// Check if question has an accepted answer
  bool get hasAcceptedAnswer => acceptedAnswerId != null;

  @override
  String toString() {
    return 'Question(id: $id, title: $title, subject: $subject, author: $authorName)';
  }
}
