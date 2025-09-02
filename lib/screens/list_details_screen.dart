import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/modern_app_bar.dart';

class ListDetailsScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const ListDetailsScreen({
    super.key, 
    required this.listId, 
    required this.listName,
  });

  @override
  State<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends State<ListDetailsScreen> {
  late Future<List<Map<String, dynamic>>> _itemsFuture;
  List<Map<String, dynamic>> _items = [];

  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _itemsFuture = _fetchItems();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchItems() async {
    try {
      final data = await Supabase.instance.client
          .from('list_items')
          .select()
          .eq('list_id', widget.listId)
          .order('created_at', ascending: true);
      
      _items = List<Map<String, dynamic>>.from(data);
      return _items;

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching items: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
      return [];
    }
  }

  Future<void> _addItem() async {
    final result = await _showAddItemDialog();
    if (result == null) return;

    final itemName = result['name'];
    final quantity = result['quantity'];

    if (itemName != null && itemName.isNotEmpty) {
      try {
        final newItem = await Supabase.instance.client
          .from('list_items')
          .insert({
            'name': itemName,
            'quantity': quantity,
            'list_id': widget.listId,
            'is_completed': false,
          })
          .select()
          .single();
        
        setState(() {
          _items.add(newItem);
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add item: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Future<void> _toggleItemCompletion(int itemId, bool currentState) async {
    try {
      await Supabase.instance.client
        .from('list_items')
        .update({'is_completed': !currentState})
        .eq('id', itemId);
      
      setState(() {
        final index = _items.indexWhere((item) => item['id'] == itemId);
        if (index != -1) {
          _items[index]['is_completed'] = !currentState;
        }
      });
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update item: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  Future<void> _deleteItem(int itemId) async {
    try {
      await Supabase.instance.client
        .from('list_items')
        .delete()
        .eq('id', itemId);
      
      setState(() {
        _items.removeWhere((item) => item['id'] == itemId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete item: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }


  Future<Map<String, String>?> _showAddItemDialog() {
    _itemController.clear();
    _quantityController.clear();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity (e.g., 1kg, 2 units)'),
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
              if (_itemController.text.isNotEmpty) {
                Navigator.of(context).pop({
                  'name': _itemController.text,
                  'quantity': _quantityController.text,
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: widget.listName,
        showBackButton: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No items yet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Add your first item to get started', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          final completedItems = _items.where((item) => item['is_completed']).length;
          final totalItems = _items.length;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progress', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('$completedItems / $totalItems items', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: totalItems > 0 ? completedItems / totalItems : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF388E3C)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Checkbox(
                          value: item['is_completed'],
                          activeColor: const Color(0xFF388E3C),
                          onChanged: (value) => _toggleItemCompletion(item['id'], item['is_completed']),
                        ),
                        title: Text(
                          item['name'],
                          style: TextStyle(
                            decoration: item['is_completed'] ? TextDecoration.lineThrough : null,
                            color: item['is_completed'] ? Colors.grey[600] : null,
                          ),
                        ),
                        subtitle: Text(
                          item['quantity'],
                          style: TextStyle(color: item['is_completed'] ? Colors.grey[600] : Colors.grey[700]),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteItem(item['id']),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
