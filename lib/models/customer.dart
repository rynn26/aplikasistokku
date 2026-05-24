class Customer {
  final int id;
  final String name;
  final String type;
  final String? phone;
  final String? address;
  final String? createdAt;
  final String? updatedAt;
  final List<CustomerProductPrice>? productPrices;

  Customer({
    required this.id,
    required this.name,
    this.type = 'customer',
    this.phone,
    this.address,
    this.createdAt,
    this.updatedAt,
    this.productPrices,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    List<CustomerProductPrice>? prices;
    if (json['product_prices'] != null) {
      prices = (json['product_prices'] as List)
          .map((e) => CustomerProductPrice.fromJson(e))
          .toList();
    }
    return Customer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'customer',
      phone: json['phone'],
      address: json['address'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      productPrices: prices,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'phone': phone,
    'address': address,
  };
}

class CustomerProductPrice {
  final int id;
  final int customerId;
  final int productId;
  final double price;
  final bool isActive;
  final String? productName;

  CustomerProductPrice({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.price,
    this.isActive = true,
    this.productName,
  });

  factory CustomerProductPrice.fromJson(Map<String, dynamic> json) {
    return CustomerProductPrice(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      price: double.tryParse('${json['price']}') ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      productName: json['product']?['name'],
    );
  }
}
