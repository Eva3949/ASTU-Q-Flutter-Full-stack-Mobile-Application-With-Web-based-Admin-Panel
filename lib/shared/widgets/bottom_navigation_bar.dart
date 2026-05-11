import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/navigation/app_router.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/text_styles.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';

/// Custom Bottom Navigation Bar
/// Provides navigation between main app sections with smooth UX
class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final bool showLabels;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    this.onTap,
    this.showLabels = true,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  _CustomBottomNavigationBarState createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(CustomBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          widget.margin ??
          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding:
          widget.padding ??
          EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BottomNavigationBar(
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedFontSize: 11.sp,
          unselectedFontSize: 10.sp,
          selectedLabelStyle: AppTextStyles.caption.copyWith(
            color: widget.selectedItemColor ?? AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.caption.copyWith(
            color: widget.unselectedItemColor ?? AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          showSelectedLabels: widget.showLabels,
          showUnselectedLabels: widget.showLabels,
          items: _buildNavigationItems(),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavigationItems() {
    return [
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          isActive: widget.currentIndex == 0,
        ),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(
          icon: Icons.question_answer_outlined,
          activeIcon: Icons.question_answer,
          isActive: widget.currentIndex == 1,
        ),
        label: 'Questions',
      ),
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(
          icon: Icons.chat_outlined,
          activeIcon: Icons.chat,
          isActive: widget.currentIndex == 2,
        ),
        label: 'Chat',
      ),
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(
          icon: Icons.notifications_outlined,
          activeIcon: Icons.notifications,
          isActive: widget.currentIndex == 3,
        ),
        label: 'Notifications',
      ),
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          isActive: widget.currentIndex == 4,
        ),
        label: 'Profile',
      ),
    ];
  }

  Widget _buildAnimatedIcon({
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
  }) {
    final currentIcon = isActive ? activeIcon : icon;
    final color = isActive
        ? (widget.selectedItemColor ?? AppColors.primaryColor)
        : (widget.unselectedItemColor ?? AppColors.textSecondary);

    if (isActive) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: (widget.selectedItemColor ?? AppColors.primaryColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(currentIcon, color: color, size: 24.sp),
              ),
            ),
          );
        },
      );
    } else {
      return Icon(currentIcon, color: color, size: 24.sp);
    }
  }
}

/// Main Navigation Container
/// Wraps the main content with bottom navigation
class MainNavigationContainer extends StatefulWidget {
  final Widget child;
  final int initialIndex;

  const MainNavigationContainer({
    Key? key,
    required this.child,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _MainNavigationContainerState createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _buildPages(),
      ),
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return CustomBottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTap,
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: AppColors.textSecondary,
            elevation: 8,
          );
        },
      ),
    );
  }

  List<Widget> _buildPages() {
    return [
      // Home Page
      Container(child: widget.child),

      // Questions Page
      Container(
        child: _buildPlaceholderPage('Questions', Icons.question_answer),
      ),

      // Chat Page
      Container(child: _buildPlaceholderPage('Chat', Icons.chat)),

      // Notifications Page
      Container(
        child: _buildPlaceholderPage('Notifications', Icons.notifications),
      ),

      // Profile Page
      Container(child: _buildPlaceholderPage('Profile', Icons.person)),
    ];
  }

  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.sp, color: AppColors.primaryColor),
          SizedBox(height: 16.h),
          Text(
            title,
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'This page is under development',
            style: AppTextStyles.bodyText2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}

/// Navigation Item Model
class NavigationItem {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final bool requiresAuth;

  const NavigationItem({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.requiresAuth = false,
  });
}

/// Navigation Service
/// Provides navigation logic for bottom navigation
class BottomNavigationService {
  static final List<NavigationItem> navigationItems = [
    NavigationItem(
      title: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      route: AppRoutes.home,
      requiresAuth: true,
    ),
    NavigationItem(
      title: 'Questions',
      icon: Icons.question_answer_outlined,
      activeIcon: Icons.question_answer,
      route: AppRoutes.questions,
      requiresAuth: true,
    ),
    NavigationItem(
      title: 'Chat',
      icon: Icons.chat_outlined,
      activeIcon: Icons.chat,
      route: AppRoutes.chat,
      requiresAuth: true,
    ),
    NavigationItem(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      route: AppRoutes.notifications,
      requiresAuth: true,
    ),
    NavigationItem(
      title: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      route: AppRoutes.profile,
      requiresAuth: true,
    ),
  ];

  /// Get navigation items based on authentication status
  static List<NavigationItem> getNavigationItems(bool isAuthenticated) {
    if (!isAuthenticated) {
      return navigationItems.where((item) => !item.requiresAuth).toList();
    }
    return navigationItems;
  }

  /// Get current index based on route
  static int getCurrentIndex(String? currentRoute, bool isAuthenticated) {
    final items = getNavigationItems(isAuthenticated);

    for (int i = 0; i < items.length; i++) {
      if (currentRoute?.startsWith(items[i].route) ?? false) {
        return i;
      }
    }

    return 0; // Default to home
  }

