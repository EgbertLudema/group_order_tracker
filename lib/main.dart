import "package:flutter/material.dart";

void main() {
    runApp(const MyApp());
}

/// Simple person model
class Person {
    Person({
        required this.id,
        required this.name,
    });

    final String id;
    String name;
}

/// Item option (for example sauce linked to fries)
class ItemOptionDefinition {
    ItemOptionDefinition({
        required this.id,
        required this.name,
        required this.price,
    });

    final String id;
    String name;
    double price;
}

/// Item with base price and optional linked options
class ItemDefinition {
    ItemDefinition({
        required this.id,
        required this.name,
        required this.price,
        List<ItemOptionDefinition>? options,
    }) : options = options ?? [];

    final String id;
    String name;
    double price;
    final List<ItemOptionDefinition> options;
}

/// Global repositories for demo purposes
class PersonRepository {
    static final List<Person> persons = [
        Person(id: "p1", name: "Alice"),
        Person(id: "p2", name: "Bob"),
    ];

    static void addPerson(String name) {
        final newId = "p${persons.length + 1}";
        persons.add(Person(id: newId, name: name));
    }

    static void removePerson(Person person) {
        persons.remove(person);
    }
}

class ItemRepository {
    static final List<ItemDefinition> items = [
        ItemDefinition(
            id: "i1",
            name: "Fries",
            price: 4.0,
            options: [
                ItemOptionDefinition(
                    id: "i1_o1",
                    name: "Curry",
                    price: 0.85,
                ),
                ItemOptionDefinition(
                    id: "i1_o2",
                    name: "Mayonnaise",
                    price: 0.85,
                ),
            ],
        ),
        ItemDefinition(
            id: "i2",
            name: "Pizza",
            price: 10.0,
        ),
        ItemDefinition(
            id: "i3",
            name: "Cola",
            price: 2.5,
        ),
    ];

    static void addItem(String name, double price) {
        final newId = "i${items.length + 1}";
        items.add(
            ItemDefinition(
                id: newId,
                name: name,
                price: price,
            ),
        );
    }

    static void removeItem(ItemDefinition item) {
        items.remove(item);
    }

    static ItemDefinition? findByName(String name) {
        for (final item in items) {
            if (item.name == name) {
                return item;
            }
        }
        return null;
    }

    static ItemDefinition? findById(String id) {
        for (final item in items) {
            if (item.id == id) {
                return item;
            }
        }
        return null;
    }

    static ItemOptionDefinition? findOptionById(String itemId, String optionId) {
        final item = findById(itemId);
        if (item == null) {
            return null;
        }
        for (final option in item.options) {
            if (option.id == optionId) {
                return option;
            }
        }
        return null;
    }

    static void addOptionToItem(
        ItemDefinition item,
        String name,
        double price,
    ) {
        final optionId = "${item.id}_o${item.options.length + 1}";
        item.options.add(
            ItemOptionDefinition(
                id: optionId,
                name: name,
                price: price,
            ),
        );
    }

    static void removeOptionFromItem(
        ItemDefinition item,
        ItemOptionDefinition option,
    ) {
        item.options.remove(option);
    }
}

enum PaymentStatus {
    unsent,
    sent,
    paid,
    myself,
}

String paymentStatusLabel(PaymentStatus status) {
    switch (status) {
        case PaymentStatus.unsent:
            return "Unsent";
        case PaymentStatus.sent:
            return "Sent";
        case PaymentStatus.paid:
            return "Paid";
        case PaymentStatus.myself:
            return "Myself";
    }
}

/// Represents one row in Table 1
class OrderItem {
    OrderItem({
        required this.amount,
        required this.itemId,
        required this.personName,
        List<String>? optionIds,
    }) : optionIds = optionIds ?? [];

    int amount;
    String itemId; // reference to ItemDefinition
    String personName;
    List<String> optionIds; // list of option ids for that item
}

/// Represents one order for a specific date
class Order {
    Order({
        required this.id,
        required this.date,
        required this.items,
        Map<String, PaymentStatus>? personStatuses,
    }) : personStatuses = personStatuses ?? {};

    final String id;
    final DateTime date;
    final List<OrderItem> items;

    /// Person name -> PaymentStatus
    final Map<String, PaymentStatus> personStatuses;
}

/// In memory repository for orders
class OrderRepository {
    static final List<Order> orders = [
        Order(
            id: "1",
            date: DateTime.now(),
            items: [
                OrderItem(
                    amount: 2,
                    itemId: "i1",
                    personName: "Alice",
                    optionIds: ["i1_o1"],
                ),
                OrderItem(
                    amount: 1,
                    itemId: "i2",
                    personName: "Alice",
                ),
                OrderItem(
                    amount: 1,
                    itemId: "i3",
                    personName: "Bob",
                ),
            ],
        ),
    ];

