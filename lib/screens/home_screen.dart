import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин Электроники'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Привет, ${user?.fullName ?? 'Гость'}!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти из аккаунта',
            onPressed: () {
              context.read<AuthNotifier>().logout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
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
