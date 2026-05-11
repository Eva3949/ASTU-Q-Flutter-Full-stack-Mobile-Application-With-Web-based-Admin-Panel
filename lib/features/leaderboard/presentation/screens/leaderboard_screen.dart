// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:provider/provider.dart';

// import '../providers/leaderboard_provider.dart';
// import '../../domain/entities/leaderboard_user.dart';
// import '../../../../core/themes/app_theme.dart';
// import '../../../../core/themes/colors.dart';
// import '../../../../core/themes/text_styles.dart';
// import '../../../../shared/widgets/custom_button.dart';
// import '../../../../shared/widgets/loading_widget.dart';

// /// Leaderboard Screen
// /// Displays top users with points, badges, and rankings
// class LeaderboardScreen extends StatefulWidget {
//   const LeaderboardScreen({Key? key}) : super(key: key);

//   @override
//   _LeaderboardScreenState createState() => _LeaderboardScreenState();
// }

// class _LeaderboardScreenState extends State<LeaderboardScreen>
//     with TickerProviderStateMixin {
//   late TabController _tabController;
//   final ScrollController _scrollController = ScrollController();
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 5, vsync: this);
//     _initializeListeners();
//     _initializeAnimations();
//     _loadLeaderboard();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _scrollController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _initializeListeners() {
//     // Listen to scroll events for pagination
//     _scrollController.addListener(_onScroll);

//     // Listen to tab changes
//     _tabController.addListener(_onTabChanged);
//   }

//   void _initializeAnimations() {
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );

//     _animationController.forward();
//   }

//   void _onScroll() {
//     if (!mounted) return;

//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent - 200) {
//       // Load more users when near bottom
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted) return;
//         final provider = Provider.of<LeaderboardProvider>(
//           context,
//           listen: false,
//         );
//         if (provider.hasMore && !provider.isLoadingMore) {
//           provider.loadMoreUsers();
//         }
//       });
//     }
//   }

//   void _onTabChanged() {
//     if (!_tabController.indexIsChanging) return;
//     if (!mounted) return;

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       final provider = Provider.of<LeaderboardProvider>(context, listen: false);
//       final categories = provider.getAvailableCategories();
//       final selectedCategory = categories[_tabController.index]['key']!;
//       provider.changeCategory(selectedCategory);
//     });
//   }

//   void _loadLeaderboard() {
//     if (!mounted) return;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       final provider = Provider.of<LeaderboardProvider>(context, listen: false);
//       provider.loadLeaderboard();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: _buildAppBar(),
//       body: AnnotatedRegion<SystemUiOverlayStyle>(
//         value: AppTheme.systemUiOverlayStyle,
//         child: SafeArea(
//           child: Consumer<LeaderboardProvider>(
//             builder: (context, provider, child) {
//               if (provider.isLoading && provider.leaderboardUsers.isEmpty) {
//                 return const Center(
//                   child: LoadingWidget(message: 'Loading leaderboard...'),
//                 );
//               }

//               if (provider.errorMessage != null &&
//                   provider.leaderboardUsers.isEmpty) {
//                 return _buildErrorState(provider);
//               }

//               if (provider.leaderboardUsers.isEmpty) {
//                 return _buildEmptyState();
//               }

