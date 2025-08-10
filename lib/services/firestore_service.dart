import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String postsCollection = 'posts';
  static const String usersCollection = 'users';
  static const String commentsCollection = 'comments';

  // ===============================
  // POSTS OPERATIONS
  // ===============================

  /// Get real-time posts stream with optimized query
  /// orderBy timestamp descending for newest first
  Stream<List<Post>> getPostsStream({int limit = 20}) {
    try {
      return _firestore
          .collection(postsCollection)
          .orderBy('timestamp', descending: true) // Newest first - requires index
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Post.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get posts stream: $e');
    }
  }

  /// Get posts for a specific user
  Stream<List<Post>> getUserPostsStream(String userId, {int limit = 10}) {
    try {
      return _firestore
          .collection(postsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Post.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get user posts: $e');
    }
  }

  /// Create a new post
  Future<String> createPost({
    required String content,
    String? imageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      print('🚀 Creating post for user: ${user.uid}');
      print('📝 Content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
      print('🖼️ Has image: ${imageUrl != null}');

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final userName = userData['name'] ?? user.displayName ?? 'QuickPost User';

      // Create post data map
      final postData = {
        'userId': user.uid,
        'userName': userName,
        'userEmail': user.email ?? '',
        'userPhotoUrl': user.photoURL,
        'content': content,
        'likes': <String>[],
        'commentsCount': 0,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
        'metadata': <String, dynamic>{},
      };

      // Only add imageUrl if it's not null or empty
      if (imageUrl != null && imageUrl.isNotEmpty) {
        postData['imageUrl'] = imageUrl;
        print('✅ Adding image URL to post');
      } else {
        print('📄 Creating text-only post');
      }

      print('💾 Saving to Firestore...');
      final docRef = await _firestore
          .collection(postsCollection)
          .add(postData);

      print('✅ Post created successfully with ID: ${docRef.id}');
      return docRef.id;
      
    } catch (e) {
      print('❌ Failed to create post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  /// Update a post (only owner can update)
  Future<void> updatePost(String postId, {
    String? content,
    String? imageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify ownership
      final postDoc = await _firestore
          .collection(postsCollection)
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data()!;
      if (postData['userId'] != user.uid) {
        throw Exception('Not authorized to update this post');
      }

      Map<String, dynamic> updates = {};
      if (content != null) updates['content'] = content;
      if (imageUrl != null) updates['imageUrl'] = imageUrl;
      updates['updatedAt'] = Timestamp.now();

      await _firestore
          .collection(postsCollection)
          .doc(postId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  /// Delete a post (only owner can delete)
  Future<void> deletePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify ownership
      final postDoc = await _firestore
          .collection(postsCollection)
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data()!;
      if (postData['userId'] != user.uid) {
        throw Exception('Not authorized to delete this post');
      }

      await _firestore
          .collection(postsCollection)
          .doc(postId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // ===============================
  // LIKES OPERATIONS
  // ===============================

  /// Toggle like on a post (optimized with transaction)
  Future<void> toggleLike(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final postRef = _firestore.collection(postsCollection).doc(postId);

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final post = Post.fromFirestore(postDoc);
        List<String> newLikes = List.from(post.likes);

        if (post.isLikedBy(user.uid)) {
          // Remove like
          newLikes.remove(user.uid);
        } else {
          // Add like
          newLikes.add(user.uid);
        }

        transaction.update(postRef, {'likes': newLikes});
      });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // ===============================
  // USER OPERATIONS
  // ===============================

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    String? photoUrl,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // ===============================
  // PAGINATION HELPERS
  // ===============================

  /// Get posts with pagination (for infinite scroll)
  Future<List<Post>> getPostsPaginated({
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(postsCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get paginated posts: $e');
    }
  }

  // ===============================
  // BATCH OPERATIONS
  // ===============================

  /// Create sample posts (for development)
  Future<void> createSamplePosts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();
      final userDoc = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final userName = userData['name'] ?? user.displayName ?? 'QuickPost User';

      final samplePosts = [
        'Just discovered this amazing Flutter framework! 🚀 #flutter #coding',
        'Building my first social media app with Firebase. The real-time updates are incredible! ✨',
        'Coffee ☕ + Code 💻 = Perfect Saturday morning',
        'Firebase Firestore is a game changer for real-time apps! 🔥',
        'Who else is excited about Flutter 3.0? The performance improvements are amazing!',
      ];

      for (int i = 0; i < samplePosts.length; i++) {
        final post = Post(
          id: '',
          userId: user.uid,
          userName: userName,
          userEmail: user.email ?? '',
          userPhotoUrl: user.photoURL,
          content: samplePosts[i],
          timestamp: DateTime.now().subtract(Duration(minutes: i * 30)),
        );

        final docRef = _firestore.collection(postsCollection).doc();
        batch.set(docRef, post.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create sample posts: $e');
    }
  }
}
