import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../models/product.dart';
import '../models/order.dart';
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isLoading = true;
  bool _hasError  = false;
  String _errorMsg = '';
  int _totalProducts = 0;
  int _totalCustomers = 0;
  int _totalOrders = 0;
  double _revenue = 0;
  List<Order> _recentOrders = [];
  List<Product> _lowStock = [];
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const _cyan = Color(0xFF00ADEF);
  static const _dark = Color(0xFF005FA3);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final results = await Future.wait([
        DataService.getDashboardData(),
        DataService.getOrders(limit: 10),
      ]);
      final dash   = results[0] as Map<String, dynamic>;
      final orders = results[1] as List<Order>;

      if (mounted) setState(() {
        _totalProducts  = (dash['total_products'] as num?)?.toInt() ?? 0;
        _totalCustomers = (dash['total_customers'] as num?)?.toInt() ?? 0;
        _totalOrders    = (dash['today_orders']   as num?)?.toInt() ?? 0;
        _revenue        = (dash['today_sales']    as num?)?.toDouble() ?? 0;
        _recentOrders   = orders.take(10).toList();
        final lowRaw = dash['low_stock_products'] as List? ?? [];
        _lowStock = lowRaw.map((e) => Product(
          id: e['id'] ?? 0, categoryId: 0, name: e['name'] ?? '',
          basePrice: 0, unitPrice: 0,
          stock: (e['stock'] as num?)?.toInt() ?? 0, status: 'active',
        )).take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _hasError  = true;
        _errorMsg  = e.toString().contains('TimeoutException')
            ? 'Koneksi ke server timeout.\nPastikan internet aktif dan coba lagi.'
            : 'Gagal memuat data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final name = auth.currentUser?.name ?? 'Kasir';
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Selamat Pagi' : (now.hour < 17 ? 'Selamat Siang' : 'Selamat Malam');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _cyan));
    }
    if (_hasError) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Gagal Memuat Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(_errorMsg, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyan, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ));
    }
    return RefreshIndicator(
            onRefresh: _load,
            color: _cyan,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // ── Greeting ──────────────────────────────────────────────
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$greeting,', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ])),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_cyan, _dark]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Revenue Card dengan motif ─────────────────────────────
                _buildRevenueCard(),
                const SizedBox(height: 16),

                // ── Stats ─────────────────────────────────────────────────
                Row(children: [
                  _statCard('Produk', '$_totalProducts', Icons.inventory_2_outlined, Colors.indigo),
                  const SizedBox(width: 10),
                  _statCard('Pelanggan', '$_totalCustomers', Icons.people_outline, _cyan),
                  const SizedBox(width: 10),
                  _statCard('Order', '$_totalOrders', Icons.receipt_long_outlined, Colors.orange),
                ]),
                const SizedBox(height: 24),

                // ── Low Stock ─────────────────────────────────────────────
                if (_lowStock.isNotEmpty) ...[
                  _sectionHeader('⚠️  Stok Menipis', '${_lowStock.length} produk'),
                  const SizedBox(height: 10),
                  ..._lowStock.map((p) => _lowStockItem(p)),
                  const SizedBox(height: 20),
                ],

                // ── Recent Orders ─────────────────────────────────────────
                _sectionHeader('Transaksi Terbaru', '${_recentOrders.length} terakhir'),
                const SizedBox(height: 10),
                if (_recentOrders.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Belum ada transaksi', style: TextStyle(color: Colors.grey[400])),
                  ))
                else
                  ..._recentOrders.map((o) => _orderItem(o)),
              ],
            ),
          );
  }

  // ── Revenue Card ─────────────────────────────────────────────────────────
  Widget _buildRevenueCard() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00C2FF), Color(0xFF0062A8)],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _cyan.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(children: [
        // Dekorasi lingkaran besar kanan atas
        Positioned(right: -25, top: -25, child: Container(
          width: 120, height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)),
        )),
        // Lingkaran outline
        Positioned(left: 80, top: 8, child: Container(
          width: 55, height: 55,
          decoration: BoxDecoration(shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5)),
        )),
        // Garis diagonal kanan
        Positioned(right: 30, top: 0, child: Transform.rotate(
          angle: -math.pi / 4,
          child: Container(width: 100, height: 1, color: Colors.white.withOpacity(0.08)),
        )),
        // Pola titik kanan bawah
        Positioned(right: 16, bottom: 12, child: CustomPaint(
          size: const Size(70, 50),
          painter: _DotPainter(color: Colors.white.withOpacity(0.1)),
        )),
        // Konten
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 13),
              ),
              const SizedBox(width: 8),
              const Text('PENDAPATAN HARI INI', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
            ]),
            const SizedBox(height: 8),
            Text(_currency.format(_revenue),
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Row(children: [
              _badge(Icons.check_circle_outline, '$_totalOrders Lunas'),
              const SizedBox(width: 8),
              _badge(Icons.storefront_outlined, '$_totalProducts Produk'),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _badge(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.12)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white70, size: 11),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    ]),
  );

  // ── Stat Card ────────────────────────────────────────────────────────────
  Widget _statCard(String title, String value, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  // ── Section Header ───────────────────────────────────────────────────────
  Widget _sectionHeader(String title, String sub) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFE0F7FF), borderRadius: BorderRadius.circular(20)),
        child: Text(sub, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _cyan)),
      ),
    ],
  );

  // ── Low Stock Item ───────────────────────────────────────────────────────
  Widget _lowStockItem(Product p) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.orange[50],
      borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: Colors.orange[400]!, width: 3)),
    ),
    child: Row(children: [
      Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(p.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(20)),
        child: Text('${p.stock} sisa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.orange[800])),
      ),
    ]),
  );

  // ── Order Item ───────────────────────────────────────────────────────────
  Widget _orderItem(Order o) {
    final isPaid = o.paymentStatus == 'paid';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: isPaid ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(isPaid ? Icons.check_circle_outline : Icons.schedule_rounded,
              color: isPaid ? Colors.green[600] : Colors.orange[600], size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(o.orderNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          Text(o.customerName ?? '-', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_currency.format(o.totalPrice),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(isPaid ? 'Lunas' : 'Pending',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                    color: isPaid ? Colors.green[700] : Colors.orange[700])),
          ),
        ]),
      ]),
    );
  }
}

// ── Dot painter ─────────────────────────────────────────────────────────────
class _DotPainter extends CustomPainter {
  final Color color;
  const _DotPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..style = PaintingStyle.fill;
    const sp = 11.0;
    for (double x = 0; x <= size.width; x += sp) {
      for (double y = 0; y <= size.height; y += sp) {
        canvas.drawCircle(Offset(x, y), 1.8, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter o) => o.color != color;
}
