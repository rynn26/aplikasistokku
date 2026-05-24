import 'package:flutter/material.dart';
import '../models/supplier.dart';

class PurchaseSupplierSelectScreen extends StatefulWidget {
  final List<Supplier> suppliers;
  final Supplier? selected;
  const PurchaseSupplierSelectScreen({super.key, required this.suppliers, this.selected});
  @override
  State<PurchaseSupplierSelectScreen> createState() => _State();
}

class _State extends State<PurchaseSupplierSelectScreen> {
  static const _blue = Color(0xFF00ADEF);
  String _q = '';

  List<Supplier> get _filtered => widget.suppliers
      .where((s) => s.name.toLowerCase().contains(_q.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Supplier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
          Text('Pilih supplier pembelian', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
      body: Column(children: [
        // Search
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Cari nama supplier...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true, fillColor: const Color(0xFFF2F3F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        // Count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Text('${_filtered.length}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            Text('Supplier', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ]),
        ),

        // List
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filtered.length,
          itemBuilder: (_, i) {
            final s = _filtered[i];
            final isSelected = widget.selected?.id == s.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: _blue, width: 2) : null,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _blue.withOpacity(0.15),
                  child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                      style: const TextStyle(color: _blue, fontWeight: FontWeight.w800)),
                ),
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: s.phone != null && s.phone!.isNotEmpty
                    ? Text(s.phone!, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
                    : null,
                trailing: isSelected ? const Icon(Icons.check_circle, color: _blue) : null,
                onTap: () => Navigator.pop(context, s),
              ),
            );
          },
        )),
      ]),
    );
  }
}
