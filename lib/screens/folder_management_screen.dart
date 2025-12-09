import "package:flutter/material.dart";
import "../models.dart";
import "../repositories.dart";

class FolderManagementScreen extends StatefulWidget {
    const FolderManagementScreen({super.key});

    @override
    State<FolderManagementScreen> createState() =>
        _FolderManagementScreenState();
}

class _FolderManagementScreenState extends State<FolderManagementScreen> {
    final TextEditingController _controller = TextEditingController();

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    void _addFolder() {
        final name = _controller.text.trim();
        if (name.isEmpty) {
            return;
        }
        setState(() {
            FolderRepository.addFolder(name);
        });
        _controller.clear();
    }

    Future<void> _confirmDeleteFolder(Folder folder) async {
        final int count = OrderRepository.orders
            .where((o) => o.folderId == folder.id)
            .length;

        final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) {
                return AlertDialog(
                    title: const Text("Delete folder"),
                    content: Text(
                        count == 0
                            ? "Are you sure you want to delete this folder?"
                            : "This folder contains $count order(s).\nDeleting it will also delete all orders in this folder.\n\nAre you sure?",
                    ),
                    actions: [
                        TextButton(
                            onPressed: () {
                                Navigator.of(context).pop(false);
                            },
                            child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                            onPressed: () {
                                Navigator.of(context).pop(true);
                            },
                            child: const Text("Delete"),
                        ),
                    ],
                );
            },
        );

        if (confirm == true) {
            setState(() {
                FolderRepository.removeFolder(folder);
            });
        }
    }

    @override
    Widget build(BuildContext context) {
        final folders = FolderRepository.folders;

        return Scaffold(
            appBar: AppBar(
                title: const Text("Folders"),
            ),
            body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    children: [
                        Row(
                            children: [
                                Expanded(
                                    child: TextField(
                                        controller: _controller,
                                        decoration: const InputDecoration(
                                            labelText: "New folder",
                                            border: OutlineInputBorder(),
                                        ),
                                    ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                    onPressed: _addFolder,
                                    child: const Text("Add"),
                                ),
                            ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                            child: folders.isEmpty
                                ? const Center(
                                    child: Text("No folders yet."),
                                )
                                : ListView.builder(
                                    itemCount: folders.length,
                                    itemBuilder: (context, index) {
                                        final folder = folders[index];
                                        return ListTile(
                                            title: Text(folder.name),
                                            trailing: IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                ),
                                                onPressed: () {
                                                    _confirmDeleteFolder(
                                                        folder,
                                                    );
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