  /// Navigate to index
  static Future<void> navigateToIndex(
    int index,
    bool isAuthenticated, {
    String? currentRoute,
  }) {
    final items = getNavigationItems(isAuthenticated);

    if (index < items.length) {
      final item = items[index];

      // Check if navigation is allowed
      if (item.requiresAuth && !isAuthenticated) {
        return NavigationService.navigateToLogin(returnRoute: currentRoute);
      }

      return NavigationService.pushNamed(item.route);
    }

    // Return an empty future for invalid index
    return Future.value();
  }

  /// Check if route is accessible
  static bool isRouteAccessible(String route, bool isAuthenticated) {
    final item = navigationItems.firstWhere(
      (item) => route.startsWith(item.route),
      orElse: () => navigationItems.first,
    );

    return !item.requiresAuth || isAuthenticated;
  }

  /// Get redirect route for unauthenticated users
  static String getRedirectRoute(String requestedRoute) {
    final item = navigationItems.firstWhere(
      (item) => requestedRoute.startsWith(item.route),
      orElse: () => navigationItems.first,
    );

    if (item.requiresAuth) {
      return '${AppRoutes.login}?return_to=$requestedRoute';
    }

    return requestedRoute;
  }
}

/// Navigation Observer
/// Tracks navigation events for analytics and debugging
class NavigationObserver extends NavigatorObserver {
  final List<String> _routeHistory = [];
  final List<NavigationEvent> _events = [];

  List<String> get routeHistory => List.unmodifiable(_routeHistory);
  List<NavigationEvent> get events => List.unmodifiable(_events);

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _addRouteToHistory(route.settings.name);
    _addEvent(NavigationEvent.push(route.settings.name));
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _removeRouteFromHistory(route.settings.name);
    _addEvent(NavigationEvent.pop(route.settings.name));
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      _removeRouteFromHistory(oldRoute.settings.name);
    }
    if (newRoute != null) {
      _addRouteToHistory(newRoute.settings.name);
    }
    _addEvent(
      NavigationEvent.replace(oldRoute?.settings.name, newRoute?.settings.name),
    );
  }

  void _addRouteToHistory(String? routeName) {
    if (routeName != null && !_routeHistory.contains(routeName)) {
      _routeHistory.add(routeName);
    }
  }

  void _removeRouteFromHistory(String? routeName) {
    if (routeName != null) {
      _routeHistory.remove(routeName);
    }
  }

  void _addEvent(NavigationEvent event) {
    _events.add(event);

    // Keep only last 100 events
    if (_events.length > 100) {
      _events.removeAt(0);
    }
  }

  void clearHistory() {
    _routeHistory.clear();
    _events.clear();
  }

  String? getPreviousRoute() {
    if (_routeHistory.length > 1) {
      return _routeHistory[_routeHistory.length - 2];
    }
    return null;
  }

  int getRouteCount(String routeName) {
    return _events.where((event) => event.routeName == routeName).length;
  }
}

/// Navigation Event Model
class NavigationEvent {
  final NavigationEventType type;
  final String? routeName;
  final String? previousRouteName;
  final DateTime timestamp;

  NavigationEvent.push(this.routeName)
    : type = NavigationEventType.push,
      previousRouteName = null,
      timestamp = DateTime.now();

  NavigationEvent.pop(this.routeName)
    : type = NavigationEventType.pop,
      previousRouteName = null,
      timestamp = DateTime.now();

  NavigationEvent.replace(this.previousRouteName, this.routeName)
    : type = NavigationEventType.replace,
      timestamp = DateTime.now();

  @override
  String toString() {
    switch (type) {
      case NavigationEventType.push:
        return 'Push: $routeName at ${timestamp.toIso8601String()}';
      case NavigationEventType.pop:
        return 'Pop: $routeName at ${timestamp.toIso8601String()}';
      case NavigationEventType.replace:
        return 'Replace: $previousRouteName -> $routeName at ${timestamp.toIso8601String()}';
    }
  }
}

/// Navigation Event Type
enum NavigationEventType { push, pop, replace }

/// Navigation Analytics
/// Provides analytics for navigation patterns
class NavigationAnalytics {
  static Map<String, int> getRouteVisitCount(NavigationObserver observer) {
    final Map<String, int> visitCount = {};

    for (final event in observer.events) {
      if (event.type == NavigationEventType.push) {
        final routeName = event.routeName;
        if (routeName != null) {
          visitCount[routeName] = (visitCount[routeName] ?? 0) + 1;
        }
      }
    }

    return visitCount;
  }

  static List<String> getMostVisitedRoutes(
    NavigationObserver observer, {
    int limit = 10,
  }) {
    final visitCount = getRouteVisitCount(observer);

    final sortedRoutes = visitCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedRoutes.take(limit).map((entry) => entry.key).toList();
  }

  static Duration getAverageSessionTime(NavigationObserver observer) {
    if (observer.events.length < 2) return Duration.zero;

    final firstEvent = observer.events.first;
    final lastEvent = observer.events.last;

    return lastEvent.timestamp.difference(firstEvent.timestamp);
  }

  static int getSessionCount(NavigationObserver observer) {
    return observer.events
        .where((event) => event.type == NavigationEventType.push)
        .length;
  }
}
