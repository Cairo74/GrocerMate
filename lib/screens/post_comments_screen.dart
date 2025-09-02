import 'package:flutter/material.dart';
import 'package:grocermate/screens/mini_profile_screen.dart';
import 'package:grocermate/widgets/modern_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// Data model to hold a comment and its replies
class CommentNode {
  final Map<String, dynamic> comment;
  final List<CommentNode> replies;
  CommentNode({required this.comment, this.replies = const []});
}

class PostCommentsScreen extends StatefulWidget {
  final String postId;
  const PostCommentsScreen({Key? key, required this.postId}) : super(key: key);
  @override
  _PostCommentsScreenState createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final _commentController = TextEditingController();
  late Future<List<CommentNode>> _commentsFuture;
  bool _isPosting = false;
  String? _replyingToCommentId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _fetchComments();
  }

  Future<List<CommentNode>> _fetchComments() async {
    final response = await Supabase.instance.client
        .from('post_comments')
        .select('*, author:profiles(id, username, avatar_url)')
        .eq('post_id', widget.postId)
        .order('created_at', ascending: true);
    
    final comments = List<Map<String, dynamic>>.from(response);
    final commentMap = {for (var c in comments) c['id']: CommentNode(comment: c, replies: [])};
    final topLevelComments = <CommentNode>[];

    for (var c in comments) {
      final parentId = c['parent_comment_id'];
      if (parentId != null && commentMap.containsKey(parentId)) {
        commentMap[parentId]!.replies.add(commentMap[c['id']]!);
      } else {
        topLevelComments.add(commentMap[c['id']]!);
      }
    }
    return topLevelComments;
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isPosting = true);
    try {
      await Supabase.instance.client.from('post_comments').insert({
        'post_id': widget.postId,
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'content': content,
        'parent_comment_id': _replyingToCommentId,
      });
      _commentController.clear();
      _cancelReply();
      setState(() { _commentsFuture = _fetchComments(); });
    } catch (e) {
      // Handle error
    } finally {
      if(mounted) setState(() => _isPosting = false);
    }
  }
  
  Future<void> _deleteComment(String commentId) async {
    final shouldDelete = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete Comment'), content: const Text('Are you sure?'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete'))]));
    if(shouldDelete != true) return;
    try {
      await Supabase.instance.client.from('post_comments').delete().match({'id': commentId});
      setState(() { _commentsFuture = _fetchComments(); });
    } catch (e) {
      // Handle error
    }
  }

  void _setReplyTo(String commentId, String username) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUsername = username;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Comments',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<CommentNode>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final commentNodes = snapshot.data!;
                return ListView.builder(
                  itemCount: commentNodes.length,
                  itemBuilder: (context, index) => _buildCommentTree(commentNodes[index]),
                );
              },
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentTree(CommentNode node, {bool isReply = false}) {
    return Column(
      children: [
        _buildCommentTile(node.comment, isReply: isReply),
        if (node.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 20.0), // Reduced indentation
            child: Column(children: node.replies.map((reply) => _buildCommentTree(reply, isReply: true)).toList()),
          ),
      ],
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> comment, {bool isReply = false}) {
    final author = comment['author'];
    final isAuthor = author != null && author['id'] == Supabase.instance.client.auth.currentUser?.id;
    final createdAt = DateTime.parse(comment['created_at']);

    return ListTile(
      dense: isReply, // Make reply tiles more compact
      leading: GestureDetector(
        onTap: () {
          if (author != null && author['id'] != null) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => MiniProfileScreen(userId: author['id'])));
          }
        },
        child: CircleAvatar(
          radius: isReply ? 16 : 20, // Smaller avatar for replies
          backgroundImage: author != null && author['avatar_url'] != null ? NetworkImage(author['avatar_url']) : null,
          child: author == null || author['avatar_url'] == null ? const Icon(Icons.person) : null,
        ),
      ),
      title: Text(
        author != null ? author['username'] ?? 'Anonymous' : 'Anonymous',
        style: isReply ? Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold) : null,
      ),
      subtitle: Text(
        comment['content'],
        style: isReply ? Theme.of(context).textTheme.bodySmall : null,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            child: Text('Reply', style: Theme.of(context).textTheme.bodySmall),
            onPressed: () => _setReplyTo(comment['id'], author['username'])
          ),
          if (isAuthor)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteComment(comment['id']),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToCommentId != null)
              Row(
                children: [
                  Text("Replying to $_replyingToUsername", style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: _cancelReply)
                ],
              ),
            Row(
              children: [
                Expanded(child: TextField(controller: _commentController, decoration: const InputDecoration(hintText: 'Add a comment...'))),
                IconButton(icon: _isPosting ? const CircularProgressIndicator() : const Icon(Icons.send), onPressed: _isPosting ? null : _postComment),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 