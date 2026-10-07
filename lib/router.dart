import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'state/auth_notifier.dart';
import 'state/list_notifier.dart';
import 'models/models.dart';
import 'models/queries.dart';
import 'screens/auth_screens.dart';
import 'screens/home_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/manufacturer_list_screen.dart';
import 'screens/customer_list_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/customer_form_screen.dart';
import 'package:flutter/material.dart';
final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/register';

      if (!loggedIn && !isAuthRoute) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }

      if (loggedIn && isAuthRoute) {
        return '/';
      }

      final isForm = path.endsWith('/new') || path.contains('/edit');
      if (isForm && !auth.hasRole(Role.manager)) {
        return '/forbidden';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),

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
        path: '/products/new',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/products/:id/edit',
        builder: (context, state) {
          return ProductFormScreen(id: int.tryParse(state.pathParameters['id'] ?? ''));
        },
      ),
      GoRoute(
        path: '/customers/new',
        builder: (context, state) => const CustomerFormScreen(),
      ),
      GoRoute(
        path: '/customers/:id/edit',
        builder: (context, state) {
          return CustomerFormScreen(id: int.tryParse(state.pathParameters['id'] ?? ''));
        },
      ),
    ],
  );
}