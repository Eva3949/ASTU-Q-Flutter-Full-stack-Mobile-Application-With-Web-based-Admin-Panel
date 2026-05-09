import 'package:equatable/equatable.dart';

/// Answer Entity
/// Represents an answer to a question in the system
class Answer extends Equatable {
  final int id;
  final String content;
  final int questionId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool authorIsVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int upvotes;
  final int downvotes;
  final bool isUpvoted;
  final bool isDownvoted;
  final bool isBest;
  final List<String> images;

  const Answer({
    required this.id,
    required this.content,
    required this.questionId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.authorIsVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isUpvoted = false,
    this.isDownvoted = false,
    this.isBest = false,
    this.images = const [],
  });

  /// Create a copy of this Answer with updated fields
  Answer copyWith({
    int? id,
    String? content,
    int? questionId,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    bool? authorIsVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? upvotes,
    int? downvotes,
    bool? isUpvoted,
    bool? isDownvoted,
    bool? isBest,
    List<String>? images,
  }) {
    return Answer(
      id: id ?? this.id,
      content: content ?? this.content,
      questionId: questionId ?? this.questionId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorIsVerified: authorIsVerified ?? this.authorIsVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      isDownvoted: isDownvoted ?? this.isDownvoted,
      isBest: isBest ?? this.isBest,
      images: images ?? this.images,
    );
  }

  /// Convert Answer to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'question_id': questionId,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar_url': authorAvatarUrl,
      'author_is_verified': authorIsVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'upvotes': upvotes,
      'downvotes': downvotes,
      'is_upvoted': isUpvoted,
      'is_downvoted': isDownvoted,
      'is_best': isBest,
      'images': images,
    };
  }

  /// Create Answer from JSON
  factory Answer.fromJson(Map<String, dynamic> json) {
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

    return Answer(
      id: toInt(json['id'] ?? json['answer_id']),
      content: toString(json['content']),
      questionId: toInt(json['question_id']),
      authorId: toString(json['author_id']),
      authorName: toString(json['author_name']),
      authorAvatarUrl: json['author_avatar_url']?.toString(),
      authorIsVerified: toBool(json['author_is_verified']),
      createdAt:
          DateTime.tryParse(toString(json['created_at'])) ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(toString(json['updated_at']))
          : null,
      upvotes: toInt(json['upvotes']),
      downvotes: toInt(json['downvotes']),
      isUpvoted: toBool(json['is_upvoted']),
      isDownvoted: toBool(json['is_downvoted']),
      isBest: toBool(json['is_best']),
      images: json['images'] is List ? List<String>.from(json['images']) : [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    content,
    questionId,
    authorId,
    authorName,
    authorAvatarUrl,
    authorIsVerified,
    createdAt,
    updatedAt,
    upvotes,
    downvotes,
    isUpvoted,
    isDownvoted,
    isBest,
    images,
  ];

  /// Get vote score (upvotes - downvotes)
  int get voteScore => upvotes - downvotes;

  /// Check if answer has any images
  bool get hasImages => images.isNotEmpty;

  @override
  String toString() {
    return 'Answer(id: $id, questionId: $questionId, author: $authorName, isBest: $isBest)';
  }
}
