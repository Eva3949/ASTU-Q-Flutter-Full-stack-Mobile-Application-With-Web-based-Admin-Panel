import 'dart:io';
import 'dart:typed_data';
import '../../../../core/types/either.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repositories/image_upload_repository.dart';

@LazySingleton(as: ImageUploadRepository)
class ImageUploadRepositoryImpl implements ImageUploadRepository {
  final DioClient _dioClient;
  final Logger _logger;
  static const String _baseUrl = 'https://evadevstudio.com/sami';

  ImageUploadRepositoryImpl(this._dioClient, this._logger);

  @override
  Future<Either<Failure, String>> uploadImage({
    File? imageFile,
    Uint8List? imageBytes,
    required String folder,
    Map<String, String> additionalFields = const {},
    Function(double)? onProgress,
  }) async {
    try {
      _logger.d('Uploading image to folder: $folder');

      if (imageFile == null && imageBytes == null) {
        return Either.left(ValidationFailure('No image provided for upload'));
      }

      final response = await _dioClient.upload(
        '$_baseUrl/upload_image.php',
        imageFile ?? imageBytes,
        data: {'type': folder, ...additionalFields},
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200) {
        final imageUrl = response.data['data']['url'];
        _logger.d('Image uploaded successfully: $imageUrl');
        return Either.right(imageUrl);
      } else {
        return Either.left(ServerFailure('Failed to upload image'));
      }
    } catch (e) {
      _logger.e('Error uploading image', error: e);
      return Either.left(ServerFailure('Failed to upload image'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteImage(String imageUrl) async {
    // Note: delete functionality not yet implemented in backend standalone scripts
    return Either.left(ServerFailure('Delete image not supported yet'));
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getImageInfo(
    String imageUrl,
  ) async {
    return Either.left(ServerFailure('Get image info not supported yet'));
  }

  @override
  Future<Either<Failure, bool>> imageExists(String imageUrl) async {
    return Either.left(
      ServerFailure('Check image existence not supported yet'),
    );
  }

  @override
  Future<Either<Failure, String>> getUploadUrl({
    required String fileName,
    required String folder,
    Map<String, String> additionalFields = const {},
  }) async {
    return Either.left(ServerFailure('Direct upload URL not supported yet'));
  }

  @override
  bool isValidImageFormat(String fileName) {
    final extension = path
        .extension(fileName)
        .toLowerCase()
        .replaceAll('.', '');
    return getSupportedFormats().contains(extension);
  }

  @override
  List<String> getSupportedFormats() {
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  }
}
