import 'package:flutter/material.dart';
import 'package:grocermate/screens/notification_settings_screen.dart';
import 'package:grocermate/widgets/modern_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final response = await Supabase.instance.client
        .from('notifications')
        .select('*, actor:actor_id(username, avatar_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    // Mark notifications as read in the background
    // In a real app, you might only do this when the screen is left, or based on visibility.
    _markNotificationsAsRead();
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<void> _markNotificationsAsRead() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    await Supabase.instance.client
      .from('notifications')
      .update({'is_read': true})
      .eq('user_id', userId)
      .eq('is_read', false);
  }

  String _buildNotificationText(Map<String, dynamic> notification) {
    final type = notification['type'];
    final actorName = notification['actor']?['username'] ?? 'Someone';

    switch (type) {
      case 'new_like':
        return '$actorName liked your post.';
      case 'new_comment':
        return '$actorName commented on your post.';
      case 'new_reply':
        return '$actorName replied to your comment.';
      case 'friend_post':
        return '$actorName created a new post.';
      default:
        return 'You have a new notification.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Notifications',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return const Center(
              child: Text('You have no notifications yet.'),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final actor = notification['actor'];
              final createdAt = DateTime.parse(notification['created_at']);

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: actor?['avatar_url'] != null
                      ? NetworkImage(actor['avatar_url'])
                      : null,
                  child: actor?['avatar_url'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(_buildNotificationText(notification)),
                subtitle: Text(timeago.format(createdAt)),
                trailing: !notification['is_read']
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () {
                  // TODO: Navigate to the post or comment
                },
              );
            },
          );
        },
      ),
    );
  }
} 