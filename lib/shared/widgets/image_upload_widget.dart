import 'package:flutter/material.dart';

/// Image Upload Widget
/// A reusable widget for uploading and managing images with camera and gallery options
class ImageUploadWidget extends StatelessWidget {
  final List<String> images;
  final bool isUploading;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final Function(String) onRemoveImage;
  final VoidCallback onClearAll;

  const ImageUploadWidget({
    Key? key,
    required this.images,
    required this.isUploading,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onRemoveImage,
    required this.onClearAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isUploading ? null : onCameraTap,
                icon: isUploading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.camera_alt_outlined),
                label: Text(isUploading ? 'Uploading...' : 'Camera'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isUploading ? null : onGalleryTap,
                icon: isUploading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.photo_library_outlined),
                label: Text(isUploading ? 'Uploading...' : 'Gallery'),
              ),
            ),
          ],
        ),
        
        // Uploaded Images
        if (images.isNotEmpty) ...[
          SizedBox(height: 16),
          _buildImageGrid(),
        ],
      ],
    );
  }

  Widget _buildImageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Uploaded Images (${images.length})'),
            TextButton(
              onPressed: onClearAll,
              child: Text('Clear All'),
            ),
          ],
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: images.map((imageUrl) {
            return Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onRemoveImage(imageUrl),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
