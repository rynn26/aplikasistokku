import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/incoming_product.dart';
import '../widgets/pagination_widget.dart';
import 'purchase_form_screen.dart';

class PurchaseTab extends StatefulWidget {
  const PurchaseTab({super.key});
  @override
  State<PurchaseTab> createState() => _PurchaseTabState();
}

class _PurchaseTabState extends State<PurchaseTab> {
  bool _isLoading = true, _isPageLoading = false;
  List<IncomingProduct> _items = [];
  int _currentPage = 1, _lastPage = 1, _total = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const _blue = Color(0xFF00ADEF);

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadPage(int page) async {
    if (mounted) setState(() => page == 1 && _items.isEmpty ? _isLoading = true : _isPageLoading = true);
    try {
      final res = await DataService.getIncomingProductsPaged(
          search: _search.isEmpty ? null : _search, page: page, perPage: 15);
      if (mounted) setState(() {
        _items       = res['data'] as List<IncomingProduct>;
        final meta   = res['meta'] as Map<String, dynamic>;
        _currentPage = meta['current_page'] as int? ?? page;
        _lastPage    = meta['last_page'] as int? ?? 1;
        _total       = meta['total'] as int? ?? _items.length;
        _isLoading = false; _isPageLoading = false;
      });
    } catch (_) { if (mounted) setState(() { _isLoading = false; _isPageLoading = false; }); }
  }

  void _load() => _loadPage(1);
  void reload() => _loadPage(1);

