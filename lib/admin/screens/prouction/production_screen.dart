import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/data_service.dart';
import '../../../models/manufacture.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});
  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  bool _isLoading = true;
  List<Manufacture> _items = [];
  String _filterType = 'semua';
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final type = _filterType == 'semua' ? null : _filterType;
      final data = await DataService.getManufactures(type: type);
      if (mounted) setState(() { _items = data; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'manufacture': return const Color(0xFF0077B6);
      case 'retur': return Colors.orange;
      default: return Colors.indigo;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'manufacture': return 'Produksi';
      case 'retur': return 'Retur';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Produksi', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0077B6),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (val) { setState(() => _filterType = val); _loadData(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'semua', child: Text('Semua')),
              const PopupMenuItem(value: 'manufacture', child: Text('Produksi')),
              const PopupMenuItem(value: 'retur', child: Text('Retur')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ADEF)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF00ADEF),
              child: _items.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.precision_manufacturing_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Belum ada data produksi', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final m = _items[i];
                        final products = m.productsList;
                        final typeColor = _typeColor(m.type);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                          ),
                          child: Column(
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Icon(Icons.precision_manufacturing_outlined, color: typeColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(m.code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Row(children: [
                                          Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey[400]),
                                          const SizedBox(width: 4),
                                          Text(m.manufactureDate ?? '-', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                          if (m.userName != null) ...[ 
                                            const SizedBox(width: 10),
                                            Icon(Icons.person_outline, size: 11, color: Colors.grey[400]),
                                            const SizedBox(width: 3),
                                            Text(m.userName!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                          ],
                                        ]),
                                      ]),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text(_typeLabel(m.type), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor)),
                                    ),
                                  ],
                                ),
                              ),
                              // Product list
                              if (products.isNotEmpty) ...[ 
                                const Divider(height: 1, thickness: 0.5),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Detail Produk (${products.length} item)', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      ...products.map((p) {
                                        final qty = p['quantity'] ?? 0;
                                        final total = p['total_cost'] ?? 0;
                                        final unitId = p['unit_id'];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Row(children: [
                                            Container(width: 6, height: 6, decoration: BoxDecoration(color: typeColor.withOpacity(0.7), shape: BoxShape.circle)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text('Produk #${p['product_id']} — $qty ${unitId != null ? "(unit $unitId)" : ""}',
                                                  style: const TextStyle(fontSize: 12)),
                                            ),
                                            Text(_currency.format(total), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: typeColor)),
                                          ]),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                              // Total
                              if (m.totalPrice != null) ...[
                                const Divider(height: 1, thickness: 0.5),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Text('Total HPP', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                    Text(_currency.format(m.totalPrice), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: typeColor)),
                                  ]),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}