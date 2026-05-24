import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/expense.dart';
import '../widgets/pagination_widget.dart';

class PengeluaranTab extends StatefulWidget {
  const PengeluaranTab({super.key});
  @override
  State<PengeluaranTab> createState() => _PengeluaranTabState();
}

class _PengeluaranTabState extends State<PengeluaranTab> {
  bool _isLoading = true, _isPageLoading = false;
  List<Expense> _items = [];
  int _currentPage = 1, _lastPage = 1, _total = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static const _cyan = Color(0xFF00ADEF);

  @override
  void initState() { super.initState(); _loadPage(1); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadPage(int page) async {
    setState(() => page == 1 && _items.isEmpty ? _isLoading = true : _isPageLoading = true);
    try {
      final res = await DataService.getExpensesPaged(search: _search.isEmpty ? null : _search, page: page, perPage: 15);
      if (mounted) setState(() {
        _items = res['data'] as List<Expense>;
        final meta = res['meta'] as Map<String, dynamic>;
        _currentPage = meta['current_page'] as int? ?? page;
        _lastPage    = meta['last_page'] as int? ?? 1;
        _total       = meta['total'] as int? ?? _items.length;
        _isLoading = false; _isPageLoading = false;
      });
    } catch (_) { if (mounted) setState(() { _isLoading = false; _isPageLoading = false; }); }
  }

  void reload() => _loadPage(1);

  void _showForm({Expense? expense}) {
    final descCtrl  = TextEditingController(text: expense?.description ?? '');
    final qtyCtrl   = TextEditingController(text: expense != null ? expense.qty.toString() : '1');
    final priceCtrl = TextEditingController(text: expense != null ? expense.price.toStringAsFixed(0) : '');
    final dateCtrl  = TextEditingController(text: expense?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        final qty   = int.tryParse(qtyCtrl.text) ?? 0;
        final price = int.tryParse(priceCtrl.text.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
        final total = qty * price;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(expense == null ? 'Tambah Pengeluaran' : 'Edit Pengeluaran', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              _field('Keterangan *', descCtrl),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _fieldCb('Qty *', qtyCtrl, keyboard: TextInputType.number, onChanged: (_) => setModal(() {}))),
                const SizedBox(width: 12),
                Expanded(child: _fieldCb('Harga Satuan *', priceCtrl, keyboard: TextInputType.number, onChanged: (_) => setModal(() {}))),
              ]),
              const SizedBox(height: 12),
              _field('Tanggal', dateCtrl),
              if (total > 0) ...[
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(_currency.format(total), style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.red, fontSize: 16)),
                  ])),
              ],
              const SizedBox(height: 24),
              Row(children: [
                if (expense != null) ...[
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => _delete(ctx, expense),
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  )),
                  const SizedBox(width: 12),
                ],
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    final qtyVal   = int.tryParse(qtyCtrl.text);
                    final priceVal = int.tryParse(priceCtrl.text.replaceAll(RegExp(r'[.,]'), ''));
                    if (descCtrl.text.trim().isEmpty || qtyVal == null || priceVal == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keterangan, qty, harga wajib diisi'), backgroundColor: Colors.red)); return;
                    }
                    final data = {'description': descCtrl.text.trim(), 'qty': qtyVal, 'price': priceVal, 'total_price': qtyVal * priceVal,
                      'date': dateCtrl.text.trim().isEmpty ? DateFormat('yyyy-MM-dd').format(DateTime.now()) : dateCtrl.text.trim()};
                    final res = expense == null ? await DataService.createExpense(data) : await DataService.updateExpense(expense.id, data);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res.success ? 'Berhasil disimpan' : (res.message.isNotEmpty ? res.message : 'Gagal')),
                        backgroundColor: res.success ? Colors.green : Colors.red));
                      if (res.success) _loadPage(_currentPage);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                )),
              ]),
            ])),
          ),
        );
      }),
    );
  }

  Future<void> _delete(BuildContext ctx, Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin hapus "${e.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(d, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await DataService.deleteExpense(e.id);
    if (ctx.mounted) Navigator.pop(ctx);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success ? 'Pengeluaran dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal')),
        backgroundColor: res.success ? Colors.green : Colors.red));
      if (res.success) _loadPage(_currentPage);
    }
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboard, int maxLines = 1}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])), const SizedBox(height: 6),
    TextField(controller: ctrl, keyboardType: keyboard, maxLines: maxLines,
      decoration: InputDecoration(filled: true, fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
  ]);

  Widget _fieldCb(String label, TextEditingController ctrl, {TextInputType? keyboard, required void Function(String) onChanged}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])), const SizedBox(height: 6),
    TextField(controller: ctrl, keyboardType: keyboard, onChanged: onChanged,
      decoration: InputDecoration(filled: true, fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
  ]);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(controller: _searchCtrl, onChanged: (v) { _search = v; _loadPage(1); },
          decoration: InputDecoration(hintText: 'Cari pengeluaran...', prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _search = ''; _loadPage(1); }) : null,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10))),
      ),
      if (!_isLoading) Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total: $_total pengeluaran', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Text('Hal $_currentPage / $_lastPage', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]),
      ),
      Expanded(
        child: _isLoading ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadPage(1),
              child: _items.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.money_off_outlined, size: 64, color: Colors.grey[300]), const SizedBox(height: 12),
                    Text('Belum ada pengeluaran', style: TextStyle(color: Colors.grey[500])),
                  ]))
                : Stack(children: [
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final e = _items[i];
                        return GestureDetector(
                          onTap: () => _showForm(expense: e),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                            child: Row(children: [
                              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.money_off, color: Colors.red[400], size: 20)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(e.description, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('${e.qty} × ${_currency.format(e.price)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                Text(e.date, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(_currency.format(e.totalPrice), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.red)),
                                Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
                              ]),
                            ]),
                          ),
                        );
                      },
                    ),
                    if (_isPageLoading) const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                  ]),
            ),
      ),
      PaginationWidget(currentPage: _currentPage, lastPage: _lastPage, total: _total, isLoading: _isPageLoading, onPageChanged: _loadPage),
    ]);
  }

  void showAddForm() => _showForm();
}
