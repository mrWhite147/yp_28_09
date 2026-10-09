import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalItems;
  final int size;
  final bool hasPrevious;
  final bool hasNext;
  final void Function(int page) onPageChanged;
  final void Function(int size) onSizeChanged;

  const PaginationControls({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.size,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page),
          onPressed: hasPrevious ? () => onPageChanged(1) : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: hasPrevious ? () => onPageChanged(page - 1) : null,
        ),
        Text('Стр. $page из $totalPages (Всего: $totalItems)'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: hasNext ? () => onPageChanged(page + 1) : null,
        ),
        IconButton(
          icon: const Icon(Icons.last_page),
          onPressed: hasNext ? () => onPageChanged(totalPages) : null,
        ),
        const SizedBox(width: 16),
        DropdownButton<int>(
          value: size,
          items: [10, 25, 50]
              .map((s) => DropdownMenuItem(value: s, child: Text('$s шт.')))
              .toList(),
          onChanged: (s) => onSizeChanged(s!),
        ),
      ],
    );
  }
}
