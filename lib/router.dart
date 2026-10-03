import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yp_2/screens/customer_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/manufacturer_list_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/customer_form_screen.dart';
import 'models/models.dart';
import 'models/queries.dart';
import 'state/list_notifier.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),

    GoRoute(
      path: '/products',
      builder: (context, state) {
        final query = ProductQuery.fromMap(state.uri.queryParameters);
        return ChangeNotifierProvider(
          create: (context) => ListNotifier<Product, ProductQuery>(context.read()),
          child: ProductListScreen(query: query),
        );
      },
    ),
    
    GoRoute(
      path: '/manufacturers',
      builder: (context, state) {
        final query = ManufacturerQuery.fromMap(state.uri.queryParameters);
        return ChangeNotifierProvider(
          create: (context) => ListNotifier<Manufacturer, ManufacturerQuery>(context.read()),
          child: ManufacturerListScreen(query: query),
        );
      },
    ),

    // --- ФОРМЫ (без PersistentStore, так как теперь данные идут через API) ---
    GoRoute(
      path: '/products/new',
      builder: (context, state) => const ProductFormScreen(),
    ),
    GoRoute(
      path: '/products/:id/edit',
      builder: (context, state) {
        final idParam = state.pathParameters['id'] ?? '';
        return ProductFormScreen(
          id: int.tryParse(idParam),
        );
      },
    ),

    GoRoute(
      path: '/customers',
      builder: (context, state) {
        final query = CustomerQuery.fromMap(state.uri.queryParameters);
        return ChangeNotifierProvider(
          create: (context) => ListNotifier<Customer, CustomerQuery>(context.read()), 
          child: CustomerListScreen(query: query)
        );
      },
    ),
    
    GoRoute(
      path: '/customers/new',
      builder: (context, state) => const CustomerFormScreen(),
    ),
    GoRoute(
      path: '/customers/:id/edit',
      builder: (context, state) {
        final idParam = state.pathParameters['id'] ?? '';
        return CustomerFormScreen(
          id: int.tryParse(idParam),
        );
      },
    ),
  ],
);