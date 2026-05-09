import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/profile_provider.dart';
import '../../domain/entities/answer.dart';
import '../../domain/entities/question.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/themes/colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';

/// Modern Profile Screen
/// A beautiful, modern profile screen matching the home screen UI theme
class ModernProfileScreen extends StatefulWidget {
  const ModernProfileScreen({Key? key}) : super(key: key);

  @override
  _ModernProfileScreenState createState() => _ModernProfileScreenState();
}

class _ModernProfileScreenState extends State<ModernProfileScreen>
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
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);

      if (_tabController.index == 0) {
        if (provider.hasMoreQuestions && !provider.isLoadingMoreQuestions) {
          provider.loadMoreQuestions();
        }
      } else {
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

  // Enhanced responsive helper methods
  double _getResponsivePadding(double screenWidth) {
    if (screenWidth < 600) {
      return screenWidth * 0.04; // 4% for mobile
    } else if (screenWidth < 900) {
      return screenWidth * 0.03; // 3% for tablet
    } else {
      return screenWidth * 0.02; // 2% for desktop
    }
  }

  double _getResponsiveFontSize(double screenWidth, {double baseSize = 14}) {
    double scaleFactor;
    if (screenWidth < 600) {
      scaleFactor = (screenWidth / 375.0).clamp(0.7, 1.2); // Mobile range
    } else if (screenWidth < 900) {
      scaleFactor = (screenWidth / 768.0).clamp(0.8, 1.1); // Tablet range
    } else {
      scaleFactor = (screenWidth / 1024.0).clamp(0.9, 1.0); // Desktop range
    }
    return baseSize * scaleFactor;
  }

  double _getResponsiveHeight(double screenHeight) {
    if (screenHeight < 800) {
      return screenHeight * 0.33; // 33% for small screens (reduced from 35%)
    } else if (screenHeight < 1200) {
      return screenHeight * 0.30; // 30% for medium screens (reduced from 32%)
    } else {
      return screenHeight * 0.28; // 28% for large screens (reduced from 30%)
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = _getResponsivePadding(screenWidth);

    return Scaffold(
      backgroundColor: const Color.fromARGB(188, 105, 73, 167),
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
                return _buildEmptyState(context);
              }

              // Calculate responsive expanded height
              final expandedHeight = _getResponsiveHeight(screenHeight);

              return CustomScrollView(
                controller: _scrollController,
                physics: ClampingScrollPhysics(), // Prevents overscroll
                slivers: [
                  // Modern Profile Header
                  SliverAppBar(
                    expandedHeight: expandedHeight,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color.fromARGB(188, 105, 73, 167),
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildProfileHeader(
                        provider,
                        screenWidth,
                        horizontalPadding,
                      ),
                    ),
                    actions: [
                      IconButton(
                        onPressed: _handleSettings,
                        icon: Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Content Section with rounded top
                  SliverToBoxAdapter(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: Container(
                        color: Colors.white,
                        constraints: BoxConstraints(
                          minHeight: 400, // Minimum height to prevent overflow
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics:
                                  NeverScrollableScrollPhysics(), // Prevent nested scrolling
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildQuickStats(
                                    provider,
                                    screenWidth,
                                    horizontalPadding,
                                  ),
                                  _buildLevelProgress(
                                    provider,
                                    screenWidth,
                                    horizontalPadding,
                                  ),
                                  _buildAchievements(
                                    provider,
                                    screenWidth,
                                    horizontalPadding,
                                  ),
                                  _buildTabsSection(
                                    provider,
                                    screenWidth,
                                    horizontalPadding,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    ProfileProvider provider,
    double screenWidth,
    double horizontalPadding,
  ) {
    final profile = provider.userProfile!;

    // Responsive sizing
    double avatarSize;
    double levelBadgeSize;
    double buttonHeight;
    double topSpacing;

    if (screenWidth < 600) {
      avatarSize = 80;
      levelBadgeSize = 28;
      buttonHeight = 36;
      topSpacing = 30; // Reduced from 40
    } else if (screenWidth < 900) {
      avatarSize = 90;
      levelBadgeSize = 30;
      buttonHeight = 38;
      topSpacing = 40; // Reduced from 50
    } else {
      avatarSize = 100;
      levelBadgeSize = 32;
      buttonHeight = 40;
      topSpacing = 50; // Reduced from 60
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color.fromARGB(188, 105, 73, 167),
            const Color.fromARGB(188, 105, 73, 167).withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topSpacing),

          // Profile Avatar with decoration
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profile.avatarUrl != null
                      ? Image.network(
                          profile.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                size: avatarSize * 0.4,
                                color: Colors.white,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.white.withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            size: avatarSize * 0.4,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              // Level Badge
              Container(
                width: levelBadgeSize,
                height: levelBadgeSize,
                decoration: BoxDecoration(
                  color: _getLevelColor(profile.level),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${profile.level}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: levelBadgeSize * 0.44,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // User Name
          Text(
            profile.name,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(screenWidth, baseSize: 24),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 4),

          // Email
          Text(
            profile.email,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(screenWidth, baseSize: 14),
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 6),

          // Bio
          if (profile.bio?.isNotEmpty == true) ...[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                profile.bio!,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(screenWidth, baseSize: 14),
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 12),
          ],

          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(buttonHeight / 2),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(buttonHeight / 2),
                        onTap: _handleEditProfile,
                        child: Center(
                          child: FittedBox(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _getResponsiveFontSize(
                                      screenWidth,
                                      baseSize: 13,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(buttonHeight / 2),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(buttonHeight / 2),
                        onTap: _handleShareProfile,
                        child: Center(
                          child: FittedBox(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.share_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Share',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _getResponsiveFontSize(
                                      screenWidth,
                                      baseSize: 13,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8), // Reduced bottom spacing to prevent overflow
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    ProfileProvider provider,
    double screenWidth,
    double horizontalPadding,
  ) {
    final stats = provider.getUserStatistics();

    return Container(
      padding: EdgeInsets.all(horizontalPadding + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(screenWidth, baseSize: 20),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  'Points',
                  '${stats['points']}',
                  Icons.star,
                  Colors.amber,
                  screenWidth,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildModernStatCard(
                  'Questions',
                  '${stats['questions']}',
                  Icons.question_answer,
                  Colors.blue,
                  screenWidth,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  'Answers',
                  '${stats['answers']}',
                  Icons.chat,
                  Colors.green,
                  screenWidth,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildModernStatCard(
                  'Best',
                  '${stats['bestAnswers']}',
                  Icons.check_circle,
                  Colors.purple,
                  screenWidth,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double screenWidth,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(screenWidth, baseSize: 20),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(screenWidth, baseSize: 12),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(
    ProfileProvider provider,
    double screenWidth,
    double horizontalPadding,
  ) {
    final levelProgress = provider.getLevelProgress();

    return Container(
      margin: EdgeInsets.all(horizontalPadding + 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level Progress',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(screenWidth, baseSize: 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getLevelColor(
                    levelProgress['currentLevel'],
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${levelProgress['pointsToNextLevel']} pts to next',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(screenWidth, baseSize: 12),
                    color: _getLevelColor(levelProgress['currentLevel']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Modern Progress Bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: levelProgress['progress'],
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getLevelColor(levelProgress['currentLevel']),
                      _getLevelColor(
                        levelProgress['currentLevel'],
                      ).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
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
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(screenWidth, baseSize: 12),
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Level ${levelProgress['currentLevel'] + 1}',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(screenWidth, baseSize: 12),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(
    ProfileProvider provider,
    double screenWidth,
    double horizontalPadding,
  ) {
    final achievements = provider.getAchievements();

    return Container(
      margin: EdgeInsets.all(horizontalPadding + 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(screenWidth, baseSize: 18),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),

          if (achievements.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No achievements yet. Keep participating to earn badges!',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(
                          screenWidth,
                          baseSize: 14,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: achievements.map((achievement) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.1),
                        Colors.green.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.green, size: 16),
                      SizedBox(width: 6),
                      Text(
                        achievement,
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
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabsSection(
    ProfileProvider provider,
    double screenWidth,
    double horizontalPadding,
  ) {
    // Calculate responsive tab height
    double tabHeight;
    if (screenWidth < 600) {
      tabHeight = 300; // Mobile
    } else if (screenWidth < 900) {
      tabHeight = 350; // Tablet
    } else {
      tabHeight = 400; // Desktop
    }

    return Container(
      margin: EdgeInsets.all(horizontalPadding + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modern Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(188, 105, 73, 167),
                    const Color.fromARGB(188, 105, 73, 167).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorWeight: 0,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, baseSize: 14),
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, baseSize: 14),
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Questions'),
                Tab(text: 'Answers'),
              ],
            ),
          ),

          // Tab Content with constrained height
          SizedBox(
            height: tabHeight,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestionsTab(provider, screenWidth),
                _buildAnswersTab(provider, screenWidth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab(ProfileProvider provider, double screenWidth) {
    if (provider.isLoadingQuestions && provider.userQuestions.isEmpty) {
      return Center(child: LoadingWidget(message: 'Loading questions...'));
    }

    if (provider.userQuestions.isEmpty) {
      return _buildEmptyTabState(
        'No questions yet',
        'Start asking questions to see them here!',
        screenWidth,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: provider.questionCount + (provider.hasMoreQuestions ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.questionCount && provider.hasMoreQuestions) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: LoadingWidget(size: 24)),
          );
        }

        final question = provider.userQuestions[index];
        return ModernQuestionCard(
          question: question,
          onTap: () => _handleQuestionTap(question),
          screenWidth: screenWidth,
        );
      },
    );
  }

  Widget _buildAnswersTab(ProfileProvider provider, double screenWidth) {
    if (provider.isLoadingAnswers && provider.userAnswers.isEmpty) {
      return Center(child: LoadingWidget(message: 'Loading answers...'));
    }

    if (provider.userAnswers.isEmpty) {
      return _buildEmptyTabState(
        'No answers yet',
        'Start answering questions to see them here!',
        screenWidth,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: provider.answerCount + (provider.hasMoreAnswers ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.answerCount && provider.hasMoreAnswers) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: LoadingWidget(size: 24)),
          );
        }

        final answer = provider.userAnswers[index];
        return ModernAnswerCard(
          answer: answer,
          onTap: () => _handleAnswerTap(answer),
          screenWidth: screenWidth,
        );
      },
    );
  }

  Widget _buildEmptyTabState(
    String title,
    String subtitle,
    double screenWidth,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, baseSize: 18),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, baseSize: 14),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ProfileProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 24),
            Text(
              'No Internet connection',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton(onPressed: _loadProfile, child: Text('Try Again')),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header Skeleton (Purple)
          Container(
            padding: EdgeInsets.all(20),
            color: const Color.fromARGB(188, 105, 73, 167),
            child: Column(
              children: [
                SizedBox(height: 40),
                // Avatar Skeleton
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Name Skeleton
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 24,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Bio Skeleton
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Button Skeleton
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 36,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content Skeleton (White)
          Container(
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(height: 20),
                // Stats Section Skeleton
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
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
                SizedBox(height: 20),
                // Level Progress Skeleton
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
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
                SizedBox(height: 20),
                // Achievements Skeleton
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
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
                SizedBox(height: 20),
                // Tabs Section Skeleton
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Tab bar
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // List items
                          ...List.generate(
                            3,
                            (index) => Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 24),
            Text(
              'Profile Not Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Unable to load your profile information.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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

  // Event Handlers
  void _handleSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _handleEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit profile functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _handleShareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share profile functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _handleQuestionTap(Question question) {
    Navigator.of(
      context,
    ).pushNamed('/question-details', arguments: question.id);
  }

  void _handleAnswerTap(Answer answer) {
    Navigator.of(
      context,
    ).pushNamed('/question-details', arguments: answer.questionId);
  }

  Color _getLevelColor(int level) {
    if (level <= 2) return Colors.blue;
    if (level <= 4) return Colors.green;
    if (level <= 6) return Colors.orange;
    return Colors.red;
  }
}

/// Modern Question Card
class ModernQuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onTap;
  final double screenWidth;

  const ModernQuestionCard({
    Key? key,
    required this.question,
    required this.onTap,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.subject,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Spacer(),
                    Text(
                      _formatTime(question.createdAt),
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.question_answer,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${question.answerCount} answers',
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.arrow_upward, color: Colors.grey[400], size: 16),
                    SizedBox(width: 4),
                    Text(
                      '${question.upvotes}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: Colors.grey[600],
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

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

/// Modern Answer Card
class ModernAnswerCard extends StatelessWidget {
  final Answer answer;
  final VoidCallback onTap;
  final double screenWidth;

  const ModernAnswerCard({
    Key? key,
    required this.answer,
    required this.onTap,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: answer.isBest ? Colors.green.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: answer.isBest
              ? Colors.green.withOpacity(0.3)
              : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (answer.isBest) ...[
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Best Answer',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
                Text(
                  answer.content,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _formatTime(answer.createdAt),
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: Colors.grey[600],
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_upward, color: Colors.grey[400], size: 16),
                    SizedBox(width: 4),
                    Text(
                      '${answer.upvotes}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: Colors.grey[600],
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

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
