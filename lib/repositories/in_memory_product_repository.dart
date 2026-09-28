import '../models/models.dart';
import '../models/page_result.dart';
import '../models/queries.dart';
import 'repository_interfaces.dart';

final List<Product> seedProducts = List.generate(25, (i) => Product(
  id: i + 1, name: 'Смартфон Модель ${i + 1} Pro', sku: 'ELEC-00${i+1}',
  price: 15000.0 + (i * 1200), stockCount: 50 - i, manufacturerId: (i % 5) + 1,
  categoryIds: [(i % 3) + 1],
));

class InMemoryProductRepository implements Repository<Product, ProductQuery> {
  final List<Product> _products = [...seedProducts];

  @override
  Future<PageResult<Product>> find(ProductQuery q) async {
    await Future.delayed(const Duration(milliseconds: 200)); 
    var rows = _products.where((p) => q.includeDeleted || !p.isDeleted).toList();

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
    final i = _products.indexWhere((p) => p.id == id);
    if (i != -1) _products[i] = _products[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids, {bool hard = false}) async {
    var count = 0;
    for (final id in ids) {
      if (hard) {
        _products.removeWhere((p) => p.id == id);
        count++;
      } else {
        final i = _products.indexWhere((p) => p.id == id && !p.isDeleted);
        if (i != -1) {
          _products[i] = _products[i].copyWith(deletedAt: DateTime.now());
          count++;
        }
      }
    }
    return count;
  }
}