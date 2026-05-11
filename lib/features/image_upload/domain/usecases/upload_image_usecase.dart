import 'dart:io';
import 'dart:typed_data';
import '../../../../core/types/either.dart';
import '../repositories/image_upload_repository.dart';
import '../../../../core/errors/failures.dart';

/// Upload Image Use Case
/// Handles image upload logic with progress tracking
class UploadImageUseCase {
  final ImageUploadRepository _repository;

  UploadImageUseCase(this._repository);

  /// Execute image upload
  Future<Either<Failure, String>> call(UploadImageParams params) async {
    if (params.imageFile == null && params.imageBytes == null) {
      return Either.left(ValidationFailure('No image provided'));
    }

    if (params.imageFile != null) {
      final file = params.imageFile!;
      // Validate file size (max 10MB)
      if (file.lengthSync() > 10 * 1024 * 1024) {
        return Either.left(
          ValidationFailure('Image size must be less than 10MB'),
        );
      }
      // Validate minimum size (at least 1KB)
      if (file.lengthSync() < 1024) {
        return Either.left(ValidationFailure('Image is too small'));
      }
    } else if (params.imageBytes != null) {
      final bytes = params.imageBytes!;
      // Validate bytes size (max 10MB)
      if (bytes.length > 10 * 1024 * 1024) {
        return Either.left(
          ValidationFailure('Image size must be less than 10MB'),
        );
      }
      // Validate minimum size (at least 1KB)
      if (bytes.length < 1024) {
        return Either.left(ValidationFailure('Image is too small'));
      }
    }

    return await _repository.uploadImage(
      imageFile: params.imageFile,
      imageBytes: params.imageBytes,
      folder: params.folder,
      additionalFields: params.additionalFields,
      onProgress: params.onProgress,
    );
  }
}

/// Upload Image Parameters
class UploadImageParams {
  final File? imageFile;
  final Uint8List? imageBytes;
  final String folder;
  final Map<String, String> additionalFields;
  final Function(double)? onProgress;

  UploadImageParams({
    this.imageFile,
    this.imageBytes,
    required this.folder,
    this.additionalFields = const {},
    this.onProgress,
  });

  Map<String, dynamic> toJson() {
    return {'folder': folder, 'additional_fields': additionalFields};
  }

  bool get hasFile => imageFile != null;
  bool get hasBytes => imageBytes != null;
  bool get hasImage => hasFile || hasBytes;
}
