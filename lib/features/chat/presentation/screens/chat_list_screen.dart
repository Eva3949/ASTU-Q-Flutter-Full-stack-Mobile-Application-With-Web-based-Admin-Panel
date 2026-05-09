import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/chat_list_provider.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/modern_dialog.dart';

/// Chat List Screen
/// Displays list of conversations with last message preview and timestamps
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeListeners();
    _initializeAnimations();
    _loadConversations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeListeners() {
    // Listen to scroll events for pagination
    _scrollController.addListener(_onScroll);

    // Listen to search controller changes
    _searchController.addListener(_onSearchChanged);

    // Listen to tab changes
    _tabController.addListener(_onTabChanged);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more conversations when near bottom
      final provider = Provider.of<ChatListProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoadingMore) {
        provider.loadMoreConversations();
      }
    }
  }

  void _onSearchChanged() {
    final provider = Provider.of<ChatListProvider>(context, listen: false);
    provider.searchConversations(_searchController.text);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    final provider = Provider.of<ChatListProvider>(context, listen: false);
    final filters = provider.getAvailableFilters();
    final selectedFilter = filters[_tabController.index]['key']!;

    provider.setFilter(selectedFilter);
  }

  void _loadConversations() {
    final provider = Provider.of<ChatListProvider>(context, listen: false);
    provider.loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemUiOverlayStyle,
        child: SafeArea(
          child: Consumer<ChatListProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.conversations.isEmpty) {
                return const Center(
                  child: LoadingWidget(message: 'Loading conversations...'),
                );
              }

              if (provider.errorMessage != null &&
                  provider.conversations.isEmpty) {
                return _buildErrorState(provider);
              }

              return _buildContent(provider);
            },
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: AppTheme.systemUiOverlayStyle,
      title: Text(
        'Messages',
        style: AppTextStyles.headline3.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
      ),
      actions: [
        Consumer<ChatListProvider>(
          builder: (context, provider, child) {
            return Stack(
              children: [
                IconButton(
                  onPressed: _handleSearch,
                  icon: Icon(Icons.search, color: AppColors.textSecondary),
                ),
                if (provider.totalUnreadMessagesCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.errorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          onPressed: _handleMoreOptions,
          icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
        ),
      ],
      bottom: _buildTabBar(),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(48.h),
      child: Consumer<ChatListProvider>(
        builder: (context, provider, child) {
          final filters = provider.getAvailableFilters();
          final tabs = filters.map((filter) {
            final count = filter['count'] as int;
            final label = filter['label'] as String;

            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (count > 0) ...[
                    SizedBox(width: 4.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList();

          return TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryColor,
            indicatorWeight: 2,
            labelStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTextStyles.caption,
            isScrollable: true,
            tabs: tabs,
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ChatListProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.errorColor),
            SizedBox(height: 24.h),
            Text(
              'No Internet connection',
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: 'Try Again',
              onPressed: _loadConversations,
              prefixIcon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ChatListProvider provider) {
    final filteredConversations = provider.filteredConversations;

    return Column(
      children: [
        // Search Bar (when active)
        if (_searchController.text.isNotEmpty) _buildSearchBar(),

        // Conversation List
        Expanded(
          child: filteredConversations.isEmpty
              ? _buildEmptyState(provider)
              : RefreshIndicator(
                  onRefresh: () async {
                    await provider.refreshConversations();
                    _animationController.reset();
                    _animationController.forward();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(20.w),
                    itemCount:
                        filteredConversations.length +
                        (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredConversations.length &&
                          provider.hasMore) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: const Center(child: LoadingWidget(size: 24)),
                        );
                      }

                      final conversation = filteredConversations[index];
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ChatConversationCard(
                          conversation: conversation,
                          onTap: () => _handleConversationTap(conversation),
                          onLongPress: () =>
                              _handleConversationLongPress(conversation),
                          onMarkAsRead: () => _handleMarkAsRead(conversation),
                          onDelete: () =>
                              _handleDeleteConversation(conversation),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(20.w),
      child: CustomTextField(
        controller: _searchController,
        hintText: 'Search conversations...',
        prefixIcon: Icons.search,
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: Icon(Icons.clear, color: AppColors.textSecondary),
              )
            : null,
        onChanged: (value) {
          // Handled by listener
        },
      ),
    );
  }

  Widget _buildEmptyState(ChatListProvider provider) {
    final isSearchActive = provider.searchQuery.isNotEmpty;
    final hasFilters = provider.selectedFilter != 'all';

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchActive ? Icons.search_off : Icons.chat_outlined,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 24.h),
            Text(
              isSearchActive ? 'No Results Found' : 'No Conversations',
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              isSearchActive
                  ? 'Try searching with different keywords.'
                  : hasFilters
                  ? 'No conversations match the selected filter.'
                  : 'Start a conversation to see it here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (!isSearchActive && !hasFilters) ...[
              SizedBox(height: 32.h),
              CustomButton(
                text: 'Start New Chat',
                onPressed: _handleNewChat,
                prefixIcon: Icons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<ChatListProvider>(
      builder: (context, provider, child) {
        if (provider.searchQuery.isNotEmpty) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton(
          onPressed: _handleNewChat,
          backgroundColor: AppColors.primaryColor,
          child: Icon(Icons.add, color: Colors.white),
        );
      },
    );
  }

  // Event Handlers
  void _handleSearch() {
    setState(() {
      _searchController.text = '';
    });
  }

  void _handleMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMoreOptionsSheet(),
    );
  }

  Widget _buildMoreOptionsSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Text(
              'More Options',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Options
          Consumer<ChatListProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.mark_email_read,
                      color: AppColors.primaryColor,
                    ),
                    title: Text('Mark All as Read'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _handleMarkAllAsRead();
                    },
                  ),
                  if (provider.totalUnreadMessagesCount > 0)
                    ListTile(
                      leading: Icon(
                        Icons.notifications,
                        color: AppColors.warningColor,
                      ),
                      title: Text('Mute Notifications'),
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Mute notifications coming soon!'),
                            backgroundColor: AppColors.infoColor,
                          ),
                        );
                      },
                    ),
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      color: AppColors.textSecondary,
                    ),
                    title: Text('Chat Settings'),
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chat settings coming soon!'),
                          backgroundColor: AppColors.infoColor,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  void _handleNewChat() {
    // Navigate to new chat screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New chat functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _handleConversationTap(ChatConversation conversation) {
    // Mark as read if unread
    if (conversation.unreadCount > 0) {
      final provider = Provider.of<ChatListProvider>(context, listen: false);
      provider.markConversationAsRead(conversation.id);
    }

    // Navigate to chat detail
    Navigator.of(context).pushNamed(
      '/chat-detail',
      arguments: {
        'conversationId': conversation.id,
        'userAvatar': conversation.otherUser?.avatar,
        'userName': conversation.otherUser?.name ?? '',
      },
    );
  }

  void _handleConversationLongPress(ChatConversation conversation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildConversationOptionsSheet(conversation),
    );
  }

  Widget _buildConversationOptionsSheet(ChatConversation conversation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // User Info
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: conversation.otherUser?.avatar != null
                        ? Image.network(
                            conversation.otherUser!.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 24.sp,
                                color: AppColors.primaryColor,
                              );
                            },
                          )
                        : Icon(
                            Icons.person,
                            size: 24.sp,
                            color: AppColors.primaryColor,
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.otherUser?.name ?? '',
                        style: AppTextStyles.bodyText1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        conversation.isGroupChat
                            ? '${conversation.participants?.length ?? 0} members'
                            : _getOnlineStatus(conversation),
                        style: AppTextStyles.bodyText2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Options
          Column(
            children: [
              if (conversation.unreadCount > 0)
                ListTile(
                  leading: Icon(
                    Icons.mark_email_read,
                    color: AppColors.primaryColor,
                  ),
                  title: Text('Mark as Read'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleMarkAsRead(conversation);
                  },
                ),
              ListTile(
                leading: Icon(
                  conversation.isStarred ? Icons.star : Icons.star_border,
                  color: conversation.isStarred
                      ? Colors.amber
                      : AppColors.textSecondary,
                ),
                title: Text(conversation.isStarred ? 'Unstar' : 'Star'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleToggleStar(conversation);
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: AppColors.infoColor),
                title: Text('View Info'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleViewInfo(conversation);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: AppColors.errorColor,
                ),
                title: Text('Delete Chat'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleDeleteConversation(conversation);
                },
              ),
            ],
          ),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  void _handleMarkAsRead(ChatConversation conversation) {
    final provider = Provider.of<ChatListProvider>(context, listen: false);
    provider.markConversationAsRead(conversation.id);
  }

  void _handleToggleStar(ChatConversation conversation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Star functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _handleViewInfo(ChatConversation conversation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View info functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _handleDeleteConversation(ChatConversation conversation) {
    ModernDialog.showConfirmation(
      context: context,
      title: 'Delete Chat',
      message:
          'Are you sure you want to delete this conversation? This action cannot be undone.',
      primaryText: 'Delete',
      secondaryText: 'Cancel',
      icon: Icons.delete_outline,
      iconColor: const Color(0xFFF44336),
    ).then((confirmed) {
      if (confirmed == true) {
        final provider = Provider.of<ChatListProvider>(context, listen: false);
        provider.deleteConversation(conversation.id);
      }
    });
  }

  void _handleMarkAllAsRead() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mark all as read functionality coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  String _getOnlineStatus(ChatConversation conversation) {
    return Provider.of<ChatListProvider>(
      context,
      listen: false,
    ).getOnlineStatus(conversation);
  }
}

/// Chat Conversation Card
class ChatConversationCard extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const ChatConversationCard({
    Key? key,
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
    required this.onMarkAsRead,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatListProvider>(
      builder: (context, provider, child) {
        final timestamp = provider.formatTimestamp(
          conversation.lastMessage?.createdAt ??
              conversation.updatedAt ??
              conversation.createdAt,
        );

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: conversation.unreadCount > 0
                ? AppColors.primaryColor.withOpacity(0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: conversation.unreadCount > 0
                ? Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    width: 1,
                  )
                : Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    // User Avatar
                    Container(
                      width: 56.w,
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Stack(
                          children: [
                            conversation.otherUser?.avatar != null
                                ? Image.network(
                                    conversation.otherUser!.avatar!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        conversation.isGroupChat
                                            ? Icons.group
                                            : Icons.person,
                                        size: 28.sp,
                                        color: AppColors.primaryColor,
                                      );
                                    },
                                  )
                                : Icon(
                                    conversation.isGroupChat
                                        ? Icons.group
                                        : Icons.person,
                                    size: 28.sp,
                                    color: AppColors.primaryColor,
                                  ),

                            // Online Status Indicator
                            if (!conversation.isGroupChat &&
                                conversation.otherUser?.isOnline == true)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 16.w,
                                  height: 16.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.successColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.w,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Conversation Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conversation.isGroupChat
                                      ? conversation.title ?? 'Group Chat'
                                      : conversation.otherUser?.name ??
                                            'Unknown',
                                  style: AppTextStyles.bodyText1.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: conversation.unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8.w),

                              // Timestamp
                              Text(
                                timestamp,
                                style: AppTextStyles.caption.copyWith(
                                  color: conversation.unreadCount > 0
                                      ? AppColors.primaryColor
                                      : AppColors.textSecondary,
                                  fontWeight: conversation.unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),

                          // Last Message Preview
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conversation.lastMessage?.content != null &&
                                          conversation
                                                  .lastMessage!
                                                  .content
                                                  .length >
                                              30
                                      ? '${conversation.lastMessage!.content.substring(0, 30)}...'
                                      : conversation.lastMessage?.content ??
                                            'No messages',
                                  style: AppTextStyles.bodyText2.copyWith(
                                    color: conversation.unreadCount > 0
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontWeight: conversation.unreadCount > 0
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Unread Count Badge
                              if (conversation.unreadCount > 0) ...[
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    conversation.unreadCount > 99
                                        ? '99+'
                                        : '${conversation.unreadCount}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                              ],

                              // Star Icon
                              if (conversation.isStarred) ...[
                                SizedBox(width: 8.w),
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16.sp,
                                ),
                              ],
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
      },
    );
  }
}
