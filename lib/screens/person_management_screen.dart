import "package:flutter/material.dart";

import "../repositories.dart";

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
