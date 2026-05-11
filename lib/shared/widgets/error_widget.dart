import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';

/// Error Widget
/// Reusable error display widget with different styles and configurations
class ErrorWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final ErrorType type;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showRetryButton;
  final String? retryText;

  const ErrorWidget({
    Key? key,
    required this.message,
    this.title,
    this.onRetry,
    this.type = ErrorType.fullScreen,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.showRetryButton = true,
    this.retryText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ErrorType.fullScreen:
        return _buildFullScreenError(context);
      case ErrorType.card:
        return _buildCardError(context);
      case ErrorType.inline:
        return _buildInlineError(context);
      case ErrorType.dialog:
        return _buildDialogError(context);
      case ErrorType.snackbar:
        return _buildSnackbarError(context);
    }
  }

  Widget _buildFullScreenError(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.backgroundColor,
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildErrorIcon(),
            SizedBox(height: 24),
            if (title != null) ...[
              Text(
                title!,
                style: AppTextStyles.headline3.copyWith(
                  color: textColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
            ],
            Text(
              message,
              style: AppTextStyles.bodyText1.copyWith(
                color: textColor ?? AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (showRetryButton && onRetry != null) ...[
              SizedBox(height: 32),
              _buildRetryButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardError(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.errorColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildErrorIcon(size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: AppTextStyles.bodyText1.copyWith(
                          color: textColor ?? AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                    ],
                    Text(
                      message,
                      style: AppTextStyles.bodyText2.copyWith(
                        color: textColor ?? AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (showRetryButton && onRetry != null) ...[
                SizedBox(width: 8),
                _buildRetryButton(compact: true),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineError(BuildContext context) {
    return Row(
      children: [
        _buildErrorIcon(size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.bodyText2.copyWith(
              color: AppColors.errorColor,
            ),
          ),
        ),
        if (showRetryButton && onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: Text(
              retryText ?? 'Retry',
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDialogError(BuildContext context) {
    return AlertDialog(
      title: title != null
          ? Text(
              title!,
              style: AppTextStyles.headline3.copyWith(
                color: textColor ?? AppColors.textPrimary,
              ),
            )
          : null,
      content: Row(
        children: [
          _buildErrorIcon(size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyText1.copyWith(
                color: textColor ?? AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (showRetryButton && onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: Text(
              retryText ?? 'Retry',
              style: AppTextStyles.button.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Dismiss',
            style: AppTextStyles.button.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSnackbarError(BuildContext context) {
    return SnackBar(
      content: Row(
        children: [
          _buildErrorIcon(size: 20, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyText2.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.errorColor,
      action: showRetryButton && onRetry != null
          ? SnackBarAction(
              label: retryText ?? 'Retry',
              onPressed: onRetry!,
              textColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildErrorIcon({double? size, Color? color}) {
    return Icon(
      icon ?? Icons.error_outline,
      size: size ?? 48,
      color: color ?? AppColors.errorColor,
    );
  }

  Widget _buildRetryButton({bool compact = false}) {
    if (compact) {
      return InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.refresh,
            size: 16.sp,
            color: AppColors.primaryColor,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onRetry,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        retryText ?? 'Try Again',
        style: AppTextStyles.button.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Show error as a dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String message,
    String? title,
    VoidCallback? onRetry,
    bool showRetryButton = true,
    String? retryText,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorWidget(
        message: message,
        title: title,
        onRetry: onRetry,
        type: ErrorType.dialog,
        showRetryButton: showRetryButton,
        retryText: retryText,
      ),
    );
  }

  /// Show error as a snackbar
  static void showErrorSnackbar(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    bool showRetryButton = true,
    String? retryText,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.errorColor,
        action: showRetryButton && onRetry != null
            ? SnackBarAction(
                label: retryText ?? 'Retry',
                onPressed: onRetry,
                textColor: Colors.white,
              )
            : null,
        duration: Duration(seconds: 4),
      ),
    );
  }
}

/// Error Type Enum
/// Different types of error display styles
enum ErrorType {
  fullScreen,
  card,
  inline,
  dialog,
  snackbar,
}

/// Network Error Widget
/// Specialized widget for network-related errors
class NetworkErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isOffline;

  const NetworkErrorWidget({
    Key? key,
    this.message = 'No internet connection. Please check your network settings.',
    this.onRetry,
    this.isOffline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      message: message,
      title: isOffline ? 'Offline' : 'Network Error',
      onRetry: onRetry,
      icon: isOffline ? Icons.wifi_off : Icons.cloud_off,
      type: ErrorType.fullScreen,
      retryText: isOffline ? 'Retry' : 'Refresh',
    );
  }
}

/// Empty State Widget
/// Widget to display when there's no data to show
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onAction;
  final String? actionText;
  final IconData? icon;

  const EmptyStateWidget({
    Key? key,
    required this.message,
    this.title,
    this.onAction,
    this.actionText,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            SizedBox(height: 24),
            if (title != null) ...[
              Text(
                title!,
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
            ],
            Text(
              message,
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  actionText ?? 'Get Started',
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
