import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/manufacture.dart';

/// Halaman detail manufaktur/produksi — setara dengan manufactures/show.blade.php di Laravel
class ManufactureDetailScreen extends StatefulWidget {
  final int manufactureId;
  final String title;
  const ManufactureDetailScreen({super.key, required this.manufactureId, required this.title});
  @override
  State<ManufactureDetailScreen> createState() => _ManufactureDetailScreenState();
}

class _ManufactureDetailScreenState extends State<ManufactureDetailScreen> {
  bool _isLoading = true;
  Manufacture? _data;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static const _blue = Color(0xFF00ADEF);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await DataService.getManufactureDetail(widget.manufactureId);
      if (mounted) setState(() { _data = res; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title,
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _data == null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.precision_manufacturing_outlined, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('Data tidak ditemukan', style: TextStyle(color: Colors.grey[500])),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Header gradient card ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF3D35B0)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.precision_manufacturing_outlined, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_data!.code,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                              Text(_data!.manufactureDate ?? '-',
                                style: const TextStyle(fontSize: 12, color: Colors.white70)),
                            ])),
                            _typeBadge(_data!.type),
                          ]),
                          if (_data!.totalPrice != null && _data!.totalPrice! > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12)),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                const Text('Total Nilai Produksi',
                                  style: TextStyle(fontSize: 12, color: Colors.white70)),
                                Text(_currency.format(_data!.totalPrice),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                              ]),
                            ),
                          ],
                          if (_data!.userName != null) ...[
                            const SizedBox(height: 10),
                            Row(children: [
                              const Icon(Icons.person_outline, size: 13, color: Colors.white60),
                              const SizedBox(width: 6),
                              Text('Oleh: ${_data!.userName}',
                                style: const TextStyle(fontSize: 12, color: Colors.white60)),
                            ]),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // ── Detail item produk ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.list_alt_outlined, size: 16, color: _blue),
                            const SizedBox(width: 8),
                            const Text('Item Produksi',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text('${_data!.productsList.length} item',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _blue)),
                            ),
                          ]),
                          const Divider(height: 20),
                          ..._data!.productsList.map((item) {
                            final name  = item['product_name'] as String? ?? item['name'] as String? ?? '-';
                            final qty   = item['quantity'] ?? item['qty'] ?? 0;
                            final unit  = item['unit'] ?? 'pcs';
                            final price = item['price'] ?? item['cost'] ?? 0;
                            final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE8EDF2)),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: _blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                                  child: Center(child: Text(letter,
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: _blue, fontSize: 16))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  Text('$qty $unit', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                ])),
                                if ((price as num) > 0)
                                  Text(_currency.format(price),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.indigo[700])),
                              ]),
                            );
                          }),
                          if (_data!.productsList.isEmpty)
                            Center(child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[300]),
                                const SizedBox(height: 8),
                                Text('Tidak ada item produksi', style: TextStyle(color: Colors.grey[400])),
                              ]),
                            )),
                        ]),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _typeBadge(String type) {
    final color = type == 'manufacture' ? Colors.purple : Colors.teal;
    final label = type == 'manufacture' ? 'Manufacture' : 'Repack';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