  // ─── Delete ──────────────────────────────────────────────
  Future<void> _delete(IncomingProduct item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pembelian', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin hapus PO ${item.orderNumber}?\nStok produk akan dikurangi kembali.'),
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
    final res = await DataService.deleteIncomingProduct(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res.success ? 'Pembelian berhasil dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal')),
      backgroundColor: res.success ? Colors.green : Colors.red,
    ));
    if (res.success) _loadPage(_currentPage);
  }

  // ─── Tambah Pembayaran ───────────────────────────────────
  Future<void> _showPaymentDialog(IncomingProduct item) async {
    final amountCtrl = TextEditingController();
    final dateCtrl   = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String method    = 'Transfer';
    final methods    = ['Transfer', 'Cash', 'QRIS', 'Lainnya'];

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
              const Text('Tambah Pembayaran Hutang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('PO: ${item.orderNumber}  |  Supplier: ${item.supplierName ?? '-'}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
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
                selectedColor: _blue.withValues(alpha: 0.15),
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
                    final res = await DataService.addIncomingProductPayment(item.id, {
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


  // ─── Detail Bottom Sheet ─────────────────────────────────
  void _showDetail(IncomingProduct item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.orderNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(item.incomingDate, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ]),
              _statusBadge(item.paymentStatus),
            ]),
            const SizedBox(height: 16),
            _infoRow(Icons.local_shipping_outlined, 'Supplier', item.supplierName ?? '-'),
            const SizedBox(height: 8),
            _infoRow(Icons.payments_outlined, 'Total', _currency.format(item.totalPrice)),
            if (item.dueDate != null) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.event_outlined, 'Jatuh Tempo', item.dueDate!),
            ],
            FutureBuilder<IncomingProduct?>(
              future: DataService.getIncomingProductDetail(item.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: _blue))),
                  );
                }
                final fullItem = snapshot.data ?? item;
                if (fullItem.details == null || fullItem.details!.isEmpty) {
                  return const SizedBox();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 24),
                    const Text('Item Produk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...fullItem.details!.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        const Icon(Icons.circle, size: 5, color: _blue),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${d.productName ?? '-'} — ${d.stock % 1 == 0 ? d.stock.toInt() : d.stock} ${d.unit}',
                          style: const TextStyle(fontSize: 12))),
                        Text(_currency.format(d.totalPrice),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    )),
                  ],
                );
              },
            ),
            const Divider(height: 24),
            // Actions
            Row(children: [
              Expanded(child: _sheetBtn('Edit', Icons.edit_outlined, Colors.indigo,
                () async {
                  Navigator.pop(ctx);
                  final detail = await DataService.getIncomingProductDetail(item.id);
                  if (!mounted) return;
                  final refresh = await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PurchaseFormScreen(existing: detail ?? item)));
                  if (refresh == true) _loadPage(_currentPage);
                })),
              if (item.paymentStatus != 'paid') ...[
                const SizedBox(width: 8),
                Expanded(child: _sheetBtn('Bayar', Icons.payment, _blue,
                  () { Navigator.pop(ctx); _showPaymentDialog(item); })),
              ],
            ]),
            const SizedBox(height: 8),
            _sheetBtn('Hapus Pembelian', Icons.delete_outline, Colors.red,
              () { Navigator.pop(ctx); _delete(item); }),
          ]),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────
  Widget _sheetBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _quickBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 15, color: color),
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3))),
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

  // ─── Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Search Bar
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) { _search = v; _loadPage(1); },
          decoration: InputDecoration(
            hintText: 'Cari no. PO atau supplier...',
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18),
              onPressed: () { _searchCtrl.clear(); _search = ''; _loadPage(1); }) : null,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        )),

      Expanded(
        child: _isLoading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadPage(1),
              child: _items.isEmpty
                ? const Center(child: Text('Belum ada data pembelian'))
                : Stack(children: [
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item    = _items[i];
                        final isPaid  = item.paymentStatus == 'paid';

                        return GestureDetector(
                          onTap: () => _showDetail(item),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10, offset: const Offset(0, 3))],
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                              // ── Header: Icon + PO + Date + Status ──────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                                child: Row(children: [
                                  Container(
                                    width: 46, height: 46,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5FD),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.shopping_bag_outlined, color: _blue, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(item.orderNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87)),
                                    const SizedBox(height: 3),
                                    Row(children: [
                                      Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(item.incomingDate,
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                    ]),
                                  ])),
                                  _statusBadge(item.paymentStatus),
                                ]),
                              ),

                              const Divider(height: 1, color: Color(0xFFF2F2F2)),

                              // ── Supplier ───────────────────────────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                                child: Row(children: [
                                  Icon(Icons.local_shipping_outlined, size: 14, color: Colors.grey[400]),
                                  const SizedBox(width: 6),
                                  Text('Supplier: ',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  Expanded(child: Text(item.supplierName ?? '-',
                                    style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                                    overflow: TextOverflow.ellipsis)),
                                ]),
                              ),

                              // ── Detail Items (kalau ada) ───────────────────
                              if (item.details != null && item.details!.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                                  child: Text('Detail Item (${item.details!.length} item)',
                                    style: TextStyle(fontSize: 11,
                                      color: Colors.grey[400], fontWeight: FontWeight.w600)),
                                ),
                                ...item.details!.take(3).map((d) => Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
                                  child: Row(children: [
                                    Container(width: 6, height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle, color: _blue)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(
                                      '${d.productName ?? '-'} — '
                                      '${d.stock % 1 == 0 ? d.stock.toInt() : d.stock} ${d.unit}',
                                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 8),
                                    Text(_currency.format(d.totalPrice),
                                      style: const TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.w700, color: _blue)),
                                  ]),
                                )),
                                if (item.details!.length > 3)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(28, 2, 14, 4),
                                    child: Text('+${item.details!.length - 3} item lainnya',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                                  ),
                                const SizedBox(height: 6),
                              ],

                              const Divider(height: 1, color: Color(0xFFF2F2F2)),

                              // ── Total ──────────────────────────────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text('Total Pembelian',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  Text(_currency.format(item.totalPrice),
                                    style: const TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.w900, color: _blue)),
                                ]),
                              ),

                              // ── Action Buttons ─────────────────────────────
                              if (!isPaid) ...[
                                const Divider(height: 1, color: Color(0xFFF2F2F2)),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                                  child: Row(children: [
                                    Expanded(child: _quickBtn(
                                      'Bayar', Icons.payment, _blue,
                                      () => _showPaymentDialog(item))),
                                    const SizedBox(width: 8),
                                    _iconBtn(Icons.delete_outline, Colors.red, () => _delete(item)),
                                  ]),
                                ),
                              ] else ...[
                                const Divider(height: 1, color: Color(0xFFF2F2F2)),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: _iconBtn(Icons.delete_outline, Colors.red, () => _delete(item)),
                                  ),
                                ),
                              ],

                            ]),
                          ),
                        );
                      },
                    ),
                    if (_isPageLoading)
                      const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                  ]),
            ),
      ),
      PaginationWidget(
        currentPage: _currentPage, lastPage: _lastPage, total: _total,
        isLoading: _isPageLoading, onPageChanged: _loadPage),
    ]);
  }
}
