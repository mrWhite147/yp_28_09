import '../models/page_result.dart';

abstract interface class Repository<T, Q> {
  Future<PageResult<T>> find(Q query);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids, {bool hard = false});
}