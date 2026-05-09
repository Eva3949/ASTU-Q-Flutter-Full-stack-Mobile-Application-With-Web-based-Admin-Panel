import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/question.dart';
import '../../domain/usecases/create_question_usecase.dart';
import '../../domain/usecases/update_question_usecase.dart';
import '../../domain/usecases/upload_image_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/network/api_service.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// Ask Question Provider
/// Manages question creation state and operations
@singleton
class AskQuestionProvider extends ChangeNotifier {
  final CreateQuestionUseCase _createQuestionUseCase;
  final UpdateQuestionUseCase _updateQuestionUseCase;
  final UploadImageUseCase _uploadImageUseCase;
  final Logger _logger;
  final AuthenticationProvider _authProvider;
  final ApiService _apiService;
  final ProfileProvider _profileProvider;

  AskQuestionProvider(
    this._createQuestionUseCase,
    this._updateQuestionUseCase,
    this._uploadImageUseCase,
    this._logger,
    this._authProvider,
    this._apiService,
    this._profileProvider,
  );

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  // State variables
  String? _selectedSubject;
  List<String> _uploadedImages = [];
  List<String> _tags = [];
  List<String> _availableSubjects = [];
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _errorMessage;
  Map<String, String?> _validationErrors = {};

  // Edit mode tracking
  bool _isEditMode = false;
  int? _editingQuestionId;
  Question? _originalQuestion;

  // Getters
  TextEditingController get titleController => _titleController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get tagsController => _tagsController;
  String? get selectedSubject => _selectedSubject;
  List<String> get uploadedImages => _uploadedImages;
  List<String> get tags => _tags;
  List<String> get availableSubjects => _availableSubjects;
  bool get isLoading => _isLoading;
  bool get isUploadingImage => _isUploadingImage;
  String? get errorMessage => _errorMessage;
  Map<String, String?> get validationErrors => _validationErrors;
  bool get isFormValid => _validateForm();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  /// Initialize provider with available subjects
  void initialize(List<String> subjects) {
    _availableSubjects = subjects;
    _safeNotify();
  }

  /// Populate form data for edit mode
  void populateFormData({
    required String title,
    required String content,
    required String subject,
    required List<String> images,
    int? questionId,
    Question? originalQuestion,
  }) {
    _isEditMode = questionId != null;
    _editingQuestionId = questionId;
    _originalQuestion = originalQuestion;

    _titleController.text = title;
    _descriptionController.text = content;
    _selectedSubject = subject;
    _uploadedImages = List.from(images);

    _safeNotify();
  }

  /// Select subject
  void selectSubject(String? subject) {
    _selectedSubject = subject;
    clearValidationError('subject');
    _safeNotify();
  }

  /// Add image from camera
  Future<void> addImageFromCamera() async {
    try {
      _setImageUploading(true);
      _clearError();
      _logger.d('Picking image from camera...');

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        _logger.d('Image picked from camera: ${pickedFile.path}');
        await _uploadImage(pickedFile.path);
      } else {
        _logger.d('No image selected from camera');
      }
    } catch (e) {
      _setError('Failed to capture image from camera. Please try again.');
      _logger.e('Error picking image from camera', error: e);
    } finally {
      _setImageUploading(false);
    }
  }

  /// Add image from gallery
  Future<void> addImageFromGallery() async {
    try {
      _setImageUploading(true);
      _clearError();
      _logger.d('Picking image from gallery...');

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        _logger.d('Image picked from gallery: ${pickedFile.path}');
        await _uploadImage(pickedFile.path);
      } else {
        _logger.d('No image selected from gallery');
      }
    } catch (e) {
      _setError('Failed to pick image from gallery. Please try again.');
      _logger.e('Error picking image from gallery', error: e);
    } finally {
      _setImageUploading(false);
    }
  }

  /// Upload image to server
  Future<void> _uploadImage(String imagePath) async {
    try {
      _logger.d('Uploading image: $imagePath');

      final result = await _uploadImageUseCase(
        UploadImageParams(
          imagePath: imagePath,
          folder: 'questions',
          maxWidth: 1024,
          maxHeight: 1024,
          quality: 80,
        ),
      ).timeout(Duration(seconds: 30)); // Add timeout to prevent hanging

      result.fold(
        (failure) {
          _setError('Failed to upload image: ${failure.message}');
          _logger.e('Image upload failed: ${failure.message}');
        },
        (imageUrl) {
          _uploadedImages.add(imageUrl);
          _logger.d('Image uploaded successfully: $imageUrl');
          _safeNotify();
        },
      );
    } catch (e) {
      if (e.toString().contains('timeout')) {
        _setError(
          'Upload timed out. Please check your connection and try again.',
        );
      } else {
        _setError('Failed to upload image. Please try again.');
      }
      _logger.e('Error uploading image', error: e);
    }
  }

  /// Remove uploaded image
  void removeImage(String imageUrl) {
    _uploadedImages.remove(imageUrl);
    _safeNotify();
  }

  /// Clear all images
  void clearAllImages() {
    _uploadedImages.clear();
    _safeNotify();
  }

  /// Add tag from input
  void addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      _tags.add(tag);
      _tagsController.clear();
      _safeNotify();
    }
  }

  /// Remove tag
  void removeTag(String tag) {
    _tags.remove(tag);
    _safeNotify();
  }

  /// Clear all tags
  void clearAllTags() {
    _tags.clear();
    _tagsController.clear();
    _safeNotify();
  }

  /// Submit question (create or update)
  Future<bool> submitQuestion() async {
    // Validate form
    if (!_validateForm()) {
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      _clearValidationErrors();

      if (_isEditMode &&
          _editingQuestionId != null &&
          _originalQuestion != null) {
        _logger.d('Updating question: $_editingQuestionId');

        try {
          // Create updated question object preserving original data
          final updatedQuestion = Question(
            id: _editingQuestionId!,
            title: _titleController.text.trim(),
            content: _descriptionController.text.trim(),
            subject: _selectedSubject!,
            authorId: _originalQuestion!.authorId,
            authorName: _originalQuestion!.authorName,
            images: _uploadedImages,
            createdAt: _originalQuestion!.createdAt,
            updatedAt: DateTime.now(),
            viewCount: _originalQuestion!.viewCount,
            answerCount: _originalQuestion!.answerCount,
            isResolved: _originalQuestion!.isResolved,
            tags: _tags,
            acceptedAnswerId: _originalQuestion!.acceptedAnswerId,
            authorAvatarUrl: _originalQuestion!.authorAvatarUrl,
            authorIsVerified: _originalQuestion!.authorIsVerified,
            upvotes: _originalQuestion!.upvotes,
            downvotes: _originalQuestion!.downvotes,
            isUpvoted: _originalQuestion!.isUpvoted,
            isDownvoted: _originalQuestion!.isDownvoted,
            isBookmarked: _originalQuestion!.isBookmarked,
            status: _originalQuestion!.status,
          );

          final result = await _updateQuestionUseCase(updatedQuestion);

          return result.fold(
            (failure) {
              _setError(_getErrorMessage(failure));
              _logger.e('Failed to update question: ${failure.message}');
              return false;
            },
            (question) {
              _logger.d('Question updated successfully: ${question.id}');
              _clearForm();
              return true;
            },
          );
        } catch (e) {
          _setError('An unexpected error occurred');
          _logger.e('Error updating question', error: e);
          return false;
        }
      } else {
        _logger.d('Creating new question...');

        final result = await _createQuestionUseCase(
          CreateQuestionParams(
            title: _titleController.text.trim(),
            content: _descriptionController.text.trim(),
            subject: _selectedSubject!,
            images: _uploadedImages,
            tags: _tags,
            userId: _authProvider.user?.id?.toString(),
          ),
        );

        return result.fold(
          (failure) {
            _setError(_getErrorMessage(failure));
            _logger.e('Failed to submit question: ${failure.message}');
            return false;
          },
          (question) async {
            _logger.d('Question submitted successfully: ${question.id}');

            // Award points for asking a question
            final userId = _authProvider.user?.id;
            if (userId != null) {
              try {
                await _apiService.updateUserPoints(
                  userId: userId,
                  points: 10, // 10 points for asking a question
                  action: 'question',
                );
                _logger.d('Points awarded for asking question');
                // Refresh profile to update points display
                _profileProvider.refreshProfile();
              } catch (e) {
                _logger.e('Failed to award points for question', error: e);
              }
            }

            _clearForm();
            return true;
          },
        );
      }
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error submitting question', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Validate form
  bool _validateForm() {
    final errors = <String, String?>{};
    bool isValid = true;

    // Validate title
    final titleError = _validateTitle(_titleController.text);
    if (titleError != null) {
      errors['title'] = titleError;
      isValid = false;
    }

    // Validate description
    final descriptionError = _validateDescription(_descriptionController.text);
    if (descriptionError != null) {
      errors['description'] = descriptionError;
      isValid = false;
    }

    // Validate subject
    final subjectError = _validateSubject(_selectedSubject);
    if (subjectError != null) {
      errors['subject'] = subjectError;
      isValid = false;
    }

    _validationErrors = errors;
    return isValid;
  }

  /// Validate title
  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a question title';
    }

    final title = value.trim();
    if (title.length < 10) {
      return 'Title must be at least 10 characters';
    }

    if (title.length > 200) {
      return 'Title must not exceed 200 characters';
    }

    return null;
  }

  /// Validate description
  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please provide a question description';
    }

    final description = value.trim();
    if (description.length < 20) {
      return 'Description must be at least 20 characters';
    }

    if (description.length > 2000) {
      return 'Description must not exceed 2000 characters';
    }

    return null;
  }

  /// Validate subject
  String? _validateSubject(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a subject';
    }

    if (!_availableSubjects.contains(value)) {
      return 'Please select a valid subject';
    }

    return null;
  }

  /// Validate specific field
  String? validateField(String fieldName) {
    switch (fieldName) {
      case 'title':
        return _validateTitle(_titleController.text);
      case 'description':
        return _validateDescription(_descriptionController.text);
      case 'subject':
        return _validateSubject(_selectedSubject);
      default:
        return null;
    }
  }

  /// Clear validation error for specific field
  void clearValidationError(String fieldName) {
    _validationErrors.remove(fieldName);
    _safeNotify();
  }

  /// Clear all validation errors
  void _clearValidationErrors() {
    _validationErrors.clear();
    notifyListeners();
  }

  /// Clear form
  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _tagsController.clear();
    _selectedSubject = null;
    _uploadedImages.clear();
    _tags.clear();
    _validationErrors.clear();
    notifyListeners();
  }

  /// Reset provider
  void reset() {
    _clearForm();
    _errorMessage = null;
    _isLoading = false;
    _isUploadingImage = false;
    _safeNotify();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    _safeNotify();
  }

  /// Set image uploading state
  void _setImageUploading(bool uploading) {
    if (_isUploadingImage == uploading) return;
    _isUploadingImage = uploading;
    _safeNotify();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    _safeNotify();
  }

  /// Clear error message
  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _safeNotify();
  }

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
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
        return 'Please login to continue.';
      case TimeoutFailure:
        return 'Request timeout. Please try again.';
      case FileUploadFailure:
        return 'Failed to upload images. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Get character count for title
  int get titleCharacterCount => _titleController.text.length;

  /// Get character count for description
  int get descriptionCharacterCount => _descriptionController.text.length;

  /// Check if title is near limit
  bool get isTitleNearLimit => titleCharacterCount > 180;

  /// Check if description is near limit
  bool get isDescriptionNearLimit => descriptionCharacterCount > 1800;

  /// Get remaining characters for title
  int get titleRemainingCharacters => 200 - titleCharacterCount;

  /// Get remaining characters for description
  int get descriptionRemainingCharacters => 2000 - descriptionCharacterCount;
}
