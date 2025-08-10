import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image with detailed error logging
  static Future<File?> pickImageWithValidation({
    required ImageSource source,
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 80,
  }) async {
    try {
      debugPrint('🖼️ Starting image picker...');
      debugPrint('📱 Source: $source');
      debugPrint('📏 Max dimensions: ${maxWidth}x$maxHeight');
      debugPrint('🎨 Quality: $imageQuality%');

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile == null) {
        debugPrint('❌ No image selected');
        return null;
      }

      debugPrint('✅ Image picked: ${pickedFile.path}');
      debugPrint('📂 File name: ${pickedFile.name}');

      // Convert XFile to File
      final File imageFile = File(pickedFile.path);

      // Validate file existence
      if (!await imageFile.exists()) {
        debugPrint('❌ File does not exist at path: ${pickedFile.path}');
        throw Exception('Selected image file does not exist');
      }

      // Get file info
      final int fileSize = await imageFile.length();
      debugPrint('📊 File size: ${_formatBytes(fileSize)}');

      // Validate file size (max 10MB for uploads)
      const int maxFileSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxFileSize) {
        debugPrint('❌ File too large: ${_formatBytes(fileSize)} > ${_formatBytes(maxFileSize)}');
        throw Exception('Image file is too large (max 10MB)');
      }

      // Validate file extension
      final String extension = pickedFile.path.split('.').last.toLowerCase();
      const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
      
      if (!allowedExtensions.contains(extension)) {
        debugPrint('❌ Invalid file type: $extension');
        throw Exception('Invalid image file type. Allowed: ${allowedExtensions.join(', ')}');
      }

      debugPrint('✅ Image validation successful');
      debugPrint('📁 Final path: ${imageFile.path}');
      
      return imageFile;

    } catch (e) {
      debugPrint('❌ Image picker error: $e');
      rethrow;
    }
  }

  /// Format bytes to human readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Show image source selection dialog
  static Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!kIsWeb) // Camera not available on web
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  subtitle: const Text('Take a new photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Check if image picker is available on this platform
  static bool get isImagePickerAvailable {
    if (kIsWeb) return true; // Web supports gallery
    if (Platform.isAndroid || Platform.isIOS) return true;
    return false; // Desktop platforms might not support
  }

  /// Get platform-appropriate image source options
  static List<ImageSource> get availableSources {
    if (kIsWeb) return [ImageSource.gallery]; // Web only supports gallery
    return [ImageSource.camera, ImageSource.gallery];
  }
}
