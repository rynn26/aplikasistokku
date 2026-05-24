import 'package:flutter/material.dart';
import '../../../services/data_service.dart';
import '../../../models/supplier.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});
  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  bool _isLoading = true;
  List<Supplier> _suppliers = [];
  List<Supplier> _filtered = [];
  String _search = '';

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await DataService.getSuppliers();
      if (mounted) setState(() { _suppliers = data; _applyFilter(); _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  void _applyFilter() {
    _filtered = _suppliers.where((s) =>
      _search.isEmpty || s.name.toLowerCase().contains(_search.toLowerCase()) || (s.phone ?? '').contains(_search)
    ).toList();
  }

  void _showForm({Supplier? supplier}) {
    final nameCtrl = TextEditingController(text: supplier?.name ?? '');
    final phoneCtrl = TextEditingController(text: supplier?.phone ?? '');
    final addressCtrl = TextEditingController(text: supplier?.address ?? '');

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(supplier == null ? 'Tambah Supplier' : 'Edit Supplier', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _field('Nama Supplier', nameCtrl),
            const SizedBox(height: 12),
            _field('Telepon', phoneCtrl, type: TextInputType.phone),
            const SizedBox(height: 12),
            _field('Alamat', addressCtrl, lines: 2),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                final data = {'name': nameCtrl.text, 'phone': phoneCtrl.text, 'address': addressCtrl.text};
                final res = supplier == null ? await DataService.createSupplier(data) : await DataService.updateSupplier(supplier.id, data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (res.success) _loadData();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.success ? 'Berhasil' : res.message)));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {TextInputType? type, int lines = 1}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      const SizedBox(height: 6),
      TextField(controller: c, keyboardType: type, maxLines: lines, decoration: InputDecoration(
        filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      )),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(title: const Text('Supplier', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.white, foregroundColor: Colors.blue[800], elevation: 0),
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(), backgroundColor: Colors.blue[700], child: const Icon(Icons.add, color: Colors.white)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(
          onChanged: (v) => setState(() { _search = v; _applyFilter(); }),
          decoration: InputDecoration(hintText: 'Cari supplier...', prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        )),
        Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
          onRefresh: _loadData,
          child: _filtered.isEmpty ? const Center(child: Text('Tidak ada supplier')) : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final s = _filtered[i];
              return GestureDetector(
                onTap: () => _showForm(supplier: s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: Colors.blue[50], child: Icon(Icons.local_shipping, color: Colors.blue[400], size: 20)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      if (s.phone != null) Text(s.phone!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      if (s.address != null) Text(s.address!, style: TextStyle(fontSize: 11, color: Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ]),
                ),
              );
            },
          ),
        )),
      ]),
    );
  }
}