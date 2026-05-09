import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/question_provider.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../domain/usecases/vote_answer_usecase.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/modern_dialog.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../../../ai_chat/presentation/widgets/ai_chat_bot_widget.dart';
import 'package:shimmer/shimmer.dart';

/// Home Screen (Question Feed)
/// Main feed displaying questions with search, filter, and pagination
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedSubject;
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initializeListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeListeners() {
    // Listen to scroll events for pagination
    _scrollController.addListener(_onScroll);

    // Listen to search changes
    _searchController.addListener(_onSearchChanged);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more questions when near bottom
      final questionProvider = Provider.of<QuestionProvider>(
        context,
        listen: false,
      );
      if (questionProvider.hasMore == true &&
          questionProvider.isLoadingMore == false) {
        questionProvider.loadMoreQuestions();
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // Cancel previous debounce timer
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      if (_isSearching) {
        _clearSearch();
      }
      return;
    }

    // Set new debounce timer
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
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

  int _getResponsiveColumns(double screenWidth) {
    // Calculate columns based on screen width
    if (screenWidth < 600) return 1; // Mobile
    if (screenWidth < 900) return 2; // Tablet
    if (screenWidth < 1200) return 3; // Large tablet
    return 4; // Desktop
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive padding calculations
    final horizontalPadding = _getResponsivePadding(screenWidth);
    final verticalPadding = _getResponsiveVerticalPadding(screenHeight);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(188, 105, 73, 167),
      drawer: _buildDrawer(),
      floatingActionButton: _buildAIActionButton(),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilterSection(
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
    );
  }

  Widget _buildAIActionButton() {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showAIChatPopup,
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: const Icon(
          Icons.smart_toy_rounded,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showAIChatPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Material(color: Colors.transparent, child: AIChatBotWidget()),
      ),
    );
  }

  Widget _buildSearchAndFilterSection(
    double screenWidth,
    double horizontalPadding,
    double verticalPadding,
  ) {
    return Container(
      child: Column(
        children: [
          // Combined Tab Layout with Solid Background
          Container(
            color: const Color.fromARGB(188, 105, 73, 167),
            child: Column(
              children: [
                // Header Section (now part of gradient)
                Consumer<AuthenticationProvider>(
                  builder: (context, authProvider, child) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: Row(
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
                                      baseSize: 24,
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
                                  'What do you want to learn today?',
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

                          // Menu Icon
                          IconButton(
                            onPressed: _handleMenu,
                            icon: Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: _getResponsiveFontSize(
                                screenWidth,
                                baseSize: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Search Bar Section
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding * 0.5,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by tags...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: _getResponsiveFontSize(
                          screenWidth,
                          baseSize: 14,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[500],
                        size: _getResponsiveFontSize(screenWidth, baseSize: 20),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey[500],
                                size: _getResponsiveFontSize(
                                  screenWidth,
                                  baseSize: 18,
                                ),
                              ),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          30.0,
                        ), // Higher number = more curve
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(
                          color: Colors.purple,
                          width: 1.0,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: _getResponsiveFontSize(
                          screenWidth,
                          baseSize: 16,
                        ),
                        vertical: _getResponsiveFontSize(
                          screenWidth,
                          baseSize: 12,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isSearching = value.isNotEmpty;
                      });
                    },
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _performSearch(value);
                      }
                    },
                  ),
                ),

                // Categories Section
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding * 0.6,
                  ),
                  child: Consumer<QuestionProvider>(
                    builder: (context, provider, child) {
                      final subjects = [
                        'All',
                        'Math',
                        'Science',
                        'English',
                        'History',
                        'Art',
                        'Physics',
                        'Chemistry',
                        'Biology',
                        'Computer Science',
                      ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Categories',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(
                                    screenWidth,
                                    baseSize: 16,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(
                                width: _getResponsiveFontSize(
                                  screenWidth,
                                  baseSize: 8,
                                ),
                              ),
                              Icon(
                                Icons.horizontal_rule,
                                color: Colors.white70,
                                size: _getResponsiveFontSize(
                                  screenWidth,
                                  baseSize: 20,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: _getResponsiveFontSize(
                              screenWidth,
                              baseSize: 6,
                            ),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: subjects.map((subject) {
                                final isSelected = _selectedSubject == subject;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: _getResponsiveFontSize(
                                      screenWidth,
                                      baseSize: 8,
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (subject == 'All') {
                                        // "All" always clears the filter
                                        setState(() {
                                          _selectedSubject = null;
                                        });
                                        _clearFilter();
                                      } else {
                                        setState(() {
                                          _selectedSubject = isSelected
                                              ? null
                                              : subject;
                                        });
                                        if (_selectedSubject != null) {
                                          _filterBySubject(_selectedSubject!);
                                        } else {
                                          _clearFilter();
                                        }
                                      }
                                    },
                                    child: Container(
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
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                          _getResponsiveFontSize(
                                            screenWidth,
                                            baseSize: 20,
                                          ),
                                        ),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.3),
                                        ),
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: Colors.white.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                        ],
                                      ),
                                      child: Text(
                                        subject,
                                        style: TextStyle(
                                          color: isSelected
                                              ? const Color(0xFF667EEA)
                                              : Colors.white,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: _getResponsiveFontSize(
                                            screenWidth,
                                            baseSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
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
    final cardSpacing = _getResponsiveFontSize(screenWidth, baseSize: 12);
    final crossAxisCount = _getResponsiveColumns(screenWidth);

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Container(
          color: Colors.white,
          child: Consumer<QuestionProvider>(
            builder: (context, provider, child) {
              // Show skeleton loading state for initial load
              if (provider.isLoading == true && provider.questionCount == 0) {
                return _buildSkeletonLoading();
              }

              // Show error state
              if (provider.errorMessage != null &&
                  provider.questionCount == 0) {
                return Center(
                  child: CustomErrorWidget(
                    message: provider.errorMessage!,
                    onRetry: () {
                      provider.refreshQuestions();
                    },
                  ),
                );
              }

              // Show empty state
              if (provider.questionCount == 0) {
                return EmptyStateWidget(
                  icon: Icons.question_answer,
                  title: provider.isSearching
                      ? 'No Questions Found'
                      : 'No Questions Yet',
                  message: provider.isSearching
                      ? 'Try adjusting your search or filters'
                      : 'Be the first to ask a question!',
                  actionText: !provider.isSearching ? 'Ask a Question' : null,
                  onAction: !provider.isSearching
                      ? () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.askQuestion);
                        }
                      : null,
                );
              }

              // Show questions list
              return RefreshIndicator(
                onRefresh: () async {
                  await provider.refreshQuestions();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  itemCount:
                      provider.questionCount + (provider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the end
                    if (index == provider.questionCount && provider.hasMore) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: cardSpacing),
                        child: Center(
                          child: LoadingWidget(
                            size: _getResponsiveFontSize(
                              screenWidth,
                              baseSize: 24,
                            ),
                          ),
                        ),
                      );
                    }

                    // Show question card
                    final questions = provider.questions;
                    if (index < questions.length) {
                      final question = questions[index];
                      if (crossAxisCount > 1) {
                        // Grid layout for tablets
                        return Card(
                          margin: EdgeInsets.all(cardSpacing / 2),
                          elevation: 2,
                          child: InkWell(
                            onTap: () => _handleQuestionTap(question),
                            child: Padding(
                              padding: EdgeInsets.all(cardSpacing),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question.title,
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(
                                        screenWidth,
                                        baseSize: 12,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    question.subject,
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(
                                        screenWidth,
                                        baseSize: 10,
                                      ),
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Spacer(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Like button for grid layout
                                      InkWell(
                                        onTap: () => _handleVote(
                                          question.id,
                                          VoteType.upvote,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              question.isUpvoted
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: question.isUpvoted
                                                  ? Colors.red
                                                  : Colors.grey[600],
                                              size: _getResponsiveFontSize(
                                                screenWidth,
                                                baseSize: 14,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '${question.upvotes}',
                                              style: TextStyle(
                                                fontSize:
                                                    _getResponsiveFontSize(
                                                      screenWidth,
                                                      baseSize: 8,
                                                    ),
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${question.answerCount} answers',
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            screenWidth,
                                            baseSize: 8,
                                          ),
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        // List layout for phones
                        return QuestionCard(
                          question: question,
                          onTap: () => _handleQuestionTap(question),
                          onUpvote: () =>
                              _handleVote(question.id, VoteType.upvote),
                          onDownvote: () {},
                          onShare: () => _handleShare(question),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Event Handlers
  void _performSearch(String query) async {
    final provider = Provider.of<QuestionProvider>(context, listen: false);
    await provider.searchQuestions(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });

    final provider = Provider.of<QuestionProvider>(context, listen: false);
    provider.clearSearchAndFilters();
  }

  void _filterBySubject(String subject) async {
    setState(() {
      _selectedSubject = subject;
    });

    final provider = Provider.of<QuestionProvider>(context, listen: false);
    await provider.filterBySubject(subject);
  }

  void _clearFilter() {
    setState(() {
      _selectedSubject = null;
    });

    final provider = Provider.of<QuestionProvider>(context, listen: false);
    provider.clearSearchAndFilters();
  }

  void _handleQuestionTap(dynamic question) {
    // Navigate to question details
    Navigator.of(context).pushNamed(
      AppRoutes.questionDetail,
      arguments: {RouteArguments.questionId: question.id},
    );
  }

  void _handleVote(int questionId, VoteType voteType) async {
    final provider = Provider.of<QuestionProvider>(context, listen: false);
    await provider.voteQuestion(questionId, voteType);
  }

  void _handleShare(dynamic question) {
    // Share question functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  Widget _buildDrawer() {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        return Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color.fromARGB(188, 105, 73, 167),
                  const Color.fromARGB(188, 105, 73, 167).withOpacity(0.95),
                  Colors.white,
                ],
                stops: [0.0, 0.35, 0.35],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Modern Drawer Header
                Container(
                  padding: EdgeInsets.fromLTRB(24, 60, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Avatar with gradient border and logout button
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Text(
                                authProvider.userInitials ?? 'U',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(
                                    188,
                                    105,
                                    73,
                                    167,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Spacer(),
                          // Logout button in top right
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              _handleLogout();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        authProvider.userDisplayName ?? 'Guest User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        authProvider.user?.email ?? 'user@example.com',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu Items
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _buildDrawerItem(
                        icon: Icons.home_rounded,
                        title: 'Home',
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.account_circle_rounded,
                        title: 'Profile',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed('/profile');
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.help_outline_rounded,
                        title: 'My Questions',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.myQuestions);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.notifications_rounded,
                        title: 'Notifications',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed('/notifications');
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.emoji_events_rounded,
                        title: 'Leaderboard',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed('/leaderboard');
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.settings_rounded,
                        title: 'Settings',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed('/settings');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor != null
                    ? iconColor.withOpacity(0.1)
                    : const Color.fromARGB(188, 105, 73, 167).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? const Color.fromARGB(188, 105, 73, 167),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: iconColor ?? Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenu() {
    _showMenuDrawer();
  }

  void _showMenuDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _handleLogout() async {
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
      // Get the authentication provider and logout
      final authProvider = Provider.of<AuthenticationProvider>(
        context,
        listen: false,
      );
      await authProvider.logout();

      // Navigate to login screen
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
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

  Widget EmptyStateWidget({
    required IconData icon,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              SizedBox(height: 32),
              CustomButton(
                text: actionText,
                onPressed: onAction,
                prefixIcon: Icons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom Error Widget
class CustomErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const CustomErrorWidget({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            SizedBox(height: 24),
            Text(
              'No Internet connection',
              textAlign: TextAlign.center,
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 32),
            CustomButton(
              text: 'Try Again',
              onPressed: onRetry,
              prefixIcon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
}

/// Question Card Widget
class QuestionCard extends StatelessWidget {
  final dynamic question; // Replace with Question entity
  final VoidCallback onTap;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final VoidCallback onShare;

  const QuestionCard({
    Key? key,
    required this.question,
    required this.onTap,
    required this.onUpvote,
    required this.onDownvote,
    required this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          splashColor: Colors.blue.withOpacity(0.1),
          highlightColor: Colors.blue.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Images (if available) - Display as thumbnail above title
                if (question.images != null && question.images.isNotEmpty) ...[
                  _buildQuestionImages(question),
                  SizedBox(height: 12),
                ],

                // Question Title
                Text(
                  question.title ?? 'Question Title',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.4,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),

                // Question Content Preview
                if (question.content != null && question.content.isNotEmpty)
                  Text(
                    question.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4A5568),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                if (question.content != null && question.content.isNotEmpty)
                  SizedBox(height: 16),

                // Tags Row
                if (question.tags != null && question.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (question.tags as List).take(3).map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF667EEA).withOpacity(0.1),
                              Color(0xFF764BA2).withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFF667EEA).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tag.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF667EEA),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                if (question.tags != null && question.tags.isNotEmpty)
                  SizedBox(height: 16),

                // Bottom Row: User Info and Stats
                Row(
                  children: [
                    // User Avatar with enhanced styling
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFF7FAFC),
                        backgroundImage: question.authorAvatarUrl != null
                            ? NetworkImage(question.authorAvatarUrl!)
                            : null,
                        child: question.authorAvatarUrl == null
                            ? Text(
                                question.authorName.isNotEmpty
                                    ? question.authorName
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : 'A',
                                style: TextStyle(
                                  color: Color(0xFF667EEA),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: 12),

                    // User Name and Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.authorName.isNotEmpty
                                ? question.authorName
                                : 'Anonymous',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _formatTime(question.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Like Button
                    InkWell(
                      onTap: onUpvote,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: question.isUpvoted
                                ? [
                                    Color(0xFFFF6B6B).withOpacity(0.1),
                                    Color(0xFFEE5A5A).withOpacity(0.1),
                                  ]
                                : [
                                    Color(0xFF667EEA).withOpacity(0.1),
                                    Color(0xFF764BA2).withOpacity(0.1),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: question.isUpvoted
                                ? Color(0xFFFF6B6B).withOpacity(0.2)
                                : Color(0xFF667EEA).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              question.isUpvoted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: question.isUpvoted
                                  ? Colors.red
                                  : Color(0xFF667EEA),
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '${question.upvotes}',
                              style: TextStyle(
                                color: question.isUpvoted
                                    ? Colors.red
                                    : Color(0xFF667EEA),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    // Answer Count
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF48BB78).withOpacity(0.1),
                            Color(0xFF38A169).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFF48BB78).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.question_answer_outlined,
                            color: Color(0xFF38A169),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${question.answerCount} answers',
                            style: TextStyle(
                              color: Color(0xFF38A169),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
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
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildQuestionImages(dynamic question) {
    // Display as thumbnail - show first image as main thumbnail
    final images = question.images as List?;
    if (images == null || images.isEmpty) return SizedBox.shrink();

    final primaryImage = images.first.toString();
    final hasMoreImages = images.length > 1;

    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
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
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.grey[300]),
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
                top: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '+${images.length - 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
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
}
