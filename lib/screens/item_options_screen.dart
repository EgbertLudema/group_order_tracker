import "package:flutter/material.dart";

import "../models.dart";
import "../repositories.dart";

/// Screen to manage options of a specific item
class ItemOptionsScreen extends StatefulWidget {
    const ItemOptionsScreen({
        super.key,
        required this.item,
    });

    final ItemDefinition item;

    @override
    State<ItemOptionsScreen> createState() => _ItemOptionsScreenState();
}

class _ItemOptionsScreenState extends State<ItemOptionsScreen> {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _priceController = TextEditingController();

    @override
    void dispose() {
        _nameController.dispose();
        _priceController.dispose();
        super.dispose();
    }

    void _addOption() {
        final name = _nameController.text.trim();
        final priceText = _priceController.text.trim();
        if (name.isEmpty || priceText.isEmpty) {
            return;
        }

        final price = double.tryParse(priceText);
        if (price == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Enter a valid price for the option"),
                ),
            );
            return;
        }

        setState(() {
            ItemRepository.addOptionToItem(widget.item, name, price);
        });
        _nameController.clear();
        _priceController.clear();
    }

    @override
    Widget build(BuildContext context) {
        final options = widget.item.options;

        return Scaffold(
            appBar: AppBar(
                title: Text("Options for ${widget.item.name}"),
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
                                            labelText: "Option name",
                                            hintText: "For example curry",
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
                                    onPressed: _addOption,
                                    child: const Text("Add"),
                                ),
                            ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                            child: options.isEmpty
                                ? const Center(
                                    child: Text("No options yet."),
                                )
                                : ListView.builder(
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                        final option = options[index];
                                        return ListTile(
                                            title: Text(option.name),
                                            subtitle: Text(
                                                "${option.price.toStringAsFixed(2)} €",
                                            ),
                                            trailing: IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                ),
                                                onPressed: () {
                                                    setState(() {
                                                        ItemRepository
                                                            .removeOptionFromItem(
                                                                widget.item,
                                                                option,
                                                            );
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
