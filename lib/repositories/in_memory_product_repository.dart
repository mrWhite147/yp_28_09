import '../models/models.dart';
import '../models/page_result.dart';
import '../models/queries.dart';
import 'repository_interfaces.dart';
import 'persistent_store_repository.dart';

class InMemoryProductRepository implements Repository<Product, ProductQuery> {
  final PersistentStore store;
  InMemoryProductRepository(this.store);

  @override
  Future<PageResult<Product>> find(ProductQuery q) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // ТЕПЕРЬ МЫ БЕРЕМ ДАННЫЕ ИЗ ХРАНИЛИЩА!
    var rows = store.products.where((p) => q.includeDeleted || !p.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((p) => p.name.toLowerCase().contains(needle) || p.sku.toLowerCase().contains(needle)).toList();
    }
    if (q.categoryId != null) rows = rows.where((p) => p.categoryIds.contains(q.categoryId)).toList();
    if (q.manufacturerId != null) rows = rows.where((p) => p.manufacturerId == q.manufacturerId).toList();
    if (q.priceFrom != null) rows = rows.where((p) => p.price >= q.priceFrom!).toList();
    if (q.priceTo != null) rows = rows.where((p) => p.price <= q.priceTo!).toList();

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'price' => a.price.compareTo(b.price),
        'stock' => a.stockCount.compareTo(b.stockCount),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Product>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<void> restore(int id) async {
    final i = store.products.indexWhere((p) => p.id == id);
    if (i != -1) store.products[i] = store.products[i].copyWith(clearDeletedAt: true);
    await store.saveProducts(); // Сохраняем
  }

  @override
  Future<int> deleteMany(List<int> ids, {bool hard = false}) async {
    var count = 0;
    for (final id in ids) {
      if (hard) {
        store.products.removeWhere((p) => p.id == id);
        count++;
      } else {
        final i = store.products.indexWhere((p) => p.id == id && !p.isDeleted);
        if (i != -1) {
          store.products[i] = store.products[i].copyWith(deletedAt: DateTime.now());
          count++;
        }
      }
    }
    await store.saveProducts(); // Сохраняем
    return count;
  }
}