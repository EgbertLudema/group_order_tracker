import "package:flutter/material.dart";

import "../models.dart";
import "../repositories.dart";
import "item_options_screen.dart";

/// Screen to manage items and prices
class ItemManagementScreen extends StatefulWidget {
    const ItemManagementScreen({super.key});

    @override
    State<ItemManagementScreen> createState() => _ItemManagementScreenState();
}

class _ItemManagementScreenState extends State<ItemManagementScreen> {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _priceController = TextEditingController();

    @override
    void dispose() {
        _nameController.dispose();
        _priceController.dispose();
        super.dispose();
    }

    void _addItem() {
        final name = _nameController.text.trim();
        final priceText = _priceController.text.trim();
        if (name.isEmpty || priceText.isEmpty) {
            return;
        }

        final price = double.tryParse(priceText);
        if (price == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Enter a valid price"),
                ),
            );
            return;
        }

        setState(() {
            ItemRepository.addItem(name, price);
        });
        _nameController.clear();
        _priceController.clear();
    }

    void _openItemOptions(ItemDefinition item) {
        Navigator.of(context)
            .push(
                MaterialPageRoute(
                    builder: (context) => ItemOptionsScreen(item: item),
                ),
            )
            .then((_) {
                setState(() {});
            });
    }

    @override
    Widget build(BuildContext context) {
        final items = ItemRepository.items;

        return Scaffold(
            appBar: AppBar(
                title: const Text("Items"),
            ),
            body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    children: [
                        Row(
                            children: [
                                Expanded(
                                    flex: 2,
                                    child: TextField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(
                                            labelText: "Item name",
                                            border: OutlineInputBorder(),
                                        ),
                                    ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    flex: 1,
                                    child: TextField(
                                        controller: _priceController,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                            decimal: true,
                                        ),
                                        decoration: const InputDecoration(
                                            labelText: "Price",
                                            border: OutlineInputBorder(),
                                        ),
                                    ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                    onPressed: _addItem,
                                    child: const Text("Add"),
                                ),
                            ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                            child: items.isEmpty
                                ? const Center(
                                    child: Text("No items yet."),
                                )
                                : ListView.builder(
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                        final item = items[index];
                                        return ListTile(
                                            title: Text(item.name),
                                            subtitle: Text(
                                                "${item.price.toStringAsFixed(2)} € • ${item.options.length} options",
                                            ),
                                            onTap: () => _openItemOptions(item),
                                            trailing: IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                ),
                                                onPressed: () {
                                                    setState(() {
                                                        ItemRepository
                                                            .removeItem(item);
                                                    });
                                                },
                                            ),
                                        );
                                    },
                                ),
                        ),
                    ],
                ),
            ),
        );
    }
}
