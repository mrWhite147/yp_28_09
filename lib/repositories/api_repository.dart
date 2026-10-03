import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/queries.dart';
import 'repository_interfaces.dart';

class ApiRepository<T, Q extends BaseQuery> implements Repository<T, Q> {
  final Dio _dio;
  final String path;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  CancelToken? _cancelToken;

  ApiRepository(this._dio, this.path, this.fromJson, this.toJson);

  @override
  Future<PageResult<T>> find(Q q) async {
    _cancelToken?.cancel('Новый запрос перекрыл старый');
    _cancelToken = CancelToken();

    return guard(() async {
      final res = await _dio.get(path, queryParameters: q.toMap(), cancelToken: _cancelToken);
      final data = res.data as Map<String, dynamic>;
      return PageResult(
        items: (data['items'] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList(),
        page: data['page'] ?? 1, size: data['size'] ?? 10, total: data['total'] ?? 0,
      );
    });
  }

  @override
  Future<void> restore(int id) => guard(() => _dio.post('$path/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids, {bool hard = false}) => guard(() async {
    final res = await _dio.post('$path/bulk-delete', data: {'ids': ids});
    return res.data['deleted'] ?? 0;
  });

  Future<T> findById(int id) => guard(() async {
    final res = await _dio.get('$path/$id');
    return fromJson(res.data);
  });

  Future<T> create(T item) => guard(() async {
    final res = await _dio.post(path, data: toJson(item));
    return fromJson(res.data);
  });

  Future<T> update(int id, T item) => guard(() async {
    final res = await _dio.put('$path/$id', data: toJson(item));
    return fromJson(res.data);
  });
}