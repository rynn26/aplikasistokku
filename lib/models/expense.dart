class Expense {
  final int id;
  final String description;
  final int qty;
  final int price;
  final int totalPrice;
  final String date;
  final int userId;
  final String? createdAt;
  final String? userName;

  Expense({
    required this.id,
    required this.description,
    required this.qty,
    required this.price,
    required this.totalPrice,
    required this.date,
    required this.userId,
    this.createdAt,
    this.userName,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? 0,
      description: json['description'] ?? '',
      qty: json['qty'] ?? 0,
      price: json['price'] ?? 0,
      totalPrice: json['total_price'] ?? 0,
      date: json['date'] ?? '',
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'],
      userName: json['user']?['name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'qty': qty,
    'price': price,
    'total_price': totalPrice,
    'date': date,
  };
}
