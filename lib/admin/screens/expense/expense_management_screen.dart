import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/data_service.dart';
import '../../../models/expense.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});
  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  bool _isLoading = true;
  List<Expense> _expenses = [];
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await DataService.getExpenses();
      if (mounted) setState(() { _expenses = data; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  void _showForm({Expense? expense}) {
    final descCtrl = TextEditingController(text: expense?.description ?? '');
    final qtyCtrl = TextEditingController(text: expense != null ? '${expense.qty}' : '1');
    final priceCtrl = TextEditingController(text: expense != null ? '${expense.price}' : '');
    final dateCtrl = TextEditingController(text: expense?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(expense == null ? 'Tambah Pengeluaran' : 'Edit Pengeluaran', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _field('Deskripsi', descCtrl, lines: 2),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field('Qty', qtyCtrl, type: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field('Harga', priceCtrl, type: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          _field('Tanggal', dateCtrl),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyCtrl.text) ?? 1;
              final price = int.tryParse(priceCtrl.text) ?? 0;
              final data = {'description': descCtrl.text, 'qty': qty, 'price': price, 'total_price': qty * price, 'date': dateCtrl.text};
              final res = expense == null ? await DataService.createExpense(data) : await DataService.updateExpense(expense.id, data);
              if (ctx.mounted) Navigator.pop(ctx);
              if (res.success) _loadData();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.success ? 'Berhasil' : res.message)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
        ])),
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
    final total = _expenses.fold(0, (sum, e) => sum + e.totalPrice);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(title: const Text('Pengeluaran', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.white, foregroundColor: Colors.blue[800], elevation: 0),
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(), backgroundColor: Colors.blue[700], child: const Icon(Icons.add, color: Colors.white)),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.red[400]!, Colors.red[300]!]), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(_currency.format(total), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              Text('${_expenses.length} item', style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ]),
          ),
          const SizedBox(height: 16),
          ..._expenses.map((e) => GestureDetector(
            onTap: () => _showForm(expense: e),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.receipt_outlined, color: Colors.red[400], size: 20)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${e.qty}x ${_currency.format(e.price)} • ${e.date}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ])),
                Text(_currency.format(e.totalPrice), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red[700])),
              ]),
            ),
          )),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}