    static void addOrder(Order order) {
        orders.add(order);
    }

    static Order getOrderById(String id) {
        return orders.firstWhere((o) => o.id == id);
    }
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Orders Demo",
            theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: true,
            ),
            home: const OrderListScreen(),
        );
    }
}

/// Main screen: list of orders per date
class OrderListScreen extends StatefulWidget {
    const OrderListScreen({super.key});

    @override
    State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
    List<Order> get _orders => OrderRepository.orders;

    void _createNewOrder() {
        final newId = (_orders.length + 1).toString();
        final newOrder = Order(
            id: newId,
            date: DateTime.now(),
            items: [],
        );
        OrderRepository.addOrder(newOrder);

        Navigator.of(context)
            .push(
                MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(orderId: newId),
                ),
            )
            .then((_) {
                setState(() {});
            });
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

    Future<void> _openItems() async {
        await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const ItemManagementScreen(),
            ),
        );
        setState(() {});
    }

    @override
    Widget build(BuildContext context) {
        final sortedOrders = [..._orders]
            ..sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
            appBar: AppBar(
                title: const Text("Orders"),
                actions: [
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
            ),
            body: ListView.builder(
                itemCount: sortedOrders.length,
                itemBuilder: (context, index) {
                    final order = sortedOrders[index];
                    final itemCount = order.items.length;
                    return ListTile(
                        title: Text("Order ${order.id}"),
                        subtitle: Text(
                            "${_formatDate(order.date)} • $itemCount rows",
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                            await Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) => OrderDetailScreen(
                                        orderId: order.id,
                                    ),
                                ),
                            );
                            setState(() {});
                        },
                    );
                },
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: _createNewOrder,
                child: const Icon(Icons.add),
            ),
        );
    }
}

/// Screen to manage persons
class PersonManagementScreen extends StatefulWidget {
    const PersonManagementScreen({super.key});

    @override
    State<PersonManagementScreen> createState() =>
        _PersonManagementScreenState();
}

class _PersonManagementScreenState extends State<PersonManagementScreen> {
    final TextEditingController _controller = TextEditingController();

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    void _addPerson() {
        final name = _controller.text.trim();
        if (name.isEmpty) {
            return;
        }
        setState(() {
            PersonRepository.addPerson(name);
        });
        _controller.clear();
    }

