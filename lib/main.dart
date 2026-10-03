import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import 'core/api_client.dart';
import 'repositories/api_repository.dart';
import 'repositories/repository_interfaces.dart';
import 'models/models.dart';
import 'models/queries.dart';
import 'router.dart';

// Кэш справочников
class DictionaryCache extends ChangeNotifier {
  final Repository<Manufacturer, ManufacturerQuery> manRepo;
  List<Manufacturer> manufacturers = [];

  DictionaryCache(this.manRepo);

  Future<void> loadOnce() async {
    if (manufacturers.isEmpty) {
      final result = await manRepo.find(const ManufacturerQuery(size: 100));
      manufacturers = result.items;
      notifyListeners();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); 

  final dio = buildDio();

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),        
        ProxyProvider<Dio, Repository<Product, ProductQuery>>(
          update: (context, d, prev) => ApiRepository<Product, ProductQuery>(d, '/products', Product.fromJson, (p) => p.toJson()),
        ),
        ProxyProvider<Dio, Repository<Manufacturer, ManufacturerQuery>>(
          update: (context, d, prev) => ApiRepository<Manufacturer, ManufacturerQuery>(d, '/manufacturers', Manufacturer.fromJson, (m) => m.toJson()),
        ),
        ProxyProvider<Dio, Repository<Customer, CustomerQuery>>(
          update: (context, d, prev) => ApiRepository<Customer, CustomerQuery>(d, '/customers', Customer.fromJson, (c) => c.toJson()),
        ),

        // Кэш справочников
        ChangeNotifierProxyProvider<Repository<Manufacturer, ManufacturerQuery>, DictionaryCache>(
          create: (context) => DictionaryCache(context.read<Repository<Manufacturer, ManufacturerQuery>>()),
          update: (context, manRepo, prev) => (prev ?? DictionaryCache(manRepo))..loadOnce(),
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
      title: 'Магазин Электроники API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}