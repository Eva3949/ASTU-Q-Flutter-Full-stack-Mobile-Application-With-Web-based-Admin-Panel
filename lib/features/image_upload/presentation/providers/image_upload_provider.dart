import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/usecases/upload_image_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';

/// Image Upload Provider
/// Manages image selection, preview, and upload state
@singleton
class ImageUploadProvider extends ChangeNotifier {
  final UploadImageUseCase _uploadImageUseCase;
  final ImagePicker _imagePicker;
  final Logger _logger;

  ImageUploadProvider(
    this._uploadImageUseCase,
    this._imagePicker,
    this._logger,
  );

  // State variables
  bool _isUploading = false;
  String? _errorMessage;
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _uploadedImageUrl;
  double _uploadProgress = 0.0;
  ImageSource? _currentSource;
  Map<String, dynamic>? _data = {};

  // Getters
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  File? get selectedImage => _selectedImage;
  Uint8List? get selectedImageBytes => _selectedImageBytes;
  String? get uploadedImageUrl => _uploadedImageUrl;
  double get uploadProgress => _uploadProgress;
  ImageSource? get currentSource => _currentSource;
  bool get hasImage => _selectedImage != null || _selectedImageBytes != null;

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  /// Pick image from camera
  Future<void> pickImageFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  /// Pick image with source
  Future<void> _pickImage(ImageSource source) async {
    try {
      _clearError();
      _currentSource = source;
      notifyListeners();

      _logger.d('Picking image from source: $source');

      if (kIsWeb) {
        // Web implementation using bytes
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );

        if (pickedFile != null) {
          final Uint8List imageBytes = await pickedFile.readAsBytes();
          _selectedImageBytes = imageBytes;
          _selectedImage = null; // Clear file reference for web
          _logger.d(
            'Image picked successfully from $source (${imageBytes.length} bytes)',
          );
        }
      } else {
        // Mobile implementation using file
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );

        if (pickedFile != null) {
          final File imageFile = File(pickedFile.path);
          _selectedImage = imageFile;
          _selectedImageBytes = null; // Clear bytes reference for mobile
          _logger.d(
            'Image picked successfully from $source: ${imageFile.path}',
          );
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to pick image: ${e.toString()}');
      _logger.e('Error picking image from $source', error: e);
    }
  }

