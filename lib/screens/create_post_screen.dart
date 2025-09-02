import 'package:flutter/material.dart';
import 'package:grocermate/widgets/modern_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitPost() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      // Maybe show a snackbar
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('posts').insert({
        'user_id': userId,
        'content': content,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true); // Return true to signal success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create post: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Create a New Post',
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _submitPost,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send, color: Colors.white),
            tooltip: 'Post',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _textController,
          autofocus: true,
          maxLines: 15,
          minLines: 1,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText: "What's on your mind?",
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
} 