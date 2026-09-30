import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ValidationException implements Exception {
  final String field;
  final String message;
  ValidationException(this.field, this.message);
}

class PersistentStore {
  final SharedPreferences prefs;
  PersistentStore(this.prefs) { _init(); }

  List<Product> products = [];
  List<Manufacturer> manufacturers = [];
  List<Category> categories = [];
  List<Supplier> suppliers = [];
  List<Customer> customers = [];

  void _init() {
    _load<Manufacturer>('manufacturers_v1', (j) => Manufacturer.fromJson(j), (v) => manufacturers = v, [
      const Manufacturer(id: 1, name: 'Samsung', foundedYear: 1938, country: 'Южная Корея'),
      const Manufacturer(id: 2, name: 'Apple', foundedYear: 1976, country: 'США'),
    ]);
    _load<Category>('categories_v1', (j) => Category.fromJson(j), (v) => categories = v, [
      const Category(id: 1, name: 'Смартфоны'), const Category(id: 2, name: 'Флагманы'),
    ]);
    _load<Supplier>('suppliers_v1', (j) => Supplier.fromJson(j), (v) => suppliers = v, [
      const Supplier(id: 1, name: 'ООО ТехноТрейд', contactEmail: 'info@techno.ru'),
    ]);
    _load<Product>('products_v1', (j) => Product.fromJson(j), (v) => products = v, [
      const Product(id: 1, name: 'iPhone 15', sku: 'APL-15', price: 90000, stockCount: 10, manufacturerId: 2, categoryIds: [1,2], supplierIds: [1]),
    ]);
    _load<Customer>('customers_v1', (j) => Customer.fromJson(j), (v) => customers = v, []);
  }

  void _load<T>(String key, T Function(Map<String, dynamic>) fromJson, void Function(List<T>) setList, List<T> seed) {
    final raw = prefs.getString(key);
    if (raw == null) { setList([...seed]); return; }
    try {
      final list = jsonDecode(raw) as List;
      setList(list.map((e) => fromJson(e as Map<String, dynamic>)).toList());
    } catch (e) {
      setList([...seed]);
    }
  }

  Future<void> saveProducts() async => prefs.setString('products_v1', jsonEncode(products.map((e) => e.toJson()).toList()));
  Future<void> saveManufacturers() async => prefs.setString('manufacturers_v1', jsonEncode(manufacturers.map((e) => e.toJson()).toList()));
  Future<void> saveCustomers() async => prefs.setString('customers_v1', jsonEncode(customers.map((e) => e.toJson()).toList()));

  void checkManufacturerDeletable(int id) {
    final linked = products.where((p) => p.manufacturerId == id && !p.isDeleted).length;
    if (linked > 0) throw ValidationException('', 'Невозможно удалить: связано с товарами ($linked шт.)');
  }

  void validateProductUnique(Product p) {
    if (products.any((exist) => exist.sku == p.sku && exist.id != p.id && !exist.isDeleted)) {
      throw ValidationException('sku', 'Товар с таким артикулом уже существует');
    }
  }

  void validateCustomerUnique(Customer c) {
    if (customers.any((exist) => exist.email == c.email && exist.id != c.id && !exist.isDeleted)) {
      throw ValidationException('email', 'Покупатель с таким email уже существует');
    }
  }
}