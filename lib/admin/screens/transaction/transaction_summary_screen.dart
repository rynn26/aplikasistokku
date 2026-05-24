import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/data_service.dart';
import '../../../models/order.dart';

class TransactionSummaryScreen extends StatefulWidget {
  const TransactionSummaryScreen({super.key});
  @override
  State<TransactionSummaryScreen> createState() => _TransactionSummaryScreenState();
}

class _TransactionSummaryScreenState extends State<TransactionSummaryScreen> {
  bool _isLoading = true;
  List<Order> _orders = [];
  List<Order> _filtered = [];
  String _selectedStatus = 'all';
  String _search = '';
  int _offset = 0;
  static const int _limit = 100;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData({bool reset = true}) async {
    if (reset) { _offset = 0; _orders = []; }
    setState(() => _isLoading = true);
    try {
      final data = await DataService.getOrders(
        paymentStatus: _selectedStatus == 'all' ? null : _selectedStatus,
        limit: _limit,
        offset: _offset,
      );
      if (mounted) setState(() {
        _orders.addAll(data);
        _applyFilter();
        _isLoading = false;
      });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  void _applyFilter() {
    _filtered = _orders.where((o) {
      return _search.isEmpty ||
        o.orderNumber.toLowerCase().contains(_search.toLowerCase()) ||
        (o.customerName ?? '').toLowerCase().contains(_search.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid = _filtered.where((o) => o.paymentStatus == 'paid').fold(0, (sum, o) => sum + o.totalPrice);
    final totalUnpaid = _filtered.where((o) => o.paymentStatus != 'paid').fold(0, (sum, o) => sum + o.totalPrice);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(title: const Text('Rekap Transaksi', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.white, foregroundColor: Colors.blue[800], elevation: 0),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Summary cards
          Row(children: [
            Expanded(child: _summaryCard('Lunas', _currency.format(totalPaid), Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard('Belum Lunas', _currency.format(totalUnpaid), Colors.red)),
          ]),
          const SizedBox(height: 16),
          // Search
          TextField(
            onChanged: (v) => setState(() { _search = v; _applyFilter(); }),
            decoration: InputDecoration(hintText: 'Cari transaksi...', prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 12),
          // Status filter
          SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: [
            _chip('Semua', 'all'), _chip('Lunas', 'paid'), _chip('Sebagian', 'partial'), _chip('Belum', 'unpaid'),
          ])),
          const SizedBox(height: 16),
          Text('${_filtered.length} transaksi', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 8),
          ..._filtered.map((o) => _orderCard(o)),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
    ]),
  );

  Widget _chip(String label, String value) {
    final sel = _selectedStatus == value;
    return GestureDetector(
      onTap: () { if (_selectedStatus != value) { _selectedStatus = value; _loadData(); } },
      child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: sel ? Colors.blue[700] : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? Colors.blue[700]! : Colors.grey[300]!)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey[700]))),
    );
  }

  Widget _orderCard(Order o) {
    Color sc = o.paymentStatus == 'paid' ? Colors.green : (o.paymentStatus == 'partial' ? Colors.orange : Colors.red);
    String sl = o.paymentStatus == 'paid' ? 'Lunas' : (o.paymentStatus == 'partial' ? 'Sebagian' : 'Belum');
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(o.orderNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(sl, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sc))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(o.customerName ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const Spacer(),
          Text(o.orderDate, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_currency.format(o.totalPrice), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.blue[700])),
          if (o.shippingCost > 0) Text('Ongkir: ${_currency.format(o.shippingCost)}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ]),
      ]),
    );
  }
}