import 'dart:io';
import 'package:flutter/material.dart';
import 'package:grocermate/screens/edit_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/modern_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const ProfileScreen({
    super.key,
    required this.onThemeToggle,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  Map<String, dynamic>? _profileData;
  String? _avatarUrl;
  late bool _isDarkMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize dark mode state here to ensure it updates when the theme changes
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userId = Supabase.instance.client.auth.currentSession!.user.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      setState(() {
        _profileData = data;
        _avatarUrl = data['avatar_url'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadAvatar() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    try {
      final picker = ImagePicker();
      final imageFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
      );

      if (imageFile == null) {
        setState(() => _isUploading = false);
        return;
      }

      final file = File(imageFile.path);
      final fileName = '${Supabase.instance.client.auth.currentUser!.id}.${imageFile.path.split('.').last}';
      
      // Upload to storage
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));

      // Get public URL
      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Update profile table
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', Supabase.instance.client.auth.currentUser!.id);

      // Update user metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': imageUrl})
      );

      setState(() {
        _avatarUrl = imageUrl;
      });

    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload avatar: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if(mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Profile',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF81C784).withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Profile header
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                    backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                                    child: _isLoading || _isUploading
                                        ? const CircularProgressIndicator()
                                        : (_avatarUrl == null
                                            ? const Icon(Icons.person, size: 60)
                                            : null),
                                  ),
                                  if (!_isLoading && !_isUploading)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 20, // Reduced radius
                                        backgroundColor: Theme.of(context).colorScheme.secondary,
                                        child: IconButton(
                                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20), // Reduced icon size
                                          onPressed: _uploadAvatar,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${_profileData?['first_name'] ?? ''} ${_profileData?['last_name'] ?? ''}'.trim(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Supabase.instance.client.auth.currentUser
                                        ?.email ??
                                    '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF81C784),
                                      Color(0xFF388E3C)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const EditProfileScreen(),
                                      ),
                                    );
                                    // Refetch profile data if returning from edit screen
                                    if (result == true || mounted) {
                                      _fetchProfile();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white),
                                  label: const Text('Edit Profile',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Settings section
                      Text(
                        'Settings',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Theme toggle
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF81C784).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _isDarkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                              color: const Color(0xFF388E3C),
                            ),
                          ),
                          title: const Text('Dark Mode'),
                          subtitle: Text(
                              _isDarkMode ? 'Enabled' : 'Disabled'),
                          trailing: Switch(
                            value: _isDarkMode,
                            onChanged: (value) => widget.onThemeToggle(),
                            activeColor: const Color(0xFF388E3C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Notifications
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF81C784).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                          title: const Text('Notifications'),
                          subtitle:
                              const Text('Manage notification preferences'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Notifications settings coming soon!')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Privacy
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF81C784).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.privacy_tip,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                          title: const Text('Privacy Settings'),
                          subtitle:
                              const Text('Control your privacy preferences'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Privacy settings coming soon!')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // About us
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF81C784).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                          title: const Text('About Us'),
                          subtitle: const Text('Learn more about GrocerMate'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Row(
                                  children: [
                                    const Icon(Icons.shopping_cart,
                                        color: Color(0xFF388E3C)),
                                    const SizedBox(width: 8),
                                    const Text('About GrocerMate'),
                                  ],
                                ),
                                content: const SingleChildScrollView(
                                  child: Text(
                                    'GrocerMate - Your Smart Shopping Companion\n\n'
                                    'Version 1.0.0\n\n'
                                    'GrocerMate is designed to make your grocery shopping experience easier and more organized. Create lists, share them with family and friends, and never forget an item again!\n\n'
                                    'Features:\n'
                                    '• Create and manage multiple shopping lists\n'
                                    '• Share lists with friends and family\n'
                                    '• Track your shopping progress\n'
                                    '• Connect with other shoppers\n'
                                    '• Dark mode support\n\n'
                                    'Developed with ❤️ for better shopping experiences.\n\n'
                                    '© 2024 GrocerMate Team',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Help & Support
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF81C784).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.help,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                          title: const Text('Help & Support'),
                          subtitle:
                              const Text('Get help and contact support'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Help & Support'),
                                content: const SingleChildScrollView(
                                  child: Text(
                                    'Need help with GrocerMate?\n\n'
                                    'Frequently Asked Questions:\n\n'
                                    'Q: How do I share a list?\n'
                                    'A: Open any list and tap the share button to send it via email or link.\n\n'
                                    'Q: How do I add friends?\n'
                                    'A: Go to the Friends tab and use your friend code or add by email.\n\n'
                                    'Q: Can I use the app offline?\n'
                                    'A: Basic list functionality works offline, but sharing requires internet.\n\n'
                                    'Q: How do I change my profile picture?\n'
                                    'A: Tap the camera icon on your profile picture.\n\n'
                                    'Contact Support:\n'
                                    'Email: support@grocermate.com\n'
                                    'Website: www.grocermate.com/help\n\n'
                                    'We typically respond within 24 hours.',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Terms of use
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF81C784).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.description,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                          title: const Text('Terms of Use'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Terms of Use'),
                                content: const SingleChildScrollView(
                                  child: Text(
                                    'GrocerMate Terms of Use\n\n'
                                    'Last updated: January 2024\n\n'
                                    '1. Acceptance of Terms\n'
                                    'By using GrocerMate, you agree to these terms and conditions.\n\n'
                                    '2. Use of Service\n'
                                    'You may use GrocerMate to create, manage, and share grocery shopping lists. You are responsible for the content you create.\n\n'
                                    '3. User Accounts\n'
                                    'You are responsible for maintaining the security of your account and password.\n\n'
                                    '4. Privacy\n'
                                    'We respect your privacy and protect your personal data according to our Privacy Policy.\n\n'
                                    '5. Prohibited Uses\n'
                                    'You may not use the service for any illegal activities or to violate any laws.\n\n'
                                    '6. Content\n'
                                    'You retain ownership of content you create, but grant us license to provide the service.\n\n'
                                    '7. Termination\n'
                                    'We may terminate accounts that violate these terms.\n\n'
                                    '8. Changes to Terms\n'
                                    'We may update these terms from time to time. Continued use constitutes acceptance.\n\n'
                                    '9. Contact\n'
                                    'Questions about these terms? Contact us at legal@grocermate.com',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Privacy policy
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF81C784).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.policy,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                          title: const Text('Privacy Policy'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Privacy Policy'),
                                content: const SingleChildScrollView(
                                  child: Text(
                                    'GrocerMate Privacy Policy\n\n'
                                    'Last updated: January 2024\n\n'
                                    '1. Information We Collect\n'
                                    'We collect information you provide when creating lists, adding friends, and using our services.\n\n'
                                    '2. How We Use Information\n'
                                    '• To provide and improve our services\n'
                                    '• To enable list sharing and collaboration\n'
                                    '• To send important service notifications\n'
                                    '• To provide customer support\n\n'
                                    '3. Information Sharing\n'
                                    'We do not sell your personal information. We only share data:\n'
                                    '• When you explicitly share lists with others\n'
                                    '• To comply with legal requirements\n'
                                    '• With service providers who help us operate\n\n'
                                    '4. Data Security\n'
                                    'We implement appropriate security measures to protect your data against unauthorized access, alteration, disclosure, or destruction.\n\n'
                                    '5. Your Rights\n'
                                    'You can access, update, or delete your personal information at any time through your account settings.\n\n'
                                    '6. Cookies and Tracking\n'
                                    'We use cookies to improve your experience and analyze app usage.\n\n'
                                    '7. Children\'s Privacy\n'
                                    'Our service is not intended for children under 13.\n\n'
                                    '8. Changes to Policy\n'
                                    'We may update this policy and will notify you of significant changes.\n\n'
                                    '9. Contact Us\n'
                                    'Questions about privacy? Contact us at privacy@grocermate.com',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
