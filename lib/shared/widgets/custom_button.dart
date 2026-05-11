import 'package:flutter/material.dart';

/// Custom Button Widget
/// Reusable button with loading states and styling
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? disabledBackgroundColor;
  final Color? disabledTextColor;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final double? borderRadius;
  final TextStyle? textStyle;
  final Widget? child;
  final bool isOutlined;
  final bool isTextButton;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? iconSize;
  final double? iconSpacing;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.textColor,
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.child,
    this.isOutlined = false,
    this.isTextButton = false,
    this.prefixIcon,
    this.suffixIcon,
    this.iconSize,
    this.iconSpacing,
    this.border,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonChild = _buildButtonChild(context);

    if (isTextButton) {
      return TextButton(
        onPressed: _getOnPressed(),
        style: TextButton.styleFrom(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: Size(width ?? 0, height ?? 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: buttonChild,
      );
    }

    if (isOutlined) {
      return OutlinedButton(
        onPressed: _getOnPressed(),
        style: OutlinedButton.styleFrom(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: Size(width ?? 0, height ?? 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side:
              border as BorderSide? ??
              BorderSide(
                color: backgroundColor ?? Theme.of(context).primaryColor,
                width: 1,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
          ),
        ),
        child: buttonChild,
      );
    }

    return ElevatedButton(
      onPressed: _getOnPressed(),
      style: ElevatedButton.styleFrom(
        backgroundColor: _getBackgroundColor(),
        foregroundColor: _getTextColor(context),
        disabledBackgroundColor:
            disabledBackgroundColor ?? Colors.grey.shade300,
        disabledForegroundColor: disabledTextColor ?? Colors.grey.shade600,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: Size(width ?? 0, height ?? 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: buttonChild,
    );
  }

  Widget _buildButtonChild(BuildContext context) {
    if (isLoading) {
      return _buildLoadingChild(context);
    }

    if (child != null) {
      return child!;
    }

    return _buildTextChild(context);
  }

  Widget _buildLoadingChild(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: iconSize ?? 16,
          height: iconSize ?? 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getTextColor(context) ?? Colors.white,
            ),
          ),
        ),
        if (text.isNotEmpty) ...[
          SizedBox(width: iconSpacing ?? 8),
          Text(text, style: _getTextStyle(context)),
        ],
      ],
    );
  }

  Widget _buildTextChild(BuildContext context) {
    if (prefixIcon == null && suffixIcon == null) {
      return Text(text, style: _getTextStyle(context));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: iconSize ?? 18, color: _getTextColor(context)),
          SizedBox(width: iconSpacing ?? 8),
        ],
        Text(text, style: _getTextStyle(context)),
        if (suffixIcon != null) ...[
          SizedBox(width: iconSpacing ?? 8),
          Icon(suffixIcon, size: iconSize ?? 18, color: _getTextColor(context)),
        ],
      ],
    );
  }

  TextStyle _getTextStyle(BuildContext context) {
    if (textStyle != null) {
      return textStyle!.copyWith(color: _getTextColor(context));
    }

    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: _getTextColor(context),
    );
  }

  Color? _getBackgroundColor() {
    if (backgroundColor != null) {
      return backgroundColor;
    }

    if (isOutlined) {
      return Colors.transparent;
    }

    return null; // Use default
  }

  Color? _getTextColor(BuildContext context) {
    if (textColor != null) {
      return textColor;
    }

    if (isOutlined) {
      return backgroundColor ?? Theme.of(context).primaryColor;
    }

    return null; // Use default
  }

  VoidCallback? _getOnPressed() {
    if (!isEnabled || isLoading) {
      return null;
    }

    return onPressed;
  }
}

/// Primary Button Widget
/// Styled primary action button
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final IconData? icon;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      width: width,
      height: height,
      prefixIcon: icon,
      backgroundColor: Theme.of(context).primaryColor,
      textColor: Colors.white,
      borderRadius: 8,
    );
  }
}

/// Secondary Button Widget
/// Styled secondary action button
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final IconData? icon;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      width: width,
      height: height,
      prefixIcon: icon,
      isOutlined: true,
      backgroundColor: Theme.of(context).primaryColor,
      textColor: Theme.of(context).primaryColor,
      borderRadius: 8,
    );
  }
}

/// Text Button Widget
/// Minimal text-only button
class TextButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final Color? textColor;
  final TextStyle? textStyle;
  final IconData? prefixIcon;
  final IconData? suffixIcon;

  const TextButtonWidget({
    Key? key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.textColor,
    this.textStyle,
    this.prefixIcon,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isEnabled: isEnabled,
      isTextButton: true,
      textColor: textColor ?? Theme.of(context).primaryColor,
      textStyle: textStyle,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }
}

/// Icon Button Widget
/// Button with only an icon
class IconButtonWidget extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? size;
  final double? iconSize;
  final double? borderRadius;
  final BoxBorder? border;

  const IconButtonWidget({
    Key? key,
    required this.icon,
    this.onPressed,
    this.isEnabled = true,
    this.iconColor,
    this.backgroundColor,
    this.size,
    this.iconSize,
    this.borderRadius,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? 40,
      height: size ?? 40,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        border: border,
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          child: Center(
            child: Icon(
              icon,
              size: iconSize ?? 20,
              color:
                  iconColor ??
                  (isEnabled
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade400),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating Action Button Widget
/// Custom FAB with additional styling options
class CustomFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;
  final bool isExtended;
  final String? extendedText;
  final Widget? extendedIcon;

  const CustomFAB({
    Key? key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
    this.isExtended = false,
    this.extendedText,
    this.extendedIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fab = isExtended
        ? FloatingActionButton.extended(
            onPressed: onPressed,
            icon: extendedIcon ?? Icon(icon),
            label: Text(extendedText ?? ''),
            backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
            foregroundColor: foregroundColor ?? Colors.white,
          )
        : FloatingActionButton(
            onPressed: onPressed,
            child: Icon(icon),
            backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
            foregroundColor: foregroundColor ?? Colors.white,
            mini: size != null && size! < 56,
          );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: fab);
    }

    return fab;
  }
}
