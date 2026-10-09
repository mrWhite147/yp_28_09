import '../models/models.dart';
import '../models/page_result.dart';
import '../models/queries.dart';
import 'repository_interfaces.dart';
import 'persistent_store_repository.dart';

class InMemoryManufacturerRepository
    implements Repository<Manufacturer, ManufacturerQuery> {
  final PersistentStore store;
  InMemoryManufacturerRepository(this.store);

  @override
  Future<PageResult<Manufacturer>> find(ManufacturerQuery q) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var rows = store.manufacturers
        .where((m) => q.includeDeleted || !m.isDeleted)
        .toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (m) =>
                m.name.toLowerCase().contains(needle) ||
                m.country.toLowerCase().contains(needle),
          )
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'foundedYear' => a.foundedYear.compareTo(b.foundedYear),
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Manufacturer>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<void> restore(int id) async {
    final i = store.manufacturers.indexWhere((m) => m.id == id);
    if (i != -1) {
      store.manufacturers[i] = store.manufacturers[i].copyWith(
        clearDeletedAt: true,
      );
    }
    await store.saveManufacturers();
  }

  @override
  Future<int> deleteMany(List<int> ids, {bool hard = false}) async {
    var count = 0;
    for (final id in ids) {
      store.checkManufacturerDeletable(id);

      if (hard) {
        store.manufacturers.removeWhere((m) => m.id == id);
      } else {
        final i = store.manufacturers.indexWhere(
          (m) => m.id == id && !m.isDeleted,
        );
        if (i != -1) {
          store.manufacturers[i] = store.manufacturers[i].copyWith(
            deletedAt: DateTime.now(),
          );
        }
      }
      count++;
    }
    await store.saveManufacturers();
    return count;
  }
}
