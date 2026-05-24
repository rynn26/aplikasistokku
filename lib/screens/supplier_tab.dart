import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/supplier.dart';
import '../widgets/pagination_widget.dart';

class SupplierTab extends StatefulWidget {
  const SupplierTab({super.key});
  @override
  State<SupplierTab> createState() => _SupplierTabState();
}

class _SupplierTabState extends State<SupplierTab> {
  bool _isLoading = true, _isPageLoading = false;
  List<Supplier> _suppliers = [];
  int _currentPage = 1, _lastPage = 1, _total = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();
  static const _cyan = Color(0xFF00ADEF);

  @override
  void initState() { super.initState(); _loadPage(1); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadPage(int page) async {
    setState(() => page == 1 && _suppliers.isEmpty ? _isLoading = true : _isPageLoading = true);
    try {
      final res = await DataService.getSuppliersPaged(search: _search.isEmpty ? null : _search, page: page, perPage: 15);
      if (mounted) setState(() {
        _suppliers = res['data'] as List<Supplier>;
        final meta = res['meta'] as Map<String, dynamic>;
        _currentPage = meta['current_page'] as int? ?? page;
        _lastPage    = meta['last_page'] as int? ?? 1;
        _total       = meta['total'] as int? ?? _suppliers.length;
        _isLoading = false; _isPageLoading = false;
      });
    } catch (_) { if (mounted) setState(() { _isLoading = false; _isPageLoading = false; }); }
  }

  void _showForm({Supplier? supplier}) {
    final nameCtrl    = TextEditingController(text: supplier?.name ?? '');
    final phoneCtrl   = TextEditingController(text: supplier?.phone ?? '');
    final addressCtrl = TextEditingController(text: supplier?.address ?? '');
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(supplier == null ? 'Tambah Supplier' : 'Edit Supplier',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _field('Nama Supplier *', nameCtrl),
            const SizedBox(height: 12),
            _field('Telepon', phoneCtrl, inputType: TextInputType.phone),
            const SizedBox(height: 12),
            _field('Alamat', addressCtrl, maxLines: 2),
            const SizedBox(height: 24),
            Row(children: [
              if (supplier != null) ...[
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _delete(ctx, supplier),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama tidak boleh kosong'))); return;
                  }
                  final data = {'name': nameCtrl.text.trim(), 'phone': phoneCtrl.text.trim(), 'address': addressCtrl.text.trim()};
                  final res = supplier == null ? await DataService.createSupplier(data) : await DataService.updateSupplier(supplier.id, data);
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
    );
  }

  Future<void> _delete(BuildContext ctx, Supplier supplier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Hapus Supplier'),
        content: Text('Yakin hapus "${supplier.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    final res = await DataService.deleteSupplier(supplier.id);
    if (ctx.mounted) Navigator.pop(ctx);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success ? 'Supplier dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal')),
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
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) { _search = v; _loadPage(1); },
          decoration: InputDecoration(
            hintText: 'Cari supplier...',
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
          Text('Total: $_total supplier', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Text('Hal $_currentPage / $_lastPage', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]),
      ),
      Expanded(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadPage(1),
              child: _suppliers.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Tidak ada supplier', style: TextStyle(color: Colors.grey[500])),
                  ]))
                : Stack(children: [
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _suppliers.length,
                      itemBuilder: (_, i) {
                        final s = _suppliers[i];
                        return Dismissible(
                          key: Key('supplier_${s.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (d) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Hapus Supplier', style: TextStyle(fontWeight: FontWeight.w800)),
                                content: Text('Yakin hapus "${s.name}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(d, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            ) ?? false;
                          },
                          onDismissed: (_) async {
                            final messenger = ScaffoldMessenger.of(context);
                            final res = await DataService.deleteSupplier(s.id);
                            messenger.showSnackBar(SnackBar(
                              content: Text(res.success ? 'Supplier "${s.name}" dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal menghapus')),
                              backgroundColor: res.success ? Colors.green : Colors.red));
                            if (res.success && mounted) _loadPage(_currentPage);
                          },
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: Colors.red[400], borderRadius: BorderRadius.circular(14)),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.delete_outline, color: Colors.white, size: 26),
                              SizedBox(height: 4),
                              Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ]),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                            child: Row(children: [
                              CircleAvatar(backgroundColor: _cyan.withValues(alpha: 0.1),
                                child: Icon(Icons.local_shipping, color: _cyan, size: 20)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                if (s.phone != null && s.phone!.isNotEmpty)
                                  Text(s.phone!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                if (s.address != null && s.address!.isNotEmpty)
                                  Text(s.address!, style: TextStyle(fontSize: 11, color: Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                              // Tombol Edit
                              IconButton(
                                onPressed: () => _showForm(supplier: s),
                                icon: Icon(Icons.edit_outlined, color: _cyan, size: 20),
                                tooltip: 'Edit',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  backgroundColor: _cyan.withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  minimumSize: const Size(34, 34),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Tombol Hapus
                              IconButton(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (d) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('Hapus Supplier', style: TextStyle(fontWeight: FontWeight.w800)),
                                      content: Text('Yakin hapus "${s.name}"?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(d, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                          child: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    final res = await DataService.deleteSupplier(s.id);
                                    messenger.showSnackBar(SnackBar(
                                      content: Text(res.success ? 'Supplier dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal')),
                                      backgroundColor: res.success ? Colors.green : Colors.red));
                                    if (res.success && mounted) _loadPage(_currentPage);
                                  }
                                },

                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'Hapus',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red.withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  minimumSize: const Size(34, 34),
                                ),
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
      PaginationWidget(currentPage: _currentPage, lastPage: _lastPage, total: _total,
        isLoading: _isPageLoading, onPageChanged: _loadPage),
    ]);
  }

  void showAddForm() => _showForm();
}
