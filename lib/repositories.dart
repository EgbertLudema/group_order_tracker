import "dart:convert";

import "package:shared_preferences/shared_preferences.dart";

import "models.dart";

class AppStorage {
    static SharedPreferences? _prefs;

    static const String _personsKey = "persons";
    static const String _itemsKey = "items";
    static const String _ordersKey = "orders";

    static Future<void> init() async {
        _prefs = await SharedPreferences.getInstance();
        await _loadPersons();
        await _loadItems();
        await _loadOrders();
    }

    static Future<void> _loadPersons() async {
        final prefs = _prefs;
        if (prefs == null) {
            return;
        }
        final jsonStr = prefs.getString(_personsKey);
        if (jsonStr == null) {
            // Use defaults from PersonRepository
            return;
        }
        final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
        PersonRepository.persons = decoded
            .map(
                (e) => Person.fromJson(e as Map<String, dynamic>),
            )
            .toList();
    }

    static Future<void> _loadItems() async {
        final prefs = _prefs;
        if (prefs == null) {
            return;
        }
        final jsonStr = prefs.getString(_itemsKey);
        if (jsonStr == null) {
            return;
        }
        final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
        ItemRepository.items = decoded
            .map(
                (e) => ItemDefinition.fromJson(e as Map<String, dynamic>),
            )
            .toList();
    }

    static Future<void> _loadOrders() async {
        final prefs = _prefs;
        if (prefs == null) {
            return;
        }
        final jsonStr = prefs.getString(_ordersKey);
        if (jsonStr == null) {
            return;
        }
        final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
        OrderRepository.orders = decoded
            .map(
                (e) => Order.fromJson(e as Map<String, dynamic>),
            )
            .toList();
    }

    static Future<void> savePersons() async {
        final prefs = _prefs;
        if (prefs == null) {
            return;
        }
        final list =
            PersonRepository.persons.map((p) => p.toJson()).toList();
        await prefs.setString(_personsKey, jsonEncode(list));
    }

    static Future<void> saveItems() async {
        final prefs = _prefs;
        if (prefs == null) {
            return;
        }
        final list =
            ItemRepository.items.map((i) => i.toJson()).toList();
        await prefs.setString(_itemsKey, jsonEncode(list));
    }

    static Future<void> saveOrders() async {
        final prefs = _prefs;
        if (prefs == null) {
            return;
        }
        final list =
            OrderRepository.orders.map((o) => o.toJson()).toList();
        await prefs.setString(_ordersKey, jsonEncode(list));
    }
}

/// Global repositories for demo purposes
class PersonRepository {
    static List<Person> persons = [
        Person(id: "p1", name: "Alice"),
        Person(id: "p2", name: "Bob"),
    ];

    static void addPerson(String name) {
        final newId = "p${persons.length + 1}";
        persons.add(Person(id: newId, name: name));
        AppStorage.savePersons();
    }

    static void removePerson(Person person) {
        persons.remove(person);
        AppStorage.savePersons();
    }
}

class ItemRepository {
    static List<ItemDefinition> items = [
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
        AppStorage.saveItems();
    }

    static void removeItem(ItemDefinition item) {
        items.remove(item);
        AppStorage.saveItems();
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
        AppStorage.saveItems();
    }

    static void removeOptionFromItem(
        ItemDefinition item,
        ItemOptionDefinition option,
    ) {
        item.options.remove(option);
        AppStorage.saveItems();
    }
}

class OrderRepository {
    static List<Order> orders = [
        Order(
            id: "1",
            date: DateTime.now(),
            title: "Demo order",
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
        saveOrders();
    }

    static void removeOrder(Order order) {
        orders.removeWhere((o) => o.id == order.id);
        saveOrders();
    }

    static Order getOrderById(String id) {
        return orders.firstWhere((o) => o.id == id);
    }

    static Future<void> saveOrders() async {
        await AppStorage.saveOrders();
    }
}

class FolderRepository {
    static final List<Folder> folders = [
        Folder(id: "f1", name: "Default"),
    ];

    static void addFolder(String name) {
        final newId = "f${folders.length + 1}";
        folders.add(
            Folder(
                id: newId,
                name: name,
            ),
        );
    }

    static void removeFolder(Folder folder) {
        folders.remove(folder);

        // Remove all orders that belong to this folder
        OrderRepository.orders.removeWhere(
            (order) => order.folderId == folder.id,
        );

        // Persist updated orders
        OrderRepository.saveOrders();
    }

    static Folder? findById(String id) {
        for (final folder in folders) {
            if (folder.id == id) {
                return folder;
            }
        }
        return null;
    }
}
