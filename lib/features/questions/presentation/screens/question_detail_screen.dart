import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/question_detail_provider.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/answer.dart';
import '../../domain/usecases/vote_answer_usecase.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';

/// Question Detail Screen
/// Displays full question details with answers and voting system
class QuestionDetailScreen extends StatefulWidget {
  final int questionId;

  const QuestionDetailScreen({Key? key, required this.questionId})
    : super(key: key);

  @override
  _QuestionDetailScreenState createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final _scrollController = ScrollController();
  final _answerFocusNode = FocusNode();
  bool _showAnswerInput = false;

  @override
  void initState() {
    super.initState();
    _initializeListeners();
    _loadQuestionDetail();
  }

  // Responsive helper methods using percentage ratios
  double _getResponsivePadding(double screenWidth) {
    return screenWidth * 0.04; // 4% of screen width
  }

  double _getResponsiveVerticalPadding(double screenHeight) {
    return screenHeight * 0.02; // 2% of screen height
  }

  double _getResponsiveFontSize(double screenWidth, {double baseSize = 14}) {
    // Scale font size based on screen width percentage
    double scaleFactor = (screenWidth / 375.0); // Base iPhone width
    scaleFactor = scaleFactor.clamp(0.8, 1.5); // Clamp between 0.8x and 1.5x
    return baseSize * scaleFactor;
  }

  double _getResponsiveSize(double screenWidth, double baseSize) {
    double scaleFactor = (screenWidth / 375.0); // Base iPhone width
    scaleFactor = scaleFactor.clamp(0.8, 1.5); // Clamp between 0.8x and 1.5x
    return baseSize * scaleFactor;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  void _initializeListeners() {
    // Listen to scroll events for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more answers when near bottom
      final provider = Provider.of<QuestionDetailProvider>(
        context,
        listen: false,
      );
      if (provider.hasMore && !provider.isLoadingMore) {
        provider.loadMoreAnswers();
      }
    }
  }

