import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/unit_model.dart';

class EcommerceProdukTab extends StatefulWidget {
  const EcommerceProdukTab({super.key});
  @override
  State<EcommerceProdukTab> createState() => _EcommerceProdukTabState();
}

class _EcommerceProdukTabState extends State<EcommerceProdukTab> {
  bool _isLoading = true;
  bool _isLoadingPage = false;
  List<Product> _products = [];
  List<Category> _categories = [];
  List<UnitModel> _units = [];

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  static const int _perPage = 15;

  // Search
  String _search = '';
  final _searchCtrl = TextEditingController();

  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static const _cyan = Color(0xFF00ADEF);

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    try {
      final res = await Future.wait([DataService.getCategories(), DataService.getUnits()]);
      if (mounted) setState(() {
        _categories = res[0] as List<Category>;
        _units       = res[1] as List<UnitModel>;
      });
    } catch (_) {}
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    if (page < 1 || (page > _lastPage && _lastPage > 0 && page != 1)) return;
    setState(() { page == 1 && _products.isEmpty ? _isLoading = true : _isLoadingPage = true; });
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$_perPage',
        if (_search.isNotEmpty) 'search': _search,
      };
      final res = await ApiService.get('products', params: params);
      if (mounted && res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final list = (data['data'] as List? ?? []).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        final meta = data['meta'] as Map<String, dynamic>? ?? {};
        setState(() {
          _products    = list;
          _currentPage = meta['current_page'] as int? ?? page;
          _lastPage    = meta['last_page'] as int? ?? 1;
          _total       = meta['total'] as int? ?? list.length;
          _isLoading   = false;
          _isLoadingPage = false;
        });
      } else {
        if (mounted) setState(() { _isLoading = false; _isLoadingPage = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _isLoadingPage = false; });
    }
  }

  void _onSearch(String val) {
    _search = val;
    _loadPage(1);
  }

  void _showForm({Product? product}) {
    final nameCtrl      = TextEditingController(text: product?.name ?? '');
    final basePriceCtrl = TextEditingController(
        text: product != null && product.basePrice != 0 ? product.basePrice.toInt().toString() : '');

    Category? selectedCategory;
    if (product?.categoryId != null) {
      try { selectedCategory = _categories.firstWhere((c) => c.id == product!.categoryId); } catch (_) {}
    }

    UnitModel? selectedUnit;
    if (product?.unitId != null) {
      try { selectedUnit = _units.firstWhere((u) => u.id == product!.unitId); } catch (_) {}
    }

    bool isManufacture = product?.isManufacture ?? false;
    String status = product?.status ?? 'active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle bar
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(product == null ? 'Tambah Produk' : 'Edit Produk',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ]),
              ),
              const Divider(height: 1),
              // Form fields (scrollable)
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Gambar Produk Placeholder
                  Text('Gambar Produk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                    ),
                    child: Center(
                      child: Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[400], size: 40),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Upload gambar produk. Hanya *.png, *.jpg, dan *.jpeg',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const SizedBox(height: 20),

                  // Row 1: Nama Produk | Kategori
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _formField('Nama Produk *', nameCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _dropdownField<Category?>(
                      label: 'Kategori *',
                      value: selectedCategory,
                      hint: 'Pilih Kategori',
                      items: _categories.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setM(() => selectedCategory = v),
                    )),
                  ]),
                  const SizedBox(height: 14),

                  // Row 2: Harga Dasar | Satuan Produk
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _formField('Harga Dasar *', basePriceCtrl,
                        keyboard: TextInputType.number, hint: 'Harga Dasar')),
                    const SizedBox(width: 12),
                    Expanded(child: _dropdownField<UnitModel?>(
                      label: 'Satuan Produk',
                      value: selectedUnit,
                      hint: 'Pilih Satuan',
                      items: _units.map((u) => DropdownMenuItem(
                        value: u,
                        child: Text(u.name),
                      )).toList(),
                      onChanged: (v) => setM(() => selectedUnit = v),
                    )),
                  ]),
                  const SizedBox(height: 16),

                  // Checkbox: Manufaktur
                  GestureDetector(
                    onTap: () => setM(() => isManufacture = !isManufacture),
                    child: Row(children: [
                      SizedBox(
                        width: 22, height: 22,
                        child: Checkbox(
                          value: isManufacture,
                          activeColor: _cyan,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setM(() => isManufacture = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Apakah produk ini manufaktur?',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Status Dropdown
                  _dropdownField<String>(
                    label: 'Status',
                    value: status,
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Aktif')),
                      DropdownMenuItem(value: 'inactive', child: Text('Tidak Aktif')),
                    ],
                    onChanged: (v) => setM(() => status = v ?? 'active'),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(children: [
                    if (product != null) ...[
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => _delete(ctx, product),
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      )),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Nama produk wajib diisi'), backgroundColor: Colors.red));
                          return;
                        }
                        if (selectedCategory == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Kategori wajib dipilih'), backgroundColor: Colors.red));
                          return;
                        }
                        if (basePriceCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Harga dasar wajib diisi'), backgroundColor: Colors.red));
                          return;
                        }
                        final data = {
                          'name'          : nameCtrl.text.trim(),
                          'category_id'   : selectedCategory!.id,
                          'base_price'    : double.tryParse(basePriceCtrl.text.replaceAll(',', '').replaceAll('.', '')) ?? 0,
                          'unit_id'       : selectedUnit?.id,
                          'is_manufacture': isManufacture ? 1 : 0,
                          'status'        : status,
                        };
                        final res = product == null
                            ? await DataService.createProduct(data)
                            : await DataService.updateProduct(product.id, data);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(res.success
                            ? (product == null ? 'Produk berhasil ditambahkan' : 'Produk berhasil diubah')
                            : (res.message.isNotEmpty ? res.message : 'Gagal menyimpan')),
                          backgroundColor: res.success ? Colors.green : Colors.red,
                        ));
                        if (res.success) _loadPage(_currentPage);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyan,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(product == null ? 'Simpan' : 'Simpan Perubahan',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )),
                  ]),
                  const SizedBox(height: 8),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext ctx, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin hapus produk "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(d, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    final res = await DataService.deleteProduct(p.id);
    if (ctx.mounted) Navigator.pop(ctx);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success ? 'Produk dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal')),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ));
      if (res.success) _loadPage(_currentPage);
    }
  }

  Widget _formField(String label, TextEditingController ctrl,
      {TextInputType? keyboard, String? hint}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          filled: true, fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? hint,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: Text(hint ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            isExpanded: true,
            items: items,
            onChanged: onChanged,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _cyan),
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'Cari produk...',
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _search.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, size: 18),
                  onPressed: () { _searchCtrl.clear(); _onSearch(''); })
              : null,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),

      // Info total & halaman
      if (!_isLoading) Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total: $_total produk', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Text('Hal $_currentPage / $_lastPage', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]),
      ),

      // List produk
      Expanded(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadPage(1),
              child: _products.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Tidak ada produk', style: TextStyle(color: Colors.grey[500])),
                  ]))
                : Stack(children: [
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: _products.length,
                      itemBuilder: (_, i) {
                        final p = _products[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(children: [
                            Container(width: 42, height: 42,
                              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.inventory_2_outlined, color: Colors.blue[400], size: 20)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (p.status == 'active' ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6)),
                                  child: Text(p.status == 'active' ? 'Aktif' : 'Nonaktif',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                      color: p.status == 'active' ? Colors.green[700] : Colors.red[700])),
                                ),
                              ]),
                              const SizedBox(height: 3),
                              Text(_currency.format(p.basePrice), style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.w600)),
                              if (p.categoryName != null)
                                Text(p.categoryName!, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('${p.stock}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                                color: p.stock > 5 ? Colors.green[700] : Colors.red)),
                              Text('stok', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                            ]),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showForm(product: p),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: _cyan.withValues(alpha: 0.08), shape: BoxShape.circle),
                                child: const Icon(Icons.edit_outlined, size: 16, color: _cyan),
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
                    if (_isLoadingPage)
                      const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                  ]),
            ),
      ),

      // Pagination controls
      if (!_isLoading && _lastPage > 1)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Tombol Pertama
            _pgBtn(Icons.first_page, _currentPage > 1, () => _loadPage(1)),
            const SizedBox(width: 4),
            // Tombol Prev
            _pgBtn(Icons.chevron_left, _currentPage > 1, () => _loadPage(_currentPage - 1)),
            const SizedBox(width: 8),
            // Nomor halaman
            ..._buildPageNumbers(),
            const SizedBox(width: 8),
            // Tombol Next
            _pgBtn(Icons.chevron_right, _currentPage < _lastPage, () => _loadPage(_currentPage + 1)),
            const SizedBox(width: 4),
            // Tombol Terakhir
            _pgBtn(Icons.last_page, _currentPage < _lastPage, () => _loadPage(_lastPage)),
          ]),
        ),
    ]);
  }

  Widget _pgBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? Colors.grey[300]! : Colors.grey[200]!),
        ),
        child: Icon(icon, size: 18, color: enabled ? Colors.grey[700] : Colors.grey[400]),
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final pages = <int>{};
    pages.add(1);
    pages.add(_lastPage);
    for (int i = _currentPage - 1; i <= _currentPage + 1; i++) {
      if (i >= 1 && i <= _lastPage) pages.add(i);
    }
    final sorted = pages.toList()..sort();
    final widgets = <Widget>[];
    int? prev;
    for (final p in sorted) {
      if (prev != null && p - prev > 1) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('...', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
        ));
      }
      widgets.add(_pgNum(p));
      prev = p;
    }
    return widgets;
  }

  Widget _pgNum(int page) {
    final isCurrent = page == _currentPage;
    return GestureDetector(
      onTap: isCurrent ? null : () => _loadPage(page),
      child: Container(
        width: 34, height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isCurrent ? _cyan : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isCurrent ? _cyan : Colors.grey[300]!),
        ),
        child: Center(child: Text('$page',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: isCurrent ? Colors.white : Colors.grey[700]))),
      ),
    );
  }

  void showAddForm() => _showForm();
}
