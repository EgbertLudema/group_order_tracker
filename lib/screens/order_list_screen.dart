import "package:flutter/material.dart";

import "../models.dart";
import "../repositories.dart";
import "order_detail_screen.dart";
import "person_management_screen.dart";
import "item_management_screen.dart";
import "folder_management_screen.dart";

/// Main screen: list of orders per date
class OrderListScreen extends StatefulWidget {
    const OrderListScreen({super.key});

    @override
    State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
    List<Order> get _orders => OrderRepository.orders;

    String? _selectedFolderId;

    /// Selected orders for multi select mode
    final Set<String> _selectedOrderIds = {};

    bool get _isSelectionMode => _selectedOrderIds.isNotEmpty;

    Future<void> _createNewOrder() async {
        final title = await _askForOrderTitle();
        if (title == null) {
            return;
        }

        final newId = (OrderRepository.orders.length + 1).toString();

        final newOrder = Order(
            id: newId,
            date: DateTime.now(),
            items: [],
            title: title,
            folderId: _selectedFolderId,
        );

        OrderRepository.addOrder(newOrder);

        await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => OrderDetailScreen(orderId: newId),
            ),
        );

        setState(() {});
    }

    Future<String?> _askForOrderTitle() async {
        final controller = TextEditingController();

        // Localized default date string based on device locale
        final localizations = MaterialLocalizations.of(context);
        final now = DateTime.now();
        final defaultTitle = localizations.formatMediumDate(now);

        controller.text = defaultTitle;

        return showDialog<String>(
            context: context,
            builder: (context) {
                return AlertDialog(
                    title: const Text("New order"),
                    content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                            labelText: "Order title",
                            border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                    ),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                            onPressed: () {
                                final value = controller.text.trim();
                                Navigator.pop(
                                    context,
                                    value.isEmpty ? null : value,
                                );
                            },
                            child: const Text("Create"),
                        ),
                    ],
                );
            },
        );
    }

    void _toggleSelection(Order order) {
        setState(() {
            if (_selectedOrderIds.contains(order.id)) {
                _selectedOrderIds.remove(order.id);
            } else {
                _selectedOrderIds.add(order.id);
            }
        });
    }

    void _enterSelectionWith(Order order) {
        setState(() {
            _selectedOrderIds
                ..clear()
                ..add(order.id);
        });
    }

    void _clearSelection() {
        setState(() {
            _selectedOrderIds.clear();
        });
    }

    Future<void> _confirmDeleteSelectedOrders() async {
        if (_selectedOrderIds.isEmpty) {
            return;
        }

        final count = _selectedOrderIds.length;

        final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) {
                return AlertDialog(
                    title: const Text("Delete orders"),
                    content: Text(
                        "Are you sure you want to delete $count order(s)?",
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
                OrderRepository.orders.removeWhere(
                    (order) => _selectedOrderIds.contains(order.id),
                );
                _selectedOrderIds.clear();
            });
            await OrderRepository.saveOrders();
        }
    }

    Future<void> _moveSelectedToFolder() async {
        if (_selectedOrderIds.isEmpty) {
            return;
        }

        if (FolderRepository.folders.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("No folders available"),
                ),
            );
            return;
        }

        final String? targetFolderId = await showDialog<String>(
            context: context,
            builder: (context) {
                return SimpleDialog(
                    title: const Text("Move to folder"),
                    children: [
                        ...FolderRepository.folders.map(
                            (folder) => SimpleDialogOption(
                                onPressed: () {
                                    Navigator.pop(context, folder.id);
                                },
                                child: Text(folder.name),
                            ),
                        ),
                    ],
                );
            },
        );

        if (targetFolderId == null) {
            return;
        }

        setState(() {
            for (final order in OrderRepository.orders) {
                if (_selectedOrderIds.contains(order.id)) {
                    order.folderId = targetFolderId;
                }
            }
            _selectedFolderId = targetFolderId;
            _selectedOrderIds.clear();
        });

        await OrderRepository.saveOrders();
    }

    String _formatDate(DateTime date) {
        return "${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}";
    }

    Future<void> _openPersons() async {
        await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const PersonManagementScreen(),
            ),
        );
        setState(() {});
    }

    Future<void> _openFolders() async {
        await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const FolderManagementScreen(),
            ),
        );
        setState(() {});
    }

    Future<void> _openItems() async {
        await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const ItemManagementScreen(),
            ),
        );
        setState(() {});
    }

    PreferredSizeWidget _buildAppBar() {
        if (_isSelectionMode) {
            return AppBar(
                leading: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: "Cancel selection",
                    onPressed: _clearSelection,
                ),
                title: Text("${_selectedOrderIds.length} selected"),
                actions: [
                    IconButton(
                        tooltip: "Move to folder",
                        icon: const Icon(Icons.drive_file_move),
                        onPressed: _moveSelectedToFolder,
                    ),
                    IconButton(
                        tooltip: "Delete selected",
                        icon: const Icon(Icons.delete),
                        onPressed: _confirmDeleteSelectedOrders,
                    ),
                ],
            );
        }

        return AppBar(
            title: const Text("Orders"),
            actions: [
                IconButton(
                    tooltip: "Manage folders",
                    onPressed: _openFolders,
                    icon: const Icon(Icons.folder),
                ),
                IconButton(
                    tooltip: "Manage persons",
                    onPressed: _openPersons,
                    icon: const Icon(Icons.people),
                ),
                IconButton(
                    tooltip: "Manage items",
                    onPressed: _openItems,
                    icon: const Icon(Icons.shopping_bag),
                ),
            ],
        );
    }

    @override
    Widget build(BuildContext context) {
        final List<Order> filtered = _selectedFolderId == null
            ? [..._orders]
            : _orders.where((o) => o.folderId == _selectedFolderId).toList();

        final sortedOrders = [...filtered]
            ..sort(
                (a, b) => b.date.compareTo(a.date),
            );

        return Scaffold(
            appBar: _buildAppBar(),
            body: Column(
                children: [
                    // Folder filter row
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                        ),
                        child: Row(
                            children: [
                                const Text("Folder: "),
                                const SizedBox(width: 8),
                                DropdownButton<String?>(
                                    value: _selectedFolderId,
                                    hint: const Text("All"),
                                    items: [
                                        const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text("All"),
                                        ),
                                        ...FolderRepository.folders.map(
                                            (folder) =>
                                                DropdownMenuItem<String?>(
                                                    value: folder.id,
                                                    child: Text(folder.name),
                                                ),
                                        ),
                                    ],
                                    onChanged: (value) {
                                        setState(() {
                                            _selectedFolderId = value;
                                        });
                                    },
                                ),
                            ],
                        ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                        child: ListView.builder(
                            itemCount: sortedOrders.length,
                            itemBuilder: (context, index) {
                                final order = sortedOrders[index];
                                final itemCount = order.items.length;

                                final String titleText = order.title.isEmpty
                                    ? "Order ${order.id}"
                                    : order.title;

                                final bool isSelected =
                                    _selectedOrderIds.contains(order.id);

                                return ListTile(
                                    leading: _isSelectionMode
                                        ? Checkbox(
                                            value: isSelected,
                                            onChanged: (_) {
                                                _toggleSelection(order);
                                            },
                                        )
                                        : const Icon(Icons.receipt_long),
                                    title: Text(titleText),
                                    subtitle: Text(
                                        "${_formatDate(order.date)} • $itemCount rows",
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    selected: isSelected,
                                    selectedTileColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    onTap: () async {
                                        if (_isSelectionMode) {
                                            _toggleSelection(order);
                                            return;
                                        }

                                        await Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    OrderDetailScreen(
                                                        orderId: order.id,
                                                    ),
                                            ),
                                        );
                                        setState(() {});
                                    },
                                    onLongPress: () {
                                        if (_isSelectionMode) {
                                            _toggleSelection(order);
                                        } else {
                                            _enterSelectionWith(order);
                                        }
                                    },
                                );
                            },
                        ),
                    ),
                ],
            ),
            floatingActionButton: _isSelectionMode
                ? null
                : FloatingActionButton(
                    onPressed: _createNewOrder,
                    child: const Icon(Icons.add),
                ),
        );
    }
}
