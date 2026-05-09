import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../widgets/edit_question_popup.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/error_widget.dart' as custom;
import '../../../../shared/widgets/modern_dialog.dart';
import '../../domain/entities/question.dart';

/// My Questions Screen
/// Displays questions posted by the current user with their answers
class MyQuestionsScreen extends StatefulWidget {
  const MyQuestionsScreen({Key? key}) : super(key: key);

  @override
  _MyQuestionsScreenState createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends State<MyQuestionsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupScrollListener();
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
    super.dispose();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserQuestions();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        if (profileProvider.hasMoreQuestions &&
            !profileProvider.isLoadingMoreQuestions) {
          profileProvider.loadMoreQuestions();
        }
      }
    });
  }

  /// Get status color and styling for question status
  Map<String, dynamic> _getStatusStyling(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return {
          'color': Colors.green,
          'backgroundColor': Colors.green.withOpacity(0.1),
          'icon': Icons.check_circle,
          'text': 'Approved',
        };
      case 'pending':
        return {
          'color': Colors.orange,
          'backgroundColor': Colors.orange.withOpacity(0.1),
          'icon': Icons.hourglass_empty,
          'text': 'Pending',
        };
      case 'rejected':
        return {
          'color': Colors.red,
          'backgroundColor': Colors.red.withOpacity(0.1),
          'icon': Icons.cancel,
          'text': 'Rejected',
        };
      case 'reported':
        return {
          'color': Colors.purple,
          'backgroundColor': Colors.purple.withOpacity(0.1),
          'icon': Icons.flag,
          'text': 'Reported',
        };
      case 'closed':
        return {
          'color': Colors.grey,
          'backgroundColor': Colors.grey.withOpacity(0.1),
          'icon': Icons.lock,
          'text': 'Closed',
        };
      default:
        return {
          'color': Colors.blue,
          'backgroundColor': Colors.blue.withOpacity(0.1),
          'icon': Icons.help_outline,
          'text': status,
        };
    }
  }

  Future<void> _loadUserQuestions() async {
    final authProvider = Provider.of<AuthenticationProvider>(
      context,
      listen: false,
    );
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      return;
    }

    // Check if user has valid ID
    if (authProvider.user?.id == null) {
      return;
    }

    try {
      await profileProvider.loadUserQuestionsDirectly(forceRefresh: true);
    } catch (e) {
      // Error is handled by the profile provider
    }
  }

  Future<void> _refreshQuestions() async {
    final authProvider = Provider.of<AuthenticationProvider>(
      context,
      listen: false,
    );
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      return;
    }

    // Check if user has valid ID
    if (authProvider.user?.id == null) {
      return;
    }

    try {
      await profileProvider.loadUserQuestionsDirectly();
    } catch (e) {
      // Error is handled by the profile provider
    }
  }

  void _navigateToQuestionDetail(Question question) {
    Navigator.of(context).pushNamed(
      '/question-details',
      arguments: {RouteArguments.questionId: question.id},
    );
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
        child: Column(
          children: [
            _buildHeaderSection(
              screenWidth,
              horizontalPadding,
              verticalPadding,
            ),
            _buildQuestionsList(
              screenWidth,
              horizontalPadding,
              verticalPadding,
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeaderSection(
    double screenWidth,
    double horizontalPadding,
    double verticalPadding,
  ) {
    return Container(
      color: const Color.fromARGB(188, 105, 73, 167),
      child: Consumer2<AuthenticationProvider, ProfileProvider>(
        builder: (context, authProvider, profileProvider, child) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              children: [
                // Header with back button and title
                Row(
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
                        'My Questions',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(
                            screenWidth,
                            baseSize: 24,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (profileProvider.userQuestions.isNotEmpty)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: _getResponsiveFontSize(
                            screenWidth,
                            baseSize: 24,
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'refresh') {
                            _refreshQuestions();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'refresh',
                            child: Row(
                              children: [
                                Icon(Icons.refresh),
                                SizedBox(width: 8),
                                Text('Refresh'),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: _getResponsiveFontSize(
                          screenWidth,
                          baseSize: 24,
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: _getResponsiveFontSize(screenWidth, baseSize: 16),
                ),
                // User info and stats
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, ${authProvider.userDisplayName ?? 'User'} 👋',
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(
                                screenWidth,
                                baseSize: 20,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                            height: _getResponsiveFontSize(
                              screenWidth,
                              baseSize: 4,
                            ),
                          ),
                          Text(
                            'You have ${profileProvider.userQuestions.length} question${profileProvider.userQuestions.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(
                                screenWidth,
                                baseSize: 14,
                              ),
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
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
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          _getResponsiveSize(screenWidth, 20),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${profileProvider.userQuestions.length}',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(
                            screenWidth,
                            baseSize: 16,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnauthenticatedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login_outlined,
              size: 80,
              color: AppColors.primaryColor.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Login Required',
              style: AppTextStyles.headline6.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please login to view your questions',
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Go to Login',
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 80,
              color: AppColors.primaryColor.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'No Questions Yet',
              style: AppTextStyles.headline6.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t posted any questions yet. Start by asking your first question!',
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Ask a Question',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.askQuestion);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ProfileProvider profileProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Questions',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profileProvider.userQuestions.length} question${profileProvider.userQuestions.length != 1 ? 's' : ''}',
                  style: AppTextStyles.bodyText2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (profileProvider.hasMoreQuestions)
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                if (profileProvider.isLoadingMoreQuestions) {
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList(
    double screenWidth,
    double horizontalPadding,
    double verticalPadding,
  ) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Container(
          color: Colors.white,
          child: Consumer2<AuthenticationProvider, ProfileProvider>(
            builder: (context, authProvider, profileProvider, child) {
              // Check if user is authenticated
              if (!authProvider.isAuthenticated) {
                return _buildUnauthenticatedView();
              }

              // Show skeleton loading state
              if (profileProvider.isLoadingQuestions &&
                  profileProvider.userQuestions.isEmpty) {
                return _buildSkeletonLoading();
              }

              // Show error state
              if (profileProvider.errorMessage != null &&
                  profileProvider.userQuestions.isEmpty) {
                return Center(
                  child: custom.ErrorWidget(
                    message: profileProvider.errorMessage!,
                    onRetry: _loadUserQuestions,
                  ),
                );
              }

              // Show empty state
              if (profileProvider.userQuestions.isEmpty) {
                return _buildEmptyState();
              }

              // Show questions list
              return RefreshIndicator(
                onRefresh: _refreshQuestions,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  itemCount:
                      profileProvider.userQuestions.length +
                      (profileProvider.isLoadingMoreQuestions ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == profileProvider.userQuestions.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: _getResponsiveSize(screenWidth, 12),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor,
                            ),
                          ),
                        ),
                      );
                    }

                    final question = profileProvider.userQuestions[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: _getResponsiveSize(screenWidth, 16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            _getResponsiveSize(screenWidth, 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: _getResponsiveSize(screenWidth, 15),
                              offset: Offset(
                                0,
                                _getResponsiveSize(screenWidth, 5),
                              ),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: _getResponsiveSize(screenWidth, 8),
                              offset: Offset(
                                0,
                                _getResponsiveSize(screenWidth, 2),
                              ),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _navigateToQuestionDetail(question),
                          borderRadius: BorderRadius.circular(
                            _getResponsiveSize(screenWidth, 20),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              _getResponsiveSize(screenWidth, 20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Question title with gradient accent
                                Container(
                                  padding: EdgeInsets.only(
                                    bottom: _getResponsiveSize(screenWidth, 12),
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        question.title,
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            screenWidth,
                                            baseSize: 18,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1A1A1A),
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: _getResponsiveSize(screenWidth, 12),
                                ),
                                // Question content
                                Text(
                                  question.content,
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      screenWidth,
                                      baseSize: 14,
                                    ),
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Question images (if available)
                                if (question.images.isNotEmpty) ...[
                                  SizedBox(
                                    height: _getResponsiveSize(screenWidth, 12),
                                  ),
                                  _buildQuestionImages(question, screenWidth),
                                  SizedBox(
                                    height: _getResponsiveSize(screenWidth, 12),
                                  ),
                                ] else
                                  SizedBox(
                                    height: _getResponsiveSize(screenWidth, 12),
                                  ),

                                // Status and subject row
                                Row(
                                  children: [
                                    // Status badge
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: _getResponsiveSize(
                                          screenWidth,
                                          8,
                                        ),
                                        vertical: _getResponsiveSize(
                                          screenWidth,
                                          4,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusStyling(
                                          question.status,
                                        )['backgroundColor'],
                                        borderRadius: BorderRadius.circular(
                                          _getResponsiveSize(screenWidth, 12),
                                        ),
                                        border: Border.all(
                                          color: _getStatusStyling(
                                            question.status,
                                          )['color'].withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getStatusStyling(
                                              question.status,
                                            )['icon'],
                                            size: _getResponsiveSize(
                                              screenWidth,
                                              12,
                                            ),
                                            color: _getStatusStyling(
                                              question.status,
                                            )['color'],
                                          ),
                                          SizedBox(
                                            width: _getResponsiveSize(
                                              screenWidth,
                                              4,
                                            ),
                                          ),
                                          Text(
                                            _getStatusStyling(
                                              question.status,
                                            )['text'],
                                            style: TextStyle(
                                              fontSize: _getResponsiveFontSize(
                                                screenWidth,
                                                baseSize: 10,
                                              ),
                                              color: _getStatusStyling(
                                                question.status,
                                              )['color'],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: _getResponsiveSize(screenWidth, 8),
                                    ),
                                    // Subject tag with gradient
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: _getResponsiveSize(
                                            screenWidth,
                                            12,
                                          ),
                                          vertical: _getResponsiveSize(
                                            screenWidth,
                                            6,
                                          ),
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF667EEA),
                                              const Color(0xFF764BA2),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            _getResponsiveSize(screenWidth, 15),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF667EEA,
                                              ).withOpacity(0.3),
                                              blurRadius: _getResponsiveSize(
                                                screenWidth,
                                                8,
                                              ),
                                              offset: Offset(
                                                0,
                                                _getResponsiveSize(
                                                  screenWidth,
                                                  2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            question.subject,
                                            style: TextStyle(
                                              fontSize: _getResponsiveFontSize(
                                                screenWidth,
                                                baseSize: 12,
                                              ),
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                    // Stats container
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: _getResponsiveSize(
                                          screenWidth,
                                          10,
                                        ),
                                        vertical: _getResponsiveSize(
                                          screenWidth,
                                          6,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(
                                          _getResponsiveSize(screenWidth, 12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            size: _getResponsiveSize(
                                              screenWidth,
                                              16,
                                            ),
                                            color: Colors.grey[600],
                                          ),
                                          SizedBox(
                                            width: _getResponsiveSize(
                                              screenWidth,
                                              6,
                                            ),
                                          ),
                                          Text(
                                            '${question.answerCount}',
                                            style: TextStyle(
                                              fontSize: _getResponsiveFontSize(
                                                screenWidth,
                                                baseSize: 12,
                                              ),
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: _getResponsiveSize(screenWidth, 12),
                                ),
                                // Action buttons row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Edit button
                                    Container(
                                      width: _getResponsiveSize(
                                        screenWidth,
                                        36,
                                      ),
                                      height: _getResponsiveSize(
                                        screenWidth,
                                        36,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF667EEA),
                                            Color(0xFF764BA2),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          _getResponsiveSize(screenWidth, 8),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(
                                              0xFF667EEA,
                                            ).withOpacity(0.3),
                                            blurRadius: _getResponsiveSize(
                                              screenWidth,
                                              8,
                                            ),
                                            offset: Offset(
                                              0,
                                              _getResponsiveSize(
                                                screenWidth,
                                                2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _editQuestion(question),
                                          borderRadius: BorderRadius.circular(
                                            _getResponsiveSize(screenWidth, 8),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.edit_outlined,
                                              size: _getResponsiveSize(
                                                screenWidth,
                                                18,
                                              ),
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: _getResponsiveSize(screenWidth, 8),
                                    ),
                                    // Delete button
                                    Container(
                                      width: _getResponsiveSize(
                                        screenWidth,
                                        36,
                                      ),
                                      height: _getResponsiveSize(
                                        screenWidth,
                                        36,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFF56565),
                                            Color(0xFFE53E3E),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          _getResponsiveSize(screenWidth, 8),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(
                                              0xFFF56565,
                                            ).withOpacity(0.3),
                                            blurRadius: _getResponsiveSize(
                                              screenWidth,
                                              8,
                                            ),
                                            offset: Offset(
                                              0,
                                              _getResponsiveSize(
                                                screenWidth,
                                                2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () =>
                                              _deleteQuestion(question),
                                          borderRadius: BorderRadius.circular(
                                            _getResponsiveSize(screenWidth, 8),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.delete_outline,
                                              size: _getResponsiveSize(
                                                screenWidth,
                                                18,
                                              ),
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionImages(Question question, double screenWidth) {
    // Limit to 3 images max in card view
    final imagesToShow = question.images.take(3).toList();
    final hasMoreImages = question.images.length > 3;

    return Container(
      height: _getResponsiveSize(screenWidth, 100),
      child: Row(
        children: [
          // Display images
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imagesToShow.length,
              separatorBuilder: (context, index) =>
                  SizedBox(width: _getResponsiveSize(screenWidth, 8)),
              itemBuilder: (context, index) {
                final imageUrl = imagesToShow[index];
                return Container(
                  width: _getResponsiveSize(screenWidth, 100),
                  height: _getResponsiveSize(screenWidth, 100),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.grey[400],
                                size: _getResponsiveSize(screenWidth, 20),
                              ),
                              SizedBox(
                                height: _getResponsiveSize(screenWidth, 4),
                              ),
                              Text(
                                'Failed to load',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: _getResponsiveFontSize(
                                    screenWidth,
                                    baseSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[100],
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
                );
              },
            ),
          ),

          // Show "more images" indicator
          if (hasMoreImages) ...[
            SizedBox(width: _getResponsiveSize(screenWidth, 8)),
            Container(
              width: _getResponsiveSize(screenWidth, 35),
              height: _getResponsiveSize(screenWidth, 100),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  _getResponsiveSize(screenWidth, 8),
                ),
                color: Colors.black.withOpacity(0.7),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: _getResponsiveSize(screenWidth, 18),
                  ),
                  SizedBox(height: _getResponsiveSize(screenWidth, 4)),
                  Text(
                    '+${question.images.length - 3}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _getResponsiveFontSize(
                        screenWidth,
                        baseSize: 11,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).pushNamed(AppRoutes.askQuestion);
      },
      backgroundColor: AppColors.primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: 3, // Show 3 skeleton cards
      itemBuilder: (context, index) {
        return _buildSkeletonCard();
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1),
        boxShadow: [
          // Primary shadow for depth - enhanced
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 32,
            offset: Offset(0, 12),
            spreadRadius: 0,
          ),
          // Secondary shadow for elevation - enhanced
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
          // Tertiary shadow for depth
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: -4,
          ),
          // Subtle ambient shadow with blue tint
          BoxShadow(
            color: Colors.blue.withOpacity(0.04),
            blurRadius: 48,
            offset: Offset(0, 20),
            spreadRadius: -12,
          ),
          // Additional colored shadow for visual interest
          BoxShadow(
            color: Colors.purple.withOpacity(0.02),
            blurRadius: 64,
            offset: Offset(0, 32),
            spreadRadius: -16,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton image placeholder
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[200],
              ),
              child: _shimmerEffect(),
            ),

            SizedBox(height: 12),

            // Skeleton title
            Container(
              width: double.infinity,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: _shimmerEffect(),
            ),

            SizedBox(height: 8),

            // Skeleton subtitle
            Container(
              width: double.infinity * 0.8,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey[200],
              ),
              child: _shimmerEffect(),
            ),

            SizedBox(height: 16),

            // Skeleton content lines
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
              ),
              child: _shimmerEffect(),
            ),

            SizedBox(height: 8),

            Container(
              width: double.infinity * 0.9,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
              ),
              child: _shimmerEffect(),
            ),

            SizedBox(height: 8),

            Container(
              width: double.infinity * 0.7,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
              ),
              child: _shimmerEffect(),
            ),

            SizedBox(height: 16),

            // Skeleton tags
            Row(
              children: [
                Container(
                  width: 80,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[200],
                  ),
                  child: _shimmerEffect(),
                ),
                SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[200],
                  ),
                  child: _shimmerEffect(),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Skeleton bottom row
            Row(
              children: [
                // Skeleton avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child: _shimmerEffect(),
                ),

                SizedBox(width: 12),

                // Skeleton user info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[200],
                        ),
                        child: _shimmerEffect(),
                      ),
                      SizedBox(height: 4),
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[200],
                        ),
                        child: _shimmerEffect(),
                      ),
                    ],
                  ),
                ),

                // Skeleton answer count
                Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[200],
                  ),
                  child: _shimmerEffect(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerEffect() {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 1500),
      tween: Tween<double>(begin: -1.0, end: 2.0),
      builder: (context, double value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [Colors.grey[200]!, Colors.grey[300]!, Colors.grey[200]!],
              stops: [0.0, 0.5, 1.0],
              begin: Alignment(value - 1.0, 0),
              end: Alignment(value, 0),
            ).createShader(bounds);
          },
          child: Container(decoration: BoxDecoration(color: Colors.grey[200])),
        );
      },
    );
  }

  void _editQuestion(Question question) {
    try {
      print('Editing question: ${question.id} - ${question.title}');
      // Get the profile provider before showing dialog
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      // Show edit question popup as bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (dialogContext) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: EditQuestionPopup(
              question: question,
              profileProvider: profileProvider,
              onUpdate: () {
                // Refresh the questions list after update
                profileProvider.loadUserQuestionsDirectly(forceRefresh: true);
              },
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error showing edit popup: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening edit popup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteQuestion(Question question) {
    // Show confirmation dialog
    ModernDialog.showConfirmation(
      context: context,
      title: 'Delete Question',
      message:
          'Are you sure you want to delete this question?\n\n"${question.title}"\n\nThis action cannot be undone.',
      primaryText: 'Delete',
      secondaryText: 'Cancel',
      icon: Icons.delete_outline,
      iconColor: const Color(0xFFF44336),
    ).then((confirmed) {
      if (confirmed == true) {
        _performDeleteQuestion(question);
      }
    });
  }

  void _performDeleteQuestion(Question question) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Deleting question...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Call the delete method from ProfileProvider
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final success = await profileProvider.deleteQuestion(question.id);

      // Close loading indicator
      Navigator.of(context).pop();

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Question deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to delete question'),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator if still open
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('An error occurred: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
