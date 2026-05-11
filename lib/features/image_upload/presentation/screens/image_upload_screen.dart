import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/image_upload_provider.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';

/// Image Upload Screen
/// Provides image selection, preview, and upload functionality
class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({Key? key}) : super(key: key);

  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen>
    with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemUiOverlayStyle,
        child: SafeArea(
          child: Consumer<ImageUploadProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upload Area
                    _buildUploadArea(provider),
                    SizedBox(height: 24.h),

                    // Image Preview
                    if (provider.hasImage) ...[
                      _buildImagePreview(provider),
                      SizedBox(height: 24.h),
                    ],

                    // Upload Controls
                    if (provider.hasImage) ...[
                      _buildUploadControls(provider),
                      SizedBox(height: 24.h),
                    ],

                    // Upload Progress
                    if (provider.isUploading) ...[
                      _buildUploadProgress(provider),
                    ],

                    // Error Message
                    if (provider.errorMessage != null) ...[
                      _buildErrorMessage(provider),
                    ],

                    // Success Message
                    if (provider.uploadedImageUrl != null) ...[
                      _buildSuccessMessage(provider),
                    ],
                  ],
                ),
              );
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
      systemOverlayStyle: AppTheme.systemUiOverlayStyle,
      title: Text(
        'Upload Image',
        style: AppTextStyles.headline3.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back, color: AppColors.textSecondary),
      ),
      actions: [
        Consumer<ImageUploadProvider>(
          builder: (context, provider, child) {
            return provider.hasImage
                ? IconButton(
                    onPressed: provider.clearImage,
                    icon: Icon(Icons.clear, color: AppColors.textSecondary),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildUploadArea(ImageUploadProvider provider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 200.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 48.sp,
                color: AppColors.primaryColor,
              ),
              SizedBox(height: 16.h),
              Text(
                'Upload Image',
                style: AppTextStyles.headline4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Choose from gallery or take a photo',
                style: AppTextStyles.bodyText2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceButton(
                    'Gallery',
                    Icons.photo_library,
                    () => provider.pickImageFromGallery(),
                  ),
                  _buildSourceButton(
                    'Camera',
                    Icons.camera_alt,
                    () => provider.pickImageFromCamera(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.primaryColor, size: 20.sp),
                SizedBox(width: 8.w),
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
      ),
    );
  }

  Widget _buildImagePreview(ImageUploadProvider provider) {
    final imageInfo = provider.getImageInfo();
    final displayImage = provider.getDisplayImage();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.image, color: AppColors.primaryColor, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Image Preview',
                  style: AppTextStyles.bodyText1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
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
          Container(
            width: double.infinity,
            height: 300.h,
            padding: EdgeInsets.all(16.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: _buildImageWidget(displayImage),
            ),
          ),

          // Image Actions
          Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Change Image',
                    onPressed: () => _showImageSourceDialog(provider),
                    prefixIcon: Icons.edit,
                    backgroundColor: AppColors.secondaryColor,
                    textColor: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CustomButton(
                    text: 'Remove',
                    onPressed: provider.clearImage,
                    prefixIcon: Icons.delete,
                    backgroundColor: AppColors.errorColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(dynamic imageData) {
    if (imageData is File) {
      return Image.file(
        imageData,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget('Failed to load image');
        },
      );
    } else if (imageData is Uint8List) {
      return Image.memory(
        imageData,
        fit: BoxFit.contain,
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
          Icon(Icons.broken_image, size: 48.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            message,
            style: AppTextStyles.bodyText2.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadControls(ImageUploadProvider provider) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Options',
            style: AppTextStyles.headline4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),

          // Folder Selection
          _buildFolderSelector(),
          SizedBox(height: 16.h),

          // Upload Button
          CustomButton(
            text: 'Upload Image',
            onPressed: provider.isUploading
                ? null
                : () => _handleUpload(provider),
            prefixIcon: Icons.cloud_upload,
            backgroundColor: AppColors.primaryColor,
            height: 48.h,
          ),

          SizedBox(height: 12.h),

          // Additional Options
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleCompressImage(provider),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.compress,
                        size: 16.sp,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Compress',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showImageInfo(provider),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16.sp,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Info',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFolderSelector() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, color: AppColors.primaryColor, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Upload to: uploads',
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Icon(
            Icons.arrow_drop_down,
            color: AppColors.textSecondary,
            size: 20.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress(ImageUploadProvider provider) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LoadingWidget(size: 24.sp, color: AppColors.primaryColor),
              SizedBox(width: 12.w),
              Text(
                'Uploading...',
                style: AppTextStyles.bodyText1.copyWith(
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
          SizedBox(height: 16.h),
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

  Widget _buildErrorMessage(ImageUploadProvider provider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.errorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.errorColor, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              provider.errorMessage!,
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.errorColor,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // Clear error by resetting provider error state
              provider.clearError();
            },
            icon: Icon(Icons.close, color: AppColors.errorColor, size: 20.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(ImageUploadProvider provider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.successColor.withOpacity(0.3),
          width: 1,
        ),
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
                  provider.uploadedImageUrl!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Copy URL',
                        onPressed: () =>
                            _copyToClipboard(provider.uploadedImageUrl!),
                        prefixIcon: Icons.copy,
                        height: 36.h,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: CustomButton(
                        text: 'View Image',
                        onPressed: () =>
                            _viewUploadedImage(provider.uploadedImageUrl!),
                        prefixIcon: Icons.visibility,
                        height: 36.h,
                        backgroundColor: AppColors.secondaryColor,
                        textColor: AppColors.textPrimary,
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

  // Event Handlers
  void _handleUpload(ImageUploadProvider provider) async {
    if (!provider.validateImage()) {
      return;
    }

    final success = await provider.uploadImage(
      folder: 'uploads',
      additionalFields: {
        'user_id': 'current_user_id', // Replace with actual user ID
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image uploaded successfully!'),
          backgroundColor: AppColors.successColor,
        ),
      );
    }
  }

  void _handleCompressImage(ImageUploadProvider provider) {
    // Show compression options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Compress Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select compression quality:'),
            SizedBox(height: 16.h),
            ...['High', 'Medium', 'Low'].map(
              (quality) => RadioListTile<String>(
                title: Text(quality),
                value: quality,
                groupValue: 'High',
                onChanged: (value) {
                  Navigator.pop(context);
                  provider.compressImage();
                },
              ),
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

  void _showImageInfo(ImageUploadProvider provider) {
    final info = provider.getImageInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Image Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Type', info['type']?.toString() ?? 'Unknown'),
            _buildInfoRow(
              'Size',
              info['sizeFormatted']?.toString() ?? 'Unknown',
            ),
            _buildInfoRow(
              'Source',
              provider.currentSource?.toString() ?? 'Unknown',
            ),
            _buildInfoRow('Format', 'JPEG/PNG'),
            _buildInfoRow(
              'Status',
              provider.isUploading ? 'Uploading' : 'Ready',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog(ImageUploadProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Image'),
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

  void _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL copied to clipboard!'),
        backgroundColor: AppColors.successColor,
      ),
    );
  }

  void _viewUploadedImage(String url) {
    // Navigate to image viewer or open in browser
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.infinity,
          height: 400.h,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Text(
                      'Uploaded Image',
                      style: AppTextStyles.headline4.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48.sp,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Failed to load image',
                              style: AppTextStyles.bodyText2.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
