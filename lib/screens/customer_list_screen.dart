import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../models/queries.dart';
import '../state/list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/debounced_search.dart';
import '../widgets/pagination_controls.dart';

class CustomerListScreen extends StatefulWidget {
  final CustomerQuery query;
  const CustomerListScreen({super.key, required this.query});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListNotifier<Customer, CustomerQuery>>().load(widget.query);
    });
  }

  @override
  void didUpdateWidget(covariant CustomerListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ListNotifier<Customer, CustomerQuery>>().load(
          widget.query,
        );
      });
    }
  }

  void _updateUrl(CustomerQuery newQuery) => context.go(
    Uri(path: '/customers', queryParameters: newQuery.toMap()).toString(),
  );

  void _confirmDelete(
    BuildContext context,
    ListNotifier<Customer, CustomerQuery> notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление'),
        content: Text(
          'Удалить выбранные элементы (${notifier.selected.length} шт.)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              notifier.deleteSelected(widget.query, hard: false);
              Navigator.pop(ctx);
            },
            child: const Text('В корзину'),
          ),
          TextButton(
            onPressed: () {
              notifier.deleteSelected(widget.query, hard: true);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Удалить навсегда',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ListNotifier<Customer, CustomerQuery>>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Покупатели'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Создать'),
            onPressed: () => context.push('/customers/new'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: DebouncedSearch(
                    initialValue: widget.query.search,
                    onChanged: (val) => _updateUrl(
                      CustomerQuery(
                        search: val,
                        page: 1,
                        size: widget.query.size,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: CheckboxListTile(
                    title: const Text('С удаленными'),
                    value: widget.query.includeDeleted,
                    onChanged: (val) => _updateUrl(
                      CustomerQuery(includeDeleted: val ?? false, page: 1),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ),

          if (notifier.hasSelection)
            Container(
              color: Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Выбрано: ${notifier.selected.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Удалить'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => _confirmDelete(context, notifier),
                  ),
                ],
              ),
            ),

          Expanded(child: _buildBody(notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(ListNotifier<Customer, CustomerQuery> notifier) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return Center(
          child: Text(
            'Ошибка: ${notifier.error}',
            style: const TextStyle(color: Colors.red),
          ),
        );
      case LoadStatus.empty:
        return const Center(child: Text('Ничего не найдено.'));
      case LoadStatus.success:
        return Column(
          children: [
            Expanded(
              child: EntityTable<Customer>(
                items: notifier.result.items,
                idOf: (c) => c.id,
                isDeletedOf: (c) => c.isDeleted,
                selected: notifier.selected,
                onToggleSelect: notifier.toggleSelection,
                sortField: widget.query.sortField,
                sortAscending: widget.query.sortAscending,
                onSort: (field) => _updateUrl(
                  CustomerQuery(
                    sortField: field,
                    sortAscending: field == widget.query.sortField
                        ? !widget.query.sortAscending
                        : true,
                    page: 1,
                    size: widget.query.size,
                  ),
                ),
                columns: [
                  TableColumnSpec(
                    label: 'ФИО',
                    sortField: 'fullName',
                    build: (c) => Text(c.fullName),
                  ),
                  TableColumnSpec(label: 'Email', build: (c) => Text(c.email)),
                  TableColumnSpec(
                    label: 'Карта лояльности',
                    build: (c) => Text(c.card.number),
                  ),
                ],
                actions: (c) => [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.push('/customers/${c.id}/edit'),
                    tooltip: 'Редактировать',
                  ),
                  if (c.isDeleted)
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: () => notifier.restore(c.id, widget.query),
                      tooltip: 'Восстановить',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: PaginationControls(
                page: notifier.result.page,
                totalPages: notifier.result.totalPages,
                totalItems: notifier.result.total,
                size: notifier.result.size,
                hasPrevious: notifier.result.hasPrevious,
                hasNext: notifier.result.hasNext,
                onPageChanged: (p) => _updateUrl(
                  CustomerQuery(
                    page: p,
                    size: widget.query.size,
                    search: widget.query.search,
                    sortField: widget.query.sortField,
                    sortAscending: widget.query.sortAscending,
                  ),
                ),
                onSizeChanged: (s) => _updateUrl(
                  CustomerQuery(
                    size: s,
                    page: 1,
                    search: widget.query.search,
                    sortField: widget.query.sortField,
                    sortAscending: widget.query.sortAscending,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
