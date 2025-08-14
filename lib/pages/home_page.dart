import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';
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
    // Removed auto sample post creation to avoid permission errors
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
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'seed':
                  try {
                    await _firestoreService.createSamplePosts();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sample posts created')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create samples: $e')),
                    );
                  }
                  break;
                case 'users':
                  Navigator.pushNamed(context, '/users');
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'logout':
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'seed',
                child: Row(
                  children: [Icon(Icons.auto_awesome, size: 18), SizedBox(width: 8), Text('Create sample posts')],
                ),
              ),
              PopupMenuItem(
                value: 'users',
                child: Row(
                  children: [Icon(Icons.group, size: 18), SizedBox(width: 8), Text('Browse users')],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [Icon(Icons.settings, size: 18), SizedBox(width: 8), Text('Settings')],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [Icon(Icons.logout, size: 18), SizedBox(width: 8), Text('Log out')],
                ),
              ),
            ],
          ),
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
        floatingActionButton: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.extended(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    icon: const Icon(Icons.add),
                    label: const Text('Post'),
                    onPressed: _navigateToCreatePost,
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.bug_report),
                    tooltip: 'Test Crash (Debug only)',
                    onPressed: () {
                      // Trigger a test crash
                      FirebaseCrashlytics.instance.crash();
                    },
                  ),
                ],
              ),
            ),
          ],
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
      elevation: 10,
      shadowColor: theme.shadowColor.withOpacity(0.15),
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
                  onSelected: (value) async {
                    switch (value) {
                      case 'delete':
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid == null || uid != post.userId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('You can delete only your posts')),
                          );
                          return;
                        }
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete post?'),
                            content: const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await FirestoreService().deletePost(post.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Post deleted')),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e')),
                            );
                          }
                        }
                        break;
                      case 'share':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share functionality coming soon!')),
                        );
                        break;
                      case 'report':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post reported')),
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
                    if (FirebaseAuth.instance.currentUser?.uid == post.userId)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Post content
            _PostContentText(content: post.content),

            const SizedBox(height: 8),

            // Hashtags row (parsed from content)
            _HashtagsRow(content: post.content),
            
            const SizedBox(height: 10),
            Divider(height: 1, color: theme.dividerColor.withOpacity(0.2)),
            const SizedBox(height: 10),
            
            // Actions row
            Row(
              children: [
                Tooltip(
                  message: isLiked ? 'Unlike' : 'Like',
                  child: InkResponse(
                    radius: 24,
                    onTap: onLike,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_outline,
                        key: ValueKey<bool>(isLiked),
                        color: isLiked ? Colors.red : theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Text(
                  '${post.likeCount}',
                  style: TextStyle(
                    color: isLiked ? Colors.red : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Tooltip(
                  message: 'Comments',
                  child: InkResponse(
                    radius: 24,
                    onTap: () {
                      // TODO: Navigate to comments
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comments feature coming soon!')),
                      );
                    },
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: theme.colorScheme.secondary,
                      size: 22,
                    ),
                  ),
                ),
                Text(
                  '${post.commentsCount}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Bookmark',
                  child: InkResponse(
                    radius: 24,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bookmark feature coming soon!')),
                      );
                    },
                    child: Icon(
                      Icons.bookmark_outline,
                      color: theme.hintColor,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HashtagsRow extends StatelessWidget {
  final String content;
  const _HashtagsRow({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = _extractHashtags(content);
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: -6,
      children: tags
          .map((t) => Chip(
                label: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ))
          .toList(),
    );
  }

  List<String> _extractHashtags(String text) {
    final regex = RegExp(r'#[A-Za-z0-9_]+');
    final set = <String>{};
    for (final m in regex.allMatches(text)) {
      set.add(m.group(0)!);
    }
    return set.toList(growable: false);
  }
}

class _PostContentText extends StatelessWidget {
  final String content;
  const _PostContentText({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spans = _buildSpans(content, theme);
    return RichText(
      text: TextSpan(
        children: spans,
        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16, color: theme.colorScheme.onSurface),
      ),
    );
  }

  List<InlineSpan> _buildSpans(String text, ThemeData theme) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(r'(https?://\S+|#[A-Za-z0-9_]+|@[A-Za-z0-9_]+)');
    final matches = regex.allMatches(text);
    int start = 0;
    for (final m in matches) {
      if (m.start > start) {
        spans.add(TextSpan(text: text.substring(start, m.start)));
      }
      final token = text.substring(m.start, m.end);
      if (token.startsWith('http')) {
        spans.add(TextSpan(
          text: token,
          style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
        ));
      } else if (token.startsWith('#')) {
        spans.add(TextSpan(
          text: token,
          style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w700),
        ));
      } else if (token.startsWith('@')) {
        spans.add(TextSpan(
          text: token,
          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
        ));
      } else {
        spans.add(TextSpan(text: token));
      }
      start = m.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }
}
