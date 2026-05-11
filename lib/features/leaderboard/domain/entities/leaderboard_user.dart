/// Leaderboard User Entity
/// Represents a user in the leaderboard system
class LeaderboardUser {
  final int id;
  final String name;
  final String? avatarUrl;
  final int points;
  final int level;
  final int rank;
  final List<String> badges;
  final int questions;
  final int answers;
  final DateTime? lastActiveAt;

  const LeaderboardUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.points,
    required this.level,
    required this.rank,
    this.badges = const [],
    this.questions = 0,
    this.answers = 0,
    this.lastActiveAt,
  });

  /// Create LeaderboardUser from JSON
  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    String? parseString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    return LeaderboardUser(
      id: parseInt(json['id']),
      name: parseString(json['name'] ?? json['username']) ?? '',
      avatarUrl:
          parseString(json['avatarUrl']) ??
          parseString(json['avatar_url']) ??
          parseString(json['avatar']),
      points: parseInt(json['points']),
      level: parseInt(json['level'] ?? 1),
      rank: parseInt(json['rank']),
      badges: json['badge'] != null
          ? [parseString(json['badge']) ?? '']
          : (json['badges'] as List<dynamic>?)
                    ?.map((e) => parseString(e) ?? '')
                    .toList() ??
                [],
      questions: parseInt(json['questionsCount'] ?? json['questions']),
      answers: parseInt(json['answersCount'] ?? json['answers']),
      lastActiveAt: json['joinedAt'] != null
          ? DateTime.tryParse(parseString(json['joinedAt']) ?? '')
          : json['last_active_at'] != null
          ? DateTime.tryParse(parseString(json['last_active_at']) ?? '')
          : json['last_active'] != null
          ? DateTime.tryParse(parseString(json['last_active']) ?? '')
          : null,
    );
  }

  /// Convert LeaderboardUser to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'points': points,
      'level': level,
      'rank': rank,
      'badges': badges,
      'questions': questions,
      'answers': answers,
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated values
  LeaderboardUser copyWith({
    int? id,
    String? name,
    String? avatarUrl,
    int? points,
    int? level,
    int? rank,
    List<String>? badges,
    int? questions,
    int? answers,
    DateTime? lastActiveAt,
  }) {
    return LeaderboardUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      level: level ?? this.level,
      rank: rank ?? this.rank,
      badges: badges ?? this.badges,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardUser &&
        other.id == id &&
        other.name == name &&
        other.avatarUrl == avatarUrl &&
        other.points == points &&
        other.level == level &&
        other.rank == rank &&
        other.badges == badges &&
        other.questions == questions &&
        other.answers == answers &&
        other.lastActiveAt == lastActiveAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      avatarUrl,
      points,
      level,
      rank,
      badges,
      questions,
      answers,
      lastActiveAt,
    );
  }

  @override
  String toString() {
    return 'LeaderboardUser(id: $id, name: $name, points: $points, level: $level, rank: $rank)';
  }
}
