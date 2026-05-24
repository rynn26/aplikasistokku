import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/manufacture.dart';
import '../widgets/pagination_widget.dart';
import 'manufacture_detail_screen.dart';
import 'manufacture_form_screen.dart';

class ProduksiTab extends StatefulWidget {
  const ProduksiTab({super.key});
  @override
  State<ProduksiTab> createState() => _ProduksiTabState();
}

class _ProduksiTabState extends State<ProduksiTab> {
  bool _isLoading = true, _isPageLoading = false;
  List<Manufacture> _items = [];
  int _currentPage = 1, _lastPage = 1, _total = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  @override
  void initState() { super.initState(); _loadPage(1); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadPage(int page) async {
    setState(() => page == 1 && _items.isEmpty ? _isLoading = true : _isPageLoading = true);
    try {
      final res = await DataService.getManufacturesPaged(search: _search.isEmpty ? null : _search, page: page, perPage: 15);
      if (mounted) setState(() {
        _items = res['data'] as List<Manufacture>;
        final meta = res['meta'] as Map<String, dynamic>;
        _currentPage = meta['current_page'] as int? ?? page;
        _lastPage    = meta['last_page'] as int? ?? 1;
        _total       = meta['total'] as int? ?? _items.length;
        _isLoading = false; _isPageLoading = false;
      });
    } catch (_) { if (mounted) setState(() { _isLoading = false; _isPageLoading = false; }); }
  }

  void _load() => _loadPage(1);

  Future<void> _delete(Manufacture m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produksi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin hapus produksi "${m.code}"?\nStok produk & bahan baku akan dikembalikan.'),
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
    final res = await DataService.deleteManufacture(m.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res.success ? 'Produksi dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal')),
      backgroundColor: res.success ? Colors.green : Colors.red,
    ));
    if (res.success) _loadPage(_currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) { _search = v; _loadPage(1); },
          decoration: InputDecoration(
            hintText: 'Cari kode produksi...',
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18),
              onPressed: () { _searchCtrl.clear(); _search = ''; _loadPage(1); }) : null,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      if (!_isLoading) Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total: $_total produksi', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Text('Hal $_currentPage / $_lastPage', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]),
      ),
      Expanded(
        child: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => _loadPage(1),
            child: _items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.precision_manufacturing_outlined, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('Belum ada data produksi', style: TextStyle(color: Colors.grey[500])),
                ]))
              : Stack(children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final m = _items[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text(m.code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(8)),
                          child: Text(m.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo[700])),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(m.manufactureDate ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        if (m.userName != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.person_outline, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(m.userName!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ]),
                      if (m.totalPrice != null && m.totalPrice! > 0) ...[
                        const SizedBox(height: 6),
                        Text(_currency.format(m.totalPrice), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.indigo[700])),
                      ],
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _btn('Detail', Icons.visibility_outlined, Colors.blue,
                          () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ManufactureDetailScreen(manufactureId: m.id, title: m.code)))
                          .then((_) => _loadPage(_currentPage)))),
                        const SizedBox(width: 6),
                        Expanded(child: _btn('Edit', Icons.edit_outlined, Colors.indigo,
                          () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ManufactureFormScreen(existingId: m.id)))
                          .then((ok) { if (ok == true) _loadPage(_currentPage); }))),
                        const SizedBox(width: 6),
                        Expanded(child: _btn('Hapus', Icons.delete_outline, Colors.red, () => _delete(m))),
                      ]),
                    ]),
                  );
                },
              ),
              if (_isPageLoading) const Positioned.fill(child: Center(child: CircularProgressIndicator())),
            ]),
          ),
      ),
      PaginationWidget(currentPage: _currentPage, lastPage: _lastPage, total: _total,
        isLoading: _isPageLoading, onPageChanged: _loadPage),
    ]);
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  /// Dipanggil dari FAB di cashier_main_screen
  void showAddForm() => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ManufactureFormScreen()))
    .then((ok) { if (ok == true) _load(); });
}
