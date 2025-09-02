import 'package:flutter/material.dart';
import 'package:grocermate/screens/mini_profile_screen.dart';
import 'package:grocermate/screens/post_comments_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class BlogFeed extends StatefulWidget {
  const BlogFeed({Key? key}) : super(key: key);

  @override
  BlogFeedState createState() => BlogFeedState();
}

class BlogFeedState extends State<BlogFeed> {
  late Future<List<Map<String, dynamic>>> _postsFuture;
  final Map<String, bool> _likedStatus = {};
  final Map<String, int> _likeCounts = {};

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
  }

  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    final response = await Supabase.instance.client
        .from('posts')
        .select(
            '*, author:profiles!posts_user_id_fkey(id, username, avatar_url), likes:post_likes(user_id), comments:post_comments(count)')
        .order('created_at', ascending: false);

    final posts = List<Map<String, dynamic>>.from(response);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    _likedStatus.clear();
    _likeCounts.clear();

    // Initialize liked status and counts for each post
    for (final post in posts) {
      final postId = post['id'];
      final likes = post['likes'] as List<dynamic>; // This will be a list of user_id maps
      
      _likeCounts[postId] = likes.length; // The count is the length of the list

      if (currentUserId != null) {
        _likedStatus[postId] =
            likes.any((like) => like['user_id'] == currentUserId);
      } else {
        _likedStatus[postId] = false;
      }
    }

    return posts;
  }

  Future<void> _deletePost(String postId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    try {
      await Supabase.instance.client.from('posts').delete().match({'id': postId});
      refreshFeed(); // Refresh the feed after deletion
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete post: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Future<void> refreshFeed() async {
    setState(() {
      _postsFuture = _fetchPosts();
    });
  }

  Future<void> _toggleLike(String postId) async {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isLiked = _likedStatus[postId] ?? false;

    setState(() {
      _likedStatus[postId] = !isLiked;
      if (isLiked) {
        _likeCounts[postId] = (_likeCounts[postId] ?? 1) - 1;
      } else {
        _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
      }
    });

    try {
      if (isLiked) {
        await Supabase.instance.client
            .from('post_likes')
            .delete()
            .match({'post_id': postId, 'user_id': currentUserId});
      } else {
        await Supabase.instance.client
            .from('post_likes')
            .insert({'post_id': postId, 'user_id': currentUserId});
      }
    } catch(e) {
      // Revert optimistic update on failure
      setState(() {
        _likedStatus[postId] = isLiked;
         if (isLiked) {
          _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
        } else {
          _likeCounts[postId] = (_likeCounts[postId] ?? 1) - 1;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error updating like: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final posts = snapshot.data!;
        if (posts.isEmpty) {
          return const Center(
            child: Text('No posts yet. Be the first to share something!'),
          );
        }

        return RefreshIndicator(
          onRefresh: refreshFeed,
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final author = post['author'];
              final postId = post['id'];
              final isLiked = _likedStatus[postId] ?? false;
              final likesCount = _likeCounts[postId] ?? 0;
              final commentsCount = post['comments'].isNotEmpty ? post['comments'][0]['count'] : 0;
              final createdAt = DateTime.parse(post['created_at']);
              final isAuthor = post['user_id'] == Supabase.instance.client.auth.currentUser?.id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (author != null && author['id'] != null) {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => MiniProfileScreen(userId: author['id']),
                            ));
                          }
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: author['avatar_url'] != null
                                ? NetworkImage(author['avatar_url'])
                                : null,
                              child: author['avatar_url'] == null
                                ? const Icon(Icons.person)
                                : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(author['username'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(timeago.format(createdAt), style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            const Spacer(), // Pushes the menu button to the end
                            if (isAuthor)
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deletePost(postId);
                                  }
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Delete Post'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(post['content']),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildInteractionButton(
                            isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                            likesCount.toString(),
                            () => _toggleLike(postId),
                            color: isLiked ? Theme.of(context).colorScheme.primary : null,
                          ),
                          const SizedBox(width: 16),
                          _buildInteractionButton(Icons.chat_bubble_outline, commentsCount.toString(), () async {
                            final result = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (context) => PostCommentsScreen(postId: postId),
                              ),
                            );
                            if (result == true) {
                              refreshFeed();
                            }
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInteractionButton(IconData icon, String text, VoidCallback onPressed, {Color? color}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(text, style: TextStyle(color: color)),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      )
    );
  }
} 