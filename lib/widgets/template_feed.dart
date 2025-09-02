import 'package:flutter/material.dart';
import 'package:grocermate/screens/mini_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class TemplateFeed extends StatefulWidget {
  const TemplateFeed({Key? key}) : super(key: key);

  @override
  TemplateFeedState createState() => TemplateFeedState();
}

class TemplateFeedState extends State<TemplateFeed> {
  late Future<List<Map<String, dynamic>>> _templatesFuture;
  final Map<String, bool> _likedStatus = {};
  final Map<String, int> _likeCounts = {};
  String? _expandedTemplateId;

  @override
  void initState() {
    super.initState();
    _templatesFuture = _fetchTemplates();
  }

  Future<List<Map<String, dynamic>>> _fetchTemplates() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Abandon the RPC. Use a direct, simpler query for reliability.
    final templatesResponse = await Supabase.instance.client
        .from('list_templates')
        .select('*, author:profiles!list_templates_user_id_fkey(id, username, avatar_url), likes:template_likes(user_id)');

    final templates = List<Map<String, dynamic>>.from(templatesResponse);
    
    // Sort templates by like count on the client-side, which is more reliable.
    templates.sort((a, b) => (b['likes'] as List).length.compareTo((a['likes'] as List).length));

    // In a single separate query, fetch all templates liked by the current user.
    final Set<String> likedTemplateIds;
    if (currentUserId != null) {
      final likesResponse = await Supabase.instance.client
          .from('template_likes')
          .select('template_id')
          .eq('user_id', currentUserId);
      likedTemplateIds = (likesResponse as List<dynamic>).map((like) => like['template_id'] as String).toSet();
    } else {
      likedTemplateIds = {};
    }

    _likedStatus.clear();
    _likeCounts.clear();
    
    // Process the results in memory.
    for (final template in templates) {
      final templateId = template['id'];
      _likeCounts[templateId] = (template['likes'] as List).length;
      _likedStatus[templateId] = likedTemplateIds.contains(templateId);
    }
    return templates;
  }

  Future<void> refreshFeed() async {
    setState(() {
      _expandedTemplateId = null; // Collapse all cards on refresh
      _templatesFuture = _fetchTemplates();
    });
  }

  Future<void> _toggleLike(String templateId) async {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isLiked = _likedStatus[templateId] ?? false;

    setState(() {
      _likedStatus[templateId] = !isLiked;
      _likeCounts[templateId] = (_likeCounts[templateId] ?? 0) + (isLiked ? -1 : 1);
    });

    try {
      if (isLiked) {
        await Supabase.instance.client.from('template_likes').delete().match({'template_id': templateId, 'user_id': currentUserId});
      } else {
        await Supabase.instance.client.from('template_likes').insert({'template_id': templateId, 'user_id': currentUserId});
      }
    } catch (e) {
      setState(() { // Revert on error
        _likedStatus[templateId] = isLiked;
        _likeCounts[templateId] = (_likeCounts[templateId] ?? 0) + (isLiked ? 1 : -1);
      });
    }
  }

  Future<void> _deleteTemplate(String templateId) async {
    // Confirmation dialog and deletion logic
    final shouldDelete = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete Template'), content: const Text('Are you sure?'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete'))]));
    if(shouldDelete != true) return;
    await Supabase.instance.client.from('list_templates').delete().match({'id': templateId});
    refreshFeed();
  }

  Future<void> _copyTemplate(String templateId, String templateName) async {
     final itemsResponse = await Supabase.instance.client.from('list_template_items').select('name, quantity').eq('template_id', templateId);
     final currentUserId = Supabase.instance.client.auth.currentUser!.id;
     final newListResponse = await Supabase.instance.client.from('lists').insert({'name': templateName, 'owner_id': currentUserId, 'is_public': false}).select().single();
     final newListId = newListResponse['id'];
     final itemsToInsert = (itemsResponse as List).map((item) => {'list_id': newListId, 'name': item['name'], 'quantity': item['quantity'], 'is_completed': false}).toList();
     if(itemsToInsert.isNotEmpty) await Supabase.instance.client.from('list_items').insert(itemsToInsert);
     if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$templateName" copied!'), backgroundColor: Colors.green));
  }

  void _toggleExpand(String templateId) {
    setState(() {
      _expandedTemplateId = _expandedTemplateId == templateId ? null : templateId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _templatesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        final templates = snapshot.data!;
        if (templates.isEmpty) return const Center(child: Text('No templates yet.'));

        return RefreshIndicator(
          onRefresh: refreshFeed,
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final author = template['author'] as Map<String, dynamic>?;
              final templateId = template['id'];
              final isLiked = _likedStatus[templateId] ?? false;
              final likesCount = _likeCounts[templateId] ?? 0;
              final createdAt = DateTime.parse(template['created_at']);
              final isAuthor = template['user_id'] == Supabase.instance.client.auth.currentUser?.id;
              final isExpanded = _expandedTemplateId == templateId;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template['name'], style: Theme.of(context).textTheme.titleLarge),
                      if (template['description'] != null && template['description'].isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4.0, bottom: 8.0), child: Text(template['description'])),
                      if (author != null)
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => MiniProfileScreen(userId: author['id']))),
                          child: Row(
                            children: [
                              CircleAvatar(radius: 12, backgroundImage: author['avatar_url'] != null ? NetworkImage(author['avatar_url']) : null, child: author['avatar_url'] == null ? const Icon(Icons.person, size: 12) : null),
                              const SizedBox(width: 8),
                              Text('by ${author['username'] ?? 'Anonymous'}', style: Theme.of(context).textTheme.bodySmall),
                              const Text(' • '),
                              Text(timeago.format(createdAt), style: Theme.of(context).textTheme.bodySmall),
                              const Spacer(),
                              if(isAuthor) IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteTemplate(templateId)),
                            ],
                          ),
                        ),
                      const Divider(height: 24),
                      if(isExpanded)
                        _buildFullItemsList(templateId)
                      else
                        TextButton(
                          onPressed: () => _toggleExpand(templateId),
                          child: const Text('Show Items...'),
                        ),
                      if(isExpanded)
                         TextButton(
                          onPressed: () => _toggleExpand(templateId),
                          child: const Text('Show Less'),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => _toggleLike(templateId),
                            icon: Icon(isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined, size: 16, color: isLiked ? Theme.of(context).colorScheme.primary : null),
                            label: Text(likesCount.toString(), style: TextStyle(color: isLiked ? Theme.of(context).colorScheme.primary : null)),
                          ),
                          ElevatedButton.icon(onPressed: () => _copyTemplate(templateId, template['name']), icon: const Icon(Icons.copy_all_outlined, size: 16), label: const Text('Copy')),
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
  
  // This widget no longer shows a preview, only the full list when expanded.
  Widget _buildFullItemsList(String templateId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client.from('list_template_items').select('name, quantity').eq('template_id', templateId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator()));
        final allItems = snapshot.data!;
        if (allItems.isEmpty) return const Text('This template has no items.');
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: allItems.map((item) => Text('• ${item['name']}')).toList());
      },
    );
  }
} 