import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import 'purchase_form_screen.dart';

// ── Screen 1: Choose Product ─────────────────────────────────
class PurchaseProductSelectScreen extends StatefulWidget {
  final List<Product> products;
  final List<SelectedItem> selected;
  const PurchaseProductSelectScreen({super.key, required this.products, required this.selected});
  @override
  State<PurchaseProductSelectScreen> createState() => _ChooseState();
}

class _ChooseState extends State<PurchaseProductSelectScreen> {
  static const _blue = Color(0xFF00ADEF);
  final _fmt = NumberFormat.currency(locale:'id_ID', symbol:'Rp ', decimalDigits:0);
  String _q = '';
  late final List<SelectedItem> _working;

  @override
  void initState() {
    super.initState();
    _working = widget.selected.map((i) => SelectedItem(product: i.product, qty: i.qty, price: i.price, unit: i.unit)).toList();
  }

  List<Product> get _filtered => widget.products
      .where((p) => p.name.toLowerCase().contains(_q.toLowerCase()))
      .toList();

  bool _isSelected(Product p) => _working.any((i) => i.product.id == p.id);

  void _toggle(Product p) {
    setState(() {
      if (_isSelected(p)) {
        _working.removeWhere((i) => i.product.id == p.id);
      } else {
        _working.add(SelectedItem(product: p));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Pilih Produk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: Column(children: [
        // Search
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Cari nama produk...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true, fillColor: const Color(0xFFF2F3F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        // Selected count indicator
        if (_working.isNotEmpty)
          Container(
            color: _blue.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Icon(Icons.check_circle, color: _blue, size: 16),
              const SizedBox(width: 8),
              Text('${_working.length} produk dipilih',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _blue)),
            ]),
          ),

        Expanded(
          child: filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(_q.isNotEmpty ? 'Produk tidak ditemukan' : 'Belum ada produk',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                const SizedBox(height: 4),
                Text(_q.isNotEmpty ? 'Coba kata kunci lain' : 'Tambahkan produk terlebih dahulu',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  final sel = _isSelected(p);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: sel ? Border.all(color: _blue, width: 2) : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: const Color(0xFFF2F3F5), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 22),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Row(children: [
                        Text(_fmt.format(p.basePrice), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(width: 8),
                        Text('Stok: ${p.stock}',
                          style: TextStyle(fontSize: 11, color: p.stock > 0 ? Colors.green[600] : Colors.red[600],
                            fontWeight: FontWeight.w600)),
                      ]),
                      trailing: sel
                          ? const Icon(Icons.check_circle_rounded, color: _blue, size: 24)
                          : Icon(Icons.add_circle_outline, color: Colors.grey[400], size: 24),
                      onTap: () => _toggle(p),
                    ),
                  );
                },
              ),
        ),
      ]),

      // Review button
      bottomNavigationBar: _working.isEmpty ? null : Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final result = await Navigator.push<List<SelectedItem>>(context,
                  MaterialPageRoute(builder: (_) => PurchaseReviewScreen(items: _working)));
              if (result != null) nav.pop(result);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Review Produk Terpilih (${_working.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}

// ── Screen 2: Review & Edit Selected ────────────────────────
class PurchaseReviewScreen extends StatefulWidget {
  final List<SelectedItem> items;
  const PurchaseReviewScreen({super.key, required this.items});
  @override
  State<PurchaseReviewScreen> createState() => _ReviewState();
}

class _ReviewState extends State<PurchaseReviewScreen> {
  static const _blue = Color(0xFF00ADEF);
  final _fmt = NumberFormat.currency(locale:'id_ID', symbol:'Rp ', decimalDigits:0);
  final _units = ['pcs','kg','liter','box','lusin','dus','karton','roll','lembar','meter'];
  late final List<SelectedItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  double get _total => _items.fold(0, (s, i) => s + i.subtotal);

  void _removeItem(int idx) {
    setState(() => _items.removeAt(idx));
    if (_items.isEmpty) {
      // Auto-navigate back when all items removed (after frame)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _editItem(int idx) async {
    final item = _items[idx];
    final qtyCtrl = TextEditingController(text: item.qty.toString());
    final priceCtrl = TextEditingController(text: item.price.toInt().toString());
    String unit = item.unit;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(item.product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _inputField('Jumlah', qtyCtrl, TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Satuan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _units.contains(unit) ? unit : _units.first,
                    isExpanded: true, underline: const SizedBox(),
                    onChanged: (v) => setModal(() => unit = v ?? 'pcs'),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
                  ),
                ),
              ])),
            ]),
            const SizedBox(height: 12),
            _inputField('Harga Beli (Rp)', priceCtrl, TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _items[idx].qty   = double.tryParse(qtyCtrl.text) ?? item.qty;
                  _items[idx].price = double.tryParse(priceCtrl.text.replaceAll('.','')) ?? item.price;
                  _items[idx].unit  = unit;
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w800)),
            )),
          ]),
        ),
      )),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, TextInputType type) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, keyboardType: type,
        decoration: InputDecoration(
          filled: true, fillColor: const Color(0xFFF2F3F5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_items.length} Produk Dipilih',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
          const Text('Tap Edit untuk ubah qty & harga', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
      body: _items.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.remove_shopping_cart_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Tidak ada produk dipilih', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 4),
            Text('Kembali dan pilih produk', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Kembali Pilih Produk'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue,
                side: const BorderSide(color: _blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final item = _items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: const Color(0xFFF2F3F5), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(_fmt.format(item.price), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ])),
                      IconButton(
                        onPressed: () => _removeItem(i),
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                      ),
                    ]),
                  ),

                  // Qty + Edit
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: const Color(0xFFF8F9FA),
                    child: Row(children: [
                      Text('(+${item.qty % 1 == 0 ? item.qty.toInt() : item.qty} ${item.unit})',
                          style: const TextStyle(color: _blue, fontWeight: FontWeight.w700, fontSize: 14)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _editItem(i),
                        child: const Row(children: [
                          Icon(Icons.edit_outlined, size: 15, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Edit', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                  ),

                  // Subtotal
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Subtotal', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(_fmt.format(item.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
              );
            },
          ),

      bottomNavigationBar: _items.isEmpty ? null : Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: Row(children: [
          Expanded(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fmt.format(_total), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _blue)),
              const Text('Total Harga', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _items),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Simpan Pilihan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          )),
        ]),
      ),
    );
  }
}
