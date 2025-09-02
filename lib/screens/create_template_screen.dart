import 'package:flutter/material.dart';
import 'package:grocermate/widgets/modern_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// A helper class to manage controllers for each list item
class ListItemController {
  final TextEditingController nameController;
  final TextEditingController quantityController;

  ListItemController()
      : nameController = TextEditingController(),
        quantityController = TextEditingController();

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
  }
}

class CreateTemplateScreen extends StatefulWidget {
  const CreateTemplateScreen({Key? key}) : super(key: key);

  @override
  _CreateTemplateScreenState createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<ListItemController> _itemControllers = [ListItemController()];
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _itemControllers.add(ListItemController());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _itemControllers[index].dispose();
      _itemControllers.removeAt(index);
    });
  }

  Future<void> _publishTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // 1. Insert the main template to get its ID
      final templateResponse = await Supabase.instance.client
          .from('list_templates')
          .insert({
            'user_id': userId,
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
          })
          .select()
          .single();
      
      final templateId = templateResponse['id'];

      // 2. Prepare and insert all the items for that template
      final itemsToInsert = _itemControllers
          .where((c) => c.nameController.text.trim().isNotEmpty)
          .map((c) => {
                'template_id': templateId,
                'name': c.nameController.text.trim(),
                'quantity': c.quantityController.text.trim(),
              })
          .toList();

      if (itemsToInsert.isNotEmpty) {
        await Supabase.instance.client.from('list_template_items').insert(itemsToInsert);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Template published successfully!'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to publish template: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Create Template',
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _publishTemplate,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.publish, color: Colors.white),
            tooltip: 'Publish',
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Template Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 24),
              Text('Items', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _itemControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _itemControllers[index].nameController,
                            decoration: const InputDecoration(hintText: 'Item Name'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _itemControllers[index].quantityController,
                            decoration: const InputDecoration(hintText: 'Qty'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 