//               return _buildContent(provider);
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: const Color(0xFF6949A7),
//       elevation: 0,
//       systemOverlayStyle: AppTheme.systemUiOverlayStyle,
//       title: Consumer<LeaderboardProvider>(
//         builder: (context, provider, child) {
//           return Text(
//             provider.getLeaderboardTitle(),
//             style: AppTextStyles.headline3.copyWith(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//             ),
//           );
//         },
//       ),
//       leading: IconButton(
//         onPressed: () => Navigator.of(context).pop(),
//         icon: Icon(Icons.arrow_back, color: Colors.white),
//       ),
//       actions: [
//         IconButton(
//           onPressed: _handleFilter,
//           icon: Icon(Icons.filter_list, color: Colors.white),
//         ),
//       ],
//       bottom: _buildTabBar(),
//       flexibleSpace: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [const Color(0xFF6949A7), const Color(0xFF9C27B0)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildTabBar() {
//     return PreferredSize(
//       preferredSize: const Size.fromHeight(kToolbarHeight),
//       child: Container(
//         decoration: BoxDecoration(color: const Color(0xFF6949A7)),
//         child: Consumer<LeaderboardProvider>(
//           builder: (context, provider, child) {
//             final categories = provider.getAvailableCategories();
//             return TabBar(
//               controller: _tabController,
//               labelColor: Colors.white,
//               unselectedLabelColor: Colors.white70,
//               indicatorColor: Colors.white,
//               indicatorWeight: 3,
//               labelStyle: AppTextStyles.caption.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//               unselectedLabelStyle: AppTextStyles.caption,
//               isScrollable: true,
//               tabs: categories.map((category) {
//                 return Tab(text: category['label']);
//               }).toList(),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorState(LeaderboardProvider provider) {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
//             SizedBox(height: 24),
//             Text(
//               'Something went wrong',
//               style: AppTextStyles.headline2.copyWith(
//                 color: AppColors.textPrimary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             SizedBox(height: 12),
//             Text(
//               provider.errorMessage!,
//               textAlign: TextAlign.center,
//               style: AppTextStyles.bodyText1.copyWith(
//                 color: AppColors.textSecondary,
//               ),
//             ),
//             SizedBox(height: 32),
//             CustomButton(
//               text: 'Try Again',
//               onPressed: _loadLeaderboard,
//               prefixIcon: Icons.refresh,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.leaderboard_outlined,
//               size: 64,
//               color: AppColors.textSecondary,
//             ),
//             SizedBox(height: 24),
//             Text(
//               'No Data Available',
//               style: AppTextStyles.headline2.copyWith(
//                 color: AppColors.textPrimary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             SizedBox(height: 12),
//             Text(
//               'Leaderboard data is not available at the moment.',
//               textAlign: TextAlign.center,
//               style: AppTextStyles.bodyText1.copyWith(
//                 color: AppColors.textSecondary,
//               ),
//             ),
//             SizedBox(height: 32),
//             CustomButton(
//               text: 'Refresh',
//               onPressed: _loadLeaderboard,
//               prefixIcon: Icons.refresh,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContent(LeaderboardProvider provider) {
//     return RefreshIndicator(
//       onRefresh: () async {
//         await provider.refreshLeaderboard();
//         _animationController.reset();
//         _animationController.forward();
//       },
//       child: Column(
//         children: [
//           // Top 3 Users Section
//           if (provider.top3Users.isNotEmpty) _buildTop3Section(provider),

//           // Current User Section
//           if (provider.currentUser != null) _buildCurrentUserSection(provider),

//           // Leaderboard List
//           Expanded(
//             child: ListView.builder(
//               controller: _scrollController,
//               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//               itemCount: provider.userCount + (provider.hasMore ? 1 : 0),
//               itemBuilder: (context, index) {
//                 if (index == provider.userCount && provider.hasMore) {
//                   return Padding(
//                     padding: EdgeInsets.symmetric(vertical: 16),
//                     child: const Center(child: LoadingWidget(size: 24)),
//                   );
//                 }

//                 final user = provider.leaderboardUsers[index];
//                 final rank = index + 1;

//                 // Skip top 3 users if they're already displayed
//                 if (rank <= 3 && provider.top3Users.isNotEmpty) {
//                   return const SizedBox.shrink();
//                 }

//                 return FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: LeaderboardUserCard(
//                     user: user,
//                     rank: rank,
//                     isCurrentUser: provider.isCurrentUser(user.id),
//                     onTap: () => _handleUserTap(user),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTop3Section(LeaderboardProvider provider) {
//     final top3 = provider.top3Users;

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isTablet = constraints.maxWidth > 600;
//         final isSmallScreen = constraints.maxWidth < 400;

//         return Container(
//           height: isTablet ? 220.h : (isSmallScreen ? 160 : 180),
//           margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               // 2nd Place
//               if (top3.length > 1)
//                 Expanded(
//                   flex: isSmallScreen ? 1 : 2,
//                   child: _buildPodiumUser(
//                     user: top3[1],
//                     rank: 2,
//                     color: Colors.grey[400]!,
//                     scale: isTablet ? 1.0 : (isSmallScreen ? 0.6 : 0.8),
//                   ),
//                 ),

//               // 1st Place
//               if (top3.isNotEmpty)
//                 Expanded(
//                   flex: isSmallScreen ? 1 : 2,
//                   child: _buildPodiumUser(
//                     user: top3[0],
//                     rank: 1,
//                     color: Colors.amber[400]!,
//                     scale: isTablet ? 1.2 : 1.0,
//                   ),
//                 ),

