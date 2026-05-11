import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Loading Widget
/// Reusable loading indicator with different styles
class LoadingWidget extends StatelessWidget {
  final double? size;
  final Color? color;
  final LoadingType type;
  final String? message;
  final double? strokeWidth;

  const LoadingWidget({
    Key? key,
    this.size,
    this.color,
    this.type = LoadingType.circle,
    this.message,
    this.strokeWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loadingColor = color ?? Theme.of(context).primaryColor;
    final loadingSize = size ?? 24.0;

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLoadingIndicator(loadingColor, loadingSize),
          if (message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );
    }

    return _buildLoadingIndicator(loadingColor, loadingSize);
  }

  Widget _buildLoadingIndicator(Color color, double size) {
    switch (type) {
      case LoadingType.circle:
        return SpinKitCircle(color: color, size: size);
      case LoadingType.dualRing:
        return SpinKitDualRing(color: color, size: size);
      case LoadingType.fadingCircle:
        return SpinKitFadingCircle(color: color, size: size);
      case LoadingType.pouringHourGlass:
        return SpinKitPouringHourGlass(color: color, size: size);
      case LoadingType.pulse:
        return SpinKitPulse(color: color, size: size);
      case LoadingType.rotatingCircle:
        return SpinKitRotatingCircle(color: color, size: size);
      case LoadingType.threeBounce:
        return SpinKitThreeBounce(color: color, size: size);
      case LoadingType.wanderingCube:
        return SpinKitCubeGrid(color: color, size: size);
      case LoadingType.wave:
        return SpinKitWave(color: color, size: size);
      case LoadingType.dancingSquare:
        return SpinKitDancingSquare(color: color, size: size);
      case LoadingType.hourGlass:
        return SpinKitHourGlass(color: color, size: size);
      case LoadingType.fadingFour:
        return SpinKitFadingFour(color: color, size: size);
      case LoadingType.foldingCube:
        return SpinKitFoldingCube(color: color, size: size);
      case LoadingType.grid:
        return SpinKitCubeGrid(color: color, size: size);
      case LoadingType.ripple:
        return SpinKitRipple(color: color, size: size);
      case LoadingType.chasingDots:
        return SpinKitChasingDots(color: color, size: size);
      default:
        return CircularProgressIndicator(
          color: color,
          strokeWidth: strokeWidth ?? 2.0,
        );
    }
  }
}

/// Full Screen Loading Widget
/// Covers the entire screen with a loading indicator
class FullScreenLoadingWidget extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final LoadingType type;
  final double? size;

  const FullScreenLoadingWidget({
    Key? key,
    this.message,
    this.backgroundColor,
    this.indicatorColor,
    this.type = LoadingType.circle,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.white.withOpacity(0.8),
      child: Center(
        child: LoadingWidget(
          size: size ?? 48,
          color: indicatorColor,
          type: type,
          message: message,
        ),
      ),
    );
  }
}

/// Button Loading Widget
/// Loading widget specifically for buttons
class ButtonLoadingWidget extends StatelessWidget {
  final double? size;
  final Color? color;

  const ButtonLoadingWidget({Key? key, this.size, this.color})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 16,
      height: size ?? 16,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.white),
      ),
    );
  }
}

/// Card Loading Widget
/// Loading widget that mimics a card with shimmer effect
class CardLoadingWidget extends StatelessWidget {
  final double? height;
  final double? width;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const CardLoadingWidget({
    Key? key,
    this.height,
    this.width,
    this.borderRadius = 8.0,
    this.baseColor,
    this.highlightColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 100,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: _buildShimmerEffect(),
    );
  }

  Widget _buildShimmerEffect() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor ?? Colors.grey[300]!,
                highlightColor ?? Colors.grey[100]!,
                baseColor ?? Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// List Loading Widget
/// Shows multiple skeleton items to mimic a list
class ListLoadingWidget extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double borderRadius;
  final EdgeInsets padding;

  const ListLoadingWidget({
    Key? key,
    this.itemCount = 5,
    this.itemHeight = 60,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CardLoadingWidget(
              height: itemHeight,
              borderRadius: borderRadius,
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading Type Enum
enum LoadingType {
  circle,
  dualRing,
  fadingCircle,
  pouringHourGlass,
  pulse,
  rotatingCircle,
  threeBounce,
  wanderingCube,
  wave,
  dancingSquare,
  hourGlass,
  fadingFour,
  foldingCube,
  grid,
  ripple,
  chasingDots,
}

/// Loading Overlay Widget
/// Can be placed over any widget to show loading state
class LoadingOverlayWidget extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? overlayColor;
  final Color? indicatorColor;
  final LoadingType type;

  const LoadingOverlayWidget({
    Key? key,
    required this.child,
    this.isLoading = false,
    this.message,
    this.overlayColor,
    this.indicatorColor,
    this.type = LoadingType.circle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: overlayColor ?? Colors.black.withOpacity(0.3),
              child: Center(
                child: LoadingWidget(
                  color: indicatorColor ?? Colors.white,
                  type: type,
                  message: message,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom Loading Animation Widget
/// Custom loading animation using Lottie or custom painter
class CustomLoadingAnimation extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const CustomLoadingAnimation({
    Key? key,
    this.size = 48,
    this.color = Colors.blue,
    this.duration = const Duration(seconds: 1),
  }) : super(key: key);

  @override
  _CustomLoadingAnimationState createState() => _CustomLoadingAnimationState();
}

class _CustomLoadingAnimationState extends State<CustomLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + (_animation.value * 0.5),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(widget.size * 0.1),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(_animation.value),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
