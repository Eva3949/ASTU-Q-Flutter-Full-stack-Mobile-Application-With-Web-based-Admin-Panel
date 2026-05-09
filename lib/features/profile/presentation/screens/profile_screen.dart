import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/profile_provider.dart';
import '../../domain/entities/answer.dart';
import '../../domain/entities/question.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/modern_dialog.dart';

/// Profile Screen
/// Displays user profile information and activity
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeListeners();
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeListeners() {
    // Listen to scroll events for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more content when near bottom
      final provider = Provider.of<ProfileProvider>(context, listen: false);

      if (_tabController.index == 0) {
        // Questions tab
        if (provider.hasMoreQuestions && !provider.isLoadingMoreQuestions) {
          provider.loadMoreQuestions();
        }
      } else {
        // Answers tab
        if (provider.hasMoreAnswers && !provider.isLoadingMoreAnswers) {
          provider.loadMoreAnswers();
        }
      }
    }
  }

  void _loadProfile() {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    provider.loadUserProfile(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemUiOverlayStyle,
        child: SafeArea(
          child: Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.userProfile == null) {
                return _buildSkeletonLoading();
              }

              if (provider.errorMessage != null &&
                  provider.userProfile == null) {
                return _buildErrorState(provider);
              }

              if (provider.userProfile == null) {
                return _buildEmptyState();
              }

              return _buildContent(provider);
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: AppTheme.systemUiOverlayStyle,
      title: Text(
        'Profile',
        style: AppTextStyles.headline3.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _handleSettings,
          icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildErrorState(ProfileProvider provider) {
    final bool isUnauthorized =
        provider.errorMessage!.toLowerCase().contains('not found') ||
        provider.errorMessage!.toLowerCase().contains('log in');

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnauthorized ? Icons.lock_outline : Icons.error_outline,
              size: 64,
              color: isUnauthorized
                  ? AppColors.primaryColor
                  : AppColors.errorColor,
            ),
            SizedBox(height: 24),
            Text(
              isUnauthorized
                  ? 'Authentication Required'
                  : 'No Internet connection',
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
            if (isUnauthorized)
              CustomButton(
                text: 'Go to Login',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false),
                prefixIcon: Icons.login,
              )
            else
              CustomButton(
                text: 'Try Again',
                onPressed: _loadProfile,
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
              Icons.person_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 24),
            Text(
              'Profile Not Found',
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Unable to load your profile information.',
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

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header Skeleton
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar Skeleton
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 16),
                      // Name and Bio Skeleton
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 24,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 16,
                              width: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // Stats Section Skeleton
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(4, (index) {
                  return Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: 30,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          SizedBox(height: 16),
          // Level Progress Skeleton
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // Achievements Skeleton
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(3, (index) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ProfileProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        await provider.refreshProfile();
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildProfileHeader(provider),
            _buildStatsSection(provider),
            _buildLevelProgress(provider),
            _buildAchievementsSection(provider),
            _buildTabsSection(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ProfileProvider provider) {
    final profile = provider.userProfile!;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: profile.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          profile.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.primaryColor,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.primaryColor,
                      ),
              ),
              SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: AppTextStyles.headline2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      profile.email,
                      style: AppTextStyles.bodyText1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor(
                              profile.level,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            provider.getLevelProgress()['levelName'],
                            style: AppTextStyles.caption.copyWith(
                              color: _getLevelColor(profile.level),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Level ${profile.level}',
                          style: AppTextStyles.bodyText2.copyWith(
                            color: AppColors.textSecondary,
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

          SizedBox(height: 16),

          // Bio (if available)
          if (profile.bio?.isNotEmpty == true) ...[
            Text(
              profile.bio!,
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
          ],

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleEditProfile,
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleShareProfile,
                  icon: Icon(Icons.share_outlined, size: 18),
                  label: Text('Share'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ProfileProvider provider) {
    final stats = provider.getUserStatistics();

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: AppTextStyles.headline4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Points',
                  '${stats['points']}',
                  Icons.star,
                  AppColors.warningColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Questions',
                  '${stats['questions']}',
                  Icons.question_answer,
                  AppColors.infoColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Answers',
                  '${stats['answers']}',
                  Icons.chat,
                  AppColors.successColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Best Answers',
                  '${stats['bestAnswers']}',
                  Icons.check_circle,
                  AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLevelProgress(ProfileProvider provider) {
    final levelProgress = provider.getLevelProgress();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level Progress',
                style: AppTextStyles.headline4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${levelProgress['pointsToNextLevel']} pts to next level',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: levelProgress['progress'],
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${levelProgress['currentLevel']}',
                style: AppTextStyles.bodyText2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Level ${levelProgress['currentLevel'] + 1}',
                style: AppTextStyles.bodyText2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(ProfileProvider provider) {
    final achievements = provider.getAchievements();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: AppTextStyles.headline4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),

          if (achievements.isEmpty)
            Text(
              'No achievements yet. Keep participating to earn badges!',
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: achievements.map((achievement) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.successColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    achievement,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabsSection(ProfileProvider provider) {
    return Container(
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryColor,
            indicatorWeight: 2,
            labelStyle: AppTextStyles.buttonText.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTextStyles.buttonText,
            tabs: const [
              Tab(text: 'Questions'),
              Tab(text: 'Answers'),
            ],
          ),

          // Tab Content
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestionsTab(provider),
                _buildAnswersTab(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab(ProfileProvider provider) {
    if (provider.isLoadingQuestions && provider.userQuestions.isEmpty) {
      return const Center(
        child: LoadingWidget(message: 'Loading questions...'),
      );
    }

    if (provider.userQuestions.isEmpty) {
      return _buildEmptyTabState(
        'No questions yet',
        'Start asking questions to see them here!',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: provider.questionCount + (provider.hasMoreQuestions ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.questionCount && provider.hasMoreQuestions) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: const Center(child: LoadingWidget(size: 24)),
          );
        }

        final question = provider.userQuestions[index];
        return CompactQuestionCard(
          question: question,
          onTap: () => _handleQuestionTap(question),
        );
      },
    );
  }

  Widget _buildAnswersTab(ProfileProvider provider) {
    if (provider.isLoadingAnswers && provider.userAnswers.isEmpty) {
      return const Center(child: LoadingWidget(message: 'Loading answers...'));
    }

    if (provider.userAnswers.isEmpty) {
      return _buildEmptyTabState(
        'No answers yet',
        'Start answering questions to see them here!',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: provider.answerCount + (provider.hasMoreAnswers ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.answerCount && provider.hasMoreAnswers) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: const Center(child: LoadingWidget(size: 24)),
          );
        }

        final answer = provider.userAnswers[index];
        return CompactAnswerCard(
          answer: answer,
          onTap: () => _handleAnswerTap(answer),
        );
      },
    );
  }

  Widget _buildEmptyTabState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.headline4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: EdgeInsets.all(20),
          child: CustomButton(
            text: 'Logout',
            onPressed: provider.isLoggingOut
                ? null
                : () => _handleLogout(provider),
            isLoading: provider.isLoggingOut,
            backgroundColor: AppColors.errorColor,
            textColor: Colors.white,
            prefixIcon: Icons.logout,
          ),
        );
      },
    );
  }

  // Event Handlers
  void _handleSettings() {
    // Navigate to settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _handleEditProfile() {
    // Navigate to edit profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit profile functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _handleShareProfile() {
    // Share profile functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share profile functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _handleQuestionTap(Question question) {
    Navigator.of(context).pushNamed(
      '/question-details',
      arguments: {RouteArguments.questionId: question.id},
    );
  }

  void _handleAnswerTap(Answer answer) {
    Navigator.of(context).pushNamed(
      '/question-details',
      arguments: {RouteArguments.questionId: answer.questionId},
    );
  }

  Future<void> _handleLogout(ProfileProvider provider) async {
    // Show confirmation dialog
    final confirmed = await ModernDialog.showConfirmation(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      primaryText: 'Logout',
      secondaryText: 'Cancel',
      icon: Icons.logout_rounded,
      iconColor: const Color.fromARGB(188, 105, 73, 167),
    );

    if (confirmed == true) {
      final success = await provider.logout();
      if (success && mounted) {
        // Navigate to login screen
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Color _getLevelColor(int level) {
    if (level <= 2) return AppColors.infoColor;
    if (level <= 4) return AppColors.successColor;
    if (level <= 6) return AppColors.warningColor;
    return AppColors.errorColor;
  }
}

/// Compact Question Card for Profile
class CompactQuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onTap;

  const CompactQuestionCard({
    Key? key,
    required this.question,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.title,
                  style: AppTextStyles.bodyText1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _formatTime(question.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${question.answerCount} answers',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.infoColor,
                          fontWeight: FontWeight.w500,
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

/// Compact Answer Card for Profile
class CompactAnswerCard extends StatelessWidget {
  final Answer answer;
  final VoidCallback onTap;

  const CompactAnswerCard({Key? key, required this.answer, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: answer.isBest
            ? AppColors.successColor.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: answer.isBest
              ? AppColors.successColor.withOpacity(0.3)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (answer.isBest) ...[
                  Row(
                    children: [
                      Icon(Icons.star, color: AppColors.successColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Best Answer',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
                Text(
                  answer.content,
                  style: AppTextStyles.bodyText2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _formatTime(answer.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.thumb_up_outlined,
                          color: AppColors.textSecondary,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${answer.upvotes}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
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

/// User Profile Model
class UserProfile {
  final int id;
  final String name;
  final String email;
  final String bio;
  final String? avatarUrl;
  final int points;
  final int level;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    this.avatarUrl,
    required this.points,
    required this.level,
    required this.createdAt,
    required this.lastActiveAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'] ?? '',
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      points: json['points'] ?? 0,
      level: json['level'] ?? 1,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
      lastActiveAt:
          DateTime.tryParse(json['last_active_at'] ?? json['lastActiveAt']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'points': points,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? email,
    String? bio,
    String? avatarUrl,
    int? points,
    int? level,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, email: $email, level: $level)';
  }
}
