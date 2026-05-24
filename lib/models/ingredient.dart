class Ingredient {
  final int id;
  final String name;
  final String type;
  final int categoryId;
  final int unitId;
  final double? price;
  final double? stock;
  final String? deletedAt;
  final String? createdAt;
  final String? categoryName;
  final String? unitName;

  Ingredient({
    required this.id,
    required this.name,
    required this.type,
    required this.categoryId,
    required this.unitId,
    this.price,
    this.stock,
    this.deletedAt,
    this.createdAt,
    this.categoryName,
    this.unitName,
  });

  bool get isDeleted => deletedAt != null;

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'barang',
      categoryId: json['category_id'] ?? 0,
      unitId: json['unit_id'] ?? 0,
      price: double.tryParse('${json['price']}'),
      stock: double.tryParse('${json['stock']}'),
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      categoryName: json['category']?['name'] ?? json['category_name'],
      unitName: json['unit']?['name'] ?? json['unit_name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'category_id': categoryId,
    'unit_id': unitId,
    'price': price,
    'stock': stock,
  };
}

