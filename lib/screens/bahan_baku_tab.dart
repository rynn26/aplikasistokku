import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/ingredient.dart';
import '../widgets/pagination_widget.dart';
import '../models/category.dart';
import '../models/unit_model.dart';

class BahanBakuTab extends StatefulWidget {
  const BahanBakuTab({super.key});
  @override
  State<BahanBakuTab> createState() => _BahanBakuTabState();
}

class _BahanBakuTabState extends State<BahanBakuTab> with SingleTickerProviderStateMixin {
  bool _isLoading = true, _isPageLoading = false;
  List<Ingredient> _items = [];
  List<Category>   _categories = [];
  List<UnitModel>  _units = [];
  int _currentPage = 1, _lastPage = 1, _total = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  late TabController _tabCtrl;

  static const _cyan = Color(0xFF00ADEF);
  static const _green = Color(0xFF22C55E);
  static const _orange = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() { _searchCtrl.dispose(); _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DataService.getIngredientsPaged(page: 1, perPage: 15),
        DataService.getCategories(),
        DataService.getUnits(),
      ]);
      if (mounted) setState(() {
        final res = results[0] as Map<String, dynamic>;
        _items      = res['data'] as List<Ingredient>;
        final meta  = res['meta'] as Map<String, dynamic>;
        _currentPage = meta['current_page'] as int? ?? 1;
        _lastPage    = meta['last_page'] as int? ?? 1;
        _total       = meta['total'] as int? ?? 0;
        
        _categories = results[1] as List<Category>;
        _units      = results[2] as List<UnitModel>;
        _isLoading  = false;
      });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _loadPage(int page) async {
    setState(() => _isPageLoading = true);
    try {
      final res = await DataService.getIngredientsPaged(search: _search.isEmpty ? null : _search, page: page, perPage: 15);
      if (mounted) setState(() {
        _items = res['data'] as List<Ingredient>;
        final meta = res['meta'] as Map<String, dynamic>;
        _currentPage = meta['current_page'] as int? ?? page;
        _lastPage    = meta['last_page'] as int? ?? 1;
        _total       = meta['total'] as int? ?? _items.length;
        _isPageLoading = false;
      });
    } catch (_) { if (mounted) setState(() => _isPageLoading = false); }
  }

  void reload() => _loadAll();

  // ─── Form Tambah / Edit ───────────────────────────────────
  void _showForm({Ingredient? ing}) {
    final nameCtrl  = TextEditingController(text: ing?.name ?? '');
    final priceCtrl = TextEditingController(text: ing?.price?.toInt().toString() ?? '');
    final stockCtrl = TextEditingController(text: ing?.stock?.toInt().toString() ?? '0');
    int? catId   = ing?.categoryId;
    int? unitId  = ing?.unitId;
    String type  = ing?.type ?? 'barang';
    final types  = ['barang', 'bahan'];

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
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(ing == null ? 'Tambah Bahan Baku' : 'Edit Bahan Baku',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                _field('Nama *', nameCtrl),
                const SizedBox(height: 12),
                const Text('Tipe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: types.map((t) => ChoiceChip(
                  label: Text(t[0].toUpperCase() + t.substring(1)),
                  selected: type == t,
                  selectedColor: _cyan.withOpacity(0.15),
                  onSelected: (_) => setModal(() => type = t),
                )).toList()),
                const SizedBox(height: 12),
                const Text('Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: catId,
                  hint: const Text('Pilih Kategori'),
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true, fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setModal(() => catId = v),
                ),
                const SizedBox(height: 12),
                const Text('Satuan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: unitId,
                  hint: const Text('Pilih Satuan'),
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true, fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
                  onChanged: (v) => setModal(() => unitId = v),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field('Harga (Rp)', priceCtrl, keyboard: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Stok Awal', stockCtrl, keyboard: TextInputType.number)),
                ]),
                const SizedBox(height: 24),
                Row(children: [
                  if (ing != null) ...[
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () => _delete(ctx, ing),
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || catId == null || unitId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Nama, Kategori, dan Satuan wajib diisi'), backgroundColor: Colors.red));
                        return;
                      }
                      final data = {
                        'name': nameCtrl.text.trim(),
                        'type': type,
                        'category_id': catId,
                        'unit_id': unitId,
                        'price': int.tryParse(priceCtrl.text) ?? 0,
                        'stock': int.tryParse(stockCtrl.text) ?? 0,
                      };
                      final res = ing == null
                          ? await DataService.createIngredient(data)
                          : await DataService.updateIngredient(ing.id, data);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(res.success ? 'Berhasil disimpan' : (res.message.isNotEmpty ? res.message : 'Gagal')),
                          backgroundColor: res.success ? Colors.green : Colors.red,
                        ));
                        if (res.success) _loadAll();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cyan, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Manajemen Stok ──────────────────────────────────────
  void _showStokDialog(Ingredient ing) {
    String mode = 'tambah';
    final qtyCtrl  = TextEditingController();
    final noteCtrl = TextEditingController();

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
              Text('Kelola Stok — ${ing.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Stok saat ini: ${ing.stock?.toInt() ?? 0} ${ing.unitName ?? ''}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 20),
              const Text('Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(children: [
                _modeChip('Tambah', 'tambah', _green, mode, (v) => setModal(() => mode = v)),
                const SizedBox(width: 8),
                _modeChip('Kurangi', 'kurangi', Colors.orange, mode, (v) => setModal(() => mode = v)),
                const SizedBox(width: 8),
                _modeChip('Penyesuaian', 'penyesuaian', Colors.purple, mode, (v) => setModal(() => mode = v)),
              ]),
              const SizedBox(height: 16),
              _field(mode == 'penyesuaian' ? 'Stok Baru' : 'Jumlah', qtyCtrl, keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _field('Catatan', noteCtrl),
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
                    final qty = int.tryParse(qtyCtrl.text);
                    if (qty == null || qty < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Jumlah tidak valid'), backgroundColor: Colors.red));
                      return;
                    }
                    final body = {'qty': qty, 'notes': noteCtrl.text.trim()};
                    late Future<dynamic> call;
                    if (mode == 'tambah') {
                      call = DataService.tambahStokIngredient(ing.id, body);
                    } else if (mode == 'kurangi') {
                      call = DataService.kurangiStokIngredient(ing.id, body);
                    } else {
                      call = DataService.penyesuaianStokIngredient(ing.id, body);
                    }
                    final res = await call;
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res.success ? 'Stok berhasil diperbarui' : (res.message.isNotEmpty ? res.message : 'Gagal')),
                        backgroundColor: res.success ? Colors.green : Colors.red,
                      ));
                      if (res.success) _loadAll();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mode == 'tambah' ? _green : (mode == 'kurangi' ? _orange : Colors.purple),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(mode == 'tambah' ? 'Tambah Stok' : (mode == 'kurangi' ? 'Kurangi Stok' : 'Sesuaikan'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String label, String value, Color color, String current, void Function(String) onSelect) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? color : Colors.grey)),
      ),
    );
  }

  Future<void> _delete(BuildContext ctx, Ingredient ing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Bahan Baku'),
        content: Text('Yakin hapus "${ing.name}"?'),
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
    final res = await DataService.deleteIngredient(ing.id);
    if (ctx.mounted) Navigator.pop(ctx);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success ? 'Bahan baku dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal')),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ));
      if (res.success) _loadAll();
    }
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboard, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, keyboardType: keyboard, maxLines: maxLines,
        decoration: InputDecoration(
          filled: true, fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }

  void _showDetail(Ingredient ing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IngDetailSheet(ingredient: ing, currency: _currency),
    );
  }

  Widget _buildCard(Ingredient ing) {
    final stock = ing.stock ?? 0;
    final Color sc = stock <= 0 ? Colors.red : (stock < 10 ? Colors.orange : _green);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _cyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.science_outlined, color: _cyan, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text('${ing.categoryName ?? '-'} • ${ing.unitName ?? '-'}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text('${stock.toInt()} ${ing.unitName ?? ''}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sc)),
            ),
            if (ing.price != null && ing.price! > 0)
              Text(_currency.format(ing.price), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ]),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _quickBtn('Detail', Icons.visibility_outlined, Colors.blue, () => _showDetail(ing))),
          const SizedBox(width: 6),
          Expanded(child: _quickBtn('Edit', Icons.edit_outlined, _cyan, () => _showForm(ing: ing))),
          const SizedBox(width: 6),
          Expanded(child: _quickBtn('Stok', Icons.inventory_2_outlined, _green, () => _showStokDialog(ing))),
        ]),
      ]),
    );
  }

  Widget _quickBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) {
            _search = v;
            _loadPage(1);
          },
          decoration: InputDecoration(
            hintText: 'Cari bahan baku...',
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _search.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 18),
                    onPressed: () { _searchCtrl.clear(); _search = ''; _loadPage(1); })
                : null,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(children: [
                _items.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.science_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Belum ada bahan baku', style: TextStyle(color: Colors.grey[500])),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _buildCard(_items[i]),
                      ),
                if (_isPageLoading) const Center(child: CircularProgressIndicator()),
              ]),
      ),
      PaginationWidget(
        currentPage: _currentPage,
        lastPage: _lastPage,
        total: _total,
        onPageChanged: _loadPage,
      ),
    ]);
  }

  void showAddForm() => _showForm();
}

