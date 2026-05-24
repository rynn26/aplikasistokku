class Supplier {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  final String? createdAt;
  final String? updatedAt;

  Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'],
      address: json['address'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'address': address,
  };
}
