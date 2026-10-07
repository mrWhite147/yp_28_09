import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';
import '../core/api_exceptions.dart';

class LoginScreen extends StatefulWidget {
  final String? from;
  const LoginScreen({super.key, this.from});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await context.read<AuthNotifier>().login(_username.text, _password.text);
      if (mounted) {
        context.go(widget.from ?? '/');
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Ошибка соединения');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход в систему')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) 
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.red.shade100,
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                TextField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Логин', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Войти'),
                ),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Нет аккаунта? Зарегистрироваться'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;
  Map<String, String> _serverErrors = {};

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthNotifier>().register(_username.text, _password.text, _fullName.text);
      if (mounted) context.go('/');
    } on ValidationException catch (e) {
      setState(() { _serverErrors = e.errors; });
      _formKey.currentState!.validate();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _username,
                    decoration: InputDecoration(labelText: 'Логин', border: const OutlineInputBorder(), errorText: _serverErrors['username']),
                    validator: (v) => (v == null || v.isEmpty) ? 'Обязательное поле' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullName,
                    decoration: const InputDecoration(labelText: 'ФИО', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Обязательное поле' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Минимум 8 символов';
                      if (!v.contains(RegExp(r'\d'))) return 'Пароль должен содержать цифру';
                      if (!v.contains(RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]'))) return 'Нужен спецсимвол (например @ или !)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Зарегистрироваться'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещен')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text('У вас нет прав для просмотра этой страницы', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Вернуться на главную'),
            ),
          ],
        ),
      ),
    );
  }
}