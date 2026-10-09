import '../models/models.dart';
import '../models/page_result.dart';
import '../models/queries.dart';
import 'repository_interfaces.dart';
import 'persistent_store_repository.dart';

class InMemoryCustomerRepository
    implements Repository<Customer, CustomerQuery> {
  final PersistentStore store;
  InMemoryCustomerRepository(this.store);

  @override
  Future<PageResult<Customer>> find(CustomerQuery q) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var rows = store.customers
        .where((c) => q.includeDeleted || !c.isDeleted)
        .toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (c) =>
                c.fullName.toLowerCase().contains(needle) ||
                c.email.toLowerCase().contains(needle),
          )
          .toList();
    }

    rows.sort((a, b) {
      final result = a.fullName.toLowerCase().compareTo(
        b.fullName.toLowerCase(),
      );
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Customer>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<void> restore(int id) async {
    final i = store.customers.indexWhere((c) => c.id == id);
    if (i != -1) {
      store.customers[i] = store.customers[i].copyWith(clearDeletedAt: true);
    }
  }

  @override
  Future<int> deleteMany(List<int> ids, {bool hard = false}) async {
    var count = 0;
    for (final id in ids) {
      if (hard) {
        store.customers.removeWhere((c) => c.id == id);
      } else {
        final i = store.customers.indexWhere((c) => c.id == id && !c.isDeleted);
        if (i != -1) {
          store.customers[i] = store.customers[i].copyWith(
            deletedAt: DateTime.now(),
          );
        }
      }
      count++;
    }
    await store.saveCustomers();
    return count;
  }
}
