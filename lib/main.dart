import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_client.dart';
import 'repositories/api_repository.dart';
import 'repositories/repository_interfaces.dart';
import 'models/models.dart';
import 'models/queries.dart';
import 'state/auth_notifier.dart';
import 'widgets/inactivity_watcher.dart';
import 'router.dart';

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

  final prefs = await SharedPreferences.getInstance();

  late AuthNotifier authNotifier;
  final dio = buildDio(getAuth: () => authNotifier);
  authNotifier = AuthNotifier(prefs, dio);

  await authNotifier.restore();

  final router = buildRouter(authNotifier);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
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

        ChangeNotifierProxyProvider<Repository<Manufacturer, ManufacturerQuery>, DictionaryCache>(
          create: (context) => DictionaryCache(context.read<Repository<Manufacturer, ManufacturerQuery>>()),
          update: (context, manRepo, prev) => (prev ?? DictionaryCache(manRepo))..loadOnce(),
        ),
      ],
      child: StoreApp(router: router),
    ),
  );
}

class StoreApp extends StatelessWidget {
  final RouterConfig<Object> router;
  const StoreApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Магазин Электроники API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
      builder: (context, child) {
        return InactivityWatcher(
          onLogout: () {
            context.read<AuthNotifier>().logout();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Сессия завершена из-за неактивности')),
            );
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}