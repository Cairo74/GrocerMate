import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MiniProfileScreen extends StatefulWidget {
  final String userId;

  const MiniProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MiniProfileScreenState createState() => _MiniProfileScreenState();
}

class _MiniProfileScreenState extends State<MiniProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  List<dynamic> _publicLists = [];
  String? _error;
  String? _friendshipStatus;
  bool _isFriendshipFromCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
      if (widget.userId == currentUserId) {
        // Se estiver vendo o próprio perfil, não precisa checar amizade
        final profileResponse = await Supabase.instance.client
            .from('profiles')
            .select('username, avatar_url')
            .eq('id', widget.userId)
            .single();
        if(mounted) setState(() => _profileData = profileResponse);

      } else {
        // Fetch profile details and friendship status in parallel
        final responses = await Future.wait([
          Supabase.instance.client
              .from('profiles')
              .select('username, avatar_url')
              .eq('id', widget.userId)
              .single(),
          Supabase.instance.client
              .from('friendships')
              .select()
              .or('and(requester_id.eq.${widget.userId},addressee_id.eq.$currentUserId),and(requester_id.eq.$currentUserId,addressee_id.eq.${widget.userId})')
              // Use limit(1) and check for list to prevent crash on multiple rows.
              .limit(1)
        ]);

        final profileResponse = responses[0] as Map<String, dynamic>;
        final friendshipResponseList = responses[1] as List<dynamic>;
        final friendshipResponse = friendshipResponseList.isNotEmpty ? friendshipResponseList.first as Map<String, dynamic>? : null;
        
        if (mounted) {
          setState(() {
            _profileData = profileResponse;
            if (friendshipResponse != null) {
              _friendshipStatus = friendshipResponse['status'];
              _isFriendshipFromCurrentUser = friendshipResponse['requester_id'] == currentUserId;
            }
          });
        }
      }
      
      // Fetch public lists (sempre busca)
      final listsResponse = await Supabase.instance.client
          .from('lists')
          .select('id, name')
          .eq('owner_id', widget.userId)
          .eq('is_public', true);

      if (mounted) {
        setState(() {
          _publicLists = listsResponse;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile. The user may not exist.';
          _isLoading = false;
        });
        debugPrint('Error fetching mini profile: $e');
      }
    }
  }
  
  Future<void> _addFriend() async {
    setState(() => _isLoading = true);
    final requesterId = Supabase.instance.client.auth.currentUser!.id;
    final addresseeId = widget.userId;

    try {
      // Inserir a solicitação de amizade
      await Supabase.instance.client.from('friendships').insert({
        'requester_id': requesterId,
        'addressee_id': addresseeId,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the status to update the button
        _fetchProfileData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending request: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFriend() async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: const Text('Are you sure you want to remove this friend?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (shouldRemove != true) return;

    setState(() => _isLoading = true);
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client
          .from('friendships')
          .delete()
          .or('and(requester_id.eq.${widget.userId},addressee_id.eq.$currentUserId),and(requester_id.eq.$currentUserId,addressee_id.eq.${widget.userId})');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Friend removed.'),
          backgroundColor: Colors.green,
        ));
        // Pop screen and return true to signal a change to the previous screen
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to remove friend: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _viewAndCopyList(String listId, String listName) async {
    // 1. Fetch items for the selected list
    final itemsResponse = await Supabase.instance.client
        .from('list_items')
        .select('name, quantity')
        .eq('list_id', listId);

    // 2. Show dialog with items and a "Copy" button
    final shouldCopy = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(listName),
          content: SizedBox(
            width: double.maxFinite,
            child: itemsResponse.isEmpty
                ? const Text('This list has no items.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: itemsResponse.length,
                    itemBuilder: (ctx, index) {
                      final item = itemsResponse[index];
                      return ListTile(
                        title: Text(item['name']),
                        trailing: Text(item['quantity'] ?? ''),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Copy to My Lists'),
              onPressed: itemsResponse.isEmpty ? null : () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldCopy != true) return;

    // 3. If "Copy" is pressed, create a new list and its items for the current user
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
      // Create a new private list
      final newListResponse = await Supabase.instance.client
          .from('lists')
          .insert({
            'name': listName, // Removed "(Copied)" suffix
            'owner_id': currentUserId,
            'is_public': false, // Copied lists are private by default
          })
          .select()
          .single();
      
      final newListId = newListResponse['id'];

      // Prepare items for the new list
      final List<Map<String, dynamic>> newItems = itemsResponse
          .map((item) => {
                'list_id': newListId,
                'name': item['name'],
                'quantity': item['quantity'],
                'is_completed': false,
              })
          .toList();

      // Insert all items
      await Supabase.instance.client.from('list_items').insert(newItems);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('"$listName" was copied to your lists!'),
        backgroundColor: Colors.green,
      ));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to copy list: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        // Ensure back button and title have visible color against the background
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _profileData == null
                  ? const Center(child: Text('User not found.'))
                  : _buildProfileView(),
    );
  }

  Widget _buildFriendshipButton() {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    // Don't show button on your own profile
    if (widget.userId == currentUserId) {
      return const SizedBox.shrink();
    }

    if (_friendshipStatus == 'accepted') {
      return OutlinedButton.icon(
        onPressed: _removeFriend,
        icon: const Icon(Icons.person_remove),
        label: const Text('Remove Friend'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 40),
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (_friendshipStatus == 'pending') {
      if (_isFriendshipFromCurrentUser) {
        return ElevatedButton.icon(
          onPressed: null, // Disabled
          icon: const Icon(Icons.hourglass_top),
          label: const Text('Request Sent'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
          ),
        );
      } else {
        // The other user sent the request
        return ElevatedButton.icon(
          onPressed: () {
            // Navigate to friends screen to respond
             Navigator.of(context).pop(); // Go back from profile
             // This assumes the user will see the request on the FriendsScreen
          },
          icon: const Icon(Icons.reply_all),
          label: const Text('Respond to Request'),
           style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    // Default: No friendship exists
    return ElevatedButton.icon(
      onPressed: _addFriend,
      icon: const Icon(Icons.person_add),
      label: const Text('Add Friend'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 40), // Make button wide
      ),
    );
  }

  Widget _buildProfileView() {
    final avatarUrl = _profileData!['avatar_url'];
    final username = _profileData!['username'] ?? 'No username';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            username,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _buildFriendshipButton(),
          const SizedBox(height: 24),
          const Divider(),
          Text(
            'Public Lists',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _publicLists.isEmpty
              ? const Text('This user has no public lists.')
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _publicLists.length,
                  itemBuilder: (context, index) {
                    final list = _publicLists[index];
                    return Card(
                      child: ListTile(
                        title: Text(list['name']),
                        leading: const Icon(Icons.list_alt),
                        onTap: () => _viewAndCopyList(list['id'], list['name']),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
} 