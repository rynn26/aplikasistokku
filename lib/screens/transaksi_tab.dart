import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/order.dart';
import '../widgets/pagination_widget.dart';

class TransaksiTab extends StatefulWidget {
  const TransaksiTab({super.key});
  @override
  State<TransaksiTab> createState() => _TransaksiTabState();
}

class _TransaksiTabState extends State<TransaksiTab> {
  bool _isLoading = true, _isPageLoading = false;
  List<Order> _orders = [];
  int _currentPage = 1, _lastPage = 1, _total = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadPage(int page) async {
    setState(() => page == 1 && _orders.isEmpty ? _isLoading = true : _isPageLoading = true);
    try {
      final res = await DataService.getOrdersPaged(search: _search.isEmpty ? null : _search, page: page, perPage: 15);
      if (mounted) setState(() {
        _orders = res['data'] as List<Order>;
        final meta = res['meta'] as Map<String, dynamic>;
        _currentPage = meta['current_page'] as int? ?? page;
        _lastPage    = meta['last_page'] as int? ?? 1;
        _total       = meta['total'] as int? ?? _orders.length;
        _isLoading = false; _isPageLoading = false;
      });
    } catch (_) { if (mounted) setState(() { _isLoading = false; _isPageLoading = false; }); }
  }

  void _load() => _loadPage(1);
  void reload() => _loadPage(1);

