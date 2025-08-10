import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'components/qp_button.dart';
import 'services/firestore_service.dart';
import 'utils/image_utils.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _firestoreService = FirestoreService();
  
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      // Check if image picker is available
      if (!ImageUtils.isImagePickerAvailable) {
        _showSnackbar('Image picker not available on this platform');
        return;
      }

      // Show source selection dialog
      final ImageSource? source = await ImageUtils.showImageSourceDialog(context);
      if (source == null) return;
      
      // Pick image with validation
      final File? imageFile = await ImageUtils.pickImageWithValidation(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (imageFile != null) {
        setState(() {
          _selectedImage = imageFile;
        });
        _showSnackbar('Image selected successfully! 📸', isError: false);
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackbar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    const int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Verify file exists and is readable
        if (!await imageFile.exists()) {
          throw Exception('Image file does not exist at path: ${imageFile.path}');
        }

        // Read and validate file
        final fileBytes = await imageFile.readAsBytes();
        if (fileBytes.isEmpty) {
          throw Exception('Image file is empty or corrupted');
        }
        
        print('📤 Starting upload attempt ${retryCount + 1}/$maxRetries');
        print('📊 File size: ${fileBytes.length} bytes');
        print('🖼️ File path: ${imageFile.path}');

        // Create unique filename with proper extension
        final extension = imageFile.path.split('.').last.toLowerCase();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'posts/${user.uid}/${timestamp}_${retryCount}.$extension';
        
        print('🎯 Upload destination: $fileName');
        
        final storageRef = FirebaseStorage.instance.ref().child(fileName);
        
        // Set metadata for better file handling
        final metadata = SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalName': imageFile.path.split('/').last,
            'fileSize': fileBytes.length.toString(),
          },
        );
        
        // Use putData instead of putFile for better reliability
        final uploadTask = storageRef.putData(fileBytes, metadata);
        
        // Track upload progress with better error handling
        StreamSubscription? progressSubscription;
        bool uploadCompleted = false;
        
        progressSubscription = uploadTask.snapshotEvents.listen(
          (TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            print('⬆️ Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
            
            switch (snapshot.state) {
              case TaskState.running:
                // Upload in progress
                break;
              case TaskState.paused:
                print('⏸️ Upload paused');
                break;
              case TaskState.success:
                print('✅ Upload completed successfully');
                uploadCompleted = true;
                break;
              case TaskState.canceled:
                print('❌ Upload was canceled');
                break;
              case TaskState.error:
                print('❌ Upload error in stream');
                break;
            }
          },
          onError: (error) {
            print('❌ Upload stream error: $error');
          },
        );

        // Wait for upload to complete with timeout
        final snapshot = await uploadTask.timeout(
          const Duration(minutes: 5),
          onTimeout: () {
            progressSubscription?.cancel();
            uploadTask.cancel();
            throw Exception('Upload timed out after 5 minutes');
          },
        );
        
        // Clean up subscription
        await progressSubscription?.cancel();
        
        // Verify upload state
        print('🔍 Final upload state: ${snapshot.state}');
        print('📊 Bytes transferred: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
        
        if (snapshot.state != TaskState.success) {
          throw Exception('Upload failed with state: ${snapshot.state}');
        }
        
        if (snapshot.bytesTransferred != snapshot.totalBytes) {
          throw Exception('Upload incomplete: ${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes');
        }
        
        // Wait a moment for Firebase to process the file
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Get download URL with retry
        String downloadUrl;
        try {
          downloadUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          print('⚠️ First download URL attempt failed: $e');
          // Wait and retry
          await Future.delayed(const Duration(seconds: 1));
          downloadUrl = await snapshot.ref.getDownloadURL();
        }
        
        // Verify the URL is valid
        if (downloadUrl.isEmpty || !downloadUrl.startsWith('https://')) {
          throw Exception('Invalid download URL: $downloadUrl');
        }
        
        print('🎉 Image uploaded successfully!');
        print('🔗 Download URL: $downloadUrl');
        
        return downloadUrl;
        
      } on FirebaseException catch (e) {
        print('🔥 Firebase error (attempt ${retryCount + 1}): ${e.code} - ${e.message}');
        
        // Check if this is a retryable error
        final retryableCodes = ['storage/retry-limit-exceeded', 'storage/network-error', 'storage/unknown'];
        
        if (retryableCodes.contains(e.code) && retryCount < maxRetries - 1) {
          retryCount++;
          print('🔄 Retrying upload in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue; // Retry the upload
        } else {
          throw Exception('Firebase Storage error: ${e.message} (${e.code})');
        }
      } catch (e) {
        print('💥 Upload error (attempt ${retryCount + 1}): $e');
        
        if (retryCount < maxRetries - 1) {
          retryCount++;
          print('🔄 Retrying upload in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue; // Retry the upload
        } else {
          throw Exception('Failed to upload image after $maxRetries attempts: $e');
        }
      }
    }
    
    throw Exception('Upload failed after $maxRetries attempts');
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      
      // Upload image if selected
      if (_selectedImage != null) {
        print('Uploading image before creating post...');
        
        // Verify file still exists
        if (!await _selectedImage!.exists()) {
          throw Exception('Selected image file no longer exists');
        }
        
        imageUrl = await _uploadImage(_selectedImage!);
        print('Image upload completed: $imageUrl');
      }

      // Create post
      print('Creating post with content: ${_contentController.text.trim()}');
      final postId = await _firestoreService.createPost(
        content: _contentController.text.trim(),
        imageUrl: imageUrl,
      );
      print('Post created successfully with ID: $postId');

      if (mounted) {
        _showSnackbar('Post created successfully! 🚀', isError: false);
        
        // Clear form
        _contentController.clear();
        setState(() {
          _selectedImage = null;
        });

        // Navigate back to home
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      print('Error creating post: $e');
      if (mounted) {
        _showSnackbar('Failed to create post: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Create Post',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF001524), const Color(0xFF15616D)]
                : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User info header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                              ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                              : null,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          child: FirebaseAuth.instance.currentUser?.photoURL == null
                              ? Icon(
                                  Icons.person,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FirebaseAuth.instance.currentUser?.displayName ?? 'QuickPost User',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Share your thoughts',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Content input
                    TextFormField(
                      controller: _contentController,
                      maxLines: 6,
                      maxLength: 500,
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        contentPadding: const EdgeInsets.all(20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter some content';
                        }
                        if (value.trim().length < 5) {
                          return 'Content must be at least 5 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Image preview
                    if (_selectedImage != null) ...[
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Actions row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.image_outlined, size: 20),
                            label: Text('Add Photo'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Future: Add hashtag suggestions
                              final currentText = _contentController.text;
                              _contentController.text = '$currentText #flutter #quickpost';
                              _contentController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _contentController.text.length),
                              );
                            },
                            icon: Icon(Icons.tag, size: 20),
                            label: Text('Add Tags'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Create post button
                    QPButton(
                      label: 'Share Post',
                      loading: _isLoading,
                      onPressed: _createPost,
                      icon: Icons.send_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