//               // 3rd Place
//               if (top3.length > 2)
//                 Expanded(
//                   flex: isSmallScreen ? 1 : 2,
//                   child: _buildPodiumUser(
//                     user: top3[2],
//                     rank: 3,
//                     color: Colors.brown[400]!,
//                     scale: isTablet ? 0.8 : (isSmallScreen ? 0.5 : 0.6),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildPodiumUser({
//     required LeaderboardUser user,
//     required int rank,
//     required Color color,
//     required double scale,
//   }) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isSmallScreen = constraints.maxWidth < 400;

//         return Column(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             // User Avatar and Rank
//             GestureDetector(
//               onTap: () => _handleUserTap(user),
//               child: Container(
//                 transform: Matrix4.identity()..scale(scale),
//                 child: Column(
//                   children: [
//                     // Rank Badge
//                     Container(
//                       width: 32 * scale,
//                       height: 32 * scale,
//                       decoration: BoxDecoration(
//                         color: color,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: color.withOpacity(0.3),
//                             blurRadius: 8,
//                             spreadRadius: 2,
//                           ),
//                         ],
//                       ),
//                       child: Center(
//                         child: Text(
//                           '$rank',
//                           style: AppTextStyles.bodyText1.copyWith(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: (14 * scale).clamp(8, 18),
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 4),

//                     // User Avatar
//                     Container(
//                       width: 48 * scale,
//                       height: 48 * scale,
//                       decoration: BoxDecoration(
//                         color: AppColors.primaryColor.withOpacity(0.1),
//                         shape: BoxShape.circle,
//                         border: Border.all(color: color, width: 2),
//                         boxShadow: [
//                           BoxShadow(
//                             color: color.withOpacity(0.2),
//                             blurRadius: 12,
//                             spreadRadius: 2,
//                           ),
//                         ],
//                       ),
//                       child: ClipOval(
//                         child: user.avatarUrl != null
//                             ? Image.network(
//                                 user.avatarUrl!,
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Icon(
//                                     Icons.person,
//                                     size: (24 * scale).clamp(16, 30),
//                                     color: AppColors.primaryColor,
//                                   );
//                                 },
//                               )
//                             : Icon(
//                                 Icons.person,
//                                 size: (24 * scale).clamp(16, 30),
//                                 color: AppColors.primaryColor,
//                               ),
//                       ),
//                     ),
//                     SizedBox(height: 4),

//                     // User Name
//                     SizedBox(
//                       width: 80 * scale,
//                       child: Text(
//                         user.name,
//                         style: AppTextStyles.bodyText2.copyWith(
//                           color: AppColors.textPrimary,
//                           fontWeight: FontWeight.w600,
//                           fontSize: (12 * scale).clamp(8, 14),
//                         ),
//                         textAlign: TextAlign.center,
//                         maxLines: isSmallScreen ? 1 : 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     SizedBox(height: 2),

//                     // Points
//                     Text(
//                       '${user.points} pts',
//                       style: AppTextStyles.caption.copyWith(
//                         color: AppColors.textSecondary,
//                         fontWeight: FontWeight.w500,
//                         fontSize: (10 * scale).clamp(8, 12),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             SizedBox(height: 8),

//             // Podium
//             Container(
//               height: 40 * scale,
//               decoration: BoxDecoration(
//                 color: color,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(8),
//                   topRight: Radius.circular(8),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: color.withOpacity(0.3),
//                     blurRadius: 8,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: Text(
//                   rank == 1
//                       ? '1st'
//                       : rank == 2
//                       ? '2nd'
//                       : '3rd',
//                   style: AppTextStyles.bodyText2.copyWith(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: (12 * scale).clamp(8, 16),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildCurrentUserSection(LeaderboardProvider provider) {
//     final currentUser = provider.currentUser!;
//     final currentRank = provider.currentUserRank;

//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.primaryColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: AppColors.primaryColor.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           // Rank
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: AppColors.primaryColor,
//               shape: BoxShape.circle,
//             ),
//             child: Center(
//               child: Text(
//                 currentRank?.toString() ?? '-',
//                 style: AppTextStyles.bodyText1.copyWith(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(width: 12),

//           // User Info
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         'You',
//                         style: AppTextStyles.bodyText1.copyWith(
//                           color: AppColors.textPrimary,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: AppColors.primaryColor,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         'Level ${currentUser.level}',
//                         style: AppTextStyles.caption.copyWith(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 10,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   '${currentUser.points} points',
//                   style: AppTextStyles.bodyText2.copyWith(
//                     color: AppColors.textSecondary,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // View Profile Button
//           IconButton(
//             onPressed: () => _handleViewProfile(currentUser),
//             icon: Icon(
//               Icons.arrow_forward_ios,
//               color: AppColors.primaryColor,
//               size: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Event Handlers
//   void _handleFilter() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => _buildFilterSheet(),
//     );
//   }

//   Widget _buildFilterSheet() {
//     return Consumer<LeaderboardProvider>(
//       builder: (context, provider, child) {
//         return Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(20),
//               topRight: Radius.circular(20),
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Handle
//               Container(
//                 width: 40,
//                 height: 4,
//                 margin: EdgeInsets.symmetric(vertical: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),

//               // Title
//               Padding(
//                 padding: EdgeInsets.all(20),
//                 child: Text(
//                   'Filter Leaderboard',
//                   style: AppTextStyles.headline3.copyWith(
//                     color: AppColors.textPrimary,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),

//               // Time Filter
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Time Period',
//                       style: AppTextStyles.bodyText1.copyWith(
//                         color: AppColors.textPrimary,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: 12),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: provider.getAvailableTimeFilters().map((
//                         filter,
//                       ) {
//                         final isSelected =
//                             filter['key'] == provider.selectedTimeFilter;
//                         return FilterChip(
//                           label: Text(filter['label']!),
//                           selected: isSelected,
//                           onSelected: (selected) {
//                             if (selected) {
//                               provider.changeTimeFilter(filter['key']!);
//                               Navigator.of(context).pop();
//                             }
//                           },
//                           backgroundColor: Colors.grey[200],
//                           selectedColor: AppColors.primaryColor.withOpacity(
//                             0.2,
//                           ),
//                           checkmarkColor: AppColors.primaryColor,
//                           labelStyle: AppTextStyles.bodyText2.copyWith(
//                             color: isSelected
//                                 ? AppColors.primaryColor
//                                 : AppColors.textPrimary,
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: 24),

