import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../utils/time_ago.dart';
import 'loading_widget.dart';
import 'error_widget.dart' as custom;
import '../../features/questions/domain/entities/question.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/text_styles.dart';

/// Question Card Widget
/// Reusable card component for displaying questions with consistent styling
class QuestionCardWidget extends StatelessWidget {
  final Question question;
  final VoidCallback? onTap;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool showFullContent;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const QuestionCardWidget({
    Key? key,
    required this.question,
    this.onTap,
    this.onUpvote,
    this.onDownvote,
    this.onBookmark,
    this.onShare,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.showFullContent = false,
    this.elevation,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.currentUser?.id == question.authorId;

    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with author info
            _buildHeader(context, isOwner),

            SizedBox(height: 12.h),

            // Question title
            _buildTitle(),

            SizedBox(height: 8.h),

            // Question content
            _buildContent(),

            // Tags
            if (question.tags.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _buildTags(),
            ],

            SizedBox(height: 16.h),

            // Stats and actions
            _buildFooter(context, isOwner),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isOwner) {
    return Row(
      children: [
        // User avatar
        CircleAvatar(
          radius: 20,
          backgroundImage: question.authorAvatarUrl != null
              ? NetworkImage(question.authorAvatarUrl!)
              : null,
          child: question.authorAvatarUrl == null
              ? Text(
                  question.authorName.isNotEmpty
                      ? question.authorName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),

        SizedBox(width: 12.w),

        // Author info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    question.authorName,
                    style: AppTextStyles.bodyText2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (question.authorIsVerified) ...[
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.verified,
                      size: 16.sp,
                      color: AppColors.primaryColor,
                    ),
                  ],
                  if (isOwner) ...[
                    SizedBox(width: 4.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'You',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Text(
                    TimeAgo.format(question.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (question.updatedAt != null &&
                      question.updatedAt != question.createdAt) ...[
                    SizedBox(width: 8.w),
                    Text(
                      '·',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'edited ${TimeAgo.format(question.updatedAt!)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // More options
        if (showActions) _buildMoreOptions(context, isOwner),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      question.title,
      style: AppTextStyles.headline4.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildContent() {
    final content = showFullContent
        ? question.content
        : question.content.length > 200
        ? '${question.content.substring(0, 200)}...'
        : question.content;

    return Text(
      content,
      style: AppTextStyles.bodyText2.copyWith(
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      maxLines: showFullContent ? null : 3,
      overflow: showFullContent ? null : TextOverflow.ellipsis,
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: question.tags.map((tag) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            tag,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context, bool isOwner) {
    return Row(
      children: [
        // Vote buttons
        _buildVoteButtons(),

        SizedBox(width: 16.w),

        // Answer count
        _buildAnswerCount(),

        Spacer(),

        // View count
        _buildViewCount(),

        SizedBox(width: 16.w),

        // Action buttons
        if (showActions) ...[_buildActionButtons(context, isOwner)],
      ],
    );
  }

  Widget _buildVoteButtons() {
    return Row(
      children: [
        // Upvote
        InkWell(
          borderRadius: BorderRadius.circular(4.r),
          onTap: onUpvote,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: question.isUpvoted
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.thumb_up_outlined,
                  size: 16.sp,
                  color: question.isUpvoted
                      ? AppColors.primaryColor
                      : AppColors.textSecondary,
                ),
                SizedBox(width: 4.w),
                Text(
                  _formatNumber(question.upvotes),
                  style: AppTextStyles.caption.copyWith(
                    color: question.isUpvoted
                        ? AppColors.primaryColor
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: 8.w),

        // Downvote
        InkWell(
          borderRadius: BorderRadius.circular(4.r),
          onTap: onDownvote,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: question.isDownvoted
                  ? AppColors.errorColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.thumb_down_outlined,
                  size: 16.sp,
                  color: question.isDownvoted
                      ? AppColors.errorColor
                      : AppColors.textSecondary,
                ),
                SizedBox(width: 4.w),
                Text(
                  _formatNumber(question.downvotes),
                  style: AppTextStyles.caption.copyWith(
                    color: question.isDownvoted
                        ? AppColors.errorColor
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerCount() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: question.hasAcceptedAnswer
            ? AppColors.successColor.withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.comment_outlined,
            size: 16.sp,
            color: question.hasAcceptedAnswer
                ? AppColors.successColor
                : AppColors.textSecondary,
          ),
          SizedBox(width: 4.w),
          Text(
            _formatNumber(question.answerCount),
            style: AppTextStyles.caption.copyWith(
              color: question.hasAcceptedAnswer
                  ? AppColors.successColor
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (question.hasAcceptedAnswer) ...[
            SizedBox(width: 4.w),
            Icon(
              Icons.check_circle,
              size: 12.sp,
              color: AppColors.successColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewCount() {
    return Row(
      children: [
        Icon(
          Icons.visibility_outlined,
          size: 16.sp,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 4.w),
        Text(
          _formatNumber(question.viewCount),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isOwner) {
    return Row(
      children: [
        // Bookmark
        InkWell(
          borderRadius: BorderRadius.circular(4.r),
          onTap: onBookmark,
          child: Container(
            padding: EdgeInsets.all(6.w),
            child: Icon(
              question.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              size: 18.sp,
              color: question.isBookmarked
                  ? AppColors.primaryColor
                  : AppColors.textSecondary,
            ),
          ),
        ),

        // Share
        InkWell(
          borderRadius: BorderRadius.circular(4.r),
          onTap: onShare,
          child: Container(
            padding: EdgeInsets.all(6.w),
            child: Icon(
              Icons.share_outlined,
              size: 18.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreOptions(BuildContext context, bool isOwner) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20.sp),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
          case 'report':
            _showReportDialog(context);
            break;
          case 'copy_link':
            _copyLink(context);
            break;
        }
      },
      itemBuilder: (context) => [
        if (isOwner) ...[
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16.sp),
                SizedBox(width: 8.w),
                Text('Edit Question'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16.sp, color: AppColors.errorColor),
                SizedBox(width: 8.w),
                Text(
                  'Delete Question',
                  style: TextStyle(color: AppColors.errorColor),
                ),
              ],
            ),
          ),
          PopupMenuDivider(),
        ],
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag, size: 16.sp),
              SizedBox(width: 8.w),
              Text('Report'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy_link',
          child: Row(
            children: [
              Icon(Icons.link, size: 16.sp),
              SizedBox(width: 8.w),
              Text('Copy Link'),
            ],
          ),
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Why are you reporting this question?'),
            SizedBox(height: 16.h),
            ...['Spam', 'Inappropriate', 'Duplicate', 'Other'].map(
              (reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: null,
                onChanged: (value) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Question reported successfully')),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _copyLink(BuildContext context) {
    // Copy link to clipboard
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Link copied to clipboard')));
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}

/// Compact Question Card Widget
/// Smaller version for use in lists and search results
class CompactQuestionCardWidget extends StatelessWidget {
  final Question question;
  final VoidCallback? onTap;
  final bool showAuthor;

  const CompactQuestionCardWidget({
    Key? key,
    required this.question,
    this.onTap,
    this.showAuthor = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question.title,
                    style: AppTextStyles.bodyText1.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    question.answerCount.toString(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            if (showAuthor) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: question.authorAvatarUrl != null
                        ? NetworkImage(question.authorAvatarUrl!)
                        : null,
                    child: question.authorAvatarUrl == null
                        ? Text(
                            question.authorName.isNotEmpty
                                ? question.authorName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    question.authorName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Spacer(),
                  Text(
                    TimeAgo.format(question.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            if (question.tags.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Wrap(
                spacing: 4.w,
                runSpacing: 4.h,
                children: question.tags.take(3).map((tag) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      tag,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Question Card List Widget
/// Displays a list of question cards with loading and error states
class QuestionCardListWidget extends StatelessWidget {
  final List<Question> questions;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Function(Question)? onQuestionTap;
  final Function(Question)? onQuestionUpvote;
  final Function(Question)? onQuestionDownvote;
  final Function(Question)? onQuestionBookmark;
  final bool compact;

  const QuestionCardListWidget({
    Key? key,
    required this.questions,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onQuestionTap,
    this.onQuestionUpvote,
    this.onQuestionDownvote,
    this.onQuestionBookmark,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading && questions.isEmpty) {
      return const LoadingWidget();
    }

    if (error != null && questions.isEmpty) {
      return custom.ErrorWidget(message: error!, onRetry: onRetry);
    }

    if (questions.isEmpty && !isLoading) {
      return custom.EmptyStateWidget(
        icon: Icons.question_answer,
        title: 'No Questions Found',
        message: 'Be the first to ask a question!',
      );
    }

    return Column(
      children: [
        // Questions list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: questions.length,
          separatorBuilder: (context, index) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final question = questions[index];

            if (compact) {
              return CompactQuestionCardWidget(
                question: question,
                onTap: () => onQuestionTap?.call(question),
              );
            } else {
              return QuestionCardWidget(
                question: question,
                onTap: () => onQuestionTap?.call(question),
                onUpvote: () => onQuestionUpvote?.call(question),
                onDownvote: () => onQuestionDownvote?.call(question),
                onBookmark: () => onQuestionBookmark?.call(question),
              );
            }
          },
        ),

        // Loading indicator at bottom
        if (isLoading && questions.isNotEmpty) ...[
          SizedBox(height: 16.h),
          const LoadingWidget(size: 40),
        ],
      ],
    );
  }
}
