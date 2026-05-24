import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/category.dart';
import '../widgets/pagination_widget.dart';

class EcommerceKategoriTab extends StatefulWidget {
  const EcommerceKategoriTab({super.key});
  @override
  State<EcommerceKategoriTab> createState() => _EcommerceKategoriTabState();
}

class _EcommerceKategoriTabState extends State<EcommerceKategoriTab> {
  bool _isLoading = true, _isPageLoading = false;
  List<Category> _categories = [];
  int _currentPage = 1, _lastPage = 1, _total = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();
  static const _cyan = Color(0xFF00ADEF);

  @override
  void initState() { super.initState(); _loadPage(1); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadPage(int page) async {
    setState(() => page == 1 && _categories.isEmpty ? _isLoading = true : _isPageLoading = true);
    try {
      final res = await DataService.getCategoriesPaged(search: _search.isEmpty ? null : _search, page: page, perPage: 15);
      if (mounted) setState(() {
        _categories = res['data'] as List<Category>;
        final meta  = res['meta'] as Map<String, dynamic>;
        _currentPage = meta['current_page'] as int? ?? page;
        _lastPage    = meta['last_page'] as int? ?? 1;
        _total       = meta['total'] as int? ?? _categories.length;
        _isLoading = false; _isPageLoading = false;
      });
    } catch (_) { if (mounted) setState(() { _isLoading = false; _isPageLoading = false; }); }
  }

  void _showForm({Category? category}) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    String status  = category?.status ?? 'active';
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(category == null ? 'Tambah Kategori' : 'Edit Kategori', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _field('Nama Kategori *', nameCtrl),
            const SizedBox(height: 12),
            _field('Deskripsi', descCtrl, maxLines: 2),
            const SizedBox(height: 14),
            Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Row(children: [
              for (final s in ['active', 'inactive'])
                GestureDetector(
                  onTap: () => setModal(() => status = s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: status == s ? (s == 'active' ? Colors.green : Colors.red).withValues(alpha: 0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: status == s ? (s == 'active' ? Colors.green : Colors.red) : Colors.transparent)),
                    child: Text(s == 'active' ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: status == s ? (s == 'active' ? Colors.green : Colors.red) : Colors.grey[600])),
                  ),
                ),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              if (category != null) ...[
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _delete(ctx, category),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
                const SizedBox(width: 12),
              ],
              Expanded(child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama tidak boleh kosong'))); return;
                  }
                  final data = {'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim(), 'status': status};
                  final res = category == null ? await DataService.createCategory(data) : await DataService.updateCategory(category.id, data);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res.success ? 'Berhasil disimpan' : (res.message.isNotEmpty ? res.message : 'Gagal')),
                      backgroundColor: res.success ? Colors.green : Colors.red));
                    if (res.success) _loadPage(_currentPage);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _cyan,
                  padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )),
            ]),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  Future<void> _delete(BuildContext ctx, Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Yakin hapus kategori "${c.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    final res = await DataService.deleteCategory(c.id);
    if (ctx.mounted) Navigator.pop(ctx);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success ? 'Kategori dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal')),
        backgroundColor: res.success ? Colors.green : Colors.red));
      if (res.success) _loadPage(_currentPage);
    }
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])), const SizedBox(height: 6),
    TextField(controller: ctrl, maxLines: maxLines,
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
          decoration: InputDecoration(hintText: 'Cari kategori...', prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _search = ''; _loadPage(1); }) : null,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10))),
      ),
      if (!_isLoading) Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total: $_total kategori', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Text('Hal $_currentPage / $_lastPage', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]),
      ),
      Expanded(
        child: _isLoading ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadPage(1),
              child: _categories.isEmpty
                ? const Center(child: Text('Belum ada kategori'))
                : Stack(children: [
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        return GestureDetector(
                          onTap: () => _showForm(category: cat),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                            child: Row(children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.category, color: Colors.purple[400], size: 18)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                if (cat.description != null && cat.description!.isNotEmpty)
                                  Text(cat.description!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (cat.status == 'active' ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6)),
                                child: Text(cat.status == 'active' ? 'Aktif' : 'Nonaktif',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: cat.status == 'active' ? Colors.green[700] : Colors.red[700])),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right, color: Colors.grey[400]),
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