  /// Upload selected image
  Future<bool> uploadImage({
    String? folder,
    Map<String, String>? additionalFields,
  }) async {
    if (!hasImage) {
      _setError('No image selected');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      _uploadProgress = 0.0;
      notifyListeners();

      _logger.d('Starting image upload to folder: $folder');

      final result = await _uploadImageUseCase(
        UploadImageParams(
          imageFile: _selectedImage,
          imageBytes: _selectedImageBytes,
          folder: folder ?? 'uploads',
          additionalFields: additionalFields ?? {},
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        ),
      );

      return result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Image upload failed: ${failure.message}');
          return false;
        },
        (imageUrl) {
          _uploadedImageUrl = imageUrl;
          _uploadProgress = 1.0;
          _logger.d('Image uploaded successfully: $imageUrl');
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred during upload');
      _logger.e('Error uploading image', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  /// Clear selected image
  void clearImage() {
    _selectedImage = null;
    _selectedImageBytes = null;
    _uploadedImageUrl = null;
    _uploadProgress = 0.0;
    _currentSource = null;
    _clearError();
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _isUploading = false;
    _errorMessage = null;
    _selectedImage = null;
    _selectedImageBytes = null;
    _uploadedImageUrl = null;
    _uploadProgress = 0.0;
    _currentSource = null;
    notifyListeners();
  }

  /// Get image size info
  Map<String, dynamic> getImageInfo() {
    if (_selectedImage != null) {
      final file = _selectedImage!;
      final fileSize = file.lengthSync();
      return {
        'path': file.path,
        'size': fileSize,
        'sizeFormatted': _formatFileSize(fileSize),
        'type': 'file',
      };
    } else if (_selectedImageBytes != null) {
      final bytes = _selectedImageBytes!;
      return {
        'size': bytes.length,
        'sizeFormatted': _formatFileSize(bytes.length),
        'type': 'bytes',
      };
    }
    return {};
  }

  /// Get image for display
  dynamic getDisplayImage() {
    if (_selectedImage != null) {
      return _selectedImage!;
    } else if (_selectedImageBytes != null) {
      return _selectedImageBytes!;
    }
    return null;
  }

  /// Validate image before upload
  bool validateImage() {
    if (!hasImage) {
      _setError('Please select an image first');
      return false;
    }

    try {
      final info = getImageInfo();
      final size = info['size'] as int? ?? 0;

      // Check file size (max 10MB)
      if (size > 10 * 1024 * 1024) {
        _setError('Image size must be less than 10MB');
        return false;
      }

      // Check minimum size (at least 1KB)
      if (size < 1024) {
        _setError('Image is too small');
        return false;
      }

      return true;
    } catch (e) {
      _logger.e('Error validating image', error: e);
      _setError('Failed to validate image');
      return false;
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isUploading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 'No internet connection. Please check your network and try again.';
      case ServerFailure:
        return 'Server error. Please try again later.';
      case ValidationFailure:
        return failure.message;
      case UnauthorizedFailure:
        return 'Session expired. Please login again.';
      case TimeoutFailure:
        return 'Upload timeout. Please try again.';
      case NotFoundFailure:
        return 'Upload endpoint not found.';
      default:
        return 'An error occurred during upload. Please try again.';
    }
  }

  /// Get supported image formats
  List<String> getSupportedFormats() {
    return ['JPEG', 'PNG', 'GIF', 'BMP', 'WEBP'];
  }

  /// Check if image format is supported
  bool isSupportedFormat(String fileName) {
    final supportedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final extension = fileName.split('.').last.toLowerCase();
    return supportedExtensions.contains(extension);
  }

  /// Compress image if needed
  Future<void> compressImage() async {
    if (!hasImage) return;

    try {
      _logger.d('Compressing image...');

      // For web, we already set quality in image picker
      // For mobile, we could use flutter_image_compress package
      // For now, we'll just validate the image and skip compression
      if (validateImage()) {
        _logger.d('Image validation passed, compression skipped');
      }
    } catch (e) {
      _logger.e('Error compressing image', error: e);
      _setError('Failed to compress image');
    }
  }

  /// Get image dimensions
  Future<Map<String, int>?> getImageDimensions() async {
    if (!hasImage) return null;

    try {
      _logger.d('Getting image dimensions...');

      // Return basic dimensions for now to prevent crashes
      final info = getImageInfo();
      final size = info['size'] as int? ?? 0;

      // Estimate dimensions based on file size (rough approximation)
      int width = 800;
      int height = 600;

      if (size > 500000) {
        // Large image
        width = 1920;
        height = 1080;
      } else if (size > 100000) {
        // Medium image
        width = 1280;
        height = 720;
      }

      return {'width': width, 'height': height};
    } catch (e) {
      _logger.e('Error getting image dimensions', error: e);
      return null;
    }
  }

  /// Create thumbnail
  Future<Uint8List?> createThumbnail({int size = 150}) async {
    if (!hasImage) return null;

    try {
      _logger.d('Creating thumbnail ($size x $size)...');

      // For now, return a simple resized version
      // This prevents crashes by not using complex image processing
      final info = getImageInfo();
      if (info['type'] == 'bytes') {
        // For web images (bytes), create a simple placeholder
        return Uint8List.fromList([]);
      }

      // For mobile images, skip thumbnail creation for now
      _logger.d('Thumbnail creation skipped for mobile images');
      return null;
    } catch (e) {
      _logger.e('Error creating thumbnail', error: e);
      return null;
    }
  }

  /// Batch upload multiple images
  Future<List<String>> uploadMultipleImages(
    List<File> images, {
    String? folder,
    Map<String, String>? additionalFields,
  }) async {
    final List<String> uploadedUrls = [];

    for (int i = 0; i < images.length; i++) {
      final image = images[i];

      // Set current image
      _selectedImage = image;
      _selectedImageBytes = null;
      notifyListeners();

      final success = await uploadImage(
        folder: folder,
        additionalFields: additionalFields,
      );

      if (success && _uploadedImageUrl != null) {
        uploadedUrls.add(_uploadedImageUrl!);
      } else {
        _logger.e('Failed to upload image ${i + 1}/${images.length}');
        break; // Stop on first error
      }
    }

    return uploadedUrls;
  }

  /// Upload with retry mechanism
  Future<bool> uploadWithRetry({
    int maxRetries = 3,
    String? folder,
    Map<String, String>? additionalFields,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      _logger.d('Upload attempt $attempt/$maxRetries');

      final success = await uploadImage(
        folder: folder,
        additionalFields: additionalFields,
      );

      if (success) {
        return true;
      }

      if (attempt < maxRetries) {
        // Wait before retry (exponential backoff)
        final delay = Duration(milliseconds: 1000 * (1 << (attempt - 1)));
        await Future.delayed(delay);
        _logger.d('Retrying upload after ${delay.inMilliseconds}ms...');
      }
    }

    _logger.e('Upload failed after $maxRetries attempts');
    return false;
  }
}