  void _loadQuestionDetail() {
    final provider = Provider.of<QuestionDetailProvider>(
      context,
      listen: false,
    );
    provider.loadQuestionDetail(widget.questionId);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive padding calculations
    final horizontalPadding = _getResponsivePadding(screenWidth);
    final verticalPadding = _getResponsiveVerticalPadding(screenHeight);

    return Scaffold(
      backgroundColor: const Color.fromARGB(188, 105, 73, 167),
      body: SafeArea(
        child: Consumer<QuestionDetailProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.question == null) {
              return Container(
                color: Colors.white,
                child: const Center(
                  child: LoadingWidget(message: 'Loading question...'),
                ),
              );
            }

            if (provider.errorMessage != null && provider.question == null) {
              return _buildErrorState(provider);
            }

            if (provider.question == null) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                _buildHeaderSection(
                  screenWidth,
                  horizontalPadding,
                  verticalPadding,
                  provider,
                ),
                _buildContentSection(
                  screenWidth,
                  horizontalPadding,
                  verticalPadding,
                  provider,
                ),
                if (_showAnswerInput)
                  _buildAnswerInputSection(
                    screenWidth,
                    horizontalPadding,
                    verticalPadding,
                    provider,
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Consumer<QuestionDetailProvider>(
        builder: (context, provider, child) {
          if (!_showAnswerInput &&
              !provider.isLoading &&
              provider.question != null) {
            return _buildAnswerButton();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeaderSection(
    double screenWidth,
    double horizontalPadding,
    double verticalPadding,
    QuestionDetailProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(188, 105, 73, 167),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: _getResponsiveFontSize(screenWidth, baseSize: 24),
              ),
            ),
            Expanded(
              child: Text(
                'Question Details',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(screenWidth, baseSize: 24),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _handleShare,
                  icon: Icon(
                    Icons.share_outlined,
                    color: Colors.white,
                    size: _getResponsiveFontSize(screenWidth, baseSize: 24),
                  ),
                ),
                IconButton(
                  onPressed: _handleBookmark,
                  icon: Icon(
                    Icons.bookmark_border_outlined,
                    color: Colors.white,
                    size: _getResponsiveFontSize(screenWidth, baseSize: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(QuestionDetailProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            SizedBox(height: 24),
            Text(
              'No Internet connection',
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 32),
            CustomButton(
              text: 'Try Again',
              onPressed: _loadQuestionDetail,
              prefixIcon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 24),
            Text(
              'Question Not Found',
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'The question you\'re looking for doesn\'t exist or has been removed.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 32),
            CustomButton(
              text: 'Go Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(
    double screenWidth,
    double horizontalPadding,
    double verticalPadding,
    QuestionDetailProvider provider,
  ) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Container(
          color: Colors.white,
          child: RefreshIndicator(
            onRefresh: () async {
              await provider.loadQuestionDetail(widget.questionId);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              itemCount:
                  provider.answerCount +
                  (provider.hasMore ? 1 : 0) +
                  1, // +1 for question
              itemBuilder: (context, index) {
                // Show question detail at index 0
                if (index == 0) {
                  return _buildQuestionCard(
                    provider.question!,
                    provider,
                    screenWidth,
                  );
                }

                // Show answer cards
                final answerIndex = index - 1;
                if (answerIndex < provider.answerCount) {
                  return _buildModernAnswerCard(
                    provider.answers[answerIndex],
                    provider,
                    screenWidth,
                  );
                }

                // Show loading indicator at the end
                if (provider.hasMore) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: _getResponsiveSize(screenWidth, 16),
                    ),
                    child: Center(
                      child: LoadingWidget(
                        size: _getResponsiveSize(screenWidth, 24),
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        setState(() {
          _showAnswerInput = true;
        });
      },
      backgroundColor: Color.fromARGB(188, 105, 73, 167),
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.edit, size: 20),
      label: const Text(
        'Add Answer',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildQuestionCard(
    Question question,
    QuestionDetailProvider provider,
    double screenWidth,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSize(screenWidth, 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          _getResponsiveSize(screenWidth, 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: _getResponsiveSize(screenWidth, 15),
            offset: Offset(0, _getResponsiveSize(screenWidth, 5)),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: _getResponsiveSize(screenWidth, 8),
            offset: Offset(0, _getResponsiveSize(screenWidth, 2)),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(_getResponsiveSize(screenWidth, 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              children: [
                CircleAvatar(
                  radius: _getResponsiveSize(screenWidth, 20),
                  backgroundColor: const Color(0xFF667EEA).withOpacity(0.1),
                  child: Text(
                    question.authorName.isNotEmpty
                        ? question.authorName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: AppTextStyles.bodyText1.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.authorName,
                        style: AppTextStyles.bodyText1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _formatTime(question.createdAt),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (question.subject.isNotEmpty) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                question.subject,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Question Title
            Text(
              question.title,
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            // Question Content
            Text(
              question.content,
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            // Question Images (if any)
            if (question.images.isNotEmpty) ...[
              SizedBox(height: 16),
              _buildQuestionImages(question.images),
            ],

            SizedBox(height: 16),

            // Question Actions
            Row(
              children: [
                // Vote Buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _voteQuestion(VoteType.upvote),
                      icon: Icon(
                        question.isUpvoted
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: question.isUpvoted
                            ? Colors.red
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${question.upvotes}',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                Spacer(),

                // Answer Count
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${provider.answerCount} answers',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.infoColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Best Answer Indicator
            if (provider.hasBestAnswer) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.successColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.successColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'This question has a best answer',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: AppColors.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionImages(List<String> images) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final imageWidth = _getResponsiveSize(screenWidth, 150);
        final imageHeight = _getResponsiveSize(screenWidth, 100);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Images',
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: _getResponsiveSize(screenWidth, 12)),
            Wrap(
              spacing: _getResponsiveSize(screenWidth, 8),
              runSpacing: _getResponsiveSize(screenWidth, 8),
              children: images.map((imageUrl) {
                return GestureDetector(
                  onTap: () => _viewImage(imageUrl),
                  child: Container(
                    width: imageWidth,
                    height: imageHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        _getResponsiveSize(screenWidth, 8),
                      ),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        _getResponsiveSize(screenWidth, 7),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                              size: _getResponsiveSize(screenWidth, 24),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModernAnswerCard(
    Answer answer,
    QuestionDetailProvider provider,
    double screenWidth,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSize(screenWidth, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          _getResponsiveSize(screenWidth, 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: _getResponsiveSize(screenWidth, 12),
            offset: Offset(0, _getResponsiveSize(screenWidth, 4)),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(_getResponsiveSize(screenWidth, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Answer header
            Row(
              children: [
                CircleAvatar(
                  radius: _getResponsiveSize(screenWidth, 16),
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  child: Text(
                    answer.authorName.isNotEmpty
                        ? answer.authorName.substring(0, 1).toUpperCase()
                        : 'A',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(
                        screenWidth,
                        baseSize: 14,
                      ),
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: _getResponsiveSize(screenWidth, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer.authorName,
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(
                            screenWidth,
                            baseSize: 14,
                          ),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatDate(answer.createdAt),
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(
                            screenWidth,
                            baseSize: 12,
                          ),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Best answer badge
                if (answer.isBest)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _getResponsiveSize(screenWidth, 8),
                      vertical: _getResponsiveSize(screenWidth, 4),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.green.shade700],
                      ),
                      borderRadius: BorderRadius.circular(
                        _getResponsiveSize(screenWidth, 12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check,
                          color: Colors.white,
                          size: _getResponsiveSize(screenWidth, 12),
                        ),
                        SizedBox(width: _getResponsiveSize(screenWidth, 4)),
                        Text(
                          'Best',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(
                              screenWidth,
                              baseSize: 10,
                            ),
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: _getResponsiveSize(screenWidth, 12)),
            // Answer content
            Text(
              answer.content,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, baseSize: 14),
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            SizedBox(height: _getResponsiveSize(screenWidth, 12)),
            // Answer actions
            Row(
              children: [
                // Like button
                InkWell(
                  onTap: () => provider.voteAnswer(answer.id, VoteType.upvote),
                  borderRadius: BorderRadius.circular(
                    _getResponsiveSize(screenWidth, 20),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _getResponsiveSize(screenWidth, 12),
                      vertical: _getResponsiveSize(screenWidth, 6),
                    ),
                    decoration: BoxDecoration(
                      color: answer.isUpvoted
                          ? Colors.red.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(
                        _getResponsiveSize(screenWidth, 20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          answer.isUpvoted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: _getResponsiveSize(screenWidth, 16),
                          color: answer.isUpvoted
                              ? Colors.red
                              : Colors.grey[600],
                        ),
                        SizedBox(width: _getResponsiveSize(screenWidth, 6)),
                        Text(
                          '${answer.upvotes}',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(
                              screenWidth,
                              baseSize: 12,
                            ),
                            color: answer.isUpvoted
                                ? Colors.red
                                : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Spacer(),
                // Mark as best answer button (for question author)
                if (provider.question?.authorId == getCurrentUserId() &&
                    !answer.isBest)
                  InkWell(
                    onTap: () => provider.markBestAnswer(answer.id),
                    borderRadius: BorderRadius.circular(
                      _getResponsiveSize(screenWidth, 20),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _getResponsiveSize(screenWidth, 12),
                        vertical: _getResponsiveSize(screenWidth, 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          _getResponsiveSize(screenWidth, 20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: _getResponsiveSize(screenWidth, 16),
                            color: Colors.green,
                          ),
                          SizedBox(width: _getResponsiveSize(screenWidth, 6)),
                          Text(
                            'Best',
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(
                                screenWidth,
                                baseSize: 12,
                              ),
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildAnswerInputSection(
    double screenWidth,
    double horizontalPadding,
    double verticalPadding,
    QuestionDetailProvider provider,
  ) {
    return Container(
      padding: EdgeInsets.all(_getResponsiveSize(screenWidth, 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_getResponsiveSize(screenWidth, 32)),
          topRight: Radius.circular(_getResponsiveSize(screenWidth, 32)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: _getResponsiveSize(screenWidth, 24),
            offset: Offset(0, -_getResponsiveSize(screenWidth, 8)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: _getResponsiveSize(screenWidth, 40),
            height: _getResponsiveSize(screenWidth, 4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(
                _getResponsiveSize(screenWidth, 2),
              ),
            ),
          ),
          SizedBox(height: _getResponsiveSize(screenWidth, 20)),

          // Answer Input Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getResponsiveSize(screenWidth, 12)),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    _getResponsiveSize(screenWidth, 12),
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  color: const Color(0xFF6366F1),
                  size: _getResponsiveSize(screenWidth, 20),
                ),
              ),
              SizedBox(width: _getResponsiveSize(screenWidth, 12)),
              Text(
                'Write Your Answer',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(screenWidth, baseSize: 20),
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              // Close button
              InkWell(
                onTap: () {
                  setState(() {
                    _showAnswerInput = false;
                  });
                },
                borderRadius: BorderRadius.circular(
                  _getResponsiveSize(screenWidth, 20),
                ),
                child: Container(
                  padding: EdgeInsets.all(_getResponsiveSize(screenWidth, 8)),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(
                      _getResponsiveSize(screenWidth, 20),
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey[600],
                    size: _getResponsiveSize(screenWidth, 20),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(screenWidth, 24)),

          // Modern Answer Input Field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(
                _getResponsiveSize(screenWidth, 20),
              ),
              border: Border.all(
                color: Colors.grey.withOpacity(0.15),
                width: _getResponsiveSize(screenWidth, 1.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: _getResponsiveSize(screenWidth, 8),
                  offset: Offset(0, _getResponsiveSize(screenWidth, 2)),
                ),
              ],
            ),
            child: TextField(
              controller: provider.answerController,
              focusNode: _answerFocusNode,
              maxLines: 5,
              maxLength: 1000,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, baseSize: 16),
                color: Colors.black87,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Share your knowledge and help others...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: _getResponsiveFontSize(screenWidth, baseSize: 16),
                  height: 1.5,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(
                  _getResponsiveSize(screenWidth, 20),
                ),
                counterText: '${provider.answerController.text.length}/1000',
                counterStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: _getResponsiveFontSize(screenWidth, baseSize: 12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: _getResponsiveSize(screenWidth, 20)),

          // Error Message
          if (provider.answerErrorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(_getResponsiveSize(screenWidth, 16)),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(
                  _getResponsiveSize(screenWidth, 16),
                ),
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
                    size: _getResponsiveSize(screenWidth, 20),
                  ),
                  SizedBox(width: _getResponsiveSize(screenWidth, 12)),
                  Expanded(
                    child: Text(
                      provider.answerErrorMessage!,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(
                          screenWidth,
                          baseSize: 14,
                        ),
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: _getResponsiveSize(screenWidth, 20)),
          ],

          // Modern Action Buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: Container(
                  height: _getResponsiveSize(screenWidth, 56),
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showAnswerInput = false;
                      });
                      provider.answerController.clear();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.grey[300]!,
                        width: _getResponsiveSize(screenWidth, 1.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _getResponsiveSize(screenWidth, 16),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: _getResponsiveSize(screenWidth, 16),
                        vertical: _getResponsiveSize(screenWidth, 12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(
                          screenWidth,
                          baseSize: 16,
                        ),
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: _getResponsiveSize(screenWidth, 12)),
              // Submit button
              Expanded(
                child: Container(
                  height: _getResponsiveSize(screenWidth, 56),
                  child: ElevatedButton(
                    onPressed:
                        provider.answerController.text.trim().isNotEmpty &&
                            !provider.isSubmittingAnswer
                        ? () => _submitAnswer(provider)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(188, 105, 73, 167),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _getResponsiveSize(screenWidth, 16),
                        ),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(
                        horizontal: _getResponsiveSize(screenWidth, 16),
                        vertical: _getResponsiveSize(screenWidth, 12),
                      ),
                    ),
                    child: provider.isSubmittingAnswer
                        ? SizedBox(
                            height: _getResponsiveSize(screenWidth, 20),
                            width: _getResponsiveSize(screenWidth, 20),
                            child: CircularProgressIndicator(
                              strokeWidth: _getResponsiveSize(screenWidth, 2.5),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.send,
                                size: _getResponsiveSize(screenWidth, 18),
                              ),
                              SizedBox(
                                width: _getResponsiveSize(screenWidth, 6),
                              ),
                              Flexible(
                                child: Text(
                                  'Submit',
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      screenWidth,
                                      baseSize: 14,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Event Handlers
  void _voteQuestion(VoteType voteType) async {
    final provider = Provider.of<QuestionDetailProvider>(
      context,
      listen: false,
    );
    await provider.voteQuestion(voteType);
    // Force a rebuild to update the UI
    if (mounted) {
      setState(() {});
    }
  }

  void _submitAnswer(QuestionDetailProvider provider) async {
    final success = await provider.submitAnswer();
    if (success) {
      // Clear focus and scroll to top to see the new answer
      _answerFocusNode.unfocus();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleShare() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _handleBookmark() {
    // Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmark functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _viewImage(String imageUrl) {
    // Implement image viewer
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(imageUrl: imageUrl),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  int getCurrentUserId() {
    // TODO: Get current user ID from authentication provider
    return 1; // Placeholder
  }
}

/// Answer Card Widget
class AnswerCard extends StatelessWidget {
  final Answer answer;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;
  final VoidCallback? onMarkBest;
  final bool canMarkBest;

  const AnswerCard({
    Key? key,
    required this.answer,
    this.onUpvote,
    this.onDownvote,
    this.onMarkBest,
    this.canMarkBest = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: answer.isBest
            ? AppColors.successColor.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: answer.isBest
            ? Border.all(
                color: AppColors.successColor.withOpacity(0.3),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Best Answer Badge
            if (answer.isBest) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Best Answer',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
            ],

            // Answer Header
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  child: Text(
                    answer.authorName.isNotEmpty
                        ? answer.authorName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: AppTextStyles.bodyText2.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer.authorName,
                        style: AppTextStyles.bodyText2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _formatTime(answer.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canMarkBest && !answer.isBest)
                  TextButton(
                    onPressed: onMarkBest,
                    child: Text(
                      'Mark as Best',
                      style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.successColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),

            // Answer Content
            Text(
              answer.content,
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),

            // Answer Actions
            Row(
              children: [
                // Vote Buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: onUpvote,
                      icon: Icon(
                        Icons.thumb_up_outlined,
                        color: answer.isUpvoted
                            ? AppColors.primaryColor
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${answer.upvotes}',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      onPressed: onDownvote,
                      icon: Icon(
                        Icons.thumb_down_outlined,
                        color: answer.isDownvoted
                            ? AppColors.errorColor
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${answer.downvotes}',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                Spacer(),

                // Share Button
                IconButton(
                  onPressed: () {
                    // Implement share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Share functionality coming soon!'),
                        backgroundColor: AppColors.infoColor,
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.share_outlined,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Image Viewer Screen
class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewerScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Image', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
