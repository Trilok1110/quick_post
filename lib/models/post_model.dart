import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final String content;
  final String? imageUrl;
  final List<String> likes;
  final int commentsCount;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    required this.content,
    this.imageUrl,
    this.likes = const [],
    this.commentsCount = 0,
    required this.timestamp,
    this.metadata,
  });

  // Convert Post to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'imageUrl': imageUrl,
      'likes': likes,
      'commentsCount': commentsCount,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata ?? {},
    };
  }

  // Create Post from Firestore document
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      userEmail: data['userEmail'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      likes: List<String>.from(data['likes'] ?? []),
      commentsCount: data['commentsCount'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'],
    );
  }

  // Create copy with updated fields
  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhotoUrl,
    String? content,
    String? imageUrl,
    List<String>? likes,
    int? commentsCount,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  // Check if current user liked the post
  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }

  // Get like count
  int get likeCount => likes.length;

  // Time ago helper
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
