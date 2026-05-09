import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../../../../core/navigation/app_routes.dart';

/// ASTU-Q Splash Screen
/// Modern, attractive design representing the educational Q&A platform
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _progressController;

  // Animations
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    // Logo entrance animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Pulse animation for logo glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Rotate animation for decorative elements
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Progress bar animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animation curves
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() async {
    // Staggered animation sequence
    await Future.delayed(const Duration(milliseconds: 100));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    _progressController.forward();

    // Navigate after splash duration - increased to allow auth provider to load
    await Future.delayed(const Duration(milliseconds: 3500));
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    final authProvider = Provider.of<AuthenticationProvider>(
      context,
      listen: false,
    );

    print('DEBUG: authProvider.isLoading = ${authProvider.isLoading}');
    print(
      'DEBUG: authProvider.isInitialLoadComplete = ${authProvider.isInitialLoadComplete}',
    );
    print(
      'DEBUG: authProvider.isAuthenticated = ${authProvider.isAuthenticated}',
    );
    print('DEBUG: authProvider.user = ${authProvider.user}');

    // Wait for initial load to complete before making navigation decision
    if (!authProvider.isInitialLoadComplete) {
      print('DEBUG: Initial load not complete yet, waiting...');
      Future.delayed(Duration(milliseconds: 500), () {
        _navigateToNextScreen();
      });
      return;
    }

    if (authProvider.isAuthenticated) {
      print('DEBUG: User is authenticated, navigating to home');
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } else {
      print('DEBUG: User is not authenticated, navigating to login');
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _fadeController,
          _pulseController,
          _rotateController,
          _progressController,
        ]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color.fromARGB(188, 105, 73, 167),
                  const Color.fromARGB(255, 75, 45, 120),
                  const Color.fromARGB(255, 45, 25, 90),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated background elements
                ..._buildBackgroundElements(size),

                // Main content
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _getResponsiveSize(screenWidth, 32),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: _getResponsiveSize(screenHeight, 60),
                            ),

                            // Logo with animation
                            _buildAnimatedLogo(screenWidth),

                            SizedBox(
                              height: _getResponsiveSize(screenHeight, 40),
                            ),

                            // App name
                            _buildAppName(screenWidth),

                            SizedBox(
                              height: _getResponsiveSize(screenHeight, 12),
                            ),

                            // Tagline
                            _buildTagline(screenWidth),

                            SizedBox(
                              height: _getResponsiveSize(screenHeight, 80),
                            ),

                            // Progress bar
                            _buildProgressBar(screenWidth),

                            SizedBox(
                              height: _getResponsiveSize(screenHeight, 60),
                            ),

                            // Footer
                            _buildFooter(screenWidth),

                            SizedBox(
                              height: _getResponsiveSize(screenHeight, 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _getResponsiveSize(double screenSize, double baseSize) {
    if (screenSize < 600) {
      // Mobile
      return baseSize;
    } else if (screenSize < 900) {
      // Tablet
      return baseSize * 1.2;
    } else {
      // Desktop
      return baseSize * 1.5;
    }
  }

  List<Widget> _buildBackgroundElements(Size size) {
    final screenWidth = size.width;
    final screenHeight = size.height;

    return [
      // Floating question marks
      Positioned(
        top: screenHeight * 0.15,
        left: screenWidth * 0.1,
        child: AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateAnimation.value * 2 * math.pi,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.help_outline,
                  size: _getResponsiveSize(screenWidth, 80),
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),

      Positioned(
        top: screenHeight * 0.2,
        right: screenWidth * 0.15,
        child: AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Transform.rotate(
              angle: -_rotateAnimation.value * 2 * math.pi,
              child: Opacity(
                opacity: 0.08,
                child: Icon(
                  Icons.school,
                  size: _getResponsiveSize(screenWidth, 100),
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),

      Positioned(
        bottom: screenHeight * 0.25,
        left: screenWidth * 0.08,
        child: AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateAnimation.value * 2 * math.pi,
              child: Opacity(
                opacity: 0.06,
                child: Icon(
                  Icons.menu_book,
                  size: _getResponsiveSize(screenWidth, 90),
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),

      Positioned(
        bottom: screenHeight * 0.15,
        right: screenWidth * 0.1,
        child: AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Transform.rotate(
              angle: -_rotateAnimation.value * 2 * math.pi,
              child: Opacity(
                opacity: 0.07,
                child: Icon(
                  Icons.lightbulb_outline,
                  size: _getResponsiveSize(screenWidth, 85),
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),

      // Central glow effect
      Center(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width:
                  _getResponsiveSize(screenWidth, 250) * _pulseAnimation.value,
              height:
                  _getResponsiveSize(screenWidth, 250) * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildAnimatedLogo(double screenWidth) {
    final logoSize = _getResponsiveSize(screenWidth, 140);
    final iconSize = _getResponsiveSize(screenWidth, 56);
    final textSize = _getResponsiveSize(screenWidth, 22);

    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoAnimation.value,
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 30 * _pulseAnimation.value,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz,
                    size: iconSize,
                    color: const Color.fromARGB(188, 105, 73, 167),
                  ),
                  SizedBox(height: _getResponsiveSize(screenWidth, 4)),
                  Text(
                    'ASTU-Q',
                    style: TextStyle(
                      fontSize: textSize,
                      fontWeight: FontWeight.w800,
                      color: const Color.fromARGB(188, 105, 73, 167),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppName(double screenWidth) {
    final fontSize = _getResponsiveSize(screenWidth, 48);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            'ASTU-Q',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 4,
              height: 1.2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline(double screenWidth) {
    final fontSize = _getResponsiveSize(screenWidth, 18);
    final lineHeight = _getResponsiveSize(screenWidth, 3);
    final lineWidth = _getResponsiveSize(screenWidth, 80);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Text(
                'Your Questions, Answered',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: _getResponsiveSize(screenWidth, 16)),
              Container(
                width: lineWidth,
                height: lineHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(double screenWidth) {
    final barWidth = _getResponsiveSize(screenWidth, 200);
    final barHeight = _getResponsiveSize(screenWidth, 4);
    final fontSize = _getResponsiveSize(screenWidth, 14);

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Container(
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: FractionallySizedBox(
                    widthFactor: _progressAnimation.value,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: _getResponsiveSize(screenWidth, 12)),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(double screenWidth) {
    final fontSize1 = _getResponsiveSize(screenWidth, 13);
    final fontSize2 = _getResponsiveSize(screenWidth, 11);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.only(bottom: _getResponsiveSize(screenWidth, 24)),
        child: Column(
          children: [
            Text(
              '© 2026 ASTU-Q',
              style: TextStyle(
                fontSize: fontSize1,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: _getResponsiveSize(screenWidth, 4)),
            Text(
              'Adama Science and Technology University',
              style: TextStyle(
                fontSize: fontSize2,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
