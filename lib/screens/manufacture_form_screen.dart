import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/ingredient.dart';
import '../models/product.dart';
import '../models/unit_model.dart';

class ManufactureFormScreen extends StatefulWidget {
  final int? existingId;
  const ManufactureFormScreen({super.key, this.existingId});
  bool get isEdit => existingId != null;
  @override
  State<ManufactureFormScreen> createState() => _ManufactureFormScreenState();
}

// Model cart item bahan baku
class _IngCart {
  final Ingredient ingredient;
  double qty;
  double price;
  int unitId;
  String unitName;
  _IngCart({required this.ingredient, required this.qty, required this.price, required this.unitId, required this.unitName});
}

// Model cart item produk dihasilkan
class _ProdCart {
  final Product product;
  double qty;
  double costPerItem;
  int unitId;
  String unitName;
  _ProdCart({required this.product, required this.qty, required this.costPerItem, required this.unitId, required this.unitName});
}

class _ManufactureFormScreenState extends State<ManufactureFormScreen> with SingleTickerProviderStateMixin {
  static const _cyan = Color(0xFF00ADEF);

  bool _isLoading = true;
  bool _isSaving = false;
  late TabController _tabCtrl;

  List<Ingredient> _ingredients = [];
  List<Product> _products = [];
  List<UnitModel> _units = [];

  final List<_IngCart> _ingCart = [];
  final List<_ProdCart> _prodCart = [];

