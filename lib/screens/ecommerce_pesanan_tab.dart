import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/order.dart';

class EcommercePesananTab extends StatefulWidget {
  const EcommercePesananTab({super.key});
  @override
  State<EcommercePesananTab> createState() => _EcommercePesananTabState();
}

class _EcommercePesananTabState extends State<EcommercePesananTab> {
  bool _isLoading = true;
  List<Order> _all = [], _filtered = [];
  String _search = '';
  String _filterStatus = 'semua';
  int _offset = 0;
  static const int _limit = 50;
  bool _hasMore = false;
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static const _blue = Color(0xFF00ADEF);

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({bool reset = true}) async {
    if (reset) { _offset = 0; _all = []; }
    setState(() => _isLoading = true);
    try {
      final data = await DataService.getOrders(
        search: _search.isEmpty ? null : _search,
        limit: _limit,
        offset: _offset,
      );
      if (mounted) setState(() {
        _all.addAll(data);
        _hasMore = data.length >= _limit;
        _applyFilter();
        _isLoading = false;
      });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  void _applyFilter() {
    _filtered = _all.where((o) {
      if (_filterStatus == 'semua') return true;
      if (_filterStatus == 'paid') return o.paymentStatus == 'paid';
      if (_filterStatus == 'unpaid') return o.paymentStatus != 'paid';
      return true;
    }).toList();
  }

  Future<void> _markAsPaid(Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lunasin Pembayaran'),
        content: Text('Tandai order ${order.orderNumber} sebagai lunas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(d, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Lunas'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await DataService.markOrderAsPaid(order.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res.success ? 'Order ${order.orderNumber} dilunasi' : (res.message.isNotEmpty ? res.message : 'Gagal')),
      backgroundColor: res.success ? Colors.green : Colors.red,
    ));
    if (res.success) _load();
  }

  Future<void> _deleteOrder(Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Order', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin hapus order ${order.orderNumber}?\nStok produk akan dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(d, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await DataService.deleteOrder(order.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res.success ? 'Order berhasil dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal')),
      backgroundColor: res.success ? Colors.green : Colors.red,
    ));
    if (res.success) _load();
  }

  Future<void> _showPaymentDialog(Order order) async {
    final amountCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String method = 'Transfer';
    final methods = ['Transfer', 'Cash', 'QRIS', 'Lainnya'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Tambah Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Order: ${order.orderNumber}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 20),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Jumlah Bayar (Rp)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true, fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tanggal Bayar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                const SizedBox(height: 6),
                TextField(
                  controller: dateCtrl,
                  decoration: InputDecoration(
                    filled: true, fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              const Text('Metode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: methods.map((m) => ChoiceChip(
                label: Text(m),
                selected: method == m,
                selectedColor: _blue.withOpacity(0.15),
                onSelected: (_) => setModal(() => method = m),
              )).toList()),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Batal'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    final amount = int.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Jumlah tidak valid'), backgroundColor: Colors.red));
                      return;
                    }
                    Navigator.pop(ctx);
                    final res = await DataService.addOrderPayment(order.id, {
                      'amount': amount,
                      'payment_date': dateCtrl.text,
                      'payment_method': method,
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res.success ? 'Pembayaran berhasil disimpan' : (res.message.isNotEmpty ? res.message : 'Gagal')),
                      backgroundColor: res.success ? Colors.green : Colors.red,
                    ));
                    if (res.success) _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _showDetail(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OrderDetailSheet(
        order: order,
        currency: _currency,
        onMarkPaid: () { Navigator.pop(ctx); _markAsPaid(order); },
        onAddPayment: () { Navigator.pop(ctx); _showPaymentDialog(order); },
        onDelete: () { Navigator.pop(ctx); _deleteOrder(order); },
        onRefresh: _load,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final totalPaid   = _all.where((o) => o.paymentStatus == 'paid').length;
    final totalUnpaid = _all.length - totalPaid;
    final totalOmset  = _all.fold<double>(0, (s, o) => s + o.totalPrice);

    return Column(children: [
      // Summary bar
      if (_all.isNotEmpty)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Expanded(child: _summaryChip('Total', _currency.format(totalOmset), _blue)),
            const SizedBox(width: 8),
            Expanded(child: _summaryChip('Lunas', '$totalPaid', Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _summaryChip('Belum', '$totalUnpaid', Colors.orange)),
          ]),
        ),
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) { _search = v; _load(); },
          decoration: InputDecoration(
            hintText: 'Cari no. order atau pelanggan...',
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _search.isNotEmpty ? IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () { _searchCtrl.clear(); _search = ''; _load(); }) : null,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      // Filter chips
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [
          for (final f in [
            {'value': 'semua',  'label': 'Semua'},
            {'value': 'paid',   'label': 'Lunas'},
            {'value': 'unpaid', 'label': 'Belum Bayar'},
          ]) ...[
            GestureDetector(
              onTap: () => setState(() { _filterStatus = f['value']!; _applyFilter(); }),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _filterStatus == f['value'] ? _blue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _filterStatus == f['value'] ? _blue : Colors.grey[300]!),
                ),
                child: Text(f['label']!, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: _filterStatus == f['value'] ? Colors.white : Colors.grey[600])),
              ),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 6),
      // List
      Expanded(
        child: _isLoading && _all.isEmpty
            ? const Center(child: CircularProgressIndicator(color: _blue))
            : RefreshIndicator(
                onRefresh: () => _load(),
                child: _filtered.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.shopping_bag_outlined, size: 52, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Belum ada pesanan', style: TextStyle(color: Colors.grey[500])),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _filtered.length + (_hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _filtered.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: ElevatedButton.icon(
                                onPressed: () { _offset += _limit; _load(reset: false); },
                                icon: const Icon(Icons.expand_more, size: 18),
                                label: const Text('Muat Lebih Banyak'),
                                style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
                              )),
                            );
                          }
                          final o = _filtered[i];
                          final isPaid    = o.paymentStatus == 'paid';
                          final isPartial = o.paymentStatus == 'partial';
                          final Color pc  = isPaid ? Colors.green : (isPartial ? Colors.orange : Colors.red);
                          final String pl = isPaid ? 'Lunas' : (isPartial ? 'Sebagian' : 'Belum Bayar');

                          return GestureDetector(
                            onTap: () => _showDetail(o),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: pc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                    child: Text(pl, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pc))),
                                ]),
                                const SizedBox(height: 6),
                                Row(children: [
                                  Icon(Icons.person_outline, size: 13, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(o.customerName ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  const Spacer(),
                                  Text(o.orderDate, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                ]),
                                const SizedBox(height: 8),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text(_currency.format(o.totalPrice),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF005FA3))),
                                  if (!isPaid)
                                    GestureDetector(
                                      onTap: () => _markAsPaid(o),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                        ),
                                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                          Icon(Icons.check_circle_outline, size: 13, color: Colors.green),
                                          SizedBox(width: 4),
                                          Text('Lunas', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                                        ]),
                                      ),
                                    ),
                                ]),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
      ),
    ]);
  }

  Widget _summaryChip(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget terpisah: Detail Order dengan Riwayat Pembayaran
// Setara orders/show.blade.php Laravel
// ─────────────────────────────────────────────────────────────────────────────
class _OrderDetailSheet extends StatefulWidget {
  final Order order;
  final NumberFormat currency;
  final VoidCallback onMarkPaid;
  final VoidCallback onAddPayment;
  final VoidCallback onDelete;
  final Future<void> Function() onRefresh;
  const _OrderDetailSheet({
    required this.order,
    required this.currency,
    required this.onMarkPaid,
    required this.onAddPayment,
    required this.onDelete,
    required this.onRefresh,
  });
  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  Order? _detail;
  bool _loading = true;
  static const _blue = Color(0xFF00ADEF);

  @override
  void initState() { super.initState(); _fetchDetail(); }

  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final d = await DataService.getOrderDetail(widget.order.id);
      if (mounted) setState(() { _detail = d; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final o         = _detail ?? widget.order;
    final totalPaid = o.payments?.fold(0.0, (s, p) => s + p.amount) ?? 0.0;
    final remaining = o.totalPrice - totalPaid;
    final isPaid    = o.paymentStatus == 'paid';

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // ── Header ──
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.orderNumber,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  Text(o.orderDate, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ]),
                _statusBadge(o.paymentStatus),
              ]),
            ]),
          ),
          // ── Content ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _blue))
                : ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
                    // Info pesanan
                    _sectionCard('Informasi Pesanan', Icons.receipt_outlined, [
                      _infoTile(Icons.person_outline, 'Pelanggan', o.customerName ?? '-'),
                      _infoTile(Icons.manage_accounts_outlined, 'Kasir', o.userName ?? '-'),
                      if (o.paymentMethod != null)
                        _infoTile(Icons.credit_card_outlined, 'Metode Bayar', o.paymentMethod!),
                      if (o.notes != null && o.notes!.isNotEmpty)
                        _infoTile(Icons.notes_outlined, 'Catatan', o.notes!),
                    ]),
                    const SizedBox(height: 12),

                    // Item produk
                    if (o.details != null && o.details!.isNotEmpty) ...[
                      _sectionCard('Detail Produk', Icons.shopping_bag_outlined,
                        o.details!.map((d) => _productTile(d)).toList()),
                      const SizedBox(height: 12),
                    ],

                    // Ringkasan keuangan
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(children: [
                        _financeRow('Total Pesanan', o.totalPrice.toDouble(), Colors.black87),
                        const Divider(height: 20),
                        _financeRow('Terbayar', totalPaid, Colors.green),
                        const SizedBox(height: 8),
                        _financeRow('Sisa Tagihan', remaining, remaining > 0 ? Colors.red : Colors.green, bold: true),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    // ── Riwayat Pembayaran (setara tabel orders/show.blade.php) ──
                    if (o.payments != null && o.payments!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.history_outlined, size: 16, color: _blue),
                            const SizedBox(width: 8),
                            const Text('Riwayat Pembayaran',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text('${o.payments!.length} transaksi',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _blue)),
                            ),
                          ]),
                          const Divider(height: 20),
                          ...o.payments!.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final pay = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FE),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE8EDF2)),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.12), shape: BoxShape.circle),
                                  child: Center(child: Text('${idx + 1}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.green))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(widget.currency.format(pay.amount),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.green)),
                                  Row(children: [
                                    Text(pay.paymentDate, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                    if (pay.paymentMethod != null) ...[
                                      Text('  •  ', style: TextStyle(color: Colors.grey[400])),
                                      Text(pay.paymentMethod!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                    ],
                                  ]),
                                  if (pay.notes != null && pay.notes!.isNotEmpty)
                                    Text(pay.notes!,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[400], fontStyle: FontStyle.italic)),
                                ])),
                              ]),
                            );
                          }),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Aksi ──
                    if (!isPaid) ...[
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: widget.onAddPayment,
                          icon: const Icon(Icons.payment, size: 16, color: _blue),
                          label: const Text('Bayar', style: TextStyle(color: _blue)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _blue),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton.icon(
                          onPressed: widget.onMarkPaid,
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Lunas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        )),
                      ]),
                      const SizedBox(height: 8),
                    ],
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('Hapus Order', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Tutup'),
                      )),
                    ]),
                    const SizedBox(height: 24),
                  ]),
          ),
        ]),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color c; String label;
    switch (status) {
      case 'paid':    c = Colors.green;  label = 'Lunas';       break;
      case 'partial': c = Colors.orange; label = 'Cicil';       break;
      default:        c = Colors.red;    label = 'Belum Lunas'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _financeRow(String label, double value, Color color, {bool bold = false}) =>
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: bold ? 14 : 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: const Color(0xFF64748B))),
      Text(widget.currency.format(value),
        style: TextStyle(fontSize: bold ? 15 : 14, fontWeight: FontWeight.w700, color: color)),
    ]);

  Widget _sectionCard(String title, IconData icon, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: _blue),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
      ]),
      const Divider(height: 20),
      ...children,
    ]),
  );

  Widget _infoTile(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      Expanded(child: Text(value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _productTile(OrderDetail d) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FE), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE8EDF2)),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: _blue.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Center(child: Text(
          (d.productName ?? '?').isNotEmpty ? (d.productName ?? '?')[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.w800, color: _blue))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d.productName ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        Text('${d.quantity} ${d.unit}  ×  ${widget.currency.format(d.price)}',
          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ])),
      Text(widget.currency.format(d.totalPrice),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _blue)),
    ]),
  );
}
