import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/data_service.dart';
import '../../../models/product.dart';
import '../../../models/category.dart';
import '../../../models/unit_model.dart';

class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});
  @override
  State<InventoryTab> createState() => InventoryTabState();
}

class InventoryTabState extends State<InventoryTab> {
  bool _isLoading = true;
  List<Product> _products = [];
  List<Product> _filtered = [];
  List<Category> _categories = [];
  List<UnitModel> _units = [];
  String _search = '';
  int? _selectedCategoryId;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const _cyanBlue = Color(0xFF00ADEF);
  static const _darkBlue = Color(0xFF0077B6);

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DataService.getProducts(),
        DataService.getCategories(),
        DataService.getUnits(),
      ]);
      if (mounted) {
        setState(() {
          _products = results[0] as List<Product>;
          _categories = results[1] as List<Category>;
          _units = results[2] as List<UnitModel>;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  void _applyFilter() {
    _filtered = _products.where((p) {
      final matchSearch = _search.isEmpty || p.name.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchSearch && matchCat;
    }).toList();
  }

  // ── FORM Tambah / Edit (public agar bisa dipanggil dari parent) ─────────
  void showAddForm() => _showForm();

  void _showForm({Product? product}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final basePriceCtrl = TextEditingController(
        text: product != null && product.basePrice != 0 ? product.basePrice.toInt().toString() : '');
    
    int? selectedCategoryId = product?.categoryId;
    int? selectedUnitId = product?.unitId;
    bool isManufacture = product?.isManufacture ?? false;
    String status = product?.status ?? 'active';

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar + header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(children: [
                    Center(child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(product == null ? 'Tambah Produk' : 'Edit Produk',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      IconButton(onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded), color: Colors.grey),
                    ]),
                  ]),
                ),
                const Divider(),
                // Scrollable form body
                SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    
                    // Gambar Produk Upload Placeholder
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

                    // Row 1: Nama & Kategori
                    Row(children: [
                      Expanded(child: _inputField('Nama Produk *', nameCtrl, hint: 'Contoh: Jelly Powder')),
                      const SizedBox(width: 12),
                      Expanded(child: _dropdownField<int?>(
                        label: 'Kategori *',
                        value: selectedCategoryId,
                        items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (v) => setModal(() => selectedCategoryId = v),
                        hint: 'Pilih kategori',
                      )),
                    ]),
                    const SizedBox(height: 14),

                    // Row 2: Harga Dasar & Satuan
                    Row(children: [
                      Expanded(child: _inputField('Harga Dasar *', basePriceCtrl, type: TextInputType.number, prefix: 'Rp')),
                      const SizedBox(width: 12),
                      Expanded(child: _dropdownField<int?>(
                        label: 'Satuan Produk',
                        value: selectedUnitId,
                        items: _units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
                        onChanged: (v) => setModal(() => selectedUnitId = v),
                        hint: 'Pilih satuan',
                      )),
                    ]),
                    const SizedBox(height: 14),

                    // Is Manufacture toggle
                    GestureDetector(
                      onTap: () => setModal(() => isManufacture = !isManufacture),
                      child: Row(children: [
                        SizedBox(
                          width: 22, height: 22,
                          child: Checkbox(
                            value: isManufacture,
                            activeColor: _cyanBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (v) => setModal(() => isManufacture = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('Apakah produk ini manufaktur?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                      onChanged: (v) => setModal(() => status = v ?? 'active'),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nama produk wajib diisi'), backgroundColor: Colors.red));
                            return;
                          }
                          if (selectedCategoryId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kategori wajib dipilih'), backgroundColor: Colors.red));
                            return;
                          }
                          final data = {
                            'name': nameCtrl.text.trim(),
                            'category_id': selectedCategoryId,
                            'unit_id': selectedUnitId,
                            'base_price': double.tryParse(basePriceCtrl.text) ?? 0,
                            'is_manufacture': isManufacture ? 1 : 0,
                            'status': status,
                          };
                          final res = product == null
                              ? await DataService.createProduct(data)
                              : await DataService.updateProduct(product.id, data);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (res.success) _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(res.success ? (product == null ? 'Produk ditambahkan' : 'Produk diperbarui') : res.message),
                              backgroundColor: res.success ? _darkBlue : Colors.red,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cyanBlue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(product == null ? 'Simpan' : 'Simpan Perubahan',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Konfirmasi Hapus ─────────────────────────────────────────────────────
  Future<void> _confirmDelete(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Produk "${p.name}" akan dihapus secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final res = await DataService.deleteProduct(p.id);
      if (res.success) _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.success ? 'Produk dihapus' : res.message),
          backgroundColor: res.success ? Colors.green : Colors.red,
        ));
      }
    }
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('eCOMMERCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _cyanBlue, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    const Text('Produk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFE0F7FF), borderRadius: BorderRadius.circular(20)),
                    child: Text('${_filtered.length} item', style: const TextStyle(fontSize: 12, color: _darkBlue, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 16),
                // Search
                TextField(
                  onChanged: (v) => setState(() { _search = v; _applyFilter(); }),
                  decoration: InputDecoration(
                    hintText: 'Cari nama produk...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: _cyanBlue),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                // Category chips
                SizedBox(
                  height: 36,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    _chip('Semua', null),
                    ..._categories.map((c) => _chip(c.name, c.id)),
                  ]),
                ),
                const SizedBox(height: 12),
              ]),
            ),
            // Product list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _cyanBlue))
                  : RefreshIndicator(
                      onRefresh: _loadData, color: _cyanBlue,
                      child: _filtered.isEmpty
                          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('Tidak ada produk', style: TextStyle(color: Colors.grey[500])),
                            ]))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) => _buildProductCard(_filtered[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int? id) {
    final selected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() { _selectedCategoryId = id; _applyFilter(); }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _cyanBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _cyanBlue : Colors.grey[300]!),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey[700])),
      ),
    );
  }

  Widget _buildProductCard(Product p) {
    Color stockColor;
    if (p.stock == 0) {
      stockColor = Colors.red;
    } else if (p.isLowStock) {
      stockColor = Colors.orange;
    } else {
      stockColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showForm(product: p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: p.isManufacture ? const Color(0xFFF3E5F5) : const Color(0xFFE0F7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                p.isManufacture ? Icons.precision_manufacturing : Icons.inventory_2_outlined,
                color: p.isManufacture ? Colors.purple : _cyanBlue, size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                if (p.categoryName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                    child: Text(p.categoryName!, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(_currency.format(p.unitPrice > 0 ? p.unitPrice : p.basePrice),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _cyanBlue)),
              ]),
            ])),
            const SizedBox(width: 8),
            // Stock + actions
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: stockColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${p.stock}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: stockColor)),
              ),
              const SizedBox(height: 6),
              // Delete button
              GestureDetector(
                onTap: () => _confirmDelete(p),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 16),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────────
  Widget _inputField(String label, TextEditingController ctrl,
      {TextInputType? type, int lines = 1, String? hint, String? prefix}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixText: prefix != null ? '$prefix ' : null,
          prefixStyle: const TextStyle(color: _cyanBlue, fontWeight: FontWeight.w700),
          filled: true, fillColor: const Color(0xFFF8F9FE),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cyanBlue, width: 1.5)),
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
          color: const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: Text(hint ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            isExpanded: true,
            items: items,
            onChanged: onChanged,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _cyanBlue),
          ),
        ),
      ),
    ]);
  }
}
