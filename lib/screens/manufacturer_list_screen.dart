import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../models/queries.dart';
import '../state/list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/debounced_search.dart';
import '../widgets/pagination_controls.dart';

class ManufacturerListScreen extends StatefulWidget {
  final ManufacturerQuery query;
  const ManufacturerListScreen({super.key, required this.query});

  @override
  State<ManufacturerListScreen> createState() => _ManufacturerListScreenState();
}

class _ManufacturerListScreenState extends State<ManufacturerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListNotifier<Manufacturer, ManufacturerQuery>>().load(widget.query);
    });
  }

  @override
  void didUpdateWidget(covariant ManufacturerListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ListNotifier<Manufacturer, ManufacturerQuery>>().load(widget.query);
      });
    }
  }

  void _updateUrl(ManufacturerQuery newQuery) => context.go(Uri(path: '/manufacturers', queryParameters: newQuery.toMap()).toString());

  void _confirmDelete(BuildContext context, ListNotifier<Manufacturer, ManufacturerQuery> notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление'),
        content: Text('Удалить выбранные элементы (${notifier.selected.length} шт.)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () { notifier.deleteSelected(widget.query, hard: false); Navigator.pop(ctx); },
            child: const Text('В корзину'),
          ),
          TextButton(
            onPressed: () { notifier.deleteSelected(widget.query, hard: true); Navigator.pop(ctx); },
            child: const Text('Удалить навсегда', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ListNotifier<Manufacturer, ManufacturerQuery>>();

    return Scaffold(
      appBar: AppBar(title: const Text('Производители'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 16, runSpacing: 16, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(width: 300, child: DebouncedSearch(initialValue: widget.query.search, onChanged: (val) => _updateUrl(ManufacturerQuery(search: val, page: 1, size: widget.query.size)))),
                SizedBox(width: 200, child: CheckboxListTile(title: const Text('С удаленными'), value: widget.query.includeDeleted, onChanged: (val) => _updateUrl(ManufacturerQuery(includeDeleted: val ?? false, page: 1)), controlAffinity: ListTileControlAffinity.leading)),
              ],
            ),
          ),
          
          if (notifier.hasSelection)
            Container(
              color: Colors.blue.shade50, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('Выбрано: ${notifier.selected.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  FilledButton.icon(icon: const Icon(Icons.delete), label: const Text('Удалить'), style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => _confirmDelete(context, notifier)),
                ],
              ),
            ),

          Expanded(child: _buildBody(notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(ListNotifier<Manufacturer, ManufacturerQuery> notifier) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading: return const Center(child: CircularProgressIndicator());
      case LoadStatus.error: return Center(child: Text('Ошибка: ${notifier.error}', style: const TextStyle(color: Colors.red)));
      case LoadStatus.empty: return const Center(child: Text('Ничего не найдено.'));
      case LoadStatus.success:
        return Column(
          children: [
            Expanded(
              child: EntityTable<Manufacturer>(
                items: notifier.result.items, idOf: (m) => m.id, isDeletedOf: (m) => m.isDeleted,
                selected: notifier.selected, onToggleSelect: notifier.toggleSelection,
                sortField: widget.query.sortField, sortAscending: widget.query.sortAscending,
                onSort: (field) => _updateUrl(ManufacturerQuery(sortField: field, sortAscending: field == widget.query.sortField ? !widget.query.sortAscending : true, page: 1, size: widget.query.size)),
                columns: [
                  TableColumnSpec(label: 'Название', sortField: 'name', build: (m) => Text(m.name)),
                  TableColumnSpec(label: 'Страна', sortField: 'country', build: (m) => Text(m.country)),
                  TableColumnSpec(label: 'Год основания', sortField: 'foundedYear', build: (m) => Text('${m.foundedYear}')),
                ],
                actions: (m) => [
                  if (m.isDeleted) IconButton(icon: const Icon(Icons.restore), onPressed: () => notifier.restore(m.id, widget.query), tooltip: 'Восстановить')
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: PaginationControls(
                page: notifier.result.page, totalPages: notifier.result.totalPages,
                totalItems: notifier.result.total, size: notifier.result.size,
                hasPrevious: notifier.result.hasPrevious, hasNext: notifier.result.hasNext,
                onPageChanged: (p) => _updateUrl(ManufacturerQuery(page: p, size: widget.query.size, search: widget.query.search, sortField: widget.query.sortField, sortAscending: widget.query.sortAscending)),
                onSizeChanged: (s) => _updateUrl(ManufacturerQuery(size: s, page: 1, search: widget.query.search, sortField: widget.query.sortField, sortAscending: widget.query.sortAscending)),
              ),
            ),
          ],
        );
    }
  }
}