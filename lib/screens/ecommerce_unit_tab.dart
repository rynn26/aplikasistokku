import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/unit_model.dart';
import '../widgets/pagination_widget.dart';

class EcommerceUnitTab extends StatefulWidget {
  const EcommerceUnitTab({super.key});
  @override
  State<EcommerceUnitTab> createState() => _EcommerceUnitTabState();
}

class _EcommerceUnitTabState extends State<EcommerceUnitTab> {
  bool _isLoading = true, _isPageLoading = false;
  List<UnitModel> _units = [];
  int _currentPage = 1, _lastPage = 1, _total = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();
  static const _cyan = Color(0xFF00ADEF);

  @override
  void initState() { super.initState(); _loadPage(1); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadPage(int page) async {
    setState(() => page == 1 && _units.isEmpty ? _isLoading = true : _isPageLoading = true);
    try {
      final res = await DataService.getUnitsPaged(search: _search.isEmpty ? null : _search, page: page, perPage: 20);
      if (mounted) setState(() {
        _units = res['data'] as List<UnitModel>;
        final meta = res['meta'] as Map<String, dynamic>;
        _currentPage = meta['current_page'] as int? ?? page;
        _lastPage    = meta['last_page'] as int? ?? 1;
        _total       = meta['total'] as int? ?? _units.length;
        _isLoading = false; _isPageLoading = false;
      });
    } catch (_) { if (mounted) setState(() { _isLoading = false; _isPageLoading = false; }); }
  }

  void _showForm({UnitModel? unit}) {
    final nameCtrl = TextEditingController(text: unit?.name ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                unit == null ? 'Tambah Unit' : 'Edit Unit',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              _field('Nama Unit', nameCtrl),
              const SizedBox(height: 24),
              Row(children: [
                if (unit != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _delete(ctx, unit),
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama tidak boleh kosong')));
                        return;
                      }
                      final data = {'name': nameCtrl.text.trim()};
                      final res = unit == null
                          ? await DataService.createUnit(data)
                          : await DataService.updateUnit(unit.id, data);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.success ? 'Berhasil disimpan' : (res.message.isNotEmpty ? res.message : 'Gagal menyimpan')),
                            backgroundColor: res.success ? Colors.green : Colors.red,
                          ),
                        );
                        if (res.success) _loadPage(_currentPage);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cyan,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext ctx, UnitModel u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Hapus Unit'),
        content: Text('Yakin hapus unit "${u.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await DataService.deleteUnit(u.id);
    if (ctx.mounted) Navigator.pop(ctx);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.success ? 'Unit dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal menghapus')),
          backgroundColor: res.success ? Colors.green : Colors.red,
        ),
      );
      if (res.success) _loadPage(_currentPage);
    }
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
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
            hintText: 'Cari unit...',
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
          Text('Total: $_total unit', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Text('Hal $_currentPage / $_lastPage', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]),
      ),
      Expanded(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadPage(1),
              child: _units.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.straighten, size: 52, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Belum ada unit', style: TextStyle(color: Colors.grey[500])),
                  ]))
                : Stack(children: [
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _units.length,
                      itemBuilder: (_, i) {
                        final u = _units[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.straighten, color: Colors.blue[400], size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                            GestureDetector(
                              onTap: () => _showForm(unit: u),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: _cyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _cyan.withValues(alpha: 0.25))),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.edit_outlined, size: 13, color: _cyan), const SizedBox(width: 4),
                                  Text('Edit', style: TextStyle(fontSize: 11, color: _cyan, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (d) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Text('Hapus Unit', style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: Text('Yakin hapus unit "${u.name}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
                                      ElevatedButton(onPressed: () => Navigator.pop(d, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                        child: const Text('Hapus')),
                                    ],
                                  ),
                                );
                                if (ok != true || !mounted) return;
                                final res = await DataService.deleteUnit(u.id);
                                messenger.showSnackBar(SnackBar(
                                  content: Text(res.success ? 'Unit dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal')),
                                  backgroundColor: res.success ? Colors.green : Colors.red));
                                if (res.success && mounted) _loadPage(_currentPage);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.25))),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.delete_outline, size: 13, color: Colors.red[600]), const SizedBox(width: 4),
                                  Text('Hapus', style: TextStyle(fontSize: 11, color: Colors.red[600], fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ),
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

  void showAddForm() => _showForm();
}
