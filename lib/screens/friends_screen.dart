import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocermate/screens/mini_profile_screen.dart';
import 'package:grocermate/widgets/modern_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  String _myFriendCode = 'Loading...';
  bool _isLoading = false;
  List<dynamic> _pendingRequests = [];
  List<dynamic> _friends = [];

  @override
  void initState() {
    super.initState();
    _fetchAllFriendData();
  }

  Future<void> _fetchAllFriendData() async {
    await _fetchMyFriendCode();
    await _fetchFriendships();
  }


  Future<void> _fetchMyFriendCode() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select('friend_code')
          .eq('id', userId)
          .single();
      
      if (data['friend_code'] == null) {
        // Simple friend code generator
        final username = Supabase.instance.client.auth.currentUser!.userMetadata!['username'] ?? 'user';
        final newFriendCode = '$username#${DateTime.now().millisecondsSinceEpoch % 10000}';
        await Supabase.instance.client
            .from('profiles')
            .update({'friend_code': newFriendCode}).eq('id', userId);
        if(mounted) {
          setState(() {
            _myFriendCode = newFriendCode;
          });
        }
      } else {
        if(mounted) {
          setState(() {
            _myFriendCode = data['friend_code'];
          });
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching your friend code: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      setState(() => _myFriendCode = 'Error');
    } finally {
       if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchFriendships() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('friendships')
          .select('*, requester:requester_id(username, avatar_url), addressee:addressee_id(username, avatar_url)')
          .or('requester_id.eq.$userId,addressee_id.eq.$userId');

      final pending = response.where((f) => f['status'] == 'pending' && f['addressee_id'] == userId).toList();
      final accepted = response.where((f) => f['status'] == 'accepted').toList();
      
      if(mounted){
        setState(() {
          _pendingRequests = pending;
          _friends = accepted;
        });
      }

    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error fetching friendships: ${e.toString()}"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToFriendRequest(String requesterId, bool accept) async {
    final addresseeId = Supabase.instance.client.auth.currentUser!.id;
    try {
      if (accept) {
        await Supabase.instance.client
            .from('friendships')
            .update({'status': 'accepted'})
            .eq('requester_id', requesterId)
            .eq('addressee_id', addresseeId);
      } else {
        await Supabase.instance.client
            .from('friendships')
            .delete()
            .eq('requester_id', requesterId)
            .eq('addressee_id', addresseeId);
      }
      _fetchAllFriendData(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error responding to request: ${e.toString()}"),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  Future<void> _searchFriend() async {
    final friendCode = _searchController.text.trim();
    if (friendCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please enter a friend code to search."),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    if (friendCode == _myFriendCode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("You can't add yourself as a friend."),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final List<dynamic> response = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('friend_code', friendCode);

      if (response.isEmpty) {
        throw 'User not found.';
      }

      final friendId = response.first['id'];
       if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MiniProfileScreen(userId: friendId),
          ),
        );
      }

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Friends',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAllFriendData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Your Friend Code Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Your Friend Code',
                      style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SelectableText(
                            _myFriendCode,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : () {
                        Clipboard.setData(ClipboardData(text: _myFriendCode));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Friend code copied to clipboard!'),
                          backgroundColor: Colors.green,
                        ));
                            },
                            icon: const Icon(Icons.copy),
                      label: const Text('Copy Code'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

            // Add Friend Section
                  Text(
              'Add a Friend',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter Friend Code',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchFriend,
                ),
              ),
              onFieldSubmitted: (_) => _searchFriend(),
            ),
            const SizedBox(height: 24),

            // Pending Requests Section
            if (_pendingRequests.isNotEmpty) ...[
                      Text(
                'Pending Requests',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pendingRequests.length,
                itemBuilder: (context, index) {
                  final request = _pendingRequests[index];
                  final requester = request['requester'];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: requester['avatar_url'] != null
                            ? NetworkImage(requester['avatar_url'])
                            : null,
                        child: requester['avatar_url'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(requester['username'] ?? 'Unknown User'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                          children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _respondToFriendRequest(request['requester_id'], true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _respondToFriendRequest(request['requester_id'], false),
                              ),
                          ],
                        ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Friends List Section
            Text(
              'Your Friends (${_friends.length})',
              style: Theme.of(context).textTheme.headlineSmall,
               textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _isLoading && _friends.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _friends.isEmpty
                    ? const Center(
                        child: Column(
                                children: [
                          Icon(Icons.people_outline, size: 60, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Your friends list is empty.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Add friends using their code!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friendship = _friends[index];
                          final currentUserId = Supabase.instance.client.auth.currentUser!.id;
                          // Determine who the friend is in the relationship
                          final friendProfile = friendship['requester_id'] == currentUserId
                              ? friendship['addressee']
                              : friendship['requester'];

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: friendProfile['avatar_url'] != null
                                    ? NetworkImage(friendProfile['avatar_url'])
                                    : null,
                                child: friendProfile['avatar_url'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(friendProfile['username'] ?? 'Friend'),
                              onTap: () async {
                                // Navigate to their profile
                                final friendId = friendship['requester_id'] == currentUserId
                                    ? friendship['addressee_id']
                                    : friendship['requester_id'];
                                final result = await Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => MiniProfileScreen(userId: friendId),
                                ));

                                // If the profile screen signaled a change (e.g., friend removed), refresh data
                                if (result == true) {
                                  _fetchAllFriendData();
                            }
                          },
                        ),
                          );
                        },
              ),
            ],
        ),
      ),
    );
  }
}
