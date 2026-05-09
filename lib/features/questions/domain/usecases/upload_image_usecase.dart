import '../../../../core/types/either.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';

/// Upload Image Use Case
/// Handles uploading images for questions
class UploadImageUseCase {
  final QuestionRepository _repository;

  UploadImageUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [String] (image URL) on success
  Future<Either<Failure, String>> call(UploadImageParams params) async {
    return await _repository.uploadImage(params);
  }
}

/// Parameters for uploading an image
class UploadImageParams {
  final String imagePath;
  final String folder;
  final int? maxWidth;
  final int? maxHeight;
  final int? quality;

  UploadImageParams({
    required this.imagePath,
    required this.folder,
    this.maxWidth,
    this.maxHeight,
    this.quality,
  });
}
