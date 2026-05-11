import 'dart:io';
import 'dart:typed_data';
import '../../../../core/types/either.dart';
import '../../../../core/errors/failures.dart';

/// Image Upload repository interface
/// Defines the contract for image upload data operations
abstract class ImageUploadRepository {
  /// Upload image to server
  Future<Either<Failure, String>> uploadImage({
    File? imageFile,
    Uint8List? imageBytes,
    required String folder,
    Map<String, String> additionalFields = const {},
    Function(double)? onProgress,
  });

  /// Delete uploaded image
  Future<Either<Failure, void>> deleteImage(String imageUrl);

  /// Get image info from URL
  Future<Either<Failure, Map<String, dynamic>>> getImageInfo(String imageUrl);

  /// Check if image exists
  Future<Either<Failure, bool>> imageExists(String imageUrl);

  /// Get upload URL for direct upload
  Future<Either<Failure, String>> getUploadUrl({
    required String fileName,
    required String folder,
    Map<String, String> additionalFields = const {},
  });

  /// Validate image format
  bool isValidImageFormat(String fileName);

  /// Get supported image formats
  List<String> getSupportedFormats();
}
