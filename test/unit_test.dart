import 'package:flutter_test/flutter_test.dart';
import 'package:yp_2/utils/validators.dart';
import 'package:yp_2/models/models.dart';
import 'package:yp_2/state/auth_notifier.dart';

void main() {
  group('Валидаторы', () {
    test('Обязательное поле отклоняет пустоту', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
      expect(Validators.required(null), isNotNull);
    });
    test('Обязательное поле принимает текст', () {
      expect(Validators.required('iPhone'), isNull);
    });
    test('Email валидатор', () {
      expect(Validators.email('test@test.com'), isNull);
      expect(Validators.email('invalid-email'), isNotNull);
    });
    test('Положительное число', () {
      expect(Validators.positiveNumber('100'), isNull);
      expect(Validators.positiveNumber('-5'), isNotNull);
      expect(Validators.positiveNumber('abc'), isNotNull);
    });
  });

  group('Модели', () {
    test('Разбор товара (Product) из неполного JSON', () {
      final json = {'id': 1, 'name': 'MacBook'};
      final p = Product.fromJson(json);
      expect(p.price, 0.0);
      expect(p.sku, '');
      expect(p.categoryIds, isEmpty);
    });
  });

  group('Роли и права', () {
    final customer = AppUser(
      id: 1,
      username: 'c',
      fullName: 'c',
      role: Role.customer,
    );
    final admin = AppUser(
      id: 2,
      username: 'a',
      fullName: 'a',
      role: Role.admin,
    );

    test('Покупатель НЕ имеет прав менеджера', () {
      expect(customer.role.level >= Role.manager.level, false);
    });
    test('Админ имеет права менеджера', () {
      expect(admin.role.level >= Role.manager.level, true);
    });
    test('Проверка парсинга роли из строки', () {
      final u = AppUser.fromJson({
        'id': 1,
        'username': 'test',
        'fullName': 't',
        'role': 'admin',
      });
      expect(u.role, Role.admin);
    });
  });
}
