class Category {
  final int id;
  final String name;
  final String? description;
  final String status;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.status = 'active',
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'status': status,
  };
}