  String _type = 'manufacture';
  final _dateCtrl = TextEditingController();
  String _ingSearch = '';
  String _prodSearch = '';

  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadData();
  }

  int? get _existingId => widget.existingId;

  @override
  void dispose() {
    _tabCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = [
        DataService.getIngredients(),
        DataService.getProducts(),
        DataService.getUnits(),
      ];
      final res = await Future.wait(futures);
      if (!mounted) return;
      _ingredients = res[0] as List<Ingredient>;
      _products    = res[1] as List<Product>;
      _units       = res[2] as List<UnitModel>;

      // Pre-fill edit mode
      if (_existingId != null) {
        final detail = await DataService.getManufactureDetail(_existingId!);
        if (detail != null && mounted) {
          _type = detail.type;
          if (detail.manufactureDate != null) _dateCtrl.text = detail.manufactureDate!;

          // Pre-fill ingredient cart
          if (detail.ingredients != null) {
            for (final ing in detail.ingredients!) {
              final matches = _ingredients.where((i) => i.id == ing.ingredientId).toList();
              if (matches.isEmpty) continue;
              final unitMatch = _units.where((u) => u.id == ing.unitId).toList();
              _ingCart.add(_IngCart(
                ingredient: matches.first,
                qty: ing.quantity,
                price: ing.price,
                unitId: ing.unitId,
                unitName: unitMatch.isNotEmpty ? unitMatch.first.name : ing.unitName,
              ));
            }
          }

          // Pre-fill produced products cart
          if (detail.producedProducts != null) {
            for (final pp in detail.producedProducts!) {
              final matches = _products.where((p) => p.id == pp.productId).toList();
              if (matches.isEmpty) continue;
              final unitMatch = _units.where((u) => u.id == pp.unitId).toList();
              _prodCart.add(_ProdCart(
                product: matches.first,
                qty: pp.quantity,
                costPerItem: pp.costPerItem,
                unitId: pp.unitId,
                unitName: unitMatch.isNotEmpty ? unitMatch.first.name : '',
              ));
            }
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  double get _totalBiaya => _ingCart.fold(0, (s, i) => s + i.qty * i.price);

  void _addIngredient(Ingredient ing) {
    if (_ingCart.any((c) => c.ingredient.id == ing.id)) return;
    final unit = _units.where((u) => u.id == ing.unitId).toList();
    final unitId   = unit.isNotEmpty ? unit.first.id   : (_units.isNotEmpty ? _units.first.id   : 0);
    final unitName = unit.isNotEmpty ? unit.first.name : '';
    _showIngDialog(_IngCart(ingredient: ing, qty: 1, price: ing.price ?? 0, unitId: unitId, unitName: unitName));
  }

  void _showIngDialog(_IngCart item, {int? editIndex}) {
    final qCtrl = TextEditingController(text: item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2));
    final pCtrl = TextEditingController(text: item.price.toInt().toString());
    int selUnit = item.unitId;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setM) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(item.ingredient.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _field('Qty', qCtrl, keyboard: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field('Harga/satuan (Rp)', pCtrl, keyboard: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            const Text('Satuan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: selUnit,
              decoration: InputDecoration(filled: true, fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: _units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
              onChanged: (v) => setM(() => selUnit = v ?? selUnit),
            ),
            const SizedBox(height: 20),
            Row(children: [
              if (editIndex != null) ...[
                Expanded(child: OutlinedButton(
                  onPressed: () { setState(() => _ingCart.removeAt(editIndex)); Navigator.pop(ctx); },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Hapus'),
                )),
                const SizedBox(width: 12),
              ],
              Expanded(child: ElevatedButton(
                onPressed: () {
                  final q = double.tryParse(qCtrl.text) ?? 0;
                  final p = double.tryParse(pCtrl.text) ?? 0;
                  if (q <= 0) return;
                  final unitName = _units.where((u) => u.id == selUnit).map((u) => u.name).firstOrNull ?? '';
                  setState(() {
                    if (editIndex != null) {
                      _ingCart[editIndex]
                        ..qty = q ..price = p ..unitId = selUnit ..unitName = unitName;
                    } else {
                      _ingCart.add(_IngCart(ingredient: item.ingredient, qty: q, price: p, unitId: selUnit, unitName: unitName));
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Simpan'),
              )),
            ]),
          ]),
        ),
      )),
    );
  }

  void _addProduct(Product prod) {
    if (_prodCart.any((c) => c.product.id == prod.id)) return;
    final unit = _units.where((u) => u.id == prod.unitId).toList();
    final unitId   = unit.isNotEmpty ? unit.first.id   : (_units.isNotEmpty ? _units.first.id   : 0);
    final unitName = unit.isNotEmpty ? unit.first.name : '';
    _showProdDialog(_ProdCart(product: prod, qty: 1, costPerItem: prod.basePrice, unitId: unitId, unitName: unitName));
  }

  void _showProdDialog(_ProdCart item, {int? editIndex}) {
    final qCtrl = TextEditingController(text: item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2));
    final cCtrl = TextEditingController(text: item.costPerItem.toInt().toString());
    int selUnit = item.unitId;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setM) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(item.product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _field('Qty dihasilkan', qCtrl, keyboard: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field('Harga Pokok/pcs (Rp)', cCtrl, keyboard: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            const Text('Satuan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: selUnit,
              decoration: InputDecoration(filled: true, fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: _units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
              onChanged: (v) => setM(() => selUnit = v ?? selUnit),
            ),
            const SizedBox(height: 20),
            Row(children: [
              if (editIndex != null) ...[
                Expanded(child: OutlinedButton(
                  onPressed: () { setState(() => _prodCart.removeAt(editIndex)); Navigator.pop(ctx); },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Hapus'),
                )),
                const SizedBox(width: 12),
              ],
              Expanded(child: ElevatedButton(
                onPressed: () {
                  final q = double.tryParse(qCtrl.text) ?? 0;
                  final c = double.tryParse(cCtrl.text) ?? 0;
                  if (q <= 0) return;
                  final unitName = _units.where((u) => u.id == selUnit).map((u) => u.name).firstOrNull ?? '';
                  setState(() {
                    if (editIndex != null) {
                      _prodCart[editIndex]
                        ..qty = q ..costPerItem = c ..unitId = selUnit ..unitName = unitName;
                    } else {
                      _prodCart.add(_ProdCart(product: item.product, qty: q, costPerItem: c, unitId: selUnit, unitName: unitName));
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Simpan'),
              )),
            ]),
          ]),
        ),
      )),
    );
  }

  Future<void> _save() async {
    if (_ingCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 bahan baku'), backgroundColor: Colors.red));
      return;
    }
    if (_prodCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 produk yang dihasilkan'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final data = {
        'type': _type,
        'manufacture_date': _dateCtrl.text,
        'total_price': _totalBiaya.toInt(),
        'ingredients': _ingCart.map((i) => {
          'ingredient_id': i.ingredient.id,
          'quantity': i.qty,
          'price': i.price,
          'unit_id': i.unitId,
        }).toList(),
        'produced_products': _prodCart.map((p) => {
          'product_id': p.product.id,
          'quantity': p.qty,
          'unit_id': p.unitId,
          'cost_per_item': p.costPerItem,
        }).toList(),
      };
      final res = widget.isEdit
          ? await DataService.updateManufacture(_existingId!, data)
          : await DataService.createManufacture(data);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.isEdit ? 'Produksi berhasil diubah' : 'Produksi berhasil disimpan'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Gagal menyimpan'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboard}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, keyboardType: keyboard,
        decoration: InputDecoration(filled: true, fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final filteredIng  = _ingredients.where((i) => i.name.toLowerCase().contains(_ingSearch.toLowerCase())).toList();
    final filteredProd = _products.where((p) => p.name.toLowerCase().contains(_prodSearch.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _cyan), onPressed: () => Navigator.pop(context)),
        title: Text(widget.isEdit ? 'Edit Produksi' : 'Catat Produksi', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          if (_isSaving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined, color: _cyan),
              label: const Text('Simpan', style: TextStyle(color: _cyan, fontWeight: FontWeight.bold)),
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _cyan,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _cyan,
          tabs: [
            Tab(text: 'Bahan Baku (${_ingCart.length})'),
            Tab(text: 'Produk Hasil (${_prodCart.length})'),
          ],
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(children: [
            // Header info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tipe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, children: ['manufacture', 'general'].map((t) => ChoiceChip(
                    label: Text(t[0].toUpperCase() + t.substring(1), style: const TextStyle(fontSize: 12)),
                    selected: _type == t,
                    selectedColor: _cyan.withValues(alpha: 0.15),
                    onSelected: (_) => setState(() => _type = t),
                  )).toList()),
                ])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tanggal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (p != null) _dateCtrl.text = DateFormat('yyyy-MM-dd').format(p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: _cyan),
                        const SizedBox(width: 6),
                        Text(_dateCtrl.text, style: const TextStyle(fontSize: 13)),
                      ]),
                    ),
                  ),
                ])),
                if (_totalBiaya > 0) ...[
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('Total Biaya', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(_currency.format(_totalBiaya), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _cyan)),
                  ]),
                ],
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(controller: _tabCtrl, children: [
                // ── Tab 1: Bahan Baku ──────────────────────────────
                Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      onChanged: (v) => setState(() => _ingSearch = v),
                      decoration: InputDecoration(
                        hintText: 'Cari bahan baku...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_ingCart.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
                      child: Column(children: _ingCart.asMap().entries.map((e) => GestureDetector(
                        onTap: () => _showIngDialog(e.value, editIndex: e.key),
                        child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
                          const Icon(Icons.science_outlined, size: 14, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${e.value.ingredient.name} — ${e.value.qty} ${e.value.unitName}', style: const TextStyle(fontSize: 12))),
                          Text(_currency.format(e.value.qty * e.value.price), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange)),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined, size: 12, color: Colors.grey),
                        ])),
                      )).toList()),
                    ),
                  ],
                  Expanded(child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: filteredIng.length,
                    itemBuilder: (_, i) {
                      final ing = filteredIng[i];
                      final inCart = _ingCart.any((c) => c.ingredient.id == ing.id);
                      return GestureDetector(
                        onTap: () => inCart ? null : _addIngredient(ing),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: inCart ? Colors.orange[50] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: inCart ? Border.all(color: Colors.orange, width: 1.5) : null,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Row(children: [
                            Icon(Icons.science_outlined, color: inCart ? Colors.orange : Colors.grey[400], size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(ing.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: inCart ? Colors.orange[800] : Colors.black87)),
                              Text('Stok: ${ing.stock?.toInt() ?? 0} ${ing.unitName ?? ''}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ])),
                            if (inCart)
                              const Icon(Icons.check_circle, color: Colors.orange, size: 18)
                            else
                              const Icon(Icons.add_circle_outline, color: _cyan, size: 18),
                          ]),
                        ),
                      );
                    },
                  )),
                ]),

                // ── Tab 2: Produk yang Dihasilkan ──────────────────
                Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      onChanged: (v) => setState(() => _prodSearch = v),
                      decoration: InputDecoration(
                        hintText: 'Cari produk yang dihasilkan...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_prodCart.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.withValues(alpha: 0.3))),
                      child: Column(children: _prodCart.asMap().entries.map((e) => GestureDetector(
                        onTap: () => _showProdDialog(e.value, editIndex: e.key),
                        child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
                          const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${e.value.product.name} — ${e.value.qty} ${e.value.unitName}', style: const TextStyle(fontSize: 12))),
                          Text('HPP: ${_currency.format(e.value.costPerItem)}', style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined, size: 12, color: Colors.grey),
                        ])),
                      )).toList()),
                    ),
                  ],
                  Expanded(child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: filteredProd.length,
                    itemBuilder: (_, i) {
                      final prod = filteredProd[i];
                      final inCart = _prodCart.any((c) => c.product.id == prod.id);
                      return GestureDetector(
                        onTap: () => inCart ? null : _addProduct(prod),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: inCart ? Colors.indigo[50] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: inCart ? Border.all(color: Colors.indigo, width: 1.5) : null,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Row(children: [
                            Icon(Icons.inventory_2_outlined, color: inCart ? Colors.indigo : Colors.grey[400], size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(prod.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: inCart ? Colors.indigo[800] : Colors.black87)),
                              Text('Stok: ${prod.stock}  |  ${_currency.format(prod.basePrice)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ])),
                            if (inCart)
                              const Icon(Icons.check_circle, color: Colors.indigo, size: 18)
                            else
                              const Icon(Icons.add_circle_outline, color: Colors.indigo, size: 18),
                          ]),
                        ),
                      );
                    },
                  )),
                ]),
              ]),
            ),
          ]),
    );
  }
}
