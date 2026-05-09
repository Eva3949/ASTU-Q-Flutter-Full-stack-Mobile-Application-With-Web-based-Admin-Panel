import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/types/either.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/answer.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../core/utils/logger.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final DioClient _dioClient;
  final SecureStorage _secureStorage;
  final Logger _logger;
  static const String _baseUrl = 'https://evadevstudio.com/sami';

  ProfileRepositoryImpl(this._dioClient, this._secureStorage, this._logger);

  @override
  Future<Either<Failure, UserProfile>> getUserProfile({int? userId}) async {
    try {
      final storageId = await _secureStorage.getUserId();
      _logger.d(
        'ProfileRepository - ID from Storage: $storageId, ID from parameter: $userId',
      );

      final targetUserId = userId?.toString() ?? storageId;

      if (targetUserId == null) {
        _logger.e('ProfileRepository - Target User ID is NULL');
        return Either.left(UnauthorizedFailure('User ID not found'));
      }

      _logger.d('Getting user profile for user: $targetUserId');
      final response = await _dioClient.get(
        '$_baseUrl/get_user.php',
        queryParameters: {'user_id': targetUserId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final profile = UserProfile.fromJson(response.data['data']);
        return Either.right(profile);
      } else {
        return Either.left(
          ServerFailure(response.data['message'] ?? 'Failed to get profile'),
        );
      }
    } catch (e) {
      _logger.e('Error getting user profile', error: e);
      return Either.left(
        ServerFailure('An error occurred while getting profile'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Question>>> getUserQuestions({
    required int userId,
    required int page,
    required int limit,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      _logger.d('Getting user questions for user: $userId, page: $page');
      final currentUserId = await _secureStorage.getUserId();

      final response = await _dioClient.get(
        '$_baseUrl/get_questions_by_user.php',
        queryParameters: {
          'user_id': userId,
          'page': page,
          'limit': limit,
          'viewer_id': currentUserId,
          '_t':
              DateTime.now().millisecondsSinceEpoch, // Cache-busting timestamp
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dynamic data = response.data['data'];
        final List<dynamic> questionsJson =
            (data is Map && data.containsKey('questions'))
            ? data['questions']
            : (data is List ? data : []);

        final questions = questionsJson
            .map((json) => Question.fromJson(json))
            .toList();
        return Either.right(questions);
      } else {
        return Either.left(
          ServerFailure(
            response.data['message'] ?? 'Failed to get user questions',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error getting user questions', error: e);
      return Either.left(ServerFailure('An error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<Answer>>> getUserAnswers({
    required int userId,
    required int page,
    required int limit,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      _logger.d('Getting user answers for user: $userId, page: $page');
      final currentUserId = await _secureStorage.getUserId();

      final response = await _dioClient.get(
        '$_baseUrl/get_answers.php',
        queryParameters: {
          'user_id': userId,
          'page': page,
          'limit': limit,
          'viewer_id': currentUserId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dynamic data = response.data['data'];
        final List<dynamic> answersJson =
            (data is Map && data.containsKey('answers'))
            ? data['answers']
            : (data is List ? data : []);

        final answers = answersJson
            .map((json) => Answer.fromJson(json))
            .toList();
        return Either.right(answers);
      } else {
        return Either.left(
          ServerFailure(
            response.data['message'] ?? 'Failed to get user answers',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error getting user answers', error: e);
      return Either.left(ServerFailure('An error occurred'));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    await _secureStorage.clearAll();
    return Either.right(true);
  }
}
