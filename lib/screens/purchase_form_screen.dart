import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/incoming_product.dart';
import 'purchase_supplier_select.dart';
import 'purchase_product_select.dart';

// ── Selected item model ────────────────────────────────────────
class SelectedItem {
  Product product;
  double qty;
  double price;
  String unit;
  SelectedItem({required this.product, this.qty = 1, double? price, this.unit = 'pcs'})
      : price = price ?? product.basePrice.toDouble();
  double get subtotal => qty * price;
}

class PurchaseFormScreen extends StatefulWidget {
  final IncomingProduct? existing;
  const PurchaseFormScreen({super.key, this.existing});
  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  static const _blue = Color(0xFF00ADEF);
  static const _bg   = Color(0xFFF2F3F5);

  bool _isLoading = true, _isSaving = false;
  List<Product>  _products  = [];
  List<Supplier> _suppliers = [];

  Supplier?            _supplier;
  List<SelectedItem>   _items = [];
  String               _poNumber = '';
  final _dueDateCtrl = TextEditingController();

  final _fmt = NumberFormat.currency(locale:'id_ID', symbol:'Rp ', decimalDigits:0);
  bool get _isEdit => widget.existing != null;
  double get _total => _items.fold(0, (s, i) => s + i.subtotal);

  @override
  void initState() {
    super.initState();
    _poNumber = 'PO/${DateFormat('yyyyMMdd').format(DateTime.now())}/0001';
    _load();
  }

  @override
  void dispose() { _dueDateCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final r = await Future.wait([DataService.getProducts(), DataService.getSuppliers()]);
      if (!mounted) return;
      setState(() {
        _products  = r[0] as List<Product>;
        _suppliers = r[1] as List<Supplier>;
        if (_isEdit) {
          final ex = widget.existing!;
          _poNumber = ex.orderNumber.isNotEmpty ? ex.orderNumber : _poNumber;
          _dueDateCtrl.text = ex.dueDate ?? '';
          try { _supplier = _suppliers.firstWhere((s) => s.id == ex.supplierId); } catch(_){}
          if (ex.details != null) {
            for (final d in ex.details!) {
              final ps = _products.where((p) => p.id == d.productId).toList();
              if (ps.isNotEmpty) _items.add(SelectedItem(product: ps.first, qty: d.stock.toDouble(), price: d.price, unit: d.unit));
            }
          }
        }
        _isLoading = false;
      });
    } catch(_) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dueDateCtrl.text) ?? DateTime.now(),
      firstDate: DateTime(2020), lastDate: DateTime(2030),
      builder: (c, ch) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: _blue)), child: ch!),
    );
    if (p != null) setState(() => _dueDateCtrl.text = DateFormat('yyyy-MM-dd').format(p));
  }

  Future<void> _save() async {
    if (_supplier == null) { _toast('Pilih supplier', true); return; }
    if (_items.isEmpty)   { _toast('Tambah minimal 1 produk', true); return; }
    setState(() => _isSaving = true);
    try {
      final data = {
        'supplier_id'  : _supplier!.id,
        'incoming_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'due_date'     : _dueDateCtrl.text.isEmpty ? null : _dueDateCtrl.text,
        'total_price'  : _total.toInt(),
        'products'     : _items.map((i) => {'product_id': i.product.id, 'stock': i.qty, 'unit': i.unit, 'price': i.price}).toList(),
      };
      final res = _isEdit
          ? await DataService.updateIncomingProduct(widget.existing!.id, data)
          : await DataService.createIncomingProduct(data);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (res.success) { _toast(_isEdit ? 'Berhasil diubah' : 'Berhasil disimpan', false); Navigator.pop(context, true); }
      else _toast(res.message.isNotEmpty ? res.message : 'Gagal menyimpan', true);
    } catch(e) { if (mounted) { setState(() => _isSaving = false); _toast('Error: $e', true); } }
  }

  void _toast(String m, bool err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(m, style: const TextStyle(fontWeight: FontWeight.w600)),
    backgroundColor: err ? Colors.red : Colors.green,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(12),
  ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(_isEdit ? 'Edit Pembelian' : 'New Purchase Order',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : ListView(padding: const EdgeInsets.all(12), children: [

              // ── Supplier ───────────────────────────────────────
              _card(children: [
                _sectionTitle('Supplier'),
                _tileRow(
                  label: 'Supplier',
                  value: _supplier?.name ?? '',
                  hint: 'Select',
                  showArrow: true,
                  onTap: () async {
                    final s = await Navigator.push<Supplier>(context,
                        MaterialPageRoute(builder: (_) => PurchaseSupplierSelectScreen(suppliers: _suppliers, selected: _supplier)));
                    if (s != null) setState(() => _supplier = s);
                  },
                ),
              ]),
              const SizedBox(height: 10),

              // ── Items ──────────────────────────────────────────
              _card(children: [
                _sectionTitle('Items'),
                _tileRow(
                  label: 'Items',
                  value: _items.isEmpty ? '' : '${_items.length} produk',
                  hint: '0',
                  showArrow: true,
                  onTap: () async {
                    final result = await Navigator.push<List<SelectedItem>>(context,
                        MaterialPageRoute(builder: (_) => PurchaseProductSelectScreen(products: _products, selected: _items)));
                    if (result != null) setState(() => _items = result);
                  },
                ),
              ]),
              const SizedBox(height: 10),

              // ── Order Number ──────────────────────────────────
              _card(children: [
                _sectionTitle('Order Number'),
                _tileRow(label: 'Order Number', value: _poNumber, readonly: true),
              ]),
              const SizedBox(height: 10),

              // ── Due Date ──────────────────────────────────────
              _card(children: [
                _sectionTitle('Jatuh Tempo'),
                _tileRow(
                  label: 'Due Date',
                  value: _dueDateCtrl.text,
                  hint: 'Pilih tanggal',
                  showArrow: true,
                  onTap: _pickDate,
                ),
              ]),
              const SizedBox(height: 10),

              // ── Summary ────────────────────────────────────────
              if (_items.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    _summaryRow('Subtotal', _fmt.format(_total), bold: false),
                    const SizedBox(height: 4),
                    const Divider(),
                    _summaryRow('Total', _fmt.format(_total), bold: true, color: _blue),
                  ]),
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 60),
            ]),

      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(_isEdit ? 'Simpan Perubahan' : 'Save',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
  );

  Widget _tileRow({required String label, String value = '', String hint = '', bool showArrow = false, bool readonly = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: readonly ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          if (value.isNotEmpty)
            Flexible(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87), textAlign: TextAlign.end))
          else
            Text(hint, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          if (showArrow) ...[const SizedBox(width: 6), Icon(Icons.chevron_right, color: Colors.grey[400], size: 20)],
        ]),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: bold ? Colors.black87 : Colors.grey[600], fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      Text(value, style: TextStyle(fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: color ?? (bold ? Colors.black87 : Colors.grey[700]))),
    ],
  );
}
