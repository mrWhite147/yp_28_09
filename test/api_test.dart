import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:yp_2/core/api_exceptions.dart';
import 'package:yp_2/repositories/api_repository.dart';
import 'package:yp_2/models/models.dart';

@GenerateNiceMocks([MockSpec<Dio>()])
import 'api_test.mocks.dart'; 

void main() {
  late MockDio mockDio;
  late ApiRepository<Product> repo;

  setUp(() {
    mockDio = MockDio();
    repo = ApiRepository(mockDio, '/products', Product.fromJson, (p) => p.toJson());
  });

  test('Успешное получение товара (200 OK)', () async {
    when(mockDio.get('/products/1')).thenAnswer((_) async => Response(
      requestOptions: RequestOptions(path: ''),
      data: {'id': 1, 'name': 'Тест', 'sku': '123', 'price': 100, 'stockCount': 10, 'manufacturerId': 1, 'categoryIds': [], 'supplierIds': []},
      statusCode: 200,
    ));

    final product = await repo.findById(1);
    expect(product.name, 'Тест');
  });

  test('Ошибка 404 превращается в NotFoundException', () async {
    when(mockDio.get('/products/99')).thenThrow(DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.badResponse,
      error: const NotFoundException('Запись не найдена.'),
    ));

    expect(() => repo.findById(99), throwsA(isA<NotFoundException>()));
  });

  test('Разбор ошибки 422 (ValidationException)', () async {
    final validationError = ValidationException('Ошибка валидации', {'sku': 'SKU занят'});
    when(mockDio.post('/products', data: anyNamed('data'))).thenThrow(DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.badResponse,
      error: validationError,
    ));

    try {
      await repo.create(const Product(id: 0, name: '', sku: '123', price: 0, stockCount: 0, manufacturerId: 0, categoryIds: [], supplierIds: []));
    } catch (e) {
      expect(e, isA<ValidationException>());
      expect((e as ValidationException).errors['sku'], 'SKU занят');
    }
  });

  test('Сетевая ошибка (ConnectionError)', () async {
    when(mockDio.get('/products/1')).thenThrow(DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.connectionError,
    ));

    expect(() => repo.findById(1), throwsA(isA<NetworkException>()));
  });
}