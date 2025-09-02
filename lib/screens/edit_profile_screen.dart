import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isDeleteLoading = false;
  late final StreamSubscription<AuthState> _authSubscription;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.userUpdated) {
        // Refetch profile if user data (like email) is updated
        _fetchProfile();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _authSubscription.cancel();
    super.dispose();
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

      _profileData = data;
      _usernameController.text = data['username'] ?? '';
      _firstNameController.text = data['first_name'] ?? '';
      _lastNameController.text = data['last_name'] ?? '';
      _phoneController.text = data['phone'] ?? ''; // Assuming 'phone' column exists
      _emailController.text = Supabase.instance.client.auth.currentUser!.email!;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load profile: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Update public profile data (primeiro para garantir que os dados estejam no DB)
      final updates = {
        'id': user.id,
        'username': _usernameController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await Supabase.instance.client.from('profiles').upsert(updates);

      // 2. Atualiza os metadados do usuário na sessão de Auth
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          email: _emailController.text.trim() != user.email ? _emailController.text.trim() : null,
          data: {
            'username': _usernameController.text.trim(),
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
          }
        )
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await Supabase.instance.client.auth.signOut();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('You have been signed out.'),
          backgroundColor: Colors.green[600],
        ),
      );
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
       scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to sign out: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action is permanent and cannot be undone. All your data will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final password = await _promptForPassword(context);
    
    if (password == null) return; // User cancelled the dialog
    if (password.isEmpty) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Password cannot be empty.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() { _isDeleteLoading = true; });

    try {
      // Step 1: Verify the user's current password by trying to sign in.
      // This is a security measure in our UI, not a Supabase API requirement for deletion.
      final email = Supabase.instance.client.auth.currentUser!.email!;
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // Step 2: If sign-in is successful, proceed to delete the account via the edge function.
      await Supabase.instance.client.functions.invoke('delete-user');
      
      final navigator = Navigator.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Your account has been successfully deleted.'),
          backgroundColor: Colors.green[600],
        ),
      );
      
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      
    } on AuthException catch (e) {
        scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Deletion failed: Incorrect password or another error occurred.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
       scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() { _isDeleteLoading = false; });
      }
    }
  }

  Future<String?> _promptForPassword(BuildContext context) {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm your password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('To delete your account, please enter your password.'),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(passwordController.text);
              },
              child: const Text('Confirm & Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0.5,
        // Força a cor do ícone de voltar para ser a cor primária do texto do tema.
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: _isLoading && _profileData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(_usernameController, 'Username', Icons.person_outline, validator: (val) {
                       if (val == null || val.isEmpty) return 'Please enter a username';
                       if (val.length < 3) return 'Username must be at least 3 characters';
                       return null;
                    }),
                    const SizedBox(height: 16),
                    _buildTextField(_firstNameController, 'First Name', Icons.person_2_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(_lastNameController, 'Last Name', Icons.person_3_outlined),
                    const SizedBox(height: 16),
                     _buildTextField(_emailController, 'Email', Icons.email_outlined, validator: (val) {
                        if (val == null || !val.contains('@')) return 'Please enter a valid email';
                        return null;
                     }),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                          : const Text('Save Changes', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 48),
                    const Divider(),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out'),
                      onPressed: _signOut,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(color: Theme.of(context).colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: _isDeleteLoading 
                        ? const SizedBox.shrink() 
                        : const Icon(Icons.delete_forever_outlined),
                      label: _isDeleteLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2,))
                        : const Text('Delete Account'),
                      onPressed: _isDeleteLoading ? null : _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        // fillColor: Theme.of(context).inputDecorationTheme.fillColor, // Use default
      ),
      validator: validator,
    );
  }
} 