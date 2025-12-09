import "package:flutter/material.dart";

/// Simple person model
class Person {
    Person({
        required this.id,
        required this.name,
    });

    final String id;
    String name;

    factory Person.fromJson(Map<String, dynamic> json) {
        return Person(
            id: json["id"] as String,
            name: json["name"] as String,
        );
    }

    Map<String, dynamic> toJson() {
        return {
            "id": id,
            "name": name,
        };
    }
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

    factory ItemOptionDefinition.fromJson(Map<String, dynamic> json) {
        return ItemOptionDefinition(
            id: json["id"] as String,
            name: json["name"] as String,
            price: (json["price"] as num).toDouble(),
        );
    }

    Map<String, dynamic> toJson() {
        return {
            "id": id,
            "name": name,
            "price": price,
        };
    }
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

    factory ItemDefinition.fromJson(Map<String, dynamic> json) {
        final List<dynamic> rawOptions =
            (json["options"] as List<dynamic>?) ?? [];
        return ItemDefinition(
            id: json["id"] as String,
            name: json["name"] as String,
            price: (json["price"] as num).toDouble(),
            options: rawOptions
                .map(
                    (e) => ItemOptionDefinition.fromJson(
                        e as Map<String, dynamic>,
                    ),
                )
                .toList(),
        );
    }

    Map<String, dynamic> toJson() {
        return {
            "id": id,
            "name": name,
            "price": price,
            "options": options.map((o) => o.toJson()).toList(),
        };
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

    factory OrderItem.fromJson(Map<String, dynamic> json) {
        return OrderItem(
            amount: json["amount"] as int,
            itemId: json["itemId"] as String,
            personName: json["personName"] as String,
            optionIds: (json["optionIds"] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
        );
    }

    Map<String, dynamic> toJson() {
        return {
            "amount": amount,
            "itemId": itemId,
            "personName": personName,
            "optionIds": optionIds,
        };
    }
}

/// Represents one order for a specific date
class Order {
    Order({
        required this.id,
        required this.date,
        required this.items,
        this.folderId,
        String? title,
        Map<String, PaymentStatus>? personStatuses,
    })  : title = title ?? "",
        personStatuses = personStatuses ?? {};

    final String id;
    final DateTime date;
    final List<OrderItem> items;

    /// Optional folder id (can be null)
    String? folderId;

    /// Editable order title
    String title;

    /// Person name -> PaymentStatus
    final Map<String, PaymentStatus> personStatuses;

    factory Order.fromJson(Map<String, dynamic> json) {
        // Items
        final List<dynamic> rawItems =
            (json["items"] as List<dynamic>?) ?? [];

        // Payment statuses (may be missing in older data)
        final Map<String, dynamic>? rawStatuses =
            json["personStatuses"] as Map<String, dynamic>?;

        final Map<String, PaymentStatus> decodedStatuses = {};
        if (rawStatuses != null) {
            rawStatuses.forEach((key, value) {
                if (value is String) {
                    final status = PaymentStatus.values.firstWhere(
                        (s) => s.name == value,
                        orElse: () => PaymentStatus.unsent,
                    );
                    decodedStatuses[key] = status;
                }
            });
        }

        // Old data might not have id or date
        final dynamic rawId = json["id"];
        final String id = rawId?.toString() ?? "";

        final String? dateStr = json["date"] as String?;
        final DateTime date = dateStr != null
            ? DateTime.parse(dateStr)
            : DateTime.now();

        // folderId is optional and might not exist in older data
        String? folderId;
        if (json.containsKey("folderId") && json["folderId"] != null) {
            folderId = json["folderId"].toString();
        }

        final String title =
            json.containsKey("title") && json["title"] != null
                ? json["title"].toString()
                : "";

        return Order(
            id: id,
            date: date,
            items: rawItems
                .map(
                    (e) => OrderItem.fromJson(
                        e as Map<String, dynamic>,
                    ),
                )
                .toList(),
            folderId: folderId,
            title: title,
            personStatuses: decodedStatuses,
        );
    }

    Map<String, dynamic> toJson() {
        return {
            "id": id,
            "date": date.toIso8601String(),
            "items": items.map((i) => i.toJson()).toList(),
            "personStatuses": personStatuses.map(
                (key, value) => MapEntry(key, value.name),
            ),
            "folderId": folderId,
            "title": title,
        };
    }
}

/// Data needed for Table 3 (not stored, just derived)
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

/// Folder to group orders
class Folder {
    Folder({
        required this.id,
        required this.name,
    });

    final String id;
    String name;

    factory Folder.fromJson(Map<String, dynamic> json) {
        return Folder(
            id: json["id"] as String,
            name: json["name"] as String,
        );
    }

    Map<String, dynamic> toJson() {
        return {
            "id": id,
            "name": name,
        };
    }
}
