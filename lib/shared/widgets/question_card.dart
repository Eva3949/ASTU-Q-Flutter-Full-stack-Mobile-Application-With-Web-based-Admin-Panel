import 'package:flutter/material.dart';
import '../../features/questions/domain/entities/question.dart';

/// Question Card Widget
/// Reusable card for displaying question information
class QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onTap;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote; // Optional, not used anymore
  final VoidCallback? onShare;
  final bool showUserAvatar;
  final bool showSubject;
  final bool showActions;

  const QuestionCard({
    Key? key,
    required this.question,
    required this.onTap,
    this.onUpvote,
    this.onDownvote = null,
    this.onShare,
    this.showUserAvatar = true,
    this.showSubject = true,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Images (if available) - Display as thumbnail above title
                if (question.images.isNotEmpty) ...[
                  _buildQuestionImages(),
                  const SizedBox(height: 12),
                ],

                // Question Header
                if (showUserAvatar) ...[
                  _buildQuestionHeader(),
                  const SizedBox(height: 12),
                ],

                // Question Title
                _buildQuestionTitle(),

                // Question Content (if available)
                if (question.content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildQuestionContent(),
                ],

                // Question Footer
                if (showActions) ...[
                  const SizedBox(height: 12),
                  _buildQuestionFooter(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return Row(
      children: [
        // User Avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Text(
            question.authorName.isNotEmpty
                ? question.authorName.substring(0, 1).toUpperCase()
                : 'U',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.authorName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    _formatTime(question.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (showSubject && question.subject.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.subject,
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // More Options
        IconButton(
          onPressed: () {
            // Show more options
          },
          icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
        ),
      ],
    );
  }

  Widget _buildQuestionTitle() {
    return Text(
      question.title,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildQuestionContent() {
    return Text(
      question.content,
      style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildQuestionImages() {
    // Display as thumbnail - show first image as main thumbnail
    final primaryImage = question.images.first;
    final hasMoreImages = question.images.length > 1;

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            // Main thumbnail image
            Positioned.fill(
              child: Image.network(
                primaryImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[100],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[50],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey[400]!,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Gradient overlay for better text readability
            if (hasMoreImages)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),

            // More images indicator
            if (hasMoreImages)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '+${question.images.length - 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionFooter() {
    return Row(
      children: [
        // Vote Buttons
        Row(
          children: [
            IconButton(
              onPressed: onUpvote,
              icon: Icon(
                question.isUpvoted ? Icons.favorite : Icons.favorite_border,
                color: question.isUpvoted ? Colors.red : Colors.grey[600],
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 4),
            Text(
              '${question.upvotes}',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const Spacer(),

        // Answer Count
        Row(
          children: [
            Icon(
              Icons.question_answer_outlined,
              color: Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              '${question.answerCount} answers',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(width: 16),

        // Share Button
        if (onShare != null)
          IconButton(
            onPressed: onShare,
            icon: Icon(Icons.share_outlined, color: Colors.grey[600], size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }

  String _formatTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}

/// Compact Question Card Widget
/// Smaller version for limited space
class CompactQuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onTap;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;

  const CompactQuestionCard({
    Key? key,
    required this.question,
    required this.onTap,
    this.onUpvote,
    this.onDownvote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Vote Section
                Column(
                  children: [
                    IconButton(
                      onPressed: onUpvote,
                      icon: Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                    Text(
                      '${question.upvotes - question.downvotes}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      onPressed: onDownvote,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Question Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show image thumbnail above title in compact view
                      if (question.images.isNotEmpty) ...[
                        Container(
                          height: 80,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.network(
                                    question.images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[100],
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey[400],
                                          size: 24,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Show more images indicator
                                if (question.images.length > 1)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '+${question.images.length - 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      Text(
                        question.title,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            question.authorName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(question.createdAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (question.answerCount > 0)
                            Text(
                              '${question.answerCount} answers',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
