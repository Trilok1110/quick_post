import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'services/firestore_service.dart';
import 'models/post_model.dart';
import 'create_post_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _hasCreatedSamples = false;

  @override
  void initState() {
    super.initState();
    _createSamplePostsIfNeeded();
  }

  Future<void> _createSamplePostsIfNeeded() async {
    if (!_hasCreatedSamples) {
      try {
        await _firestoreService.createSamplePosts();
        setState(() => _hasCreatedSamples = true);
      } catch (e) {
        print('Sample posts already exist or error: $e');
      }
    }
  }

  Future<void> _navigateToCreatePost() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );
    // No need to refresh - StreamBuilder handles real-time updates!
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: ShaderMask(
          shaderCallback: (Rect bounds) => const LinearGradient(
            colors: [Color(0xFF38A3A5), Color(0xFFF8C6FB)],
          ).createShader(bounds),
          child: const Text(
            'QuickPost',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: 1,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Log Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: StreamBuilder<List<Post>>(
        stream: _firestoreService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.post_add,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to share something!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToCreatePost,
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Post'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // No need to manually refresh - StreamBuilder handles it!
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _PostCard(
                  post: post,
                  onLike: () => _firestoreService.toggleLike(post.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Post'),
        onPressed: _navigateToCreatePost,
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  
  const _PostCard({
    required this.post,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked = currentUser != null && post.isLikedBy(currentUser.uid);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: post.userPhotoUrl != null
                      ? CachedNetworkImageProvider(post.userPhotoUrl!)
                      : null,
                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.15),
                  child: post.userPhotoUrl == null
                      ? Icon(
                          Icons.person,
                          color: theme.colorScheme.primary,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            post.userEmail,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            ' • ${post.timeAgo}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: theme.hintColor),
                  onSelected: (value) {
                    switch (value) {
                      case 'report':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post reported')),
                        );
                        break;
                      case 'share':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share functionality coming soon!')),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 20),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.report, size: 20),
                          SizedBox(width: 8),
                          Text('Report'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Post content
            Text(
              post.content,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
            ),
            
            // Post image (if exists)
            if (post.imageUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceVariant,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceVariant,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Actions row
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_outline,
                    color: isLiked ? Colors.red : theme.colorScheme.primary,
                  ),
                  onPressed: onLike,
                ),
                Text(
                  '${post.likeCount}',
                  style: TextStyle(
                    color: isLiked ? Colors.red : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: theme.colorScheme.secondary,
                  ),
                  onPressed: () {
                    // TODO: Navigate to comments
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comments feature coming soon!')),
                    );
                  },
                ),
                Text(
                  '${post.commentsCount}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.bookmark_outline,
                    color: theme.hintColor,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bookmark feature coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