  // ─── Delete Order ───────────────────────────────────────
  Future<void> _deleteOrder(Order o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Order', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin hapus order ${o.orderNumber}?\nStok produk akan dikembalikan.'),
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
    final res = await DataService.deleteOrder(o.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res.success ? 'Order berhasil dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal menghapus')),
      backgroundColor: res.success ? Colors.green : Colors.red,
    ));
    if (res.success) _loadPage(_currentPage);
  }

  // ─── Tambah Pembayaran ──────────────────────────────────
  Future<void> _showPaymentDialog(Order o) async {
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
              Text('Tambah Pembayaran', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Order: ${o.orderNumber}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 20),
              _inputField('Jumlah Bayar (Rp)', amountCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _inputField('Tanggal Bayar', dateCtrl),
              const SizedBox(height: 12),
              const Text('Metode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: methods.map((m) => ChoiceChip(
                label: Text(m),
                selected: method == m,
                selectedColor: const Color(0xFF00ADEF).withOpacity(0.15),
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah tidak valid'), backgroundColor: Colors.red));
                      return;
                    }
                    Navigator.pop(ctx);
                    final res = await DataService.addOrderPayment(o.id, {
                      'amount': amount,
                      'payment_date': dateCtrl.text,
                      'payment_method': method,
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res.success ? 'Pembayaran berhasil disimpan' : (res.message.isNotEmpty ? res.message : 'Gagal')),
                      backgroundColor: res.success ? Colors.green : Colors.red,
                    ));
                    if (res.success) _loadPage(_currentPage);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ADEF), foregroundColor: Colors.white,
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

  // ─── Lunas otomatis ─────────────────────────────────────
  Future<void> _markAsPaid(Order o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tandai Lunas'),
        content: Text('Lunasin order ${o.orderNumber}?\nSisa pembayaran akan dilunasi otomatis.'),
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
    final res = await DataService.markOrderAsPaid(o.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res.success ? 'Order berhasil dilunasi' : (res.message.isNotEmpty ? res.message : 'Gagal')),
      backgroundColor: res.success ? Colors.green : Colors.red,
    ));
    if (res.success) _loadPage(_currentPage);
  }

  // ─── Detail Order Bottom Sheet ──────────────────────────
  void _showDetail(Order o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.orderNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(o.orderDate, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ]),
                  _statusBadge(o.paymentStatus),
                ]),
                const SizedBox(height: 16),
                _infoRow(Icons.person_outline, 'Pelanggan', o.customerName ?? '-'),
                const SizedBox(height: 8),
                _infoRow(Icons.payments_outlined, 'Total', _currency.format(o.totalPrice)),
                if (o.shippingCost > 0)
                  Padding(padding: const EdgeInsets.only(top: 8),
                    child: _infoRow(Icons.local_shipping_outlined, 'Ongkir', _currency.format(o.shippingCost))),
                const Divider(height: 24),
              ]),
            ),
            Expanded(child: ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), children: [
              if (o.details != null && o.details!.isNotEmpty) ...[
                const Text('Detail Produk', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                ...o.details!.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text('${d.productName ?? '-'}\n${d.quantity} ${d.unit}',
                      style: const TextStyle(fontSize: 13))),
                    Text(_currency.format(d.totalPrice),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                )),
                const Divider(height: 16),
              ],
              // Action buttons
              Row(children: [
                if (o.paymentStatus != 'paid') ...[
                  Expanded(child: _actionButton('Bayar', Icons.payment, Colors.blue,
                    () { Navigator.pop(ctx); _showPaymentDialog(o); })),
                  const SizedBox(width: 8),
                  Expanded(child: _actionButton('Lunas', Icons.check_circle_outline, Colors.green,
                    () { Navigator.pop(ctx); _markAsPaid(o); })),
                  const SizedBox(width: 8),
                ],
                Expanded(child: _actionButton('Hapus', Icons.delete_outline, Colors.red,
                  () { Navigator.pop(ctx); _deleteOrder(o); })),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 16, color: Colors.grey[500]),
      const SizedBox(width: 8),
      Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _statusBadge(String? status) {
    final isPaid    = status == 'paid';
    final isPartial = status == 'partial';
    final color = isPaid ? Colors.green : (isPartial ? Colors.orange : Colors.red);
    final label = isPaid ? 'Lunas' : (isPartial ? 'Sebagian' : 'Belum Bayar');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, {TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          filled: true, fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) { _search = v; _loadPage(1); },
              decoration: InputDecoration(
                hintText: 'Cari no. order atau pelanggan...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00ADEF)),
                suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                  onPressed: () { _searchCtrl.clear(); _search = ''; _loadPage(1); }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
            ),
          ),
        ),
        if (!_isLoading) Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total: $_total transaksi', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            Text('Hal $_currentPage / $_lastPage', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
        ),
        Expanded(
          child: _isLoading && _orders.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ADEF)))
            : RefreshIndicator(
                color: const Color(0xFF00ADEF),
                onRefresh: () => _loadPage(1),
                child: _orders.isEmpty ? _buildEmptyState() : Stack(children: [ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: _orders.length,
                  itemBuilder: (_, i) {
                    final o = _orders[i];
                    final isPaid = o.paymentStatus == 'paid';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                        border: Border.all(color: Colors.grey.shade100, width: 1),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showDetail(o),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00ADEF).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.receipt_long, color: Color(0xFF00ADEF), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    Text(o.orderDate, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  ]),
                                ]),
                                _statusBadge(o.paymentStatus),
                              ]),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 14),
                                child: Divider(height: 1, color: Color(0xFFF0F0F0))),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Expanded(child: Row(children: [
                                  Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(
                                    o.customerName?.isNotEmpty == true ? o.customerName! : 'Pelanggan Umum',
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                  )),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('Total Harga', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                  const SizedBox(height: 2),
                                  Text(_currency.format(o.totalPrice),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF005FA3))),
                                ]),
                              ]),
                              // Quick action buttons
                              if (!isPaid) ...[
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(child: GestureDetector(
                                    onTap: () => _showPaymentDialog(o),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00ADEF).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF00ADEF).withOpacity(0.2)),
                                      ),
                                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(Icons.payment, size: 14, color: Color(0xFF00ADEF)),
                                        SizedBox(width: 4),
                                        Text('Bayar', style: TextStyle(fontSize: 12, color: Color(0xFF00ADEF), fontWeight: FontWeight.w600)),
                                      ]),
                                    ),
                                  )),
                                  const SizedBox(width: 8),
                                  Expanded(child: GestureDetector(
                                    onTap: () => _markAsPaid(o),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                                      ),
                                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                                        SizedBox(width: 4),
                                        Text('Lunas', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                                      ]),
                                    ),
                                  )),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _deleteOrder(o),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                                      ),
                                      child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                    ),
                                  ),
                                ]),
                              ] else ...[
                                const SizedBox(height: 12),
                                Align(alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () => _deleteOrder(o),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                                      ),
                                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                        SizedBox(width: 4),
                                        Text('Hapus', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                                      ]),
                                    ),
                                  ),
                                ),
                              ],
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (_isPageLoading) const Positioned.fill(child: Center(child: CircularProgressIndicator())),
              ]),
              ),
        ),
        PaginationWidget(currentPage: _currentPage, lastPage: _lastPage, total: _total,
          isLoading: _isPageLoading, onPageChanged: _loadPage),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('Belum Ada Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Text(_search.isNotEmpty ? 'Tidak ada hasil untuk pencarian ini' : 'Transaksi yang dilakukan akan tampil di sini',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
      ]),
    );
  }
}
