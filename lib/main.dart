import "package:flutter/material.dart";
import "screens/order_list_screen.dart";
import "repositories.dart";

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await AppStorage.init();
    runApp(const MyApp());
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
