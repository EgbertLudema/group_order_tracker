import "package:flutter/material.dart";

import "../models.dart";
import "../repositories.dart";

/// Screen for one order with 3 tables
class OrderDetailScreen extends StatefulWidget {
    const OrderDetailScreen({
        super.key,
        required this.orderId,
    });

    final String orderId;

    @override
    State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
    late Order _order;

    @override
    void initState() {
        super.initState();
        _order = OrderRepository.getOrderById(widget.orderId);
    }

    void _addEmptyRow() {
        setState(() {
            _order.items.add(
                OrderItem(
                    amount: 1,
                    itemId: "",
                    personName: "",
                ),
            );
        });
        OrderRepository.saveOrders();
    }

    void _removeRow(int index) {
        setState(() {
            _order.items.removeAt(index);
        });
        OrderRepository.saveOrders();
    }

    void _changeAmount(int index, int delta) {
        setState(() {
            final item = _order.items[index];
            final newAmount = item.amount + delta;
            if (newAmount > 0) {
                item.amount = newAmount;
            }
        });
        OrderRepository.saveOrders();
    }

    Future<void> _editTitle() async {
        final TextEditingController controller =
            TextEditingController(text: _order.title);

        final String? result = await showDialog<String>(
            context: context,
            builder: (context) {
                return AlertDialog(
                    title: const Text("Edit order title"),
                    content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                            labelText: "Title",
                            border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                    ),
                    actions: [
                        TextButton(
                            onPressed: () {
                                Navigator.of(context).pop();
                            },
                            child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                            onPressed: () {
                                final value = controller.text.trim();
                                Navigator.of(context).pop(value);
                            },
                            child: const Text("Save"),
                        ),
                    ],
                );
            },
        );

        if (result != null) {
            setState(() {
                _order.title = result;
            });
            OrderRepository.saveOrders();
        }
    }

    Map<String, int> _buildOrderList(List<OrderItem> items) {
        final Map<String, int> result = {};

        for (final orderItem in items) {
            if (orderItem.itemId.isEmpty) {
                continue;
            }

            final itemDef = ItemRepository.findById(orderItem.itemId);
            if (itemDef == null) {
                continue;
            }

            // Collect option names for this row
            final List<String> optionNames = [];
            for (final optionId in orderItem.optionIds) {
                final option = ItemRepository.findOptionById(
                    orderItem.itemId,
                    optionId,
                );
                if (option != null) {
                    optionNames.add(option.name);
                }
            }

            // Sort so &ldquo;Fries + Curry + Mayo&rdquo; and &ldquo;Fries + Mayo + Curry&rdquo; become the same key
            optionNames.sort();

            // Build label for Table 2: &ldquo;Fries&rdquo;, &ldquo;Fries Curry&rdquo;, &ldquo;Fries Curry, Mayo&rdquo;, etc.
            String label = itemDef.name;
            if (optionNames.isNotEmpty) {
                label += " ${optionNames.join(", ")}";
            }

            // Aggregate by label
            result[label] = (result[label] ?? 0) + orderItem.amount;
        }

        return result;
    }


    List<PersonCostRow> _buildPersonCosts(Order order) {
        final Map<String, List<OrderItem>> itemsPerPerson = {};
        for (final orderItem in order.items) {
            final personName = orderItem.personName.trim();
            if (personName.isEmpty) {
                continue;
            }
            itemsPerPerson.putIfAbsent(personName, () => []);
            itemsPerPerson[personName]!.add(orderItem);
        }

        final List<PersonCostRow> rows = [];

        itemsPerPerson.forEach((person, personItems) {
            final List<String> itemDescriptions = [];
            double totalPrice = 0.0;

            for (final orderItem in personItems) {
                final itemDef = ItemRepository.findById(orderItem.itemId);
                if (itemDef == null) {
                    continue;
                }

                final basePrice = itemDef.price * orderItem.amount;

                double optionsPrice = 0.0;
                final List<String> optionNames = [];
                for (final optionId in orderItem.optionIds) {
                    final option = ItemRepository.findOptionById(
                        orderItem.itemId,
                        optionId,
                    );
                    if (option == null) {
                        continue;
                    }
                    optionsPrice += option.price * orderItem.amount;
                    optionNames.add(option.name);
                }

                final lineTotal = basePrice + optionsPrice;
                totalPrice += lineTotal;

                String desc = "${orderItem.amount}x ${itemDef.name}";
                if (optionNames.isNotEmpty) {
                    desc += " (${optionNames.join(", ")})";
                }
                itemDescriptions.add(desc);
            }

            final status = _order.personStatuses[person] ?? PaymentStatus.unsent;

            rows.add(
                PersonCostRow(
                    person: person,
                    items: itemDescriptions,
                    totalPrice: totalPrice,
                    status: status,
                ),
            );
        });

        return rows;
    }

    String _formatDate(DateTime date) {
        return "${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}";
    }

    Future<void> _selectOptionsForRow(OrderItem orderItem) async {
        final itemDef = ItemRepository.findById(orderItem.itemId);
        if (itemDef == null || itemDef.options.isEmpty) {
            return;
        }

        final currentSelection = Set<String>.from(orderItem.optionIds);
        final newSelection = await showModalBottomSheet<Set<String>>(
            context: context,
            isScrollControlled: true,
            builder: (context) {
                final localSelection = Set<String>.from(currentSelection);
                return DraggableScrollableSheet(
                    expand: false,
                    builder: (context, scrollController) {
                        return SafeArea(
                          bottom: true,
                          child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                        "Options for ${itemDef.name}",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                        child: ListView.builder(
                                            controller: scrollController,
                                            itemCount: itemDef.options.length,
                                            itemBuilder: (context, index) {
                                                final option =
                                                    itemDef.options[index];
                                                final selected = localSelection
                                                    .contains(option.id);
                                                return CheckboxListTile(
                                                    title: Text(option.name),
                                                    subtitle: Text(
                                                        "${option.price.toStringAsFixed(2)} € per piece",
                                                    ),
                                                    value: selected,
                                                    onChanged: (value) {
                                                        if (value == null) {
                                                            return;
                                                        }
                                                        if (value) {
                                                            localSelection
                                                                .add(option.id);
                                                        } else {
                                                            localSelection
                                                                .remove(
                                                                    option.id,
                                                                );
                                                        }
                                                        (context as Element)
                                                            .markNeedsBuild();
                                                    },
                                                );
                                            },
                                        ),
                                    ),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                            TextButton(
                                                onPressed: () {
                                                    Navigator.of(context).pop(
                                                        currentSelection,
                                                    );
                                                },
                                                child: const Text("Cancel"),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                                onPressed: () {
                                                    Navigator.of(context).pop(
                                                        localSelection,
                                                    );
                                                },
                                                child: const Text("Save"),
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                          ),
                      );
                    },
                );
            },
        );

        if (newSelection != null) {
            setState(() {
                orderItem.optionIds = newSelection.toList();
            });
            OrderRepository.saveOrders();
        }
    }

    Widget _buildEditableItemsTable() {
        final persons = PersonRepository.persons;
        final items = ItemRepository.items;

        return Card(
            elevation: 2,
            child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text(
                            "Table 1 – Items per person",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                        const SizedBox(height: 12),
                        // HORIZONTAL SCROLL FOR TABLE CONTENT
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                        children: const [
                                            SizedBox(
                                                width: 100,
                                                child: Text(
                                                    "Amount",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                    ),
                                                ),
                                            ),
                                            SizedBox(width: 8),
                                            SizedBox(
                                                width: 160,
                                                child: Text(
                                                    "Item",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                    ),
                                                ),
                                            ),
                                            SizedBox(width: 8),
                                            SizedBox(
                                                width: 160,
                                                child: Text(
                                                    "Person",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                    ),
                                                ),
                                            ),
                                            SizedBox(width: 80),
                                        ],
                                    ),
                                    const Divider(),
                                    ..._order.items.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final orderItem = entry.value;
                                        final itemDef = orderItem.itemId.isEmpty
                                            ? null
                                            : ItemRepository.findById(
                                                orderItem.itemId,
                                            );

                                        final selectedOptions =
                                            <ItemOptionDefinition>[];
                                        if (itemDef != null) {
                                            for (final optionId
                                                in orderItem.optionIds) {
                                                final opt =
                                                    ItemRepository.findOptionById(
                                                itemDef.id,
                                                optionId,
                                                );
                                                if (opt != null) {
                                                    selectedOptions.add(opt);
                                                }
                                            }
                                        }

                                        final optionsLabel = selectedOptions.isEmpty
                                            ? "No options"
                                            : selectedOptions
                                                .map((e) => e.name)
                                                .join(", ");

                                        return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0,
                                            ),
                                            child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                    // Amount column with FittedBox to avoid overflow
                                                    SizedBox(
                                                        width: 90,
                                                        child: FittedBox(
                                                            fit:
                                                                BoxFit.scaleDown,
                                                            child: Row(
                                                                children: [
                                                                    IconButton(
                                                                        onPressed: () =>
                                                                            _changeAmount(
                                                                        index,
                                                                        -1,
                                                                        ),
                                                                        icon: const Icon(
                                                                            Icons
                                                                                .remove,
                                                                        ),
                                                                        iconSize:
                                                                            18,
                                                                        padding:
                                                                            EdgeInsets
                                                                                .zero,
                                                                    ),
                                                                    Text(
                                                                        orderItem
                                                                            .amount
                                                                            .toString(),
                                                                    ),
                                                                    IconButton(
                                                                        onPressed: () =>
                                                                            _changeAmount(
                                                                        index,
                                                                        1,
                                                                        ),
                                                                        icon: const Icon(
                                                                            Icons
                                                                                .add,
                                                                        ),
                                                                        iconSize:
                                                                            18,
                                                                        padding:
                                                                            EdgeInsets
                                                                                .zero,
                                                                    ),
                                                                ],
                                                            ),
                                                        ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Item dropdown (no Expanded, fixed width for scrollable row)
                                                    SizedBox(
                                                        width: 200,
                                                        child:
                                                            DropdownButtonFormField<
                                                                String>(
                                                                value: orderItem
                                                                        .itemId
                                                                        .isEmpty
                                                                    ? null
                                                                    : orderItem
                                                                        .itemId,
                                                                items: items
                                                                    .map(
                                                                        (item) =>
                                                                            DropdownMenuItem(
                                                                                value: item.id,
                                                                                child: Text(
                                                                                    "${item.name} (${item.price.toStringAsFixed(2)} €)",
                                                                                ),
                                                                            ),
                                                                    )
                                                                    .toList(),
                                                                decoration:
                                                                    const InputDecoration(
                                                                hintText:
                                                                    "Select item",
                                                                border:
                                                                    OutlineInputBorder(),
                                                                isDense: true,
                                                                ),
                                                                onChanged:
                                                                    (value) async {
                                                                setState(
                                                                    () {
                                                                        orderItem
                                                                            .itemId =
                                                                        value ??
                                                                            "";
                                                                        orderItem
                                                                            .optionIds =
                                                                        [];
                                                                    },
                                                                );
                                                                OrderRepository
                                                                    .saveOrders();

                                                                final item =
                                                                    ItemRepository
                                                                        .findById(
                                                                        orderItem
                                                                            .itemId,
                                                                    );

                                                                if (item != null &&
                                                                    item.options
                                                                        .isNotEmpty) {
                                                                    await _selectOptionsForRow(
                                                                        orderItem,
                                                                    );
                                                                }
                                                                },
                                                            ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Person dropdown (no Expanded, fixed width)
                                                    SizedBox(
                                                        width: 200,
                                                        child:
                                                            DropdownButtonFormField<
                                                                String>(
                                                                value: orderItem
                                                                        .personName
                                                                        .isEmpty
                                                                    ? null
                                                                    : orderItem
                                                                        .personName,
                                                                items: persons
                                                                    .map(
                                                                        (person) =>
                                                                            DropdownMenuItem(
                                                                                value: person.name,
                                                                                child: Text(
                                                                                    person.name,
                                                                                ),
                                                                            ),
                                                                    )
                                                                    .toList(),
                                                                decoration:
                                                                    const InputDecoration(
                                                                hintText:
                                                                    "Select person",
                                                                border:
                                                                    OutlineInputBorder(),
                                                                isDense: true,
                                                                ),
                                                                onChanged:
                                                                    (value) {
                                                                setState(
                                                                    () {
                                                                        orderItem
                                                                            .personName =
                                                                        value ??
                                                                            "";
                                                                    },
                                                                );
                                                                OrderRepository
                                                                    .saveOrders();
                                                                },
                                                            ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Column(
                                                        children: [
                                                            IconButton(
                                                                onPressed: () =>
                                                                    _removeRow(
                                                                    index,
                                                                    ),
                                                                icon: const Icon(
                                                                    Icons
                                                                        .delete_outline,
                                                                    color:
                                                                        Colors.red,
                                                                ),
                                                            ),
                                                            const SizedBox(
                                                                height: 4,
                                                            ),
                                                            if (itemDef != null &&
                                                                itemDef
                                                                    .options
                                                                    .isNotEmpty)
                                                                TextButton(
                                                                    onPressed: () =>
                                                                        _selectOptionsForRow(
                                                                        orderItem,
                                                                        ),
                                                                    child: Text(
                                                                        optionsLabel,
                                                                        style:
                                                                            const TextStyle(
                                                                            fontSize:
                                                                                11,
                                                                        ),
                                                                    ),
                                                                )
                                                            else
                                                                const Text(
                                                                    "No options",
                                                                    style:
                                                                        TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        color: Colors
                                                                            .grey,
                                                                    ),
                                                                ),
                                                        ],
                                                    ),
                                                ],
                                            ),
                                        );
                                    }),
                                ],
                            ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                                onPressed: _addEmptyRow,
                                icon: const Icon(Icons.add),
                                label: const Text("Add item row"),
                            ),
                        ),
                        if (PersonRepository.persons.isEmpty ||
                            ItemRepository.items.isEmpty)
                            const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text(
                                    "Tip: add persons and items on the main screen first.",
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                    ),
                                ),
                            ),
                    ],
                ),
            ),
        );
    }



    Widget _buildGeneratedOrderTable(Map<String, int> orderList) {
        return Card(
            elevation: 2,
            child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text(
                            "Table 2 – Order list (by item)",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                        const SizedBox(height: 12),
                        // HORIZONTAL SCROLL FOR TABLE 2
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                        children: const [
                                            SizedBox(
                                                width: 100,
                                                child: Text(
                                                    "Amount",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                    ),
                                                ),
                                            ),
                                            SizedBox(width: 8),
                                            SizedBox(
                                                width: 200,
                                                child: Text(
                                                    "Item",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                    ),
                                                ),
                                            ),
                                        ],
                                    ),
                                    const Divider(),
                                    if (orderList.isEmpty)
                                        const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8.0,
                                            ),
                                            child: Text("No items yet."),
                                        )
                                    else
                                        ...orderList.entries.map((e) {
                                            return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                vertical: 4.0,
                                                ),
                                                child: Row(
                                                    children: [
                                                        SizedBox(
                                                            width: 100,
                                                            child: Text(
                                                                e.value
                                                                    .toString(),
                                                            ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8,
                                                        ),
                                                        SizedBox(
                                                            width: 200,
                                                            child: Text(e.key),
                                                        ),
                                                    ],
                                                ),
                                            );
                                        }),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _buildGeneratedPersonCostTable(List<PersonCostRow> rows) {
        return Card(
            elevation: 2,
            child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text(
                            "Table 3 – Costs per person",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                        const SizedBox(height: 12),
                        // HORIZONTAL SCROLL FOR TABLE 3
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                        children: const [
                                            SizedBox(
                                                width: 140,
                                                child: Text(
                                                    "Person",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                    ),
                                                ),
                                            ),
                                            SizedBox(
                                                width: 220,
                                                child: Text(
                                                    "Items",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                    ),
                                                ),
                                            ),
                                            SizedBox(
                                                width: 100,
                                                child: Text(
                                                    "Price",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                    ),
                                                ),
                                            ),
                                            SizedBox(
                                                width: 140,
                                                child: Text(
                                                    "Status",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                    ),
                                                ),
                                            ),
                                        ],
                                    ),
                                    const Divider(),
                                    if (rows.isEmpty)
                                        const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8.0,
                                            ),
                                            child: Text(
                                                "No persons yet. Fill Table 1 first.",
                                            ),
                                        )
                                    else
                                        ...rows.map((row) {
                                            return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                vertical: 4.0,
                                                ),
                                                child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                        SizedBox(
                                                            width: 140,
                                                            child: Text(
                                                                row.person,
                                                            ),
                                                        ),
                                                        SizedBox(
                                                            width: 220,
                                                            child: Text(
                                                                row.items
                                                                    .join(", "),
                                                            ),
                                                        ),
                                                        SizedBox(
                                                            width: 100,
                                                            child: Text(
                                                                "${row.totalPrice.toStringAsFixed(2)} €",
                                                            ),
                                                        ),
                                                        SizedBox(
                                                            width: 140,
                                                            child:
                                                                DropdownButton<
                                                                    PaymentStatus>(
                                                                    value: row
                                                                        .status,
                                                                    isExpanded:
                                                                        true,
                                                                    onChanged:
                                                                        (newStatus) {
                                                                    if (newStatus ==
                                                                        null) {
                                                                        return;
                                                                    }
                                                                    setState(
                                                                        () {
                                                                        _order.personStatuses[row
                                                                            .person] = newStatus;
                                                                        },
                                                                    );
                                                                    OrderRepository
                                                                        .saveOrders();
                                                                    },
                                                                    items: PaymentStatus
                                                                        .values
                                                                        .map(
                                                                    (status) =>
                                                                        DropdownMenuItem(
                                                                        value:
                                                                            status,
                                                                        child:
                                                                            Text(
                                                                            paymentStatusLabel(
                                                                                status,
                                                                            ),
                                                                        ),
                                                                    ),
                                                                        )
                                                                        .toList(),
                                                                ),
                                                        ),
                                                    ],
                                                ),
                                            );
                                        }),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        final orderList = _buildOrderList(_order.items);
        final personCostRows = _buildPersonCosts(_order);

        return Scaffold(
            appBar: AppBar(
                title: Text(
                    (_order.title.isEmpty
                        ? "Order ${_order.id}"
                        : _order.title) +
                        " • ${_formatDate(_order.date)}",
                ),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: "Edit title",
                        onPressed: _editTitle,
                    ),
                ],
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        _buildEditableItemsTable(),
                        const SizedBox(height: 24),
                        _buildGeneratedOrderTable(orderList),
                        const SizedBox(height: 24),
                        _buildGeneratedPersonCostTable(personCostRows),
                    ],
                ),
            ),
        );
    }
}
