import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/modern_app_bar.dart';
import 'list_details_screen.dart';

class YourListsScreen extends StatefulWidget {
  const YourListsScreen({super.key});

  @override
  State<YourListsScreen> createState() => _YourListsScreenState();
}

class _YourListsScreenState extends State<YourListsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _lists = [];

  @override
  void initState() {
    super.initState();
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    setState(() { _isLoading = true; });
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('lists')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);
      
      setState(() {
        _lists = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching lists: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Future<void> _createNewList() async {
    final listNameController = TextEditingController();
    bool isPublic = false; // Default to private
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder to manage state inside the dialog
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New List'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: listNameController,
                      decoration: const InputDecoration(
                        labelText: 'List Name',
                        hintText: 'e.g., Weekly Groceries',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a list name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Make this list public?'),
                        Switch(
                          value: isPublic,
                          onChanged: (value) {
                            setState(() {
                              isPublic = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop({
                        'name': listNameController.text.trim(),
                        'is_public': isPublic,
                      });
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result['name'] != null) {
      final listName = result['name']!;
      final isPublicValue = result['is_public']!;
      final userId = Supabase.instance.client.auth.currentUser!.id;

      try {
        final newList = await Supabase.instance.client
            .from('lists')
            .insert({
              'name': listName,
              'owner_id': userId,
              'is_public': isPublicValue,
            })
            .select()
            .single();

        setState(() {
          _lists.add(newList);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to create list: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        }
      }
    }
  }

  Future<String?> _showCreateListDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New List'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'List Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _navigateToListDetails(String listId, String listName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ListDetailsScreen(
          listId: listId,
          listName: listName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Your Lists',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shopping Lists',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF81C784), Color(0xFF388E3C)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _createNewList,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('New List', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _lists.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                                Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                                Text('No lists yet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text(
                                  'Create your first shopping list by tapping the "New List" button.',
                        style: TextStyle(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                        : RefreshIndicator(
                            onRefresh: _fetchLists,
                            child: ListView.builder(
                  itemCount: _lists.length,
                  itemBuilder: (context, index) {
                    final list = _lists[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                                    title: Text(list['name']),
                                    trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ListDetailsScreen(
                                            listId: list['id'],
                                listName: list['name'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