// ── Detail Sheet: Riwayat Stok Bahan Baku ───────────────────────────────────
class _IngDetailSheet extends StatefulWidget {
  final Ingredient ingredient;
  final NumberFormat currency;
  const _IngDetailSheet({required this.ingredient, required this.currency});
  @override
  State<_IngDetailSheet> createState() => _IngDetailSheetState();
}

class _IngDetailSheetState extends State<_IngDetailSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];
  static const _cyan = Color(0xFF00ADEF);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await DataService.getIngredientHistories(ingredientId: widget.ingredient.id);
      if (mounted) setState(() {
        _history = data.map((h) => {
          'tipe': h.tipe,
          'qty': h.qty,
          'stok_sesudah': h.stokSesudah,
          'catatan': h.catatan,
          'created_at': h.createdAt,
          'user_name': h.userName,
        }).toList();
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _cyan.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.science_outlined, color: _cyan, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ing.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  Text('${ing.categoryName ?? '-'} • ${ing.unitName ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _cyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('Stok: ${ing.stock?.toInt() ?? 0} ${ing.unitName ?? ''}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _cyan)),
                ),
              ]),
              if (ing.price != null && ing.price! > 0) ...[
                const SizedBox(height: 8),
                Text('Harga: ${widget.currency.format(ing.price)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ]),
          ),
          const Divider(height: 1),
          // Riwayat
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: _cyan))
              : _history.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.history, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('Belum ada riwayat stok', style: TextStyle(color: Colors.grey[500])),
                  ]))
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (_, i) {
                      final h = _history[i];
                      final tipe = h['tipe'] as String? ?? '';
                      final isIn = tipe == 'masuk';
                      final color = isIn ? Colors.green : Colors.red;
                      final icon  = isIn ? Icons.arrow_downward : Icons.arrow_upward;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(icon, size: 16, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(tipe.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                            if (h['catatan'] != null && (h['catatan'] as String).isNotEmpty)
                              Text(h['catatan'] as String, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            if (h['user_name'] != null)
                              Text('Oleh: ${h['user_name']}', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${isIn ? '+' : '-'}${h['qty']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
                            Text('→ ${h['stok_sesudah']}', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                          ]),
                        ]),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

