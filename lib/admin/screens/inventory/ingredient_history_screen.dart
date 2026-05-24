import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/data_service.dart';
import '../../../models/ingredient_history.dart';
import '../../../models/ingredient.dart';

class IngredientHistoryScreen extends StatefulWidget {
  final Ingredient? ingredient; // Jika null, tampilkan semua riwayat

  const IngredientHistoryScreen({super.key, this.ingredient});

  @override
  State<IngredientHistoryScreen> createState() => _IngredientHistoryScreenState();
}

class _IngredientHistoryScreenState extends State<IngredientHistoryScreen> {
  bool _isLoading = true;
  List<IngredientHistory> _items = [];
  String _filterTipe = 'semua';
  final _dateFormat = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await DataService.getIngredientHistories(
        ingredientId: widget.ingredient?.id,
      );
      if (mounted) {
        setState(() {
          _items = _filterTipe == 'semua'
              ? data
              : data.where((h) => h.tipe == _filterTipe).toList();
          _isLoading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  Color _tipeColor(String tipe) {
    switch (tipe) {
      case 'masuk': return Colors.green;
      case 'keluar': return Colors.red;
      case 'penyesuaian': return const Color(0xFF00ADEF);
      default: return Colors.grey;
    }
  }

  IconData _tipeIcon(String tipe) {
    switch (tipe) {
      case 'masuk': return Icons.arrow_downward_rounded;
      case 'keluar': return Icons.arrow_upward_rounded;
      case 'penyesuaian': return Icons.swap_horiz_rounded;
      default: return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          widget.ingredient != null
              ? 'Riwayat: ${widget.ingredient!.name}'
              : 'Riwayat Bahan Baku',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0077B6),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (val) {
              setState(() => _filterTipe = val);
              _loadData();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'semua', child: Text('Semua')),
              const PopupMenuItem(value: 'masuk', child: Text('Masuk')),
              const PopupMenuItem(value: 'keluar', child: Text('Keluar')),
              const PopupMenuItem(value: 'penyesuaian', child: Text('Penyesuaian')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['semua', 'masuk', 'keluar', 'penyesuaian'].map((tipe) {
                final isSelected = _filterTipe == tipe;
                final color = tipe == 'semua' ? const Color(0xFF0077B6) : _tipeColor(tipe);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () { setState(() => _filterTipe = tipe); _loadData(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tipe == 'semua' ? 'Semua' : tipe[0].toUpperCase() + tipe.substring(1),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : color),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ADEF)))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFF00ADEF),
                    child: _items.isEmpty
                        ? Center(
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('Belum ada riwayat', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                            ]),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            itemBuilder: (_, i) {
                              final h = _items[i];
                              final color = _tipeColor(h.tipe);
                              final isKeluar = h.tipe == 'keluar';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                                      child: Icon(_tipeIcon(h.tipe), color: color, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Row(children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                            child: Text(h.tipeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                                          ),
                                          const SizedBox(width: 8),
                                          if (h.referensiTipe != null)
                                            Text('· ${h.referensiTipe}', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                                        ]),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${isKeluar ? "-" : "+"}${h.qty.toStringAsFixed(h.qty.truncateToDouble() == h.qty ? 0 : 1)}',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
                                        ),
                                        const SizedBox(height: 2),
                                        Text('${h.stokSebelum} → ${h.stokSesudah}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                        if (h.catatan != null && h.catatan!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(h.catatan!, style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        ],
                                      ]),
                                    ),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      if (h.userName != null)
                                        Text(h.userName!, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(
                                        h.createdAt != null ? _formatDate(h.createdAt!) : '-',
                                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                                        textAlign: TextAlign.end,
                                      ),
                                    ]),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return _dateFormat.format(dt);
    } catch (_) {
      return raw;
    }
  }
}
