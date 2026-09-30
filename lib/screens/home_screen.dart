import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Магазин Электроники')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.devices), 
              label: const Text('Каталог товаров'), 
              onPressed: () => context.go('/products'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.business), 
              label: const Text('Производители'), 
              onPressed: () => context.go('/manufacturers'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.people), 
              label: const Text('Покупатели'), 
              onPressed: () => context.go('/customers'),
            ),
          ],
        ),
      ),
    );
  }
}