//               // Close Button
//               Padding(
//                 padding: EdgeInsets.all(20),
//                 child: SizedBox(
//                   width: double.infinity,
//                   child: CustomButton(
//                     text: 'Close',
//                     onPressed: () => Navigator.of(context).pop(),
//                     backgroundColor: AppColors.textSecondary,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _handleUserTap(LeaderboardUser user) {
//     // Navigate to user profile
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Viewing ${user.name}\'s profile'),
//         backgroundColor: AppColors.infoColor,
//       ),
//     );
//   }

//   void _handleViewProfile(LeaderboardUser user) {
//     // Navigate to current user's profile
//     Navigator.of(context).pushNamed('/profile');
//   }
// }

// class LeaderboardUserCard extends StatelessWidget {
//   final LeaderboardUser user;
//   final int rank;
//   final VoidCallback? onTap;
//   final bool isCurrentUser;

//   const LeaderboardUserCard({
//     Key? key,
//     required this.user,
//     required this.rank,
//     this.onTap,
//     this.isCurrentUser = false,
//   }) : super(key: key);

//   Color _getRankColor(int rank) {
//     switch (rank) {
//       case 1:
//         return Colors.amber;
//       case 2:
//         return Colors.grey[400]!;
//       case 3:
//         return Colors.brown[400]!;
//       default:
//         return AppColors.primaryColor;
//     }
//   }

//   Color _getLevelColor(int level) {
//     if (level <= 2) return AppColors.infoColor;
//     if (level <= 4) return AppColors.successColor;
//     if (level <= 6) return AppColors.warningColor;
//     return AppColors.errorColor;
//   }

//   Color _getBadgeColor(String badge) {
//     switch (badge) {
//       case 'Diamond':
//         return Colors.blueGrey;
//       case 'Platinum':
//         return Colors.grey[300]!;
//       case 'Gold':
//         return Colors.amber;
//       case 'Silver':
//         return Colors.grey[400]!;
//       case 'Bronze':
//         return Colors.brown[300]!;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getBadgeIcon(String badge) {
//     switch (badge) {
//       case 'Diamond':
//         return Icons.diamond;
//       case 'Platinum':
//         return Icons.workspace_premium;
//       case 'Gold':
//         return Icons.star;
//       case 'Silver':
//         return Icons.star_border;
//       case 'Bronze':
//         return Icons.military_tech;
//       default:
//         return Icons.star;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isTablet = constraints.maxWidth > 600;
//         final isSmallScreen = constraints.maxWidth < 350;

//         return Container(
//           margin: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
//               onTap: onTap,
//               child: Padding(
//                 padding: EdgeInsets.all(isTablet ? 16 : 12),
//                 child: Row(
//                   children: [
//                     // Rank
//                     Container(
//                       width: 32,
//                       height: 32,
//                       decoration: BoxDecoration(
//                         color: _getRankColor(rank),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Text(
//                           '$rank',
//                           style: AppTextStyles.bodyText1.copyWith(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: isSmallScreen ? 10 : 12,
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 8),

//                     // User Avatar
//                     Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: AppColors.primaryColor.withOpacity(0.1),
//                         shape: BoxShape.circle,
//                       ),
//                       child: ClipOval(
//                         child: user.avatarUrl != null
//                             ? Image.network(
//                                 user.avatarUrl!,
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Icon(
//                                     Icons.person,
//                                     size: isSmallScreen ? 16 : 20,
//                                     color: AppColors.primaryColor,
//                                   );
//                                 },
//                               )
//                             : Icon(
//                                 Icons.person,
//                                 size: isSmallScreen ? 16 : 20,
//                                 color: AppColors.primaryColor,
//                               ),
//                       ),
//                     ),
//                     SizedBox(width: 8),

//                     // User Info
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: Text(
//                                   user.name,
//                                   style: AppTextStyles.bodyText1.copyWith(
//                                     color: AppColors.textPrimary,
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: isSmallScreen ? 12 : 14,
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                   maxLines: 1,
//                                 ),
//                               ),
//                               if (isCurrentUser) ...[
//                                 SizedBox(width: 4),
//                                 Container(
//                                   padding: EdgeInsets.symmetric(
//                                     horizontal: 4,
//                                     vertical: 1,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: AppColors.primaryColor,
//                                     borderRadius: BorderRadius.circular(6),
//                                   ),
//                                   child: Text(
//                                     'You',
//                                     style: AppTextStyles.caption.copyWith(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.w600,
//                                       fontSize: isSmallScreen ? 8 : 9,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ],
//                           ),
//                           SizedBox(height: 2),
//                           Wrap(
//                             spacing: 4,
//                             runSpacing: 2,
//                             children: [
//                               Container(
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: 4,
//                                   vertical: 1,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: _getLevelColor(
//                                     user.level,
//                                   ).withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(6),
//                                 ),
//                                 child: Text(
//                                   'L${user.level}',
//                                   style: AppTextStyles.caption.copyWith(
//                                     color: _getLevelColor(user.level),
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: isSmallScreen ? 8 : 9,
//                                   ),
//                                 ),
//                               ),
//                               if (!isSmallScreen) ...[
//                                 Text(
//                                   '${user.questions}Q',
//                                   style: AppTextStyles.caption.copyWith(
//                                     color: AppColors.textSecondary,
//                                     fontSize: isSmallScreen ? 8 : 9,
//                                   ),
//                                 ),
//                                 Text(
//                                   '${user.answers}A',
//                                   style: AppTextStyles.caption.copyWith(
//                                     color: AppColors.textSecondary,
//                                     fontSize: isSmallScreen ? 8 : 9,
//                                   ),
//                                 ),
//                               ],
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),

//                     // Points
//                     if (!isSmallScreen) ...[
//                       SizedBox(width: 8),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             '${user.points}',
//                             style: AppTextStyles.bodyText1.copyWith(
//                               color: AppColors.textPrimary,
//                               fontWeight: FontWeight.bold,
//                               fontSize: isSmallScreen ? 12 : 14,
//                             ),
//                           ),
//                           Text(
//                             'pts',
//                             style: AppTextStyles.caption.copyWith(
//                               color: AppColors.textSecondary,
//                               fontSize: isSmallScreen ? 8 : 9,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/leaderboard_provider.dart';
import '../../domain/entities/leaderboard_user.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';

/// Leaderboard Screen - Modern, Responsive & Beautiful
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeListeners();
    _initializeAnimations();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeListeners() {
    _scrollController.addListener(_onScroll);
    _tabController.addListener(_onTabChanged);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  void _onScroll() {
    if (!mounted) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final provider = Provider.of<LeaderboardProvider>(
          context,
          listen: false,
        );
        if (provider.hasMore && !provider.isLoadingMore) {
          provider.loadMoreUsers();
        }
      });
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<LeaderboardProvider>(context, listen: false);
      final categories = provider.getAvailableCategories();
      final selectedCategory = categories[_tabController.index]['key']!;
      provider.changeCategory(selectedCategory);
    });
  }

  void _loadLeaderboard() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<LeaderboardProvider>(context, listen: false);
      provider.loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Consumer<LeaderboardProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.leaderboardUsers.isEmpty) {
                return _buildLoadingState();
              }

              if (provider.errorMessage != null &&
                  provider.leaderboardUsers.isEmpty) {
                return _buildErrorState(provider);
              }

              if (provider.leaderboardUsers.isEmpty) {
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
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Consumer<LeaderboardProvider>(
        builder: (context, provider, child) {
          return Text(
            provider.getLeaderboardTitle(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [Color(0xFF6B2EEF), Color(0xFF9B4DFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 50.0)),
            ),
          );
        },
      ),
      centerTitle: false,
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: const Color(0xFF6B2EEF),
            size: 18,
          ),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _handleFilter,
            icon: Icon(Icons.filter_list, color: const Color(0xFF6B2EEF)),
          ),
        ),
      ],
      bottom: _buildTabBar(),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        color: Colors.white,
        child: Consumer<LeaderboardProvider>(
          builder: (context, provider, child) {
            final categories = provider.getAvailableCategories();
            return TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6B2EEF),
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: const Color(0xFF6B2EEF),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              isScrollable: true,
              padding: EdgeInsets.symmetric(horizontal: 16),
              tabs: categories.map((category) {
                return Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(category['label']!),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B2EEF), Color(0xFF9B4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading leaderboard...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LeaderboardProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B2EEF), Color(0xFF9B4DFF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _loadLeaderboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: TextStyle(fontSize: 16, color: Colors.white),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.leaderboard_outlined,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Leaderboard data is not available at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B2EEF), Color(0xFF9B4DFF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _loadLeaderboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Refresh',
                      style: TextStyle(fontSize: 16, color: Colors.white),
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

  Widget _buildContent(LeaderboardProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        await provider.refreshLeaderboard();
        _animationController.reset();
        _animationController.forward();
      },
      color: const Color(0xFF6B2EEF),
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Top 3 Users Section
          if (provider.top3Users.isNotEmpty)
            SliverToBoxAdapter(child: _buildTop3Section(provider)),

          // Current User Section
          if (provider.currentUser != null)
            SliverToBoxAdapter(child: _buildCurrentUserSection(provider)),

          // Leaderboard List
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == provider.userCount && provider.hasMore) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6B2EEF),
                      ),
                    ),
                  ),
                );
              }

              final user = provider.leaderboardUsers[index];
              final rank = index + 1;

              if (rank <= 3 && provider.top3Users.isNotEmpty) {
                return const SizedBox.shrink();
              }

              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  if (_animationController.isCompleted) {
                    return child!;
                  }
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * index * 0.1),
                    child: Opacity(opacity: _fadeAnimation.value, child: child),
                  );
                },
                child: LeaderboardUserCard(
                  user: user,
                  rank: rank,
                  isCurrentUser: provider.isCurrentUser(user.id),
                  onTap: () => _handleUserTap(user),
                ),
              );
            }, childCount: provider.userCount + (provider.hasMore ? 1 : 0)),
          ),
        ],
      ),
    );
  }

  Widget _buildTop3Section(LeaderboardProvider provider) {
    final top3 = provider.top3Users;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (top3.length > 1)
            Expanded(
              child: _buildPodiumUser(
                user: top3[1],
                rank: 2,
                color: Colors.grey[400]!,
                height: 180,
                avatarSize: 70,
              ),
            ),

          // 1st Place
          if (top3.isNotEmpty)
            Expanded(
              flex: 2,
              child: _buildPodiumUser(
                user: top3[0],
                rank: 1,
                color: const Color(0xFFFFD700),
                height: 220,
                avatarSize: 90,
                isFirst: true,
              ),
            ),

          // 3rd Place
          if (top3.length > 2)
            Expanded(
              child: _buildPodiumUser(
                user: top3[2],
                rank: 3,
                color: Colors.brown[400]!,
                height: 160,
                avatarSize: 70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumUser({
    required LeaderboardUser user,
    required int rank,
    required Color color,
    required double height,
    required double avatarSize,
    bool isFirst = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Rank Badge
        Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                rank == 1 ? Icons.emoji_events : Icons.star,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                rank == 1
                    ? '1st'
                    : rank == 2
                    ? '2nd'
                    : '3rd',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // User Avatar
        GestureDetector(
          onTap: () => _handleUserTap(user),
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: isFirst ? 4 : 2,
                ),
              ],
            ),
            padding: EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: user.avatarUrl != null
                    ? Image.network(
                        user.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: avatarSize * 0.5,
                            color: const Color(0xFF6B2EEF),
                          );
                        },
                      )
                    : Icon(
                        Icons.person,
                        size: avatarSize * 0.5,
                        color: const Color(0xFF6B2EEF),
                      ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),

        // User Name
        Text(
          user.name,
          style: TextStyle(
            fontSize: isFirst ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),

        // Points
        Text(
          '${user.points} pts',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12),

        // Podium
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, -4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentUserSection(LeaderboardProvider provider) {
    final currentUser = provider.currentUser!;
    final currentRank = provider.currentUserRank;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6B2EEF).withOpacity(0.1),
            const Color(0xFF9B4DFF).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6B2EEF).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B2EEF), Color(0xFF9B4DFF)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B2EEF).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                currentRank?.toString() ?? '-',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'You',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B2EEF), Color(0xFF9B4DFF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Level ${currentUser.level}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  '${currentUser.points} points • ${currentUser.questions} questions • ${currentUser.answers} answers',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // View Profile Button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6B2EEF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _handleViewProfile(currentUser),
              icon: Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFF6B2EEF),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return Consumer<LeaderboardProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 60,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Filter Leaderboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF6B2EEF), Color(0xFF9B4DFF)],
                      ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 50.0)),
                  ),
                ),
              ),
              SizedBox(height: 8),

              // Subtitle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Choose time period to filter results',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              SizedBox(height: 24),

              // Time Filter
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: provider.getAvailableTimeFilters().map((filter) {
                    final isSelected =
                        filter['key'] == provider.selectedTimeFilter;
                    return FilterChip(
                      label: Text(filter['label']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          provider.changeTimeFilter(filter['key']!);
                          Navigator.of(context).pop();
                        }
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: const Color(0xFF6B2EEF).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF6B2EEF),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF6B2EEF)
                            : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF6B2EEF)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: 32),

              // Close Button
              Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B2EEF), Color(0xFF9B4DFF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _handleUserTap(LeaderboardUser user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${user.name}\'s profile'),
        backgroundColor: const Color(0xFF6B2EEF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleViewProfile(LeaderboardUser user) {
    Navigator.of(context).pushNamed('/profile');
  }
}

class LeaderboardUserCard extends StatelessWidget {
  final LeaderboardUser user;
  final int rank;
  final VoidCallback? onTap;
  final bool isCurrentUser;

  const LeaderboardUserCard({
    Key? key,
    required this.user,
    required this.rank,
    this.onTap,
    this.isCurrentUser = false,
  }) : super(key: key);

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return const Color(0xFF6B2EEF);
    }
  }

  Color _getLevelColor(int level) {
    if (level <= 2) return Colors.blue;
    if (level <= 4) return Colors.green;
    if (level <= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getRankColor(rank),
                        _getRankColor(rank).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // User Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B2EEF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: user.avatarUrl != null
                        ? Image.network(
                            user.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 22,
                                color: const Color(0xFF6B2EEF),
                              );
                            },
                          )
                        : Icon(
                            Icons.person,
                            size: 22,
                            color: const Color(0xFF6B2EEF),
                          ),
                  ),
                ),
                SizedBox(width: 12),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6B2EEF),
                                    Color(0xFF9B4DFF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getLevelColor(
                                user.level,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'L${user.level}',
                              style: TextStyle(
                                fontSize: 11,
                                color: _getLevelColor(user.level),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${user.questions}Q',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${user.answers}A',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Points
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${user.points}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFF6B2EEF), Color(0xFF9B4DFF)],
                          ).createShader(Rect.fromLTWH(0.0, 0.0, 80.0, 30.0)),
                      ),
                    ),
                    Text(
                      'points',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
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
}
