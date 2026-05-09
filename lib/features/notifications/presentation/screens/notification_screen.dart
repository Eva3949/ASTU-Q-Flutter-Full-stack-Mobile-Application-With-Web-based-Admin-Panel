import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../../domain/entities/notification.dart' as app_notification;
import '../../../../core/themes/colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/modern_dialog.dart';

/// Notification Screen
/// Modern notification center with purple header, filter chips,
/// and swipeable notification cards matching the home screen aesthetic.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeListeners();
    _initializeAnimations();
    _loadNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeListeners() {
    _scrollController.addListener(_onScroll);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  double _getResponsivePadding(double screenWidth) {
    return screenWidth * 0.04;
  }

  double _getResponsiveVerticalPadding(double screenHeight) {
    return screenHeight * 0.015;
  }

  double _getResponsiveFontSize(double screenWidth, {double baseSize = 14}) {
    double scaleFactor = (screenWidth / 375.0);
    scaleFactor = scaleFactor.clamp(0.8, 1.5);
    return baseSize * scaleFactor;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      if (provider.hasMore && !provider.isLoadingMore) {
        provider.loadMoreNotifications();
      }
    }
  }

  void _loadNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      provider.loadNotifications(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = _getResponsivePadding(screenWidth);
    final verticalPadding = _getResponsiveVerticalPadding(screenHeight);

    return Scaffold(
      backgroundColor: const Color.fromARGB(188, 105, 73, 167),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderSection(
              screenWidth,
              screenHeight,
              horizontalPadding,
              verticalPadding,
            ),
            _buildNotificationList(
              screenWidth,
              screenHeight,
              horizontalPadding,
              verticalPadding,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    double screenWidth,
    double screenHeight,
    double horizontalPadding,
    double verticalPadding,
  ) {
    return Container(
      color: const Color.fromARGB(188, 105, 73, 167),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: _getResponsiveFontSize(screenWidth, baseSize: 24),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(
                        screenWidth,
                        baseSize: 22,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: _handleMarkAllAsRead,
                          icon: Icon(
                            Icons.mark_email_read_outlined,
                            color: Colors.white,
                            size: _getResponsiveFontSize(
                              screenWidth,
                              baseSize: 24,
                            ),
                          ),
                        ),
                        if (provider.unreadNotificationsCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color.fromARGB(
                                    188,
                                    105,
                                    73,
                                    167,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                IconButton(
                  onPressed: _handleMoreOptions,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: _getResponsiveFontSize(screenWidth, baseSize: 24),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding * 0.4,
            ),
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                final total = provider.notifications.length;
                final unread = provider.unreadNotificationsCount;
                final read = provider.notifications
                    .where((n) => n.isRead)
                    .length;
                return Row(
                  children: [
                    _buildStatChip(
                      screenWidth,
                      screenHeight,
                      label: 'All',
                      count: total,
                      icon: Icons.notifications_none,
                    ),
                    SizedBox(width: horizontalPadding * 0.5),
                    _buildStatChip(
                      screenWidth,
                      screenHeight,
                      label: 'Unread',
                      count: unread,
                      icon: Icons.mark_email_unread_outlined,
                      accentColor: Colors.orangeAccent,
                    ),
                    SizedBox(width: horizontalPadding * 0.5),
                    _buildStatChip(
                      screenWidth,
                      screenHeight,
                      label: 'Read',
                      count: read,
                      icon: Icons.mark_email_read_outlined,
                      accentColor: Colors.greenAccent,
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding * 0.6,
            ),
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                final filters = provider.getAvailableFilters();
                final selectedKey = provider.selectedFilter;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Filters',
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
                      height: _getResponsiveFontSize(screenWidth, baseSize: 6),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filters.map((filter) {
                          final key = filter['key'] as String;
                          final label = filter['label'] as String;
                          final count = filter['count'] as int;
                          final icon = filter['icon'] as IconData;
                          final isSelected = selectedKey == key;
                          return Padding(
                            padding: EdgeInsets.only(
                              right: _getResponsiveFontSize(
                                screenWidth,
                                baseSize: 8,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () => provider.setFilter(key),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: _getResponsiveFontSize(
                                    screenWidth,
                                    baseSize: 14,
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
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: _getResponsiveFontSize(
                                        screenWidth,
                                        baseSize: 14,
                                      ),
                                      color: isSelected
                                          ? const Color.fromARGB(
                                              188,
                                              105,
                                              73,
                                              167,
                                            )
                                          : Colors.white,
                                    ),
                                    SizedBox(
                                      width: _getResponsiveFontSize(
                                        screenWidth,
                                        baseSize: 4,
                                      ),
                                    ),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color.fromARGB(
                                                188,
                                                105,
                                                73,
                                                167,
                                              )
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
                                    if (count > 0) ...[
                                      SizedBox(
                                        width: _getResponsiveFontSize(
                                          screenWidth,
                                          baseSize: 4,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color.fromARGB(
                                                  188,
                                                  105,
                                                  73,
                                                  167,
                                                )
                                              : Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          count > 99 ? '99+' : '$count',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: _getResponsiveFontSize(
                                              screenWidth,
                                              baseSize: 10,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
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
    );
  }

  Widget _buildStatChip(
    double screenWidth,
    double screenHeight, {
    required String label,
    required int count,
    required IconData icon,
    Color accentColor = Colors.white,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: _getResponsiveFontSize(screenWidth, baseSize: 10),
          horizontal: _getResponsiveFontSize(screenWidth, baseSize: 8),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(
            _getResponsiveFontSize(screenWidth, baseSize: 16),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: accentColor,
              size: _getResponsiveFontSize(screenWidth, baseSize: 20),
            ),
            SizedBox(height: _getResponsiveFontSize(screenWidth, baseSize: 4)),
            Text(
              '$count',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, baseSize: 18),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, baseSize: 11),
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    double screenWidth,
    double screenHeight,
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
          child: Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.notifications.isEmpty) {
                return _buildSkeletonLoading(screenWidth);
              }

              if (provider.errorMessage != null &&
                  provider.notifications.isEmpty) {
                return _buildErrorState(
                  screenWidth,
                  provider,
                  horizontalPadding,
                  verticalPadding,
                );
              }

              final items = provider.filteredNotifications;
              if (items.isEmpty) {
                return _buildEmptyState(
                  screenWidth,
                  provider,
                  horizontalPadding,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await provider.refreshNotifications();
                  _animationController.reset();
                  _animationController.forward();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  itemCount: items.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == items.length && provider.hasMore) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
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
                    final notification = items[index];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _ModernNotificationCard(
                        notification: notification,
                        screenWidth: screenWidth,
                        onTap: () => _handleNotificationTap(notification),
                        onMarkAsRead: () => _handleMarkAsRead(notification),
                        onDelete: () => _handleDeleteNotification(notification),
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

  Widget _buildSkeletonLoading(double screenWidth) {
    final basePadding = _getResponsivePadding(screenWidth);
    return ListView.builder(
      padding: EdgeInsets.all(basePadding),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: screenWidth * 0.6,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    double screenWidth,
    NotificationProvider provider,
    double horizontalPadding,
  ) {
    final hasFilters = provider.selectedFilter != 'all';
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color.fromARGB(188, 105, 73, 167).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.filter_list_off : Icons.notifications_none,
                size: 48,
                color: const Color.fromARGB(188, 105, 73, 167),
              ),
            ),
            SizedBox(height: 24),
            Text(
              hasFilters ? 'No Notifications Found' : 'All Caught Up!',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, baseSize: 20),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'No notifications match the selected filter.'
                  : 'You have no new notifications right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, baseSize: 14),
                color: Colors.grey[600],
              ),
            ),
            if (hasFilters) ...[
              SizedBox(height: 24),
              GestureDetector(
                onTap: () => provider.setFilter('all'),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromARGB(188, 105, 73, 167),
                        const Color.fromARGB(200, 125, 93, 187),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Clear Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: _getResponsiveFontSize(
                        screenWidth,
                        baseSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    double screenWidth,
    NotificationProvider provider,
    double horizontalPadding,
    double verticalPadding,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Internet connection',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, baseSize: 20),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, baseSize: 14),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            GestureDetector(
              onTap: _loadNotifications,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(188, 105, 73, 167),
                      const Color.fromARGB(200, 125, 93, 187),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: _getResponsiveFontSize(screenWidth, baseSize: 18),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: _getResponsiveFontSize(
                          screenWidth,
                          baseSize: 14,
                        ),
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

  void _handleMarkAllAsRead() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    if (provider.unreadNotificationsCount > 0) {
      final confirmed = await ModernDialog.showConfirmation(
        context: context,
        title: 'Mark All as Read',
        message: 'Are you sure you want to mark all notifications as read?',
        primaryText: 'Mark as Read',
        secondaryText: 'Cancel',
        icon: Icons.mark_email_read,
        iconColor: const Color.fromARGB(188, 105, 73, 167),
      );

      if (confirmed == true) {
        await provider.markAllNotificationsAsRead();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No unread notifications to mark as read'),
          backgroundColor: AppColors.infoColor,
        ),
      );
    }
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
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: const Color.fromARGB(188, 105, 73, 167),
                    ),
                    title: Text('Push Notifications'),
                    subtitle: Text('Enable push notifications'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Push notification settings coming soon!',
                            ),
                            backgroundColor: AppColors.infoColor,
                          ),
                        );
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.email,
                      color: const Color.fromARGB(188, 105, 73, 167),
                    ),
                    title: Text('Email Notifications'),
                    subtitle: Text('Enable email notifications'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Email notification settings coming soon!',
                            ),
                            backgroundColor: AppColors.infoColor,
                          ),
                        );
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_sweep, color: Colors.redAccent),
                    title: Text('Clear All Notifications'),
                    subtitle: Text('Delete all notifications'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _handleClearAllNotifications();
                    },
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  void _handleClearAllNotifications() {
    ModernDialog.showConfirmation(
      context: context,
      title: 'Clear All Notifications',
      message:
          'Are you sure you want to clear all notifications? This action cannot be undone.',
      primaryText: 'Clear All',
      secondaryText: 'Cancel',
      icon: Icons.delete_sweep,
      iconColor: const Color(0xFFF44336),
    ).then((confirmed) {
      if (confirmed == true) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clear all notifications coming soon!'),
            backgroundColor: AppColors.infoColor,
          ),
        );
      }
    });
  }

  void _handleNotificationTap(
    app_notification.Notification notification,
  ) async {
    if (!notification.isRead) {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      await provider.markNotificationAsRead(notification.id);
    }
    final route = Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).getNavigationRoute(notification);
    final arguments = Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).getNavigationArguments(notification);

    if (route != null) {
      Navigator.of(context).pushNamed(route, arguments: arguments);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This notification cannot be navigated to'),
          backgroundColor: AppColors.infoColor,
        ),
      );
    }
  }

  void _handleMarkAsRead(app_notification.Notification notification) async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    await provider.markNotificationAsRead(notification.id);
  }

  void _handleDeleteNotification(
    app_notification.Notification notification,
  ) async {
    final confirmed = await ModernDialog.showConfirmation(
      context: context,
      title: 'Delete Notification',
      message: 'Are you sure you want to delete this notification?',
      primaryText: 'Delete',
      secondaryText: 'Cancel',
      icon: Icons.delete_outline,
      iconColor: const Color(0xFFF44336),
    );

    if (confirmed == true) {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      await provider.deleteNotification(notification.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification deleted'),
          backgroundColor: AppColors.successColor,
        ),
      );
    }
  }
}

