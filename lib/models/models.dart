class Product {
  final int id;
  final String name;
  final String sku;
  final double price;
  final int stockCount;
  final int manufacturerId;
  final List<int> categoryIds;
  final List<int> supplierIds;
  final DateTime? deletedAt;

  const Product({
    required this.id, required this.name, required this.sku, required this.price,
    required this.stockCount, required this.manufacturerId,
    required this.categoryIds, required this.supplierIds, this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    int? id, String? name, String? sku, double? price, int? stockCount, int? manufacturerId,
    List<int>? categoryIds, List<int>? supplierIds, DateTime? deletedAt, bool clearDeletedAt = false,
  }) {
    return Product(
      id: id ?? this.id,  
      name: name ?? this.name, sku: sku ?? this.sku, price: price ?? this.price,
      stockCount: stockCount ?? this.stockCount, manufacturerId: manufacturerId ?? this.manufacturerId,
      categoryIds: categoryIds ?? this.categoryIds, supplierIds: supplierIds ?? this.supplierIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'sku': sku, 'price': price, 'stockCount': stockCount,
    'manufacturerId': manufacturerId, 'categoryIds': categoryIds, 'supplierIds': supplierIds,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    sku: json['sku'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    stockCount: json['stockCount'] as int? ?? 0,
    manufacturerId: json['manufacturerId'] as int? ?? 0,
    categoryIds: (json['categoryIds'] as List?)?.cast<int>() ?? const [],
    supplierIds: (json['supplierIds'] as List?)?.cast<int>() ?? const [],
    deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
  );
}

class Manufacturer {
  final int id;
  final String name;
  final int foundedYear;
  final String country;
  final DateTime? deletedAt;

  const Manufacturer({required this.id, required this.name, required this.foundedYear, required this.country, this.deletedAt});

  bool get isDeleted => deletedAt != null;

  Manufacturer copyWith({String? name, int? foundedYear, String? country, DateTime? deletedAt, bool clearDeletedAt = false}) {
    return Manufacturer(
      id: id, name: name ?? this.name,
      foundedYear: foundedYear ?? this.foundedYear, country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'foundedYear': foundedYear, 'country': country, 'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Manufacturer.fromJson(Map<String, dynamic> json) => Manufacturer(
    id: json['id'] as int, name: json['name'] as String? ?? '',
    foundedYear: json['foundedYear'] as int? ?? 0, country: json['country'] as String? ?? '',
    deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
  );
}

class Category {
  final int id;
  final String name;
  final DateTime? deletedAt;
  const Category({required this.id, required this.name, this.deletedAt});
  bool get isDeleted => deletedAt != null;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'deletedAt': deletedAt?.toIso8601String()};
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as int, name: json['name'] as String? ?? '',
    deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
  );
}

class Supplier {
  final int id;
  final String name;
  final String contactEmail;
  final DateTime? deletedAt;
  const Supplier({required this.id, required this.name, required this.contactEmail, this.deletedAt});
  bool get isDeleted => deletedAt != null;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'contactEmail': contactEmail, 'deletedAt': deletedAt?.toIso8601String()};
  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: json['id'] as int, name: json['name'] as String? ?? '', contactEmail: json['contactEmail'] as String? ?? '',
    deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
  );
}

class DiscountCard {
  final String number;
  final String issuedAt;
  const DiscountCard({required this.number, required this.issuedAt});
  Map<String, dynamic> toJson() => {'number': number, 'issuedAt': issuedAt};
  factory DiscountCard.fromJson(Map<String, dynamic> json) => DiscountCard(
    number: json['number'] as String? ?? '', issuedAt: json['issuedAt'] as String? ?? '',
  );
}

class Customer {
  final int id;
  final String fullName;
  final String email;
  final DiscountCard card;
  final DateTime? deletedAt;

  const Customer({required this.id, required this.fullName, required this.email, required this.card, this.deletedAt});
  
  bool get isDeleted => deletedAt != null;

  Customer copyWith({
    int? id, String? fullName, String? email, DiscountCard? card, 
    DateTime? deletedAt, bool clearDeletedAt = false
  }) {
    return Customer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id, 'fullName': fullName, 'email': email, 'card': card.toJson(), 'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as int, fullName: json['fullName'] as String? ?? '', email: json['email'] as String? ?? '',
    card: DiscountCard.fromJson(json['card'] as Map<String, dynamic>? ?? {}),
    deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
  );
}