    @override
    Widget build(BuildContext context) {
        final persons = PersonRepository.persons;

        return Scaffold(
            appBar: AppBar(
                title: const Text("Persons"),
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
                                            labelText: "New person",
                                            border: OutlineInputBorder(),
                                        ),
                                    ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                    onPressed: _addPerson,
                                    child: const Text("Add"),
                                ),
                            ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                            child: persons.isEmpty
                                ? const Center(
                                    child: Text("No persons yet."),
                                )
                                : ListView.builder(
                                    itemCount: persons.length,
                                    itemBuilder: (context, index) {
                                        final person = persons[index];
                                        return ListTile(
                                            title: Text(person.name),
                                            trailing: IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                ),
                                                onPressed: () {
                                                    setState(() {
                                                        PersonRepository
                                                            .removePerson(
                                                                person,
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

/// Data needed for Table 3
class PersonCostRow {
    PersonCostRow({
        required this.person,
        required this.items,
        required this.totalPrice,
        required this.status,
    });

    final String person;
    final List<String> items;
    final double totalPrice;
    final PaymentStatus status;
}

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
    }

    void _removeRow(int index) {
        setState(() {
            _order.items.removeAt(index);
        });
    }

    void _changeAmount(int index, int delta) {
        setState(() {
            final item = _order.items[index];
            final newAmount = item.amount + delta;
            if (newAmount > 0) {
                item.amount = newAmount;
            }
        });
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
            final key = itemDef.name;
            result[key] = (result[key] ?? 0) + orderItem.amount;
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

                // Calculate add on prices
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
                        return Padding(
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
                                                        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
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
                        );
                    },
                );
            },
        );

        if (newSelection != null) {
            setState(() {
                orderItem.optionIds = newSelection.toList();
            });
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
                        Row(
                            children: const [
                                SizedBox(
                                    width: 100,
                                    child: Text(
                                        "Amount",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                        "Item",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                        "Person",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
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
                                : ItemRepository.findById(orderItem.itemId);

                            final selectedOptions = <ItemOptionDefinition>[];
                            if (itemDef != null) {
                                for (final optionId in orderItem.optionIds) {
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
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        SizedBox(
                                            width: 100,
                                            child: Row(
                                                children: [
                                                    IconButton(
                                                        onPressed: () =>
                                                            _changeAmount(
                                                                index,
                                                                -1,
                                                            ),
                                                        icon: const Icon(
                                                            Icons.remove,
                                                        ),
                                                        iconSize: 18,
                                                        padding: EdgeInsets.zero,
                                                    ),
                                                    Text(orderItem.amount.toString()),
                                                    IconButton(
                                                        onPressed: () =>
                                                            _changeAmount(
                                                                index,
                                                                1,
                                                            ),
                                                        icon: const Icon(Icons.add),
                                                        iconSize: 18,
                                                        padding: EdgeInsets.zero,
                                                    ),
                                                ],
                                            ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            flex: 2,
                                            child: DropdownButtonFormField<String>(
                                                value: orderItem.itemId.isEmpty
                                                    ? null
                                                    : orderItem.itemId,
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
                                                decoration: const InputDecoration(
                                                    hintText: "Select item",
                                                    border: OutlineInputBorder(),
                                                    isDense: true,
                                                ),
                                                onChanged: (value) {
                                                    setState(() {
                                                        orderItem.itemId =
                                                            value ?? "";
                                                        orderItem.optionIds = [];
                                                    });
                                                },
                                            ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            flex: 2,
                                            child: DropdownButtonFormField<String>(
                                                value: orderItem.personName.isEmpty
                                                    ? null
                                                    : orderItem.personName,
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
                                                decoration: const InputDecoration(
                                                    hintText: "Select person",
                                                    border: OutlineInputBorder(),
                                                    isDense: true,
                                                ),
                                                onChanged: (value) {
                                                    setState(() {
                                                        orderItem.personName =
                                                            value ?? "";
                                                    });
                                                },
                                            ),
                                        ),
                                        const SizedBox(width: 4),
                                        Column(
                                            children: [
                                                IconButton(
                                                    onPressed: () =>
                                                        _removeRow(index),
                                                    icon: const Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.red,
                                                    ),
                                                ),
                                                const SizedBox(height: 4),
                                                if (itemDef != null &&
                                                    itemDef.options.isNotEmpty)
                                                    TextButton(
                                                        onPressed: () =>
                                                            _selectOptionsForRow(
                                                                orderItem,
                                                            ),
                                                        child: Text(
                                                            optionsLabel,
                                                            style: const TextStyle(
                                                                fontSize: 11,
                                                            ),
                                                        ),
                                                    )
                                                else
                                                    const Text(
                                                        "No options",
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey,
                                                        ),
                                                    ),
                                            ],
                                        ),
                                    ],
                                ),
                            );
                        }).toList(),
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
                        Row(
                            children: const [
                                SizedBox(
                                    width: 100,
                                    child: Text(
                                        "Amount",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        "Item",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                            ],
                        ),
                        const Divider(),
                        if (orderList.isEmpty)
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text("No items yet."),
                            )
                        else
                            ...orderList.entries.map((e) {
                                return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                        children: [
                                            SizedBox(
                                                width: 100,
                                                child: Text(e.value.toString()),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(e.key),
                                            ),
                                        ],
                                    ),
                                );
                            }).toList(),
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
                        Row(
                            children: const [
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                        "Person",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                Expanded(
                                    flex: 3,
                                    child: Text(
                                        "Items",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                        "Price",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                        "Status",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                            ],
                        ),
                        const Divider(),
                        if (rows.isEmpty)
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                    "No persons yet. Fill Table 1 first.",
                                ),
                            )
                        else
                            ...rows.map((row) {
                                return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                            Expanded(
                                                flex: 2,
                                                child: Text(row.person),
                                            ),
                                            Expanded(
                                                flex: 3,
                                                child: Text(
                                                    row.items.join(", "),
                                                ),
                                            ),
                                            Expanded(
                                                flex: 2,
                                                child: Text(
                                                    "${row.totalPrice.toStringAsFixed(2)} €",
                                                ),
                                            ),
                                            Expanded(
                                                flex: 2,
                                                child: DropdownButton<
                                                    PaymentStatus>(
                                                    value: row.status,
                                                    isExpanded: true,
                                                    onChanged: (newStatus) {
                                                        if (newStatus == null) {
                                                            return;
                                                        }
                                                        setState(() {
                                                            _order.personStatuses[
                                                                    row.person] =
                                                                newStatus;
                                                        });
                                                    },
                                                    items: PaymentStatus.values
                                                        .map(
                                                            (status) =>
                                                                DropdownMenuItem(
                                                                    value: status,
                                                                    child: Text(
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
                            }).toList(),
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
                title: Text("Order ${_order.id} • ${_formatDate(_order.date)}"),
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
