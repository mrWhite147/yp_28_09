import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/manufacturer_list_screen.dart';
import 'models/models.dart';
import 'models/queries.dart';
import 'state/list_notifier.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/products',
      builder: (context, state) {
        final query = ProductQuery.fromMap(state.uri.queryParameters);
        return ChangeNotifierProvider(
          create: (context) => ListNotifier<Product, ProductQuery>(context.read()), 
          child: ProductListScreen(query: query)
        );
      },
    ),
    GoRoute(
      path: '/manufacturers',
      builder: (context, state) {
        final query = ManufacturerQuery.fromMap(state.uri.queryParameters);
        return ChangeNotifierProvider(
          create: (context) => ListNotifier<Manufacturer, ManufacturerQuery>(context.read()), 
          child: ManufacturerListScreen(query: query)
        );
      },
    ),
  ],
);