import 'dart:convert';

class ManufactureIngredient {
  final int ingredientId;
  final String ingredientName;
  final int unitId;
  final String unitName;
  final double quantity;
  final double price;

  ManufactureIngredient({
    required this.ingredientId,
    required this.ingredientName,
    required this.unitId,
    required this.unitName,
    required this.quantity,
    required this.price,
  });

  factory ManufactureIngredient.fromJson(Map<String, dynamic> j) =>
      ManufactureIngredient(
        ingredientId:   j['ingredient_id'] is int ? j['ingredient_id'] : int.tryParse('${j['ingredient_id'] ?? 0}') ?? 0,
        ingredientName: j['ingredient_name'] ?? '',
        unitId:         j['unit_id'] is int ? j['unit_id'] : int.tryParse('${j['unit_id'] ?? 0}') ?? 0,
        unitName:       j['unit_name'] ?? '',
        quantity:       (j['quantity'] as num?)?.toDouble() ?? 0,
        price:          (j['price'] as num?)?.toDouble() ?? 0,
      );
}

class ManufactureProduct {
  final int productId;
  final int unitId;
  final double quantity;
  final double costPerItem;

  ManufactureProduct({
    required this.productId,
    required this.unitId,
    required this.quantity,
    required this.costPerItem,
  });

  factory ManufactureProduct.fromJson(Map<String, dynamic> j) =>
      ManufactureProduct(
        productId:   j['product_id'] is int ? j['product_id'] : int.tryParse('${j['product_id'] ?? 0}') ?? 0,
        unitId:      j['unit_id'] is int ? j['unit_id'] : int.tryParse('${j['unit_id'] ?? 0}') ?? 0,
        quantity:    (j['quantity'] as num?)?.toDouble() ?? 0,
        costPerItem: (j['cost_per_item'] as num?)?.toDouble() ?? 0,
      );
}

class Manufacture {
  final int id;
  final String code;
  final String type;
  final String? manufactureDate;
  final String? productsJson;
  final int? totalPrice;
  final int userId;
  final String? createdAt;
  final String? userName;
  final List<ManufactureIngredient>? ingredients;
  final List<ManufactureProduct>? producedProducts;

  Manufacture({
    required this.id,
    required this.code,
    this.type = 'manufacture',
    this.manufactureDate,
    this.productsJson,
    this.totalPrice,
    required this.userId,
    this.createdAt,
    this.userName,
    this.ingredients,
    this.producedProducts,
  });

  factory Manufacture.fromJson(Map<String, dynamic> json) {
    String? prodJson;
    List<ManufactureProduct>? producedProducts;

    if (json['products'] is String) {
      prodJson = json['products'];
      try {
        final list = jsonDecode(prodJson!) as List;
        producedProducts = list.map((e) => ManufactureProduct.fromJson(e)).toList();
      } catch (_) {}
    } else if (json['products'] is List) {
      prodJson = jsonEncode(json['products']);
      producedProducts = (json['products'] as List)
          .map((e) => ManufactureProduct.fromJson(e))
          .toList();
    }

    List<ManufactureIngredient>? ingredients;
    if (json['ingredients'] is List) {
      ingredients = (json['ingredients'] as List)
          .map((e) => ManufactureIngredient.fromJson(e))
          .toList();
    }

    return Manufacture(
      id:              json['id'] ?? 0,
      code:            json['code'] ?? '',
      type:            json['type'] ?? 'manufacture',
      manufactureDate: json['manufacture_date'],
      productsJson:    prodJson,
      totalPrice:      json['total_price'] is num ? (json['total_price'] as num).toInt() : null,
      userId:          json['user_id'] ?? 0,
      createdAt:       json['created_at'],
      userName:        json['user_name'] ?? json['user']?['name'],
      ingredients:     ingredients,
      producedProducts: producedProducts,
    );
  }

  List<Map<String, dynamic>> get productsList {
    if (productsJson == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(productsJson!));
    } catch (_) {
      return [];
    }
  }
}
