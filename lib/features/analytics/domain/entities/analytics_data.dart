import 'package:equatable/equatable.dart';

/// Analytics Overview Entity
class AnalyticsOverview {
  final int totalQuestions;
  final int totalAnswers;
  final int totalUsers;
  final double averageResponseTime;
  final int todayActivity;

  const AnalyticsOverview({
    required this.totalQuestions,
    required this.totalAnswers,
    required this.totalUsers,
    required this.averageResponseTime,
    required this.todayActivity,
  });
}

/// Daily Activity Data Entity
class DailyActivityData extends Equatable {
  final DateTime date;
  final int questionsCount;
  final int answersCount;

  const DailyActivityData({
    required this.date,
    required this.questionsCount,
    required this.answersCount,
  });

  @override
  List<Object?> get props => [date, questionsCount, answersCount];
}

/// Subject Distribution Data Entity
class SubjectDistributionData extends Equatable {
  final String subject;
  final int count;

  const SubjectDistributionData({required this.subject, required this.count});

  @override
  List<Object?> get props => [subject, count];
}

/// User Growth Data Entity
class UserGrowthData extends Equatable {
  final DateTime date;
  final int userCount;

  const UserGrowthData({required this.date, required this.userCount});

  @override
  List<Object?> get props => [date, userCount];
}

/// Response Time Data Entity
class ResponseTimeData extends Equatable {
  final int hour;
  final double averageTime;

  const ResponseTimeData({required this.hour, required this.averageTime});

  @override
  List<Object?> get props => [hour, averageTime];
}

/// Top User Data Entity
class TopUserData extends Equatable {
  final String userId;
  final String username;
  final String? email;
  final int questionsCount;
  final int answersCount;
  final double averageResponseTime;
  final DateTime lastActive;

  const TopUserData({
    required this.userId,
    required this.username,
    this.email,
    required this.questionsCount,
    required this.answersCount,
    required this.averageResponseTime,
    required this.lastActive,
  });

  @override
  List<Object?> get props => [
    userId,
    username,
    email,
    questionsCount,
    answersCount,
    averageResponseTime,
    lastActive,
  ];
}
