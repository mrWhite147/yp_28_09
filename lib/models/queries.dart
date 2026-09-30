abstract class BaseQuery {
  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const BaseQuery({
    this.search = '', required this.sortField, this.sortAscending = true,
    this.page = 1, this.size = 10, this.includeDeleted = false,
  });

  Map<String, String> toMap();
}

class ProductQuery extends BaseQuery {
  final int? categoryId;
  final int? manufacturerId;
  final double? priceFrom;
  final double? priceTo;

  const ProductQuery({
    super.search, super.sortField = 'name', super.sortAscending, super.page, super.size, super.includeDeleted,
    this.categoryId, this.manufacturerId, this.priceFrom, this.priceTo,
  });

  factory ProductQuery.fromMap(Map<String, String> map) => ProductQuery(
    search: map['search'] ?? '', sortField: map['sort'] ?? 'name',
    sortAscending: map['asc'] != 'false', page: int.tryParse(map['page'] ?? '1') ?? 1,
    size: int.tryParse(map['size'] ?? '10') ?? 10, includeDeleted: map['del'] == 'true',
    categoryId: int.tryParse(map['cat'] ?? ''), manufacturerId: int.tryParse(map['man'] ?? ''),
    priceFrom: double.tryParse(map['pf'] ?? ''), priceTo: double.tryParse(map['pt'] ?? ''),
  );

  @override
  Map<String, String> toMap() => {
    if (search.isNotEmpty) 'search': search, if (sortField != 'name') 'sort': sortField,
    if (!sortAscending) 'asc': 'false', if (page > 1) 'page': page.toString(),
    if (size != 10) 'size': size.toString(), if (includeDeleted) 'del': 'true',
    if (categoryId != null) 'cat': categoryId.toString(), if (manufacturerId != null) 'man': manufacturerId.toString(),
    if (priceFrom != null) 'pf': priceFrom.toString(), if (priceTo != null) 'pt': priceTo.toString(),
  };
}

class ManufacturerQuery extends BaseQuery {
  const ManufacturerQuery({super.search, super.sortField = 'name', super.sortAscending, super.page, super.size, super.includeDeleted});

  factory ManufacturerQuery.fromMap(Map<String, String> map) => ManufacturerQuery(
    search: map['search'] ?? '', sortField: map['sort'] ?? 'name',
    sortAscending: map['asc'] != 'false', page: int.tryParse(map['page'] ?? '1') ?? 1,
    size: int.tryParse(map['size'] ?? '10') ?? 10, includeDeleted: map['del'] == 'true',
  );
  
  @override
  Map<String, String> toMap() => {
    if (search.isNotEmpty) 'search': search, if (sortField != 'name') 'sort': sortField,
    if (!sortAscending) 'asc': 'false', if (page > 1) 'page': page.toString(),
    if (size != 10) 'size': size.toString(), if (includeDeleted) 'del': 'true',
  }; 
}

class CustomerQuery extends BaseQuery {
  const CustomerQuery({super.search, super.sortField = 'fullName', super.sortAscending, super.page, super.size, super.includeDeleted});

  factory CustomerQuery.fromMap(Map<String, String> map) => CustomerQuery(
    search: map['search'] ?? '', sortField: map['sort'] ?? 'fullName',
    sortAscending: map['asc'] != 'false', page: int.tryParse(map['page'] ?? '1') ?? 1,
    size: int.tryParse(map['size'] ?? '10') ?? 10, includeDeleted: map['del'] == 'true',
  );
  
  @override
  Map<String, String> toMap() => {
    if (search.isNotEmpty) 'search': search, if (sortField != 'fullName') 'sort': sortField,
    if (!sortAscending) 'asc': 'false', if (page > 1) 'page': page.toString(),
    if (size != 10) 'size': size.toString(), if (includeDeleted) 'del': 'true',
  };
}
