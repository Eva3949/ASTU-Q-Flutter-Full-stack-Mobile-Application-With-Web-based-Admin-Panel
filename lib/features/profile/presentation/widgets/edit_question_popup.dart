import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/question.dart';
import '../providers/profile_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../features/questions/domain/usecases/upload_image_usecase.dart';
import '../../../../features/questions/domain/repositories/question_repository.dart';
import '../../../../core/di/injection_container.dart';

/// Edit Question Popup Widget
/// Shows a popup dialog for editing an existing question
class EditQuestionPopup extends StatefulWidget {
  final Question question;
  final VoidCallback? onUpdate;
  final ProfileProvider profileProvider;

  const EditQuestionPopup({
    Key? key,
    required this.question,
    this.onUpdate,
    required this.profileProvider,
  }) : super(key: key);

  @override
  _EditQuestionPopupState createState() => _EditQuestionPopupState();
}

class _EditQuestionPopupState extends State<EditQuestionPopup> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _subjectController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _errorMessage;
  List<String> _tags = [];
  List<String> _images = [];
  final ImagePicker _imagePicker = ImagePicker();
  final Logger _logger = sl<Logger>();
  late final QuestionRepository _questionRepository;

  @override
  void initState() {
    super.initState();
    _questionRepository = sl<QuestionRepository>();
    // Pre-populate form with existing question data
    _titleController.text = widget.question.title;
    _contentController.text = widget.question.content;
    _subjectController.text = widget.question.subject;
    _tags = widget.question.tags ?? [];
    _images = List.from(widget.question.images ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _subjectController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _clearAllTags() {
    setState(() {
      _tags.clear();
    });
  }

  void _removeImage(String imageUrl) {
    setState(() {
      _images.remove(imageUrl);
    });
  }

  void _clearAllImages() {
    setState(() {
      _images.clear();
    });
  }

  Future<void> _addImageFromCamera() async {
    try {
      setState(() {
        _isUploadingImage = true;
        _errorMessage = null;
      });
      _logger.d('Picking image from camera...');

      final pickedFile = await _imagePicker.pickImage(
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
      setState(() {
        _errorMessage =
            'Failed to capture image from camera. Please try again.';
      });
      _logger.e('Error picking image from camera', error: e);
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _addImageFromGallery() async {
    try {
      setState(() {
        _isUploadingImage = true;
        _errorMessage = null;
      });
      _logger.d('Picking image from gallery...');

      final pickedFile = await _imagePicker.pickImage(
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
      setState(() {
        _errorMessage = 'Failed to pick image from gallery. Please try again.';
      });
      _logger.e('Error picking image from gallery', error: e);
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    try {
      _logger.d('Uploading image: $imagePath');

      final result = await _questionRepository
          .uploadImage(
            UploadImageParams(
              imagePath: imagePath,
              folder: 'questions',
              maxWidth: 1024,
              maxHeight: 1024,
              quality: 80,
            ),
          )
          .timeout(Duration(seconds: 30));

      result.fold(
        (failure) {
          setState(() {
            _errorMessage = 'Failed to upload image: ${failure.message}';
          });
          _logger.e('Image upload failed: ${failure.message}');
        },
        (imageUrl) {
          setState(() {
            _images.add(imageUrl);
          });
          _logger.d('Image uploaded successfully: $imageUrl');
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload image. Please try again.';
      });
      _logger.e('Error uploading image', error: e);
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call the update method (we'll need to add this to ProfileProvider)
      final success = await widget.profileProvider.updateQuestion(
        widget.question.id,
        _titleController.text.trim(),
        _contentController.text.trim(),
        _subjectController.text.trim(),
        tags: _tags,
        images: _images,
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        widget.onUpdate?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update question';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Question',
                    style: TextStyle(
                      fontSize: isTablet ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(188, 105, 73, 167),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, size: isTablet ? 28 : 24),
                    color: Colors.grey[600],
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 32 : 24),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: isTablet ? 24 : 20,
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isTablet ? 32 : 24),
              ],

              // Title Field
              _buildTitleField(isTablet),
              SizedBox(height: isTablet ? 32 : 24),

              // Description Field
              _buildDescriptionField(isTablet),
              SizedBox(height: isTablet ? 32 : 24),

              // Subject Field
              _buildSubjectField(isTablet),
              SizedBox(height: isTablet ? 32 : 24),

              // Tags Field
              _buildTagsField(isTablet),
              SizedBox(height: isTablet ? 32 : 24),

              // Image Upload Section
              _buildImageUploadSection(isTablet),
              SizedBox(height: isTablet ? 40 : 32),

              // Update button
              SizedBox(
                width: double.infinity,
                height: isTablet ? 64 : 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(188, 105, 73, 167),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: isTablet ? 28 : 24,
                          height: isTablet ? 28 : 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Update Question',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 10 : 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.title,
                color: const Color.fromARGB(188, 105, 73, 167),
                size: isTablet ? 24 : 20,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Text(
              'Title',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Enter question title',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: isTablet ? 18 : 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(isTablet ? 24 : 20),
            ),
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.black87,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              if (value.length > 200) {
                return 'Title must be less than 200 characters';
              }
              return null;
            },
          ),
        ),
        SizedBox(height: 8),
        Text(
          '${_titleController.text.length}/200 characters',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 10 : 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description,
                color: const Color.fromARGB(188, 105, 73, 167),
                size: isTablet ? 24 : 20,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Text(
              'Description',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _contentController,
            maxLines: 6,
            maxLength: 2000,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter content';
              }
              return null;
            },
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.black87,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText:
                  'Include all the information someone would need to answer your question...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: isTablet ? 18 : 16,
                height: 1.4,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(isTablet ? 24 : 20),
              counterText: '${_contentController.text.length}/2000',
              counterStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectField(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 10 : 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.category,
                color: const Color.fromARGB(188, 105, 73, 167),
                size: isTablet ? 24 : 20,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Text(
              'Subject',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _subjectController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a subject';
              }
              return null;
            },
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Enter subject',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: isTablet ? 18 : 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(isTablet ? 24 : 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsField(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 10 : 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.tag,
                color: const Color.fromARGB(188, 105, 73, 167),
                size: isTablet ? 24 : 20,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Text(
              'Tags (Optional)',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Tags input row
              Padding(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          hintText: 'Enter a tag and press Add',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: isTablet ? 18 : 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          color: Colors.black87,
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    SizedBox(
                      height: isTablet ? 44 : 36,
                      child: ElevatedButton(
                        onPressed: _addTag,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            188,
                            105,
                            73,
                            167,
                          ),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 24 : 20,
                            vertical: isTablet ? 12 : 8,
                          ),
                          minimumSize: Size(
                            isTablet ? 80 : 70,
                            isTablet ? 44 : 36,
                          ),
                        ),
                        child: Text(
                          'Add',
                          style: TextStyle(fontSize: isTablet ? 16 : 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tags display
              if (_tags.isNotEmpty) ...[
                Divider(height: 1, color: Colors.grey[300]),
                Padding(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 12,
                          vertical: isTablet ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            188,
                            105,
                            73,
                            167,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color.fromARGB(
                              188,
                              105,
                              73,
                              167,
                            ).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: const Color.fromARGB(188, 105, 73, 167),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: isTablet ? 10 : 8),
                            GestureDetector(
                              onTap: () => _removeTag(tag),
                              child: Icon(
                                Icons.close,
                                size: isTablet ? 18 : 16,
                                color: const Color.fromARGB(188, 105, 73, 167),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 8,
                    right: isTablet ? 20 : 16,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _clearAllTags,
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.red[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Add tags to help others find your question',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 10 : 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image,
                color: const Color.fromARGB(188, 105, 73, 167),
                size: isTablet ? 24 : 20,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Text(
              'Images (Optional)',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Add images to help explain your question',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),

        // Image Upload Buttons
        Row(
          children: [
            Expanded(
              child: Container(
                height: isTablet ? 64 : 56,
                child: OutlinedButton.icon(
                  onPressed: _isUploadingImage ? null : _addImageFromCamera,
                  icon: _isUploadingImage
                      ? SizedBox(
                          width: isTablet ? 24 : 20,
                          height: isTablet ? 24 : 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color.fromARGB(188, 105, 73, 167),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.camera_alt_outlined,
                          size: isTablet ? 24 : 20,
                        ),
                  label: Text(
                    _isUploadingImage ? 'Uploading...' : 'Camera',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: _isUploadingImage
                          ? Colors.grey
                          : const Color.fromARGB(188, 105, 73, 167),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _isUploadingImage
                          ? Colors.grey[300]!
                          : const Color.fromARGB(188, 105, 73, 167),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Container(
                height: isTablet ? 64 : 56,
                child: OutlinedButton.icon(
                  onPressed: _isUploadingImage ? null : _addImageFromGallery,
                  icon: _isUploadingImage
                      ? SizedBox(
                          width: isTablet ? 24 : 20,
                          height: isTablet ? 24 : 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color.fromARGB(188, 105, 73, 167),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.photo_library_outlined,
                          size: isTablet ? 24 : 20,
                        ),
                  label: Text(
                    _isUploadingImage ? 'Uploading...' : 'Gallery',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: _isUploadingImage
                          ? Colors.grey
                          : const Color.fromARGB(188, 105, 73, 167),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _isUploadingImage
                          ? Colors.grey[300]!
                          : const Color.fromARGB(188, 105, 73, 167),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Uploaded Images
        if (_images.isNotEmpty) ...[
          SizedBox(height: isTablet ? 20 : 16),
          _buildUploadedImages(isTablet),
        ],
      ],
    );
  }

  Widget _buildUploadedImages(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Uploaded Images (${_images.length})',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
            TextButton(
              onPressed: _clearAllImages,
              child: Text(
                'Clear All',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.red[600],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Wrap(
          spacing: isTablet ? 12 : 8,
          runSpacing: isTablet ? 12 : 8,
          children: _images.map((imageUrl) {
            return Stack(
              children: [
                Container(
                  width: isTablet ? 100 : 80,
                  height: isTablet ? 100 : 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[400],
                            size: isTablet ? 28 : 24,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: isTablet ? 6 : 4,
                  right: isTablet ? 6 : 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(imageUrl),
                    child: Container(
                      width: isTablet ? 28 : 24,
                      height: isTablet ? 28 : 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: isTablet ? 18 : 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
