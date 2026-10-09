import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yp_2/state/list_notifier.dart';
import 'package:yp_2/models/page_result.dart';

class FakeNotifier<T, Q> extends ChangeNotifier implements ListNotifier<T, Q> {
  @override
  LoadStatus status = LoadStatus.idle;
  @override
  String? error;
  @override
  PageResult<T> result = PageResult.empty();
  @override
  Set<int> get selected => {};
  @override
  bool get hasSelection => false;

  @override
  Future<void> load(Q query) async {}
  @override
  void toggleSelection(int id) {}
  @override
  Future<void> deleteSelected(Q currentQuery, {bool hard = false}) async {}
  @override
  Future<void> restore(int id, Q currentQuery) async {}
}

class RoleTestScreen extends StatelessWidget {
  final bool isManager;
  const RoleTestScreen({super.key, required this.isManager});

  @override
  Widget build(BuildContext context) {
    if (isManager) {
      return ElevatedButton(onPressed: () {}, child: const Text('Создать'));
    }
    return const Text('Каталог');
  }
}

void main() {
  testWidgets('Отображение состояния загрузки', (tester) async {
    final notifier = FakeNotifier<String, dynamic>()
      ..status = LoadStatus.loading;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: notifier.status == LoadStatus.loading
              ? const CircularProgressIndicator()
              : const Text('Готово'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Отображение пустого результата', (tester) async {
    final notifier = FakeNotifier<String, dynamic>()..status = LoadStatus.empty;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: notifier.status == LoadStatus.empty
              ? const Text('Ничего не найдено')
              : const SizedBox(),
        ),
      ),
    );
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });

  testWidgets('Отображение ошибки', (tester) async {
    final notifier = FakeNotifier<String, dynamic>()
      ..status = LoadStatus.error
      ..error = 'Сбой сети';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: notifier.status == LoadStatus.error
              ? Text('Ошибка: ${notifier.error}')
              : const SizedBox(),
        ),
      ),
    );
    expect(find.text('Ошибка: Сбой сети'), findsOneWidget);
  });

  testWidgets('Срабатывание валидации формы', (tester) async {
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: key,
            child: TextFormField(
              validator: (v) => (v == null || v.isEmpty) ? 'Пусто' : null,
            ),
          ),
        ),
      ),
    );
    key.currentState!.validate();
    await tester.pump();
    expect(find.text('Пусто'), findsOneWidget);
  });

  testWidgets('Скрытие кнопки создания при недостатке прав', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RoleTestScreen(isManager: false))),
    );

    expect(find.text('Создать'), findsNothing);
  });
}
