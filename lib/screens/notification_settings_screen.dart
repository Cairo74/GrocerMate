import 'package:flutter/material.dart';
import 'package:grocermate/widgets/modern_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  final Map<String, bool> _prefs = {
    'new_like': true,
    'new_comment': true,
    'new_reply': true,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select('notification_prefs')
          .eq('id', userId)
          .single();

      final loadedPrefs = data['notification_prefs'] as Map<String, dynamic>?;
      if (loadedPrefs != null) {
        setState(() {
          _prefs['new_like'] = loadedPrefs['new_like'] ?? true;
          _prefs['new_comment'] = loadedPrefs['new_comment'] ?? true;
          _prefs['new_reply'] = loadedPrefs['new_reply'] ?? true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error loading settings: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    setState(() {
      _prefs[key] = value;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client
          .from('profiles')
          .update({'notification_prefs': _prefs}).eq('id', userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error saving setting: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
      // Revert on error
      setState(() {
        _prefs[key] = !value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Notification Settings',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Likes on your posts'),
                  subtitle: const Text('Get notified when someone likes your post.'),
                  value: _prefs['new_like']!,
                  onChanged: (val) => _updatePreference('new_like', val),
                ),
                SwitchListTile(
                  title: const Text('Comments on your posts'),
                  subtitle: const Text('Get notified when someone comments on your post.'),
                  value: _prefs['new_comment']!,
                  onChanged: (val) => _updatePreference('new_comment', val),
                ),
                SwitchListTile(
                  title: const Text('Replies to your comments'),
                  subtitle: const Text('Get notified when someone replies to your comment.'),
                  value: _prefs['new_reply']!,
                  onChanged: (val) => _updatePreference('new_reply', val),
                ),
              ],
            ),
    );
  }
} 