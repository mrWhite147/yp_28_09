import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../models/queries.dart';
import '../state/list_notifier.dart';
import '../state/auth_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/debounced_search.dart';
import '../widgets/pagination_controls.dart';

class ProductListScreen extends StatefulWidget {
  final ProductQuery query;
  const ProductListScreen({super.key, required this.query});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListNotifier<Product, ProductQuery>>().load(widget.query);
    });
  }

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ListNotifier<Product, ProductQuery>>().load(widget.query);
      });
    }
  }

  void _updateUrl(ProductQuery newQuery) => context.go(
    Uri(path: '/products', queryParameters: newQuery.toMap()).toString(),
  );

  void _confirmDelete(
    BuildContext context,
    ListNotifier<Product, ProductQuery> notifier,
    AuthNotifier auth,
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
          if (auth.hasRole(Role.admin))
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
    final notifier = context.watch<ListNotifier<Product, ProductQuery>>();
    final auth = context.watch<AuthNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Товары'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (auth.hasRole(Role.manager))
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Создать'),
              onPressed: () => context.push('/products/new'),
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
                  width: 250,
                  child: DebouncedSearch(
                    initialValue: widget.query.search,
                    onChanged: (val) => _updateUrl(
                      ProductQuery(
                        search: val,
                        page: 1,
                        size: widget.query.size,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    initialValue: widget.query.priceFrom?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Цена от (₽)',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (val) => _updateUrl(
                      ProductQuery(priceFrom: double.tryParse(val), page: 1),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    initialValue: widget.query.priceTo?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Цена до (₽)',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (val) => _updateUrl(
                      ProductQuery(priceTo: double.tryParse(val), page: 1),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: CheckboxListTile(
                    title: const Text('С удаленными'),
                    value: widget.query.includeDeleted,
                    onChanged: (val) => _updateUrl(
                      ProductQuery(includeDeleted: val ?? false, page: 1),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ),

          if (notifier.hasSelection && auth.hasRole(Role.manager))
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
                    onPressed: () => _confirmDelete(context, notifier, auth),
                  ),
                ],
              ),
            ),

          Expanded(child: _buildBody(notifier, auth)),
        ],
      ),
    );
  }

  Widget _buildBody(
    ListNotifier<Product, ProductQuery> notifier,
    AuthNotifier auth,
  ) {
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
        return const Center(
          child: Text('Ничего не найдено. Попробуйте изменить фильтры.'),
        );
      case LoadStatus.success:
        return Column(
          children: [
            Expanded(
              child: EntityTable<Product>(
                items: notifier.result.items,
                idOf: (p) => p.id,
                isDeletedOf: (p) => p.isDeleted,
                selected: notifier.selected,
                onToggleSelect: auth.hasRole(Role.manager)
                    ? notifier.toggleSelection
                    : null,
                sortField: widget.query.sortField,
                sortAscending: widget.query.sortAscending,
                onSort: (field) => _updateUrl(
                  ProductQuery(
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
                    label: 'Название',
                    sortField: 'name',
                    build: (p) => Text(p.name),
                  ),
                  TableColumnSpec(label: 'Артикул', build: (p) => Text(p.sku)),
                  TableColumnSpec(
                    label: 'Цена (₽)',
                    sortField: 'price',
                    build: (p) => Text('${p.price}'),
                  ),
                  TableColumnSpec(
                    label: 'Остаток',
                    sortField: 'stock',
                    build: (p) => Text('${p.stockCount} шт.'),
                  ),
                ],
                actions: (p) => [
                  if (auth.hasRole(Role.manager))
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => context.push('/products/${p.id}/edit'),
                      tooltip: 'Редактировать',
                    ),
                  if (p.isDeleted && auth.hasRole(Role.admin))
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: () => notifier.restore(p.id, widget.query),
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
                  ProductQuery(
                    page: p,
                    size: widget.query.size,
                    search: widget.query.search,
                    sortField: widget.query.sortField,
                    sortAscending: widget.query.sortAscending,
                  ),
                ),
                onSizeChanged: (s) => _updateUrl(
                  ProductQuery(
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
