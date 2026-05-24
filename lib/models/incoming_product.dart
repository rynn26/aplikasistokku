class IncomingProduct {
  final int id;
  final String orderNumber;
  final int supplierId;
  final int totalPrice;
  final String status;
  final String paymentStatus;
  final String? paymentDate;
  final String? paymentMethod;
  final String incomingDate;
  final String? dueDate;
  final int userId;
  final String? createdAt;
  final String? supplierName;
  final List<IncomingProductDetail>? details;
  final List<IncomingProductPayment>? payments;

  IncomingProduct({
    required this.id,
    required this.orderNumber,
    required this.supplierId,
    required this.totalPrice,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.paymentDate,
    this.paymentMethod,
    required this.incomingDate,
    this.dueDate,
    required this.userId,
    this.createdAt,
    this.supplierName,
    this.details,
    this.payments,
  });

  factory IncomingProduct.fromJson(Map<String, dynamic> json) {
    List<IncomingProductDetail>? details;
    if (json['details'] != null) {
      details = (json['details'] as List)
          .map((e) => IncomingProductDetail.fromJson(e))
          .toList();
    }
    List<IncomingProductPayment>? payments;
    if (json['payments'] != null) {
      payments = (json['payments'] as List)
          .map((e) => IncomingProductPayment.fromJson(e))
          .toList();
    }
    return IncomingProduct(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      supplierId: json['supplier_id'] ?? 0,
      totalPrice: (json['total_price'] is num)
          ? (json['total_price'] as num).toInt()
          : (double.tryParse('${json['total_price']}')?.toInt() ?? 0),
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      paymentDate: json['payment_date'],
      paymentMethod: json['payment_method'],
      incomingDate: json['incoming_date'] ?? '',
      dueDate: json['due_date'],
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'],
      supplierName: json['supplier']?['name'] ?? json['supplier_name'],
      details: details,
      payments: payments,
    );
  }
}

class IncomingProductDetail {
  final int id;
  final int incomingProductId;
  final int productId;
  final int stock;
  final String unit;
  final double price;
  final int totalPrice;
  final String? productName;

  IncomingProductDetail({
    required this.id,
    required this.incomingProductId,
    required this.productId,
    required this.stock,
    this.unit = 'pcs',
    required this.price,
    required this.totalPrice,
    this.productName,
  });

  factory IncomingProductDetail.fromJson(Map<String, dynamic> json) {
    return IncomingProductDetail(
      id: json['id'] ?? 0,
      incomingProductId: json['incoming_product_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      stock: (json['stock'] is num)
          ? (json['stock'] as num).toInt()
          : (double.tryParse('${json['stock']}')?.toInt() ?? 0),
      unit: json['unit'] ?? 'pcs',
      price: double.tryParse('${json['price']}') ?? 0,
      totalPrice: (json['total_price'] is num)
          ? (json['total_price'] as num).toInt()
          : (double.tryParse('${json['total_price']}')?.toInt() ?? 0),
      productName: json['product']?['name'] ?? json['product_name'],
    );
  }
}

class IncomingProductPayment {
  final int id;
  final int incomingProductId;
  final double amount;
  final String paymentDate;
  final String? paymentMethod;
  final String? notes;
  final int userId;

  IncomingProductPayment({
    required this.id,
    required this.incomingProductId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod,
    this.notes,
    required this.userId,
  });

  factory IncomingProductPayment.fromJson(Map<String, dynamic> json) {
    return IncomingProductPayment(
      id: json['id'] ?? 0,
      incomingProductId: json['incoming_product_id'] ?? 0,
      amount: double.tryParse('${json['amount']}') ?? 0,
      paymentDate: json['payment_date'] ?? '',
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      userId: json['user_id'] ?? 0,
    );
  }
}
