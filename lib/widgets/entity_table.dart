import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final Widget Function(T item) build;
  const TableColumnSpec({required this.label, required this.build, this.sortField});
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final bool Function(T item) isDeletedOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key, required this.columns, required this.items, required this.idOf, required this.isDeletedOf,
    this.selected = const {}, this.onToggleSelect, this.sortField, this.sortAscending = true, this.onSort, this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => _buildCard(items[i]),
          );
        }
        
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: columns.indexWhere((c) => c.sortField == sortField).clamp(0, columns.length),
              sortAscending: sortAscending,
              columns: columns.map((c) => DataColumn(
                label: Text(c.label),
                onSort: c.sortField != null ? (col, asc) => onSort?.call(c.sortField!) : null,
              )).toList()..add(const DataColumn(label: Text('Действия'))),
              rows: items.map((item) {
                final isDel = isDeletedOf(item);
                return DataRow(
                  selected: selected.contains(idOf(item)),
                  onSelectChanged: onToggleSelect != null ? (_) => onToggleSelect!(idOf(item)) : null,
                  color: isDel ? WidgetStateProperty.all(Colors.red.shade50) : null,
                  cells: columns.map((c) => DataCell(
                    DefaultTextStyle(style: TextStyle(decoration: isDel ? TextDecoration.lineThrough : null, color: Colors.black), child: c.build(item))
                  )).toList()..add(DataCell(Row(children: actions?.call(item) ?? []))),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(T item) {
    final isDel = isDeletedOf(item);
    return Card(
      color: isDel ? Colors.red.shade50 : null,
      child: ListTile(
        leading: onToggleSelect != null ? Checkbox(value: selected.contains(idOf(item)), onChanged: (_) => onToggleSelect!(idOf(item))) : null,
        title: DefaultTextStyle(style: TextStyle(decoration: isDel ? TextDecoration.lineThrough : null, color: Colors.black), child: columns.first.build(item)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columns.skip(1).map((c) => Row(children: [Text('${c.label}: '), c.build(item)])).toList(),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: actions?.call(item) ?? []),
      ),
    );
  }
}