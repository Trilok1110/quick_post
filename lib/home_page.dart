import 'package:flutter/material.dart';
import 'components/qp_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...List.generate(3, (index) => _PostCard(index: index + 1)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Post'),
        onPressed: () {
          // TODO: Navigate to new post creation.
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Show create post screen!')));
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final int index;
  const _PostCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: AssetImage(
                    'assets/user_demo_${(index % 3) + 1}.png',
                  ),
                  // TODO: Dynamic images from backend
                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.15),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User$index',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text('@genzusername$index',
                        style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.more_vert, color: theme.hintColor)
              ],
            ),
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                'https://source.unsplash.com/random/800x400?sig=$index',
                fit: BoxFit.cover,
                height: 182,
                width: double.infinity,
                loadingBuilder: (c, child, progress) => progress == null
                    ? child
                    : Center(child: CircularProgressIndicator()),
                errorBuilder: (c, err, s) => Container(
                  height: 180,
                  color: theme.colorScheme.surfaceVariant,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 11),
            Text(
              'Here\'s a trendy post caption for Gen Z! #vibes #flutter',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.favorite_outline, color: theme.colorScheme.primary),
                  onPressed: () {},
                ),
                const Text('124'),
                const SizedBox(width: 14),
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline_rounded, color: theme.colorScheme.secondary),
                  onPressed: () {},
                ),
                const Text('12'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

