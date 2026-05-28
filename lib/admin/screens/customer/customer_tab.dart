import 'package:flutter/material.dart';
import '../../../services/data_service.dart';
import '../../../models/customer.dart';
import '../../../widgets/pagination_widget.dart';
import '../../../screens/customer_detail_screen.dart';

class CustomerTab extends StatefulWidget {
  const CustomerTab({super.key});

  @override
  State<CustomerTab> createState() => _CustomerTabState();
}

class _CustomerTabState extends State<CustomerTab> {
  bool _isLoading = true, _isPageLoading = false;
  List<Customer> _customers = [];
  int _currentPage = 1, _lastPage = 1, _total = 0;
  String _search = '', _selectedType = 'all';
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
        type: _selectedType == 'all' ? null : _selectedType,
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

  // ─── Hapus Pelanggan ─────────────────────────────────────────
  Future<void> _delete(Customer c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pelanggan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus pelanggan "${c.name}"?\nData transaksi terkait tidak akan ikut terhapus.'),
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
    final res = await DataService.deleteCustomer(c.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res.success ? 'Pelanggan berhasil dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal menghapus')),
      backgroundColor: res.success ? Colors.green : Colors.red,
    ));
    if (res.success) _loadPage(_currentPage);
  }

  // ─── Form Tambah / Edit ──────────────────────────────────────
  void _showForm({Customer? customer}) {
    final nameCtrl    = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl   = TextEditingController(text: customer?.phone ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');
    String type = customer?.type ?? 'customer';

    showModalBottomSheet(
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
              Text(customer == null ? 'Tambah Pelanggan' : 'Edit Pelanggan',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              _field('Nama', nameCtrl),
              const SizedBox(height: 12),
              _field('Telepon', phoneCtrl, keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              _field('Alamat', addressCtrl, maxLines: 2),
              const SizedBox(height: 12),
              Text('Tipe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['customer', 'pasar', 'shopee', 'reseller'].map((t) => ChoiceChip(
                label: Text(t[0].toUpperCase() + t.substring(1)),
                selected: type == t,
                selectedColor: _cyan.withValues(alpha: 0.15),
                onSelected: (_) => setModal(() => type = t),
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
                    if (nameCtrl.text.trim().isEmpty) return;
                    final data = {
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'address': addressCtrl.text.trim(),
                      'type': type,
                    };
                    final res = customer == null
                        ? await DataService.createCustomer(data)
                        : await DataService.updateCustomer(customer.id, data);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res.success ? (customer == null ? 'Pelanggan ditambahkan' : 'Pelanggan diperbarui')
                          : (res.message.isNotEmpty ? res.message : 'Gagal menyimpan')),
                      backgroundColor: res.success ? Colors.green : Colors.red,
                    ));
                    if (res.success) _loadPage(_currentPage);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: Colors.white,
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

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboard, int maxLines = 1}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      const SizedBox(height: 6),
      TextField(controller: ctrl, keyboardType: keyboard, maxLines: maxLines,
        decoration: InputDecoration(
          filled: true, fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        )),
    ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: _cyan,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PELANGGAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                color: _cyan, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Daftar Pelanggan', style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                if (!_isLoading)
                  Text('$_total data', style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 16),
              // Search bar
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) { _search = v; _loadPage(1); },
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau telepon...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: _cyan),
                    suffixIcon: _search.isNotEmpty ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: () { _searchCtrl.clear(); _search = ''; _loadPage(1); }) : null,
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Filter tipe
              SizedBox(
                height: 36,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  _chip('Semua', 'all'),
                  _chip('Customer', 'customer'),
                  _chip('Pasar', 'pasar'),
                  _chip('Shopee', 'shopee'),
                  _chip('Reseller', 'reseller'),
                ]),
              ),
              const SizedBox(height: 8),
              if (!_isLoading)
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Hal $_currentPage / $_lastPage', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  if (_isPageLoading) const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                ]),
            ]),
          ),
          // List
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _cyan))
              : RefreshIndicator(
                  color: _cyan,
                  onRefresh: () => _loadPage(1),
                  child: _customers.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.people_outline, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Tidak ada pelanggan', style: TextStyle(color: Colors.grey[500])),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                        itemCount: _customers.length,
                        itemBuilder: (ctx, i) => _buildCard(_customers[i]),
                      ),
                ),
          ),
          // Pagination
          PaginationWidget(
            currentPage: _currentPage, lastPage: _lastPage, total: _total,
            isLoading: _isPageLoading, onPageChanged: _loadPage),
        ]),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _selectedType == value;
    return GestureDetector(
      onTap: () { setState(() => _selectedType = value); _loadPage(1); },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _cyan : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _cyan : Colors.grey[300]!),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: selected ? Colors.white : Colors.grey[600])),
      ),
    );
  }

  Widget _buildCard(Customer c) {
    final typeColor = c.type == 'pasar' ? Colors.orange
      : c.type == 'shopee' ? Colors.deepOrange
      : c.type == 'reseller' ? Colors.purple
      : const Color(0xFF00ADEF);
    final typeLabel = c.type[0].toUpperCase() + c.type.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info row
        InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _cyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.analytics_outlined, color: _cyan),
                    ),
                    title: const Text('Lihat Detail & Analitik'),
                    subtitle: const Text('Riwayat transaksi, produk terbeli, harga khusus'),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c)),
                      );
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.edit_outlined, color: Colors.orange),
                    ),
                    title: const Text('Edit Pelanggan'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showForm(customer: c);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    title: const Text('Hapus Pelanggan', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _delete(c);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: typeColor.withValues(alpha: 0.12),
                child: Text(c.name[0].toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: typeColor, fontSize: 15)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                if (c.phone != null && c.phone!.isNotEmpty)
                  Text(c.phone!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                if (c.address != null && c.address!.isNotEmpty)
                  Text(c.address!, style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor)),
              ),
            ]),
          ),
        ),
        // Divider + action buttons
        Divider(height: 1, color: Colors.grey[100]),
        Row(children: [
          Expanded(child: _actionBtn(Icons.edit_outlined, 'Edit', const Color(0xFF00ADEF),
            () => _showForm(customer: c))),
          Container(width: 1, height: 36, color: Colors.grey[100]),
          Expanded(child: _actionBtn(Icons.delete_outline, 'Hapus', Colors.red,
            () => _delete(c))),
        ]),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}
