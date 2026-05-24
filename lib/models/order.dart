class Order {
  final int id;
  final int customerId;
  final String orderNumber;
  final int totalPrice;
  final int shippingCost;
  final String status;
  final String? paymentMethod;
  final String paymentStatus;
  final String orderDate;
  final String? paymentDate;
  final String? notes;
  final int userId;
  final String? createdAt;
  final String? customerName;
  final String? userName;
  final List<OrderDetail>? details;
  final List<OrderPayment>? payments;

  Order({
    required this.id,
    required this.customerId,
    required this.orderNumber,
    required this.totalPrice,
    this.shippingCost = 0,
    this.status = 'pending',
    this.paymentMethod,
    this.paymentStatus = 'unpaid',
    required this.orderDate,
    this.paymentDate,
    this.notes,
    required this.userId,
    this.createdAt,
    this.customerName,
    this.userName,
    this.details,
    this.payments,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderDetail>? details;
    if (json['details'] != null || json['order_details'] != null) {
      final detailList = json['details'] ?? json['order_details'];
      details = (detailList as List).map((e) => OrderDetail.fromJson(e)).toList();
    }
    List<OrderPayment>? payments;
    if (json['payments'] != null || json['order_payments'] != null) {
      final paymentList = json['payments'] ?? json['order_payments'];
      payments = (paymentList as List).map((e) => OrderPayment.fromJson(e)).toList();
    }
    return Order(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      totalPrice: json['total_price'] ?? 0,
      shippingCost: json['shipping_cost'] ?? 0,
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'] ?? 'unpaid',
      orderDate: json['order_date'] ?? '',
      paymentDate: json['payment_date'],
      notes: json['notes'],
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'],
      customerName: json['customer']?['name'] ?? json['customer_name'],
      userName: json['user']?['name'] ?? json['user_name'],
      details: details,
      payments: payments,
    );
  }

  Map<String, dynamic> toJson() => {
    'customer_id': customerId,
    'order_date': orderDate,
    'shipping_cost': shippingCost,
    'notes': notes,
    'payment_method': paymentMethod,
  };

  double get totalPaid {
    if (payments == null) return 0;
    return payments!.fold(0.0, (sum, p) => sum + p.amount);
  }

  double get remaining => totalPrice - totalPaid;
}

class OrderDetail {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final String unit;
  final double price;
  final int totalPrice;
  final String? productName;

  OrderDetail({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    this.unit = 'pcs',
    required this.price,
    required this.totalPrice,
    this.productName,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? 'pcs',
      price: double.tryParse('${json['price']}') ?? 0,
      totalPrice: json['total_price'] ?? 0,
      productName: json['product']?['name'] ?? json['product_name'],
    );
  }
}

class OrderPayment {
  final int id;
  final int orderId;
  final double amount;
  final String paymentDate;
  final String? paymentMethod;
  final String? notes;
  final int userId;

  OrderPayment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod,
    this.notes,
    required this.userId,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      amount: double.tryParse('${json['amount']}') ?? 0,
      paymentDate: json['payment_date'] ?? '',
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      userId: json['user_id'] ?? 0,
    );
  }
}
