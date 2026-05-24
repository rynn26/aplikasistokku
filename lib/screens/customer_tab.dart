import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/customer.dart';
import '../widgets/pagination_widget.dart';
import 'customer_detail_screen.dart';

class CustomerTab extends StatefulWidget {
  const CustomerTab({super.key});
  @override
  State<CustomerTab> createState() => _CustomerTabState();
}

class _CustomerTabState extends State<CustomerTab> {
  bool _isLoading = true;
  bool _isPageLoading = false;
  List<Customer> _customers = [];
  int _currentPage = 1, _lastPage = 1, _total = 0;
  String _search = '', _typeFilter = '';
  final _searchCtrl = TextEditingController();
  static const _cyan = Color(0xFF00ADEF);

  @override
  void initState() { super.initState(); _loadPage(1); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadPage(int page) async {
    setState(() => page == 1 && _customers.isEmpty ? _isLoading = true : _isPageLoading = true);
    try {
      final res = await DataService.getCustomersPaged(
        search: _search.isEmpty ? null : _search,
        type: _typeFilter.isEmpty ? null : _typeFilter,
        page: page, perPage: 15,
      );
      if (mounted) setState(() {
        _customers = res['data'] as List<Customer>;
        final meta = res['meta'] as Map<String, dynamic>;
        _currentPage = meta['current_page'] as int? ?? page;
        _lastPage    = meta['last_page'] as int? ?? 1;
        _total       = meta['total'] as int? ?? _customers.length;
        _isLoading = false; _isPageLoading = false;
      });
    } catch (_) { if (mounted) setState(() { _isLoading = false; _isPageLoading = false; }); }
  }

  void _showForm({Customer? customer}) {
    final nameCtrl    = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl   = TextEditingController(text: customer?.phone ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');
    String type = customer?.type ?? 'customer';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(customer == null ? 'Tambah Pelanggan' : 'Edit Pelanggan',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              _field('Nama *', nameCtrl),
              const SizedBox(height: 12),
              _field('Telepon', phoneCtrl, inputType: TextInputType.phone),
              const SizedBox(height: 12),
              _field('Alamat', addressCtrl, maxLines: 2),
              const SizedBox(height: 12),
              Text('Tipe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['customer', 'pasar', 'shopee'].map((t) {
                final sel = type == t;
                return ChoiceChip(
                  label: Text(t[0].toUpperCase() + t.substring(1)),
                  selected: sel,
                  selectedColor: _cyan.withValues(alpha: 0.15),
                  onSelected: (_) => setModal(() => type = t),
                );
              }).toList()),
              const SizedBox(height: 24),
              Row(children: [
                if (customer != null) ...[
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => _delete(ctx, customer),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  )),
                  const SizedBox(width: 12),
                ],
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama tidak boleh kosong')));
                      return;
                    }
                    final data = {'name': nameCtrl.text.trim(), 'phone': phoneCtrl.text.trim(),
                      'address': addressCtrl.text.trim(), 'type': type};
                    final res = customer == null
                        ? await DataService.createCustomer(data)
                        : await DataService.updateCustomer(customer.id, data);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res.success ? 'Berhasil disimpan' : (res.message.isNotEmpty ? res.message : 'Gagal')),
                        backgroundColor: res.success ? Colors.green : Colors.red));
                      if (res.success) _loadPage(_currentPage);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _cyan,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )),
              ]),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext ctx, Customer customer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: Text('Yakin hapus "${customer.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(d, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    final res = await DataService.deleteCustomer(customer.id);
    if (ctx.mounted) Navigator.pop(ctx);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success ? 'Pelanggan dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal')),
        backgroundColor: res.success ? Colors.green : Colors.red));
      if (res.success) _loadPage(_currentPage);
    }
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? inputType, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      const SizedBox(height: 6),
      TextField(controller: ctrl, keyboardType: inputType, maxLines: maxLines,
        decoration: InputDecoration(filled: true, fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Search
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) { _search = v; _loadPage(1); },
          decoration: InputDecoration(
            hintText: 'Cari pelanggan...',
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18),
              onPressed: () { _searchCtrl.clear(); _search = ''; _loadPage(1); }) : null,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      // Filter tipe
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: ['', 'customer', 'pasar', 'shopee'].map((t) {
            final lbl = t.isEmpty ? 'Semua' : t[0].toUpperCase() + t.substring(1);
            final sel = _typeFilter == t;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () { setState(() => _typeFilter = t); _loadPage(1); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? _cyan : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? _cyan : Colors.grey[300]!)),
                  child: Text(lbl, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : Colors.grey[600])),
                ),
              ),
            );
          }).toList()),
        ),
      ),
      // Info total
      if (!_isLoading) Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total: $_total pelanggan', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Text('Hal $_currentPage / $_lastPage', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]),
      ),
      Expanded(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadPage(1),
              child: _customers.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Tidak ada pelanggan', style: TextStyle(color: Colors.grey[500])),
                  ]))
                : Stack(children: [
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _customers.length,
                      itemBuilder: (_, i) {
                        final c = _customers[i];
                        final typeColor = c.type == 'pasar' ? Colors.orange
                            : (c.type == 'shopee' ? Colors.deepOrange : Colors.blue);
                        return GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context: context, backgroundColor: Colors.transparent,
                            builder: (ctx) => Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(color: Colors.white,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 40, height: 4,
                                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                                const SizedBox(height: 16),
                                Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: Container(padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: _cyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.analytics_outlined, color: _cyan)),
                                  title: const Text('Lihat Detail & Analitik'),
                                  subtitle: const Text('Riwayat transaksi, produk terbeli, harga khusus'),
                                  onTap: () { Navigator.pop(ctx);
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c)));
                                  },
                                ),
                                ListTile(
                                  leading: Container(padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.edit_outlined, color: Colors.orange)),
                                  title: const Text('Edit Pelanggan'),
                                  onTap: () { Navigator.pop(ctx); _showForm(customer: c); },
                                ),
                                const SizedBox(height: 8),
                              ]),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                            child: Row(children: [
                              CircleAvatar(
                                backgroundColor: typeColor.withValues(alpha: 0.1),
                                child: Text(c.name[0].toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: typeColor))),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                if (c.phone != null && c.phone!.isNotEmpty)
                                  Text(c.phone!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(c.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor)),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                    if (_isPageLoading) const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                  ]),
            ),
      ),
      PaginationWidget(
        currentPage: _currentPage, lastPage: _lastPage, total: _total,
        isLoading: _isPageLoading, onPageChanged: _loadPage),
    ]);
  }

  void showAddForm() => _showForm();
}
