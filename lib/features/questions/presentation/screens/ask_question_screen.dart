import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/ask_question_provider.dart';
import '../../domain/entities/question.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/image_upload_widget.dart';
import '../../../../shared/widgets/modern_dialog.dart';

/// Ask Question Screen
/// Screen for creating and submitting new questions
class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({Key? key}) : super(key: key);

  @override
  _AskQuestionScreenState createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  bool _isEditMode = false;
  Map<String, dynamic>? _editQuestionData;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is fully available for inherited widgets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEditMode();
      _initializeProvider();
    });
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  double _getResponsiveFontSize(double screenWidth, {double baseSize = 14}) {
    double scaleFactor = (screenWidth / 375.0);
    scaleFactor = scaleFactor.clamp(0.8, 1.5);
    return baseSize * scaleFactor;
  }

  double _getResponsivePadding(double screenWidth) {
    return screenWidth * 0.04; // 4% of screen width
  }

  void _checkEditMode() {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _isEditMode = args.containsKey('question');
        _editQuestionData = args;
      }
    } catch (e) {
      print('Error checking edit mode: $e');
      _isEditMode = false;
      _editQuestionData = null;
    }
  }

  void _initializeProvider() {
    // Initialize provider with available subjects
    final provider = Provider.of<AskQuestionProvider>(context, listen: false);
    final subjects = [
      'Mathematics',
      'Physics',
      'Chemistry',
      'Biology',
      'Computer Science',
      'Engineering',
      'Medicine',
      'Business',
      'Economics',
      'Literature',
      'History',
      'Geography',
      'Other',
    ];
    provider.initialize(subjects);

    // If in edit mode, pre-populate the form with existing data
    if (_isEditMode && _editQuestionData != null) {
      try {
        final question = _editQuestionData!['question'];
        if (question is Question) {
          provider.populateFormData(
            title: question.title,
            content: question.content,
            subject: question.subject,
            images: question.images,
            questionId: question.id,
            originalQuestion: question,
          );
        }
      } catch (e) {
        print('Error loading question data: $e');
        // If there's an error, fall back to create mode
        _isEditMode = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = _getResponsivePadding(screenWidth);

    return Scaffold(
      backgroundColor: const Color.fromARGB(188, 105, 73, 167),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemUiOverlayStyle,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeaderSection(screenWidth, horizontalPadding),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Consumer<AskQuestionProvider>(
                          builder: (context, provider, child) {
                            return _buildForm(context, provider, screenWidth);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(double screenWidth, double horizontalPadding) {
    return Container(
      color: const Color.fromARGB(188, 105, 73, 167),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _handleBack,
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: _getResponsiveFontSize(screenWidth, baseSize: 24),
              ),
            ),
            Expanded(
              child: Text(
                _isEditMode ? 'Edit Question' : 'Ask a Question',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(screenWidth, baseSize: 24),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            TextButton(
              onPressed: _handleClear,
              child: Text(
                'Clear',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(screenWidth, baseSize: 14),
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AskQuestionProvider provider,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Field
        _buildTitleField(provider),
        SizedBox(height: 24),

        // Description Field
        _buildDescriptionField(provider),
        SizedBox(height: 24),

        // Subject Dropdown
        _buildSubjectDropdown(provider),
        SizedBox(height: 24),

        // Tags Field
        _buildTagsField(provider),
        SizedBox(height: 24),

        // Image Upload Section
        _buildImageUploadSection(provider),
        SizedBox(height: 32),

        // Guidelines
        _buildGuidelines(),
      ],
    );
  }

  Widget _buildTitleField(AskQuestionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.title,
                color: const Color.fromARGB(188, 105, 73, 167),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Question Title',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: provider.validationErrors['title'] != null
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(188, 105, 73, 167),
                brightness: Brightness.light,
              ),
              inputDecorationTheme: InputDecorationTheme(
                fillColor: Colors.grey[50],
                hintStyle: TextStyle(color: Colors.grey[500]),
                counterStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
            child: TextFormField(
              controller: provider.titleController,
              maxLines: 2,
              maxLength: 200,
              textInputAction: TextInputAction.next,
              focusNode: _titleFocusNode,
              validator: (value) => provider.validateField('title'),
              onChanged: (value) {
                provider.clearValidationError('title');
              },
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_descriptionFocusNode);
              },
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: 'What\'s your question? Be specific...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  height: 1.4,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
                counterText: '${provider.titleCharacterCount}/200',
                counterStyle: TextStyle(
                  color: provider.isTitleNearLimit
                      ? Colors.red[600]
                      : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        if (provider.validationErrors['title'] != null) ...[
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.validationErrors['title']!,
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionField(AskQuestionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description,
                color: const Color.fromARGB(188, 105, 73, 167),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: provider.validationErrors['description'] != null
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(188, 105, 73, 167),
                brightness: Brightness.light,
              ),
              inputDecorationTheme: InputDecorationTheme(
                fillColor: Colors.grey[50],
                hintStyle: TextStyle(color: Colors.grey[500]),
                counterStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
            child: TextFormField(
              controller: provider.descriptionController,
              maxLines: 6,
              maxLength: 2000,
              textInputAction: TextInputAction.done,
              focusNode: _descriptionFocusNode,
              validator: (value) => provider.validateField('description'),
              onChanged: (value) {
                provider.clearValidationError('description');
              },
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText:
                    'Include all the information someone would need to answer your question...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  height: 1.4,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
                counterText: '${provider.descriptionCharacterCount}/2000',
                counterStyle: TextStyle(
                  color: provider.isDescriptionNearLimit
                      ? Colors.red[600]
                      : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        if (provider.validationErrors['description'] != null) ...[
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.validationErrors['description']!,
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSubjectDropdown(AskQuestionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.category,
                color: const Color.fromARGB(188, 105, 73, 167),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Subject',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: provider.validationErrors['subject'] != null
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: Theme(
              data: Theme.of(context).copyWith(
                brightness: Brightness.light,
                canvasColor: Colors.white,
                textTheme: TextTheme(
                  bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
                  bodyMedium: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                iconTheme: IconThemeData(
                  color: const Color.fromARGB(188, 105, 73, 167),
                ),
              ),
              child: DropdownButton<String>(
                value: provider.selectedSubject,
                hint: Text(
                  'Select a subject',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                isExpanded: true,
                items: provider.availableSubjects.map((subject) {
                  return DropdownMenuItem<String>(
                    value: subject,
                    child: Text(
                      subject,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  provider.selectSubject(value);
                },
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: const Color.fromARGB(188, 105, 73, 167),
                ),
                selectedItemBuilder: (BuildContext context) {
                  return provider.availableSubjects.map((String value) {
                    return Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: const Color.fromARGB(188, 105, 73, 167),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            value,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        if (provider.validationErrors['subject'] != null) ...[
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.validationErrors['subject']!,
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTagsField(AskQuestionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.tag,
                color: const Color.fromARGB(188, 105, 73, 167),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Tags (Optional)',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.15),
              width: 1.5,
            ),
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
                padding: EdgeInsets.all(16),
                child: Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: provider.tagsController,
                            decoration: InputDecoration(
                              hintText: 'Enter a tag and press Add',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: _getResponsiveFontSize(
                                  screenWidth,
                                  baseSize: 16,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(
                                screenWidth,
                                baseSize: 16,
                              ),
                              color: Colors.black87,
                            ),
                            onSubmitted: (_) => provider.addTag(),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          height: _getResponsiveFontSize(
                            screenWidth,
                            baseSize: 36,
                          ),
                          child: ElevatedButton(
                            onPressed: provider.addTag,
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
                                horizontal: _getResponsiveFontSize(
                                  screenWidth,
                                  baseSize: 16,
                                ),
                                vertical: _getResponsiveFontSize(
                                  screenWidth,
                                  baseSize: 8,
                                ),
                              ),
                            ),
                            child: Text(
                              'Add',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(
                                  screenWidth,
                                  baseSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Tags display
              if (provider.tags.isNotEmpty) ...[
                Divider(height: 1, color: Colors.grey[300]),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.tags.map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
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
                                fontSize: 14,
                                color: const Color.fromARGB(188, 105, 73, 167),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => provider.removeTag(tag),
                              child: Icon(
                                Icons.close,
                                size: 16,
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
                  padding: EdgeInsets.only(bottom: 8, right: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: provider.clearAllTags,
                      child: Text(
                        'Clear All',
                        style: TextStyle(fontSize: 12, color: Colors.red[600]),
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
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection(AskQuestionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image,
                color: const Color.fromARGB(188, 105, 73, 167),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Images (Optional)',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Add images to help explain your question',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 16),

        // Modern Image Upload Buttons
        Row(
          children: [
            Expanded(
              child: Container(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: provider.isUploadingImage
                      ? null
                      : () => provider.addImageFromCamera(),
                  icon: provider.isUploadingImage
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color.fromARGB(188, 105, 73, 167),
                            ),
                          ),
                        )
                      : Icon(Icons.camera_alt_outlined, size: 20),
                  label: Text(
                    provider.isUploadingImage ? 'Uploading...' : 'Camera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: provider.isUploadingImage
                          ? Colors.grey
                          : const Color.fromARGB(188, 105, 73, 167),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: provider.isUploadingImage
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
            SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: provider.isUploadingImage
                      ? null
                      : () => provider.addImageFromGallery(),
                  icon: provider.isUploadingImage
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color.fromARGB(188, 105, 73, 167),
                            ),
                          ),
                        )
                      : Icon(Icons.photo_library_outlined, size: 20),
                  label: Text(
                    provider.isUploadingImage ? 'Uploading...' : 'Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: provider.isUploadingImage
                          ? Colors.grey
                          : const Color.fromARGB(188, 105, 73, 167),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: provider.isUploadingImage
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
        if (provider.uploadedImages.isNotEmpty) ...[
          SizedBox(height: 16),
          _buildUploadedImages(provider),
        ],
      ],
    );
  }

  Widget _buildUploadedImages(AskQuestionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Uploaded Images (${provider.uploadedImages.length})',
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton(
              onPressed: provider.clearAllImages,
              child: Text(
                'Clear All',
                style: AppTextStyles.buttonText.copyWith(
                  color: AppColors.errorColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: provider.uploadedImages.map((imageUrl) {
            return Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
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
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => provider.removeImage(imageUrl),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 16),
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

  Widget _buildGuidelines() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    188,
                    105,
                    73,
                    167,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: const Color.fromARGB(188, 105, 73, 167),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Writing a good question',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color.fromARGB(188, 105, 73, 167),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...[
            'Be specific and provide details',
            'Include relevant context and background',
            'Check for similar questions first',
            'Use proper formatting and grammar',
            'Be respectful and professional',
          ].map((guideline) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: const Color.fromARGB(188, 105, 73, 167),
                    size: 18,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      guideline,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Consumer<AskQuestionProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Message
              if (provider.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Submit Button
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: provider.isFormValid && !provider.isLoading
                      ? () => _handleSubmit(context, provider)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(188, 105, 73, 167),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: provider.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              _isEditMode
                                  ? 'Update Question'
                                  : 'Submit Question',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Event Handlers
  void _handleBack() {
    Navigator.of(context).pop();
  }

  void _handleClear() {
    final provider = Provider.of<AskQuestionProvider>(context, listen: false);
    ModernDialog.showConfirmation(
      context: context,
      title: 'Clear Form',
      message: 'Are you sure you want to clear all entered data?',
      primaryText: 'Clear',
      secondaryText: 'Cancel',
      icon: Icons.delete_outline,
      iconColor: const Color(0xFFF44336),
    ).then((confirmed) {
      if (confirmed == true) {
        provider.reset();
      }
    });
  }

  Future<void> _handleSubmit(
    BuildContext context,
    AskQuestionProvider provider,
  ) async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showSubmitConfirmation();
    if (!confirmed) return;

    // Submit question
    final success = await provider.submitQuestion();

    if (success && mounted) {
      // Show success dialog
      _showSuccessDialog();
    }
  }

  Future<bool> _showSubmitConfirmation() async {
    final result = await ModernDialog.showConfirmation(
      context: context,
      title: _isEditMode ? 'Update Question' : 'Submit Question',
      message: _isEditMode
          ? 'Are you ready to update your question?'
          : 'Are you ready to submit your question?',
      primaryText: _isEditMode ? 'Update' : 'Submit',
      secondaryText: 'Cancel',
      icon: Icons.send_rounded,
      iconColor: const Color.fromARGB(188, 105, 73, 167),
    );
    return result ?? false;
  }

  void _showSuccessDialog() {
    ModernDialog.showSuccess(
      context: context,
      title: _isEditMode ? 'Question Updated!' : 'Question Submitted!',
      message: _isEditMode
          ? 'Your question has been successfully updated.'
          : 'Your question has been successfully submitted and will be reviewed by the community.',
      buttonText: 'OK',
      onButtonPressed: () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Go back to home
      },
    );
  }
}
