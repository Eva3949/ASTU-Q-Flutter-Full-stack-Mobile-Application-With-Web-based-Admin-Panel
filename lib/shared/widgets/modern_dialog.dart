import 'package:flutter/material.dart';

/// Modern Dialog Widget
/// A beautiful, responsive dialog with purple theme matching ASTU-Q app design
class ModernDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? customContent;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final IconData? icon;
  final Color? iconColor;
  final bool barrierDismissible;
  final bool showIcon;

  const ModernDialog({
    super.key,
    required this.title,
    this.message,
    this.customContent,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.icon,
    this.iconColor,
    this.barrierDismissible = true,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 900;

    double dialogWidth;
    double padding;
    double titleFontSize;
    double messageFontSize;
    double buttonHeight;
    double borderRadius;

    if (isMobile) {
      dialogWidth = screenWidth * 0.9;
      padding = 24;
      titleFontSize = 22;
      messageFontSize = 16;
      buttonHeight = 48;
      borderRadius = 20;
    } else if (isTablet) {
      dialogWidth = screenWidth * 0.6;
      padding = 32;
      titleFontSize = 26;
      messageFontSize = 18;
      buttonHeight = 52;
      borderRadius = 24;
    } else {
      dialogWidth = 500;
      padding = 40;
      titleFontSize = 28;
      messageFontSize = 18;
      buttonHeight = 56;
      borderRadius = 28;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(188, 105, 73, 167),
              Color.fromARGB(255, 75, 45, 120),
              Color.fromARGB(255, 45, 25, 90),
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon && icon != null) ...[
                Container(
                  width: isMobile ? 60 : 80,
                  height: isMobile ? 60 : 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: isMobile ? 32 : 40,
                    color: iconColor ?? Colors.white,
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  message!,
                  style: TextStyle(
                    fontSize: messageFontSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (customContent != null) ...[
                SizedBox(height: isMobile ? 12 : 16),
                customContent!,
              ],
              SizedBox(height: isMobile ? 24 : 32),
              Row(
                children: [
                  if (secondaryButtonText != null) ...[
                    Expanded(
                      child: _buildSecondaryButton(
                        text: secondaryButtonText!,
                        onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
                        height: buttonHeight,
                        fontSize: messageFontSize,
                      ),
                    ),
                    if (primaryButtonText != null) SizedBox(width: isMobile ? 12 : 16),
                  ],
                  if (primaryButtonText != null)
                    Expanded(
                      child: _buildPrimaryButton(
                        text: primaryButtonText!,
                        onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
                        height: buttonHeight,
                        fontSize: messageFontSize,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    required double height,
    required double fontSize,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(height / 2),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(188, 105, 73, 167),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    required double height,
    required double fontSize,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(height / 2),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    String? message,
    String primaryText = 'Confirm',
    String secondaryText = 'Cancel',
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ModernDialog(
        title: title,
        message: message,
        primaryButtonText: primaryText,
        secondaryButtonText: secondaryText,
        onPrimaryPressed: () => Navigator.of(context).pop(true),
        onSecondaryPressed: () => Navigator.of(context).pop(false),
        icon: icon ?? Icons.help_outline,
        iconColor: iconColor,
      ),
    );
  }

  /// Show success dialog
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    String? message,
    String buttonText = 'OK',
    VoidCallback? onButtonPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModernDialog(
        title: title,
        message: message,
        primaryButtonText: buttonText,
        onPrimaryPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
        icon: Icons.check_circle,
        iconColor: const Color(0xFF4CAF50),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showError({
    required BuildContext context,
    required String title,
    String? message,
    String buttonText = 'OK',
    VoidCallback? onButtonPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ModernDialog(
        title: title,
        message: message,
        primaryButtonText: buttonText,
        onPrimaryPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
        icon: Icons.error_outline,
        iconColor: const Color(0xFFF44336),
      ),
    );
  }

  /// Show warning dialog
  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    String? message,
    String buttonText = 'OK',
    VoidCallback? onButtonPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ModernDialog(
        title: title,
        message: message,
        primaryButtonText: buttonText,
        onPrimaryPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFFF9800),
      ),
    );
  }

  /// Show info dialog
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    String? message,
    String buttonText = 'OK',
    VoidCallback? onButtonPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ModernDialog(
        title: title,
        message: message,
        primaryButtonText: buttonText,
        onPrimaryPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
        icon: Icons.info_outline,
        iconColor: const Color(0xFF2196F3),
      ),
    );
  }
}
