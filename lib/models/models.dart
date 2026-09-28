class Product {
  final int id;
  final String name;
  final String sku;
  final double price;
  final int stockCount;
  final int manufacturerId;
  final List<int> categoryIds;
  final DateTime? deletedAt;

  const Product({
    required this.id, required this.name, required this.sku,
    required this.price, required this.stockCount, required this.manufacturerId,
    required this.categoryIds, this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    String? name, String? sku, double? price, int? stockCount,
    int? manufacturerId, List<int>? categoryIds, DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Product(
      id: id,
      name: name ?? this.name, sku: sku ?? this.sku,
      price: price ?? this.price, stockCount: stockCount ?? this.stockCount,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      categoryIds: categoryIds ?? this.categoryIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}

class Manufacturer {
  final int id;
  final String name;
  final int foundedYear;
  final String country;
  final DateTime? deletedAt;

  const Manufacturer({
    required this.id, required this.name,
    required this.foundedYear, required this.country, this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Manufacturer copyWith({String? name, int? foundedYear, String? country, DateTime? deletedAt, bool clearDeletedAt = false}) {
    return Manufacturer(
      id: id, name: name ?? this.name,
      foundedYear: foundedYear ?? this.foundedYear, country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}