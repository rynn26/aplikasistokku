class Product {
  final int id;
  final int categoryId;
  final String name;
  final String? slug;
  final String? image;
  final double basePrice;
  final double unitPrice;
  final double grosirPrice;
  final double resellerPrice;
  final int stock;
  final int? weight;
  final String status;
  final bool isManufacture;
  final int? unitId;
  final String? categoryName;
  final String? unitName;
  final String? createdAt;
  final String? updatedAt;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    this.slug,
    this.image,
    required this.basePrice,
    required this.unitPrice,
    this.grosirPrice = 0,
    this.resellerPrice = 0,
    required this.stock,
    this.weight,
    this.status = 'active',
    this.isManufacture = false,
    this.unitId,
    this.categoryName,
    this.unitName,
    this.createdAt,
    this.updatedAt,
  });

  /// Stok rendah jika <= 5 (threshold tetap)
  bool get isLowStock => stock <= 5;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'],
      image: json['image'],
      basePrice: double.tryParse('${json['base_price']}') ?? 0,
      unitPrice: double.tryParse('${json['unit_price']}') ?? 0,
      grosirPrice: double.tryParse('${json['grosir_price']}') ?? 0,
      resellerPrice: double.tryParse('${json['reseller_price']}') ?? 0,
      stock: (json['stock'] is num)
          ? (json['stock'] as num).toInt()
          : (double.tryParse('${json['stock']}')?.toInt() ?? 0),
      weight: json['weight'],
      status: json['status'] ?? 'active',
      isManufacture: json['is_manufacture'] == 1 || json['is_manufacture'] == true,
      unitId: json['unit_id'],
      categoryName: json['category']?['name'] ?? json['category_name'],
      unitName: json['unit']?['name'] ?? json['unit_name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'name': name,
    'base_price': basePrice,
    'unit_price': unitPrice,
    'grosir_price': grosirPrice,
    'reseller_price': resellerPrice,
    'stock': stock,
    'weight': weight,
    'status': status,
    'is_manufacture': isManufacture ? 1 : 0,
    'unit_id': unitId,
  };
}
