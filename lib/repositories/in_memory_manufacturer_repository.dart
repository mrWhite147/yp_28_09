import '../models/models.dart';
import '../models/page_result.dart';
import '../models/queries.dart';
import 'repository_interfaces.dart';

final List<Manufacturer> seedManufacturers = [
  const Manufacturer(id: 1, name: 'Samsung', foundedYear: 1938, country: 'Южная Корея'),
  const Manufacturer(id: 2, name: 'Apple', foundedYear: 1976, country: 'США'),
  const Manufacturer(id: 3, name: 'Sony', foundedYear: 1946, country: 'Япония'),
  const Manufacturer(id: 4, name: 'LG', foundedYear: 1947, country: 'Южная Корея'),
  const Manufacturer(id: 5, name: 'Asus', foundedYear: 1989, country: 'Тайвань'),
  const Manufacturer(id: 6, name: 'Lenovo', foundedYear: 1984, country: 'Китай'),
  const Manufacturer(id: 7, name: 'HP', foundedYear: 1939, country: 'США'),
  const Manufacturer(id: 8, name: 'Dell', foundedYear: 1984, country: 'США'),
];

class InMemoryManufacturerRepository implements Repository<Manufacturer, ManufacturerQuery> {
  final List<Manufacturer> _manufacturers = [...seedManufacturers];

  @override
  Future<PageResult<Manufacturer>> find(ManufacturerQuery q) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var rows = _manufacturers.where((m) => q.includeDeleted || !m.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((m) => m.name.toLowerCase().contains(needle) || m.country.toLowerCase().contains(needle)).toList();
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
    final i = _manufacturers.indexWhere((m) => m.id == id);
    if (i != -1) _manufacturers[i] = _manufacturers[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids, {bool hard = false}) async {
    var count = 0;
    for (final id in ids) {
      if (hard) _manufacturers.removeWhere((m) => m.id == id);
      else {
        final i = _manufacturers.indexWhere((m) => m.id == id && !m.isDeleted);
        if (i != -1) _manufacturers[i] = _manufacturers[i].copyWith(deletedAt: DateTime.now());
      }
      count++;
    }
    return count;
  }
}