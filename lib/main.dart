import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'router.dart';
import 'repositories/persistent_store_repository.dart';
import 'repositories/repository_interfaces.dart';
import 'repositories/in_memory_product_repository.dart';
import 'repositories/in_memory_manufacturer_repository.dart';
import 'repositories/in_memory_customer_repository.dart';
import 'models/models.dart';
import 'models/queries.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  
  usePathUrlStrategy(); 
  final prefs = await SharedPreferences.getInstance();  
  final store = PersistentStore(prefs);

  runApp(
    MultiProvider(
      providers: [
        Provider<PersistentStore>.value(value: store),        
        Provider<Repository<Product, ProductQuery>>(
          create: (context) => InMemoryProductRepository(context.read<PersistentStore>()), 
        ),
        
        Provider<Repository<Manufacturer, ManufacturerQuery>>(
          create: (context) => InMemoryManufacturerRepository(context.read<PersistentStore>()),
        ),
        
        Provider<Repository<Customer, CustomerQuery>>(
          create: (context) => InMemoryCustomerRepository(context.read<PersistentStore>()),
        ),
      ],
      child: const StoreApp(),
    ),
  );
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Магазин Электроники',
      debugShowCheckedModeBanner: false, // Убирает красную плашку "DEBUG"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}