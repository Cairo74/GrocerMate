import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grocermate/screens/notifications_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/modern_app_bar.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToLists;
  final VoidCallback onNavigateToFriends;
  final VoidCallback onNavigateToCommunity;

  const HomeScreen({
    Key? key,
    required this.onNavigateToLists,
    required this.onNavigateToFriends,
    required this.onNavigateToCommunity,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes to force a rebuild when user data is updated.
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.userUpdated) {
        // A simple setState is enough to trigger a rebuild and fetch fresh user metadata.
        if (mounted) {
          setState(() {});
        }
      }
    });
    _fetchUnreadNotifications();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadNotifications() async {
    if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final count = await Supabase.instance.client
          .from('notifications')
          .count(CountOption.exact)
          .eq('user_id', userId)
          .eq('is_read', false);

      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] ?? 'friend';
    final avatarUrl = user?.userMetadata?['avatar_url'];

    return Scaffold(
      appBar: const ModernAppBar(
        title: 'GrocerMate',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(username,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                            );
                            // Refresh count after returning from notifications screen
                            _fetchUnreadNotifications();
                          },
                        ),
                        if (_unreadNotifications > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                '$_unreadNotifications',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Actions Section
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              _buildQuickActionCard(
                context,
                icon: Icons.list_alt,
                title: 'Your Lists',
                subtitle: 'View and manage your shopping lists',
                onTap: widget.onNavigateToLists,
              ),
              _buildQuickActionCard(
                context,
                icon: Icons.groups,
                title: 'Community',
                subtitle: 'Posts & Templates',
                onTap: widget.onNavigateToCommunity,
              ),
              _buildQuickActionCard(
                context,
                icon: Icons.people,
                title: 'Friends',
                subtitle: 'Connect & Share',
                onTap: widget.onNavigateToFriends,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.3), // Opacity increased 3x
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