class _ModernNotificationCard extends StatelessWidget {
  final app_notification.Notification notification;
  final double screenWidth;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const _ModernNotificationCard({
    Key? key,
    required this.notification,
    required this.screenWidth,
    required this.onTap,
    required this.onMarkAsRead,
    required this.onDelete,
  }) : super(key: key);

  double _fs(double base) {
    double scale = (screenWidth / 375.0).clamp(0.8, 1.5);
    return base * scale;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final icon = provider.getNotificationIcon(notification.type);
        final color = provider.getNotificationColor(notification.type);
        final timeAgo = provider.formatTimestamp(notification.createdAt);

        return Dismissible(
          key: Key('notification_${notification.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            child: Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => onDelete(),
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: !notification.isRead
                  ? const Color.fromARGB(188, 105, 73, 167).withOpacity(0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: !notification.isRead
                  ? Border.all(
                      color: const Color.fromARGB(
                        188,
                        105,
                        73,
                        167,
                      ).withOpacity(0.2),
                      width: 1,
                    )
                  : Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                onLongPress: () => _showContextMenu(context),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(color, icon),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontSize: _fs(15),
                                      fontWeight: !notification.isRead
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    margin: EdgeInsets.only(left: 6, top: 5),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        188,
                                        105,
                                        73,
                                        167,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              notification.message,
                              style: TextStyle(
                                fontSize: _fs(13),
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: _fs(12),
                                  color: Colors.grey[500],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    fontSize: _fs(12),
                                    color: Colors.grey[500],
                                  ),
                                ),
                                Spacer(),
                                _buildTypeChip(notification.type, color),
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
          ),
        );
      },
    );
  }

  Widget _buildAvatar(Color color, IconData icon) {
    return Container(
      width: _fs(48),
      height: _fs(48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.25), color.withOpacity(0.12)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: _fs(22)),
    );
  }

  Widget _buildTypeChip(String type, Color color) {
    String label = _capitalize(type.split('_').first);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: _fs(11),
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildActionSheet(context),
    );
  }

  Widget _buildActionSheet(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (!notification.isRead)
            ListTile(
              leading: Icon(
                Icons.mark_email_read,
                color: const Color.fromARGB(188, 105, 73, 167),
              ),
              title: Text('Mark as Read'),
              onTap: () {
                Navigator.of(context).pop();
                onMarkAsRead();
              },
            ),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.isActionable(notification)) {
                return ListTile(
                  leading: Icon(
                    Icons.open_in_new,
                    color: const Color.fromARGB(188, 105, 73, 167),
                  ),
                  title: Text('Open'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onTap();
                  },
                );
              } else {
                return SizedBox.shrink();
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.redAccent),
            title: Text('Delete'),
            onTap: () {
              Navigator.of(context).pop();
              onDelete();
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
