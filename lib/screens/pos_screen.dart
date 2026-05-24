import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/product.dart';
import '../models/customer.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _CartItem {
  final Product product;
  int quantity;
  _CartItem({required this.product}) : quantity = 1;
  double get total => product.unitPrice * quantity;
}

class _POSScreenState extends State<POSScreen> {
  bool _isLoading = true;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Customer> _customers = [];
  
  Customer? _selectedCustomer;
  final List<_CartItem> _cart = [];
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  static const _cyan = Color(0xFF00ADEF);

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DataService.getProducts(),
        DataService.getCustomers(),
      ]);
      
      if (mounted) {
        setState(() {
          _products = results[0] as List<Product>;
          _filteredProducts = List.from(_products);
          _customers = results[1] as List<Customer>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredProducts = _products.where((p) => 
        p.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        if (_cart[existingIndex].quantity < product.stock) {
          _cart[existingIndex].quantity++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok tidak mencukupi')));
        }
      } else {
        if (product.stock > 0) {
          _cart.add(_CartItem(product: product));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok habis')));
        }
      }
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = _cart[index].quantity + delta;
      if (newQty > 0) {
        if (newQty <= _cart[index].product.stock) {
          _cart[index].quantity = newQty;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok tidak mencukupi')));
        }
      } else {
        _cart.removeAt(index);
      }
    });
  }

  double get _cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keranjang kosong')));
      return;
    }
    
    // Bottom sheet for checkout confirmation
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Konfirmasi Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  
                  // Customer Selection
                  const Text('Pilih Pelanggan (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Customer>(
                    value: _selectedCustomer,
                    decoration: InputDecoration(
                      filled: true, fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    hint: const Text('Pilih Pelanggan'),
                    items: [
                      const DropdownMenuItem<Customer>(value: null, child: Text('Pelanggan Umum')),
                      ..._customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    ],
                    onChanged: (val) {
                      setModalState(() => _selectedCustomer = val);
                      setState(() => _selectedCustomer = val); // Also update parent state
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tagihan:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(_currency.format(_cartTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _cyan)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _processOrder(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyan,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Buat Pesanan & Bayar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Future<void> _processOrder(BuildContext ctx) async {
    // Pre-capture messenger BEFORE any await (safe for async gaps)
    final messenger = ScaffoldMessenger.of(context);

    // Show loading
    showDialog(context: ctx, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final orderData = {
        'customer_id': _selectedCustomer?.id,
        'order_date': DateTime.now().toIso8601String().split('T')[0],
        'payment_method': 'cash',
        'details': _cart.map((item) => {
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.unitPrice,
        }).toList(),
      };
      
      final res = await DataService.createOrder(orderData);
      
      // Close loading dialog
      if (ctx.mounted) Navigator.pop(ctx);
      
      if (res.success) {
        if (ctx.mounted) Navigator.pop(ctx); // Close bottom sheet
        messenger.showSnackBar(const SnackBar(content: Text('Pesanan berhasil dibuat'), backgroundColor: Colors.green));
        if (mounted) {
          setState(() {
            _cart.clear();
            _selectedCustomer = null;
          });
          _loadData();
        }
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'Gagal membuat pesanan'),
          backgroundColor: Colors.red));
      }
    } catch (e) {
      if (ctx.mounted) Navigator.pop(ctx); // Close loading
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart_outlined, color: _cyan),
                  SizedBox(width: 10),
                  Text('Keranjang Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cart.length,
                    separatorBuilder: (_, __) => const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                    itemBuilder: (ctx, i) {
                      final item = _cart[i];
                      return Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.inventory_2, color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(_currency.format(item.product.unitPrice), style: const TextStyle(color: _cyan, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () {
                                    setModalState(() { _updateQuantity(i, -1); });
                                    setState(() {});
                                    if (_cart.isEmpty) Navigator.pop(ctx);
                                  },
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                ),
                                Container(
                                  width: 24, alignment: Alignment.center,
                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () {
                                    setModalState(() { _updateQuantity(i, 1); });
                                    setState(() {});
                                  },
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          )
                        ],
                      );
                    },
                  );
                }
              ),
            ),
            // Checkout button at bottom
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tagihan', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600)),
                      Text(_currency.format(_cartTotal), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _cyan)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _checkout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyan,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Lanjut Pembayaran', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(int crossAxisCount) {
    return _filteredProducts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Produk tidak ditemukan', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // extra padding for bottom cart
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (ctx, i) {
              final p = _filteredProducts[i];
              final isOut = p.stock <= 0;
              // Check if item in cart
              final cartItemIndex = _cart.indexWhere((c) => c.product.id == p.id);
              final qtyInCart = cartItemIndex >= 0 ? _cart[cartItemIndex].quantity : 0;
              
              return GestureDetector(
                onTap: isOut ? null : () => _addToCart(p),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: isOut ? Colors.red.withOpacity(0.3) : Colors.grey.shade100),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Text(_currency.format(p.unitPrice), style: const TextStyle(fontWeight: FontWeight.w900, color: _cyan, fontSize: 14)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Stok: ${p.stock}', style: TextStyle(fontSize: 12, color: isOut ? Colors.red : Colors.grey[500])),
                                    if (qtyInCart > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: _cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                        child: Text('x$qtyInCart', style: const TextStyle(color: _cyan, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      if (isOut)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text('HABIS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _filterProducts,
          decoration: InputDecoration(
            hintText: 'Cari nama produk...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: _cyan),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 20, color: Colors.grey), onPressed: () { _searchCtrl.clear(); _filterProducts(''); })
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _cyan),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text('Transaksi Kasir', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _cyan))
        : isTablet
            ? Row(
                children: [
                  // Left: Products
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        Expanded(child: _buildProductGrid(3)), // 3 columns for tablet left side
                      ],
                    ),
                  ),
                  Container(width: 1, color: Colors.grey[200]),
                  // Right: Cart
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            color: Colors.white,
                            child: const Row(
                              children: [
                                Icon(Icons.shopping_cart_outlined, color: _cyan),
                                SizedBox(width: 12),
                                Expanded(child: Text('Keranjang Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: _cart.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
                                        const SizedBox(height: 16),
                                        Text('Belum ada pesanan', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _cart.length,
                                    separatorBuilder: (_, __) => const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                    itemBuilder: (ctx, i) {
                                      final item = _cart[i];
                                      return Row(
                                        children: [
                                          Container(
                                            width: 50, height: 50,
                                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                                            child: Icon(Icons.inventory_2, color: Colors.grey[400]),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                const SizedBox(height: 4),
                                                Text(_currency.format(item.product.unitPrice), style: const TextStyle(color: _cyan, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[200]!),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove, size: 16),
                                                  onPressed: () => _updateQuantity(i, -1),
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                  padding: EdgeInsets.zero,
                                                ),
                                                Container(
                                                  width: 24, alignment: Alignment.center,
                                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add, size: 16),
                                                  onPressed: () => _updateQuantity(i, 1),
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      );
                                    },
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Tagihan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
                                    Text(_currency.format(_cartTotal), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _cyan)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _cart.isEmpty ? null : _checkout,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _cyan,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      disabledBackgroundColor: Colors.grey[300],
                                    ),
                                    child: const Text('Checkout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildSearchBar(),
                  Expanded(child: _buildProductGrid(2)), // 2 columns for mobile
                ],
              ),
      bottomNavigationBar: (!isTablet && _cart.isNotEmpty && !_isLoading)
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_cart.length} item', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          Text(_currency.format(_cartTotal), style: const TextStyle(color: _cyan, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCartSheet(context),
                      icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                      label: const Text('Lihat Keranjang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyan,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
