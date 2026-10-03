import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/queries.dart';

class ApiRepository<T> {
  final Dio _dio;
  final String path;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  CancelToken? _cancelToken;

  ApiRepository(this._dio, this.path, this.fromJson, this.toJson);

  Future<PageResult<T>> find(BaseQuery q) async {
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

  Future<void> softDelete(int id) => guard(() => _dio.delete('$path/$id'));
  Future<void> hardDelete(int id) => guard(() => _dio.delete('$path/$id', queryParameters: {'hard': true}));
  Future<void> restore(int id) => guard(() => _dio.post('$path/$id/restore'));

  Future<int> deleteMany(List<int> ids) => guard(() async {
    final res = await _dio.post('$path/bulk-delete', data: {'ids': ids});
    return res.data['deleted'] ?? 0;
  });
}