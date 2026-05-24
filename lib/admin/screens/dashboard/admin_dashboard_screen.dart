import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';
import '../../../models/product.dart';
import '../../../models/order.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  int _totalProducts = 0;
  int _totalCustomers = 0;
  int _totalSuppliers = 0;
  int _totalOrders = 0;
  double _totalRevenue = 0;
  double _totalExpenses = 0;
  double _monthlyProfit = 0;
  double _todaySales = 0;
  int _totalManufactures = 0;
  List<Order> _recentOrders = [];
  List<Product> _lowStockProducts = [];
  DateTime _selectedDate = DateTime.now();

  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Gunakan dashboard endpoint + hanya 5 order terbaru (jauh lebih cepat)
      final results = await Future.wait([
        DataService.getDashboardData(
          month: _selectedDate.month,
          year: _selectedDate.year,
          date: _selectedDate.toIso8601String().split('T')[0],
        ),
        DataService.getOrders(limit: 5),
      ]);

      final dash   = results[0] as Map<String, dynamic>;
      final orders = results[1] as List<Order>;

      if (mounted) {
        setState(() {
          _totalProducts    = (dash['total_products']  as num?)?.toInt()    ?? 0;
          _totalCustomers   = (dash['total_customers'] as num?)?.toInt()    ?? 0;
          _totalSuppliers   = (dash['total_suppliers'] as num?)?.toInt()    ?? 0;
          _totalOrders      = (dash['total_orders']    as num?)?.toInt()    ?? 0;
          _totalRevenue     = (dash['monthly_revenue'] as num?)?.toDouble() ?? 0;
          _totalExpenses    = (dash['monthly_expenses'] as num?)?.toDouble() ?? 0;
          _monthlyProfit    = (dash['monthly_profit'] as num?)?.toDouble() ?? 0;
          _todaySales       = (dash['today_sales'] as num?)?.toDouble() ?? 0;
          _totalManufactures = (dash['total_manufactures'] as num?)?.toInt() ?? 0;
          _recentOrders     = orders;
          // Low stock dari dashboard
          final lowRaw = dash['low_stock_products'] as List? ?? [];
          _lowStockProducts = lowRaw.map((e) => Product(
            id: e['id'] ?? 0,
            categoryId: 0,
            name: e['name'] ?? '',
            basePrice: 0,
            unitPrice: 0,
            stock: (e['stock'] as num?)?.toInt() ?? 0,
            status: 'active',
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ADEF)))
            : RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF00ADEF),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo, ${auth.currentUser?.name ?? 'Admin'} 👋',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF00ADEF), // header background color
                                onPrimary: Colors.white, // header text color
                                onSurface: Colors.black, // body text color
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF00ADEF), // button text color
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                        });
                        _loadData();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFE0F7FF), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.calendar_month_outlined, color: Color(0xFF00ADEF)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Highlight Cards
              _buildHighlightCards(),
              const SizedBox(height: 24),

              // Stats Grid — 3 kolom atas, 3 kolom bawah
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard('Produk', '$_totalProducts', Icons.inventory_2_outlined, Colors.indigo),
                  _buildStatCard('Pelanggan', '$_totalCustomers', Icons.people_outline, Colors.teal),
                  _buildStatCard('Supplier', '$_totalSuppliers', Icons.local_shipping_outlined, Colors.orange),
                  _buildStatCard('Transaksi', '$_totalOrders', Icons.receipt_long_outlined, const Color(0xFF00ADEF)),
                  _buildStatCard('Produksi', '$_totalManufactures', Icons.precision_manufacturing_outlined, Colors.purple),
                  _buildStatCard('Pengeluaran', _currencyFormat.format(_totalExpenses), Icons.money_off_csred_outlined, Colors.redAccent, compact: true),
                ],
              ),
              const SizedBox(height: 24),

              // Low Stock Alert
              if (_lowStockProducts.isNotEmpty) ...[
                _sectionTitle('⚠️ Stok Rendah (${_lowStockProducts.length} produk)'),
                const SizedBox(height: 12),
                ..._lowStockProducts.take(5).map((p) => _buildLowStockItem(p)),
                const SizedBox(height: 24),
              ],

              // Recent Orders
              _sectionTitle('Transaksi Terbaru'),
              const SizedBox(height: 12),
              if (_recentOrders.isEmpty)
                const Center(child: Text('Belum ada transaksi', style: TextStyle(color: Colors.grey)))
              else
                ..._recentOrders.map((o) => _buildOrderItem(o)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Highlight Cards ────────────────────────────────
  Widget _buildHighlightCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.8,
      children: [
        _buildHighlightCard('Profit Bulanan', _currencyFormat.format(_monthlyProfit), const Color(0xFFF43F5E)), // Merah
        _buildHighlightCard('Omset Hari Ini', _currencyFormat.format(_todaySales), const Color(0xFFFACC15)), // Kuning
        _buildHighlightCard('Omset Bulan Ini', _currencyFormat.format(_totalRevenue), const Color(0xFF4ADE80)), // Hijau
        _buildHighlightCard('Total Pelanggan', '$_totalCustomers', const Color(0xFF0EA5E9)), // Biru
      ],
    );
  }

  Widget _buildHighlightCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)));

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool compact = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
          ]),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: compact ? 13 : 20, fontWeight: FontWeight.w800, color: color)),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildLowStockItem(Product p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Min. stok: 5', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
            child: Text('Stok: ${p.stock}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Order o) {
    Color statusColor = o.paymentStatus == 'paid' ? Colors.green : (o.paymentStatus == 'partial' ? Colors.orange : Colors.red);
    String statusLabel = o.paymentStatus == 'paid' ? 'Lunas' : (o.paymentStatus == 'partial' ? 'Sebagian' : 'Belum Bayar');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.orderNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(o.customerName ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_currencyFormat.format(o.totalPrice), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
