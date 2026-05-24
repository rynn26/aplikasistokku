import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/customer.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isLoadingTrx = true, _isLoadingProduk = true, _isLoadingHarga = true;
  Map<String, dynamic> _trxData = {};
  List<Map<String, dynamic>> _produkTerbeli = [];
  List<Map<String, dynamic>> _hargaKhusus = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static const _blue = Color(0xFF00ADEF);
  final _months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  void _loadAll() { _loadTrx(); _loadProduk(); _loadHarga(); }

  Future<void> _loadTrx() async {
    setState(() => _isLoadingTrx = true);
    try {
      final data = await DataService.getCustomerTransactions(
        widget.customer.id,
        month: _selectedMonth,
        year:  _selectedYear,
      );
      if (mounted) setState(() { _trxData = data; _isLoadingTrx = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingTrx = false); }
  }

  Future<void> _loadProduk() async {
    setState(() => _isLoadingProduk = true);
    try {
      final data = await DataService.getCustomerProdukTerbeli(
        widget.customer.id,
        bulan: _selectedMonth,
        tahun: _selectedYear,
      );
      if (mounted) setState(() { _produkTerbeli = data; _isLoadingProduk = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingProduk = false); }
  }

  Future<void> _loadHarga() async {
    setState(() => _isLoadingHarga = true);
    try {
      final data = await DataService.getCustomerHargaKhusus(widget.customer.id);
      if (mounted) setState(() { _hargaKhusus = data; _isLoadingHarga = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingHarga = false); }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: _blue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00C2FF), Color(0xFF0062A8)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0x33FFFFFF),
                          child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                          _typeBadge(c.type),
                        ])),
                        _rewardTierBadge((_trxData['total_omset'] as num?)?.toDouble() ?? 0),
                      ]),
                      const SizedBox(height: 10),
                      if (c.phone != null && c.phone!.isNotEmpty)
                        Row(children: [
                          Expanded(child: _infoRow(Icons.phone_outlined, c.phone!)),
                          GestureDetector(
                            onTap: () {
                              final phone = c.phone!.replaceAll(RegExp(r'[^0-9]'), '');
                              final waNum = phone.startsWith('0') ? '62\${phone.substring(1)}' : phone;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('WA: $waNum'), duration: const Duration(seconds: 2)));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(16)),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.chat_outlined, size: 11, color: Colors.white),
                                SizedBox(width: 4),
                                Text('WA', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                        ]),
                      if (c.address != null && c.address!.isNotEmpty)
                        _infoRow(Icons.location_on_outlined, c.address!),
                    ]),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Transaksi'),
                Tab(text: 'Produk Terbeli'),
                Tab(text: 'Harga Khusus'),
              ],
            ),
          ),
        ],
        body: Column(children: [
          // Month/Year filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF00ADEF)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    ..._months.asMap().entries.map((e) {
                      final mIdx = e.key + 1;
                      final sel = _selectedMonth == mIdx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () { setState(() => _selectedMonth = mIdx); _loadTrx(); _loadProduk(); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel ? _blue : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(e.value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : Colors.grey[500])),
                          ),
                        ),
                      );
                    }),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedYear,
                items: List.generate(4, (i) {
                  final y = DateTime.now().year - i;
                  return DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontSize: 12)));
                }),
                onChanged: (v) { if (v != null) { setState(() => _selectedYear = v); _loadTrx(); _loadProduk(); } },
                underline: const SizedBox.shrink(),
                style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
              ),
            ]),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildTransaksiTab(),
                _buildProdukTab(),
                _buildHargaTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Tab 1: Transaksi ───────────────────────────────────────────────────────
  Widget _buildTransaksiTab() {
    if (_isLoadingTrx) return const Center(child: CircularProgressIndicator(color: _blue));
    final orders = (_trxData['orders'] as List?) ?? [];
    final omset  = (_trxData['total_omset'] as num?)?.toDouble() ?? 0;
    final total  = (_trxData['total_orders'] as num?)?.toInt() ?? 0;

    return RefreshIndicator(
      onRefresh: _loadTrx,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Omset summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00C2FF), Color(0xFF0062A8)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Omset Bulan Ini', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                Text(_currency.format(omset), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('$total Transaksi', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Tidak ada transaksi bulan ini', style: TextStyle(color: Colors.grey[500])),
              ]),
            ))
          else
            ...orders.map((o) {
              final order = o as Map<String, dynamic>;
              final isPaid = order['payment_status'] == 'paid';
              final details = (order['details'] as List?) ?? [];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(order['order_number'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(isPaid ? 'Lunas' : 'Belum Lunas',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: isPaid ? Colors.green[700] : Colors.orange[700])),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(order['order_date'] ?? '-', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...details.take(3).map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(children: [
                        const Icon(Icons.circle, size: 5, color: Color(0xFF00ADEF)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(
                          '${d['product_name']} - ${d['quantity']} ${d['unit'] ?? ''}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis)),
                      ]),
                    )),
                    if (details.length > 3)
                      Text('+${details.length - 3} item lainnya', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  ],
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight,
                    child: Text(_currency.format((order['total_price'] as num?) ?? 0),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF005FA3)))),
                ]),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Tab 2: Produk Terbeli ─────────────────────────────────────────────────
  Widget _buildProdukTab() {
    if (_isLoadingProduk) return const Center(child: CircularProgressIndicator(color: _blue));
    return RefreshIndicator(
      onRefresh: _loadProduk,
      child: _produkTerbeli.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('Belum ada data produk terbeli', style: TextStyle(color: Colors.grey[500])),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _produkTerbeli.length,
              itemBuilder: (_, i) {
                final p = _produkTerbeli[i];
                final maxQty = _produkTerbeli.isNotEmpty
                    ? (_produkTerbeli.map((x) => (x['total_qty'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b))
                    : 1.0;
                final qty = (p['total_qty'] as num?)?.toDouble() ?? 0;
                final pct = maxQty > 0 ? qty / maxQty : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(p['nama_produk'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('${qty.toInt()} pcs', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _blue)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey[200],
                        color: _blue,
                        minHeight: 6,
                      ),
                    ),
                  ]),
                );
              },
            ),
    );
  }

  // ── Tab 3: Harga Khusus ───────────────────────────────────────────────────
  Widget _buildHargaTab() {
    if (_isLoadingHarga) return const Center(child: CircularProgressIndicator(color: _blue));
    return RefreshIndicator(
      onRefresh: _loadHarga,
      child: _hargaKhusus.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.price_change_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('Tidak ada harga khusus\nuntuk pelanggan ini',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500])),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _hargaKhusus.length,
              itemBuilder: (_, i) {
                final h = _hargaKhusus[i];
                final isActive = h['is_active'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                    border: Border(left: BorderSide(
                      color: isActive ? Colors.green[400]! : Colors.grey[300]!,
                      width: 3)),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(h['product_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Harga Khusus', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(_currency.format(h['price'] ?? 0),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF005FA3))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10)),
                        child: Text(isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                            color: isActive ? Colors.green[700] : Colors.grey[600])),
                      ),
                    ]),
                  ]),
                );
              },
            ),
    );
  }

  Widget _rewardTierBadge(double totalOmset) {
    final tier = _getTierInfo(totalOmset);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tier['color'] as Color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(tier['icon'] as IconData, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text(tier['label'] as String,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    );
  }

  Map<String, dynamic> _getTierInfo(double omset) {
    if (omset >= 50000000) return {'label': 'PLATINUM', 'color': const Color(0xFF5C6BC0), 'icon': Icons.diamond_outlined};
    if (omset >= 10000000) return {'label': 'GOLD',     'color': const Color(0xFFFFA000), 'icon': Icons.workspace_premium_outlined};
    if (omset >= 3000000)  return {'label': 'SILVER',   'color': const Color(0xFF78909C), 'icon': Icons.star_outlined};
    return {'label': 'BRONZE', 'color': const Color(0xFF8D6E63), 'icon': Icons.emoji_events_outlined};
  }

  Widget _typeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20)),
      child: Text(type.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(children: [
      Icon(icon, size: 12, color: Colors.white60),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis)),
    ]),
  );
}
