import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'repositories/repository_interfaces.dart';
import 'repositories/in_memory_product_repository.dart';
import 'repositories/in_memory_manufacturer_repository.dart';
import 'models/models.dart';
import 'models/queries.dart';

void main() {
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        Provider<Repository<Product, ProductQuery>>(create: (_) => InMemoryProductRepository()),
        Provider<Repository<Manufacturer, ManufacturerQuery>>(create: (_) => InMemoryManufacturerRepository()),
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}