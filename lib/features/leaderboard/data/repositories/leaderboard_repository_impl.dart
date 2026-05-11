import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/leaderboard_user.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/types/either.dart';
import 'mock_leaderboard_repository.dart';
import 'dart:io';


class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final DioClient _dioClient;
  final Logger _logger;
  final MockLeaderboardRepository _mockRepository;

  LeaderboardRepositoryImpl(this._dioClient, this._logger)
    : _mockRepository = MockLeaderboardRepository();

  @override
  Future<Either<Failure, List<LeaderboardUser>>> getLeaderboard({
    required int page,
    required int limit,
    required String timeFilter,
    required String category,
  }) async {
    try {
      _logger.d(
        'Fetching leaderboard: page=$page, limit=$limit, filter=$timeFilter, category=$category',
      );

      final response = await _dioClient.get(
        'https://evadevstudio.com/sami/leaderboard.php',
        queryParameters: {
          'page': page,
          'limit': limit,
          'time_filter': timeFilter,
          'category': category,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data['success'] == true) {
          final usersList = data['users'] as List?;
          if (usersList == null) {
            return Either.left(ServerFailure('No users data received'));
          }

          try {
            final users = usersList.map((userJson) {
              if (userJson is! Map<String, dynamic>) {
                _logger.e(
                  'Invalid user data format: expected Map, got ${userJson.runtimeType}',
                );
                throw Exception('Invalid user data format');
              }
              return LeaderboardUser.fromJson(userJson);
            }).toList();
            return Either.right(users);
          } catch (e, stackTrace) {
            _logger.e(
              'Error parsing user data',
              error: e,
              stackTrace: stackTrace,
            );
            return Either.left(ServerFailure('Error parsing user data: $e'));
          }
        } else {
          return Either.left(
            ServerFailure(data['message'] ?? 'Failed to load leaderboard'),
          );
        }
      } else {
        return Either.left(
          ServerFailure('Server error: ${response.statusCode}'),
        );
      }
    } on DioException catch (e) {
      _logger.e('Dio error fetching leaderboard', error: e);
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.error is SocketException) {
        _logger.w('Server unreachable, falling back to mock data');
        // Fallback to mock data when server is unreachable
        return await _mockRepository.getLeaderboard(
          page: page,
          limit: limit,
          timeFilter: timeFilter,
          category: category,
        );
      }
      return Either.left(ServerFailure('Server error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error fetching leaderboard',
        error: e,
        stackTrace: stackTrace,
      );
      return Either.left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getUserRank({
    required int userId,
    required String timeFilter,
    required String category,
  }) async {
    try {
      _logger.d(
        'Fetching user rank: userId=$userId, filter=$timeFilter, category=$category',
      );

      final response = await _dioClient.get(
        'https://evadevstudio.com/sami/get_user_rank.php',
        queryParameters: {
          'user_id': userId,
          'time_filter': timeFilter,
          'category': category,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data['success'] == true) {
          return Either.right(data['rank'] as int);
        } else {
          return Either.left(
            ServerFailure(data['message'] ?? 'Failed to get user rank'),
          );
        }
      } else {
        return Either.left(
          ServerFailure('Server error: ${response.statusCode}'),
        );
      }
    } on DioException catch (e) {
      _logger.e('Dio error fetching user rank', error: e);
      return Either.left(ServerFailure('Network error: ${e.message}'));
    } catch (e) {
      _logger.e('Unexpected error fetching user rank', error: e);
      return Either.left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getLeaderboardStats({
    required String timeFilter,
    required String category,
  }) async {
    try {
      _logger.d(
        'Fetching leaderboard stats: filter=$timeFilter, category=$category',
      );

      final response = await _dioClient.get(
        'https://evadevstudio.com/sami/leaderboard_stats.php',
        queryParameters: {'time_filter': timeFilter, 'category': category},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data['success'] == true) {
          return Either.right(data['stats'] as Map<String, dynamic>);
        } else {
          return Either.left(
            ServerFailure(data['message'] ?? 'Failed to get leaderboard stats'),
          );
        }
      } else {
        return Either.left(
          ServerFailure('Server error: ${response.statusCode}'),
        );
      }
    } on DioException catch (e) {
      _logger.e('Dio error fetching leaderboard stats', error: e);
      return Either.left(ServerFailure('Network error: ${e.message}'));
    } catch (e) {
      _logger.e('Unexpected error fetching leaderboard stats', error: e);
      return Either.left(ServerFailure('An unexpected error occurred'));
    }
  }
}
