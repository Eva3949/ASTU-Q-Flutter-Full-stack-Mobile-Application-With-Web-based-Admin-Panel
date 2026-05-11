import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/image_upload_provider.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/text_styles.dart';

/// Image Picker Widget
/// Reusable widget for image selection and preview
class ImagePickerWidget extends StatelessWidget {
  final ImageUploadProvider provider;
  final String? title;
  final double? height;
  final double? width;
  final bool showActions;
  final VoidCallback? onImageSelected;
  final VoidCallback? onImageRemoved;
  final Widget? placeholder;

  const ImagePickerWidget({
    Key? key,
    required this.provider,
    this.title,
    this.height,
    this.width,
    this.showActions = true,
    this.onImageSelected,
    this.onImageRemoved,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: provider.hasImage 
              ? AppColors.primaryColor.withOpacity(0.3)
              : Colors.grey[300]!,
          width: provider.hasImage ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: provider.hasImage 
          ? _buildImagePreview(context)
          : _buildEmptyState(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => _showImageSourceDialog(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          placeholder ?? _buildDefaultPlaceholder(),
          SizedBox(height: 16.h),
          Text(
            title ?? 'Tap to select image',
            style: AppTextStyles.bodyText1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Choose from gallery or camera',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: 64.w,
      height: 64.h,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.add_photo_alternate,
        size: 32.sp,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final displayImage = provider.getDisplayImage();
    final imageInfo = provider.getImageInfo();
    
    return Column(
      children: [
        // Preview Header
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              topRight: Radius.circular(12.r),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.image,
                color: AppColors.primaryColor,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title ?? 'Selected Image',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                imageInfo['sizeFormatted'] ?? '',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Image Display
        Expanded(
          child: Container(
            padding: EdgeInsets.all(8.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: _buildImageWidget(displayImage),
            ),
          ),
        ),
        
        // Actions
        if (showActions) ...[
          Container(
            padding: EdgeInsets.all(8.w),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Change',
                    Icons.edit,
                    () {
                      _showImageSourceDialog(context);
                      onImageSelected?.call();
                    },
                    AppColors.secondaryColor,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildActionButton(
                    'Remove',
                    Icons.delete,
                    () {
                      provider.clearImage();
                      onImageRemoved?.call();
                    },
                    AppColors.errorColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageWidget(dynamic imageData) {
    if (imageData is File) {
      return Image.file(
        imageData,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget('Failed to load image');
        },
      );
    } else if (imageData is Uint8List) {
      return Image.memory(
        imageData,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget('Failed to load image');
        },
      );
    } else {
      return _buildErrorWidget('No image data');
    }
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 32.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, Color color) {
    return Container(
      height: 32.h,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6.r),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 14.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                provider.pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                provider.pickImageFromCamera();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Compact Image Picker Widget
/// Smaller version for use in forms
class CompactImagePickerWidget extends StatelessWidget {
  final ImageUploadProvider provider;
  final double size;
  final VoidCallback? onImageSelected;
  final VoidCallback? onImageRemoved;

  const CompactImagePickerWidget({
    Key? key,
    required this.provider,
    this.size = 80,
    this.onImageSelected,
    this.onImageRemoved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: provider.hasImage 
              ? AppColors.primaryColor.withOpacity(0.3)
              : Colors.grey[300]!,
          width: provider.hasImage ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: provider.hasImage 
          ? _buildCompactPreview()
          : _buildCompactEmptyState(),
    );
  }

  Widget _buildCompactEmptyState() {
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: () => _showImageSourceDialog(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 24.sp,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: 4.h),
          Text(
            'Add',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPreview() {
    final displayImage = provider.getDisplayImage();
    
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: _buildImageWidget(displayImage),
        ),
        
        // Remove Button
        Positioned(
          top: 4.h,
          right: 4.w,
          child: GestureDetector(
            onTap: () {
              provider.clearImage();
              onImageRemoved?.call();
            },
            child: Container(
              width: 20.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: AppColors.errorColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 12.sp,
              ),
            ),
          ),
        ),
        
        // Change Overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              _showImageSourceDialog();
              onImageSelected?.call();
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: Colors.black.withOpacity(0.0),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Change',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(dynamic imageData) {
    if (imageData is File) {
      return Image.file(
        imageData,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else if (imageData is Uint8List) {
      return Image.memory(
        imageData,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Icon(
        Icons.broken_image,
        size: 24.sp,
        color: Colors.grey[400],
      ),
    );
  }

  void _showImageSourceDialog() {
    // This would need context - for now, just pick from gallery
    provider.pickImageFromGallery();
  }
}

/// Image Upload Progress Widget
class ImageUploadProgressWidget extends StatelessWidget {
  final ImageUploadProvider provider;

  const ImageUploadProgressWidget({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16.w,
                height: 16.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Uploading...',
                style: AppTextStyles.bodyText2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                '${(provider.uploadProgress * 100).toInt()}%',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          LinearProgressIndicator(
            value: provider.uploadProgress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please wait while we upload your image...',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Image Upload Result Widget
class ImageUploadResultWidget extends StatelessWidget {
  final ImageUploadProvider provider;
  final VoidCallback? onCopyUrl;
  final VoidCallback? onViewImage;

  const ImageUploadResultWidget({
    Key? key,
    required this.provider,
    this.onCopyUrl,
    this.onViewImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.successColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.successColor,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Upload Successful!',
                style: AppTextStyles.bodyText1.copyWith(
                  color: AppColors.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image URL:',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  provider.uploadedImageUrl ?? '',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Copy URL',
                        Icons.copy,
                        () {
                          onCopyUrl?.call();
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildActionButton(
                        'View',
                        Icons.visibility,
                        () {
                          onViewImage?.call();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return Container(
      height: 32.h,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6.r),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.primaryColor,
                size: 14.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
