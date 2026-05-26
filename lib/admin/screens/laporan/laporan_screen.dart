import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/data_service.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _reportData = {};
  List<dynamic> _salesData = [];
  List<dynamic> _filteredData = [];

  // Dropdown values
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedType = 'per_tanggal';
  String _searchQuery = '';

  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final List<Map<String, dynamic>> _months = [
    {'value': 1, 'label': 'Januari'},
    {'value': 2, 'label': 'Februari'},
    {'value': 3, 'label': 'Maret'},
    {'value': 4, 'label': 'April'},
    {'value': 5, 'label': 'Mei'},
    {'value': 6, 'label': 'Juni'},
    {'value': 7, 'label': 'Juli'},
    {'value': 8, 'label': 'Agustus'},
    {'value': 9, 'label': 'September'},
    {'value': 10, 'label': 'Oktober'},
    {'value': 11, 'label': 'November'},
    {'value': 12, 'label': 'Desember'},
  ];

  final List<Map<String, String>> _types = [
    {'value': 'per_tanggal', 'label': 'Per Tanggal'},
    {'value': 'per_nota', 'label': 'Per Nota'},
    {'value': 'per_item', 'label': 'Per Item'},
    {'value': 'per_pelanggan', 'label': 'Per Pelanggan'},
    {'value': 'per_username', 'label': 'Per Kasir/User'},
  ];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final res = await DataService.getReports(
        month: _selectedMonth,
        year: _selectedYear,
        type: _selectedType,
      );
      setState(() {
        _reportData = res;
        _salesData = res['sales_data'] as List? ?? [];
        _applySearch();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredData = List.from(_salesData);
      return;
    }

    final query = _searchQuery.toLowerCase();
    _filteredData = _salesData.where((item) {
      if (_selectedType == 'per_tanggal') {
        final date = (item['date'] ?? '').toString().toLowerCase();
        final dayName = (item['day_name'] ?? '').toString().toLowerCase();
        return date.contains(query) || dayName.contains(query);
      } else if (_selectedType == 'per_nota') {
        final orderNumber = (item['order_number'] ?? '').toString().toLowerCase();
        final customerName = (item['customer_name'] ?? '').toString().toLowerCase();
        return orderNumber.contains(query) || customerName.contains(query);
      } else if (_selectedType == 'per_item') {
        final productName = (item['product_name'] ?? '').toString().toLowerCase();
        return productName.contains(query);
      } else if (_selectedType == 'per_pelanggan') {
        final customerName = (item['customer_name'] ?? '').toString().toLowerCase();
        return customerName.contains(query);
      } else if (_selectedType == 'per_username') {
        final username = (item['username'] ?? '').toString().toLowerCase();
        return username.contains(query);
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Hitung ringkasan total
    double totalSales = 0;
    double totalCost = 0;
    double totalProfit = 0;

    for (var item in _salesData) {
      totalSales += _toDouble(item['total_sales'] ?? item['sales_amount']);
      totalCost += _toDouble(item['total_cost'] ?? item['cost']);
      totalProfit += _toDouble(item['total_profit'] ?? item['profit']);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Laporan Penjualan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF00ADEF)),
      ),
      body: Column(
        children: [
          // Filter Panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // Tipe Laporan Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF475569)),
                      items: _types.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['value'],
                          child: Text(type['label']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedType = val;
                          });
                          _loadReport();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Month Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedMonth,
                            isExpanded: true,
                            icon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF475569)),
                            items: _months.map((m) {
                              return DropdownMenuItem<int>(
                                value: m['value'],
                                child: Text(m['label'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedMonth = val);
                                _loadReport();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Year Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedYear,
                            isExpanded: true,
                            icon: const Icon(Icons.date_range_outlined, size: 16, color: Color(0xFF475569)),
                            items: [
                              DateTime.now().year - 2,
                              DateTime.now().year - 1,
                              DateTime.now().year,
                              DateTime.now().year + 1
                            ].map((y) {
                              return DropdownMenuItem<int>(
                                value: y,
                                child: Text('$y', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedYear = val);
                                _loadReport();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ADEF)))
                : RefreshIndicator(
                    onRefresh: _loadReport,
                    color: const Color(0xFF00ADEF),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Summary Cards Grid
                        Row(
                          children: [
                            Expanded(child: _summaryCard('Omset Penjualan', totalSales, Colors.green)),
                            const SizedBox(width: 8),
                            Expanded(child: _summaryCard('Modal (HPP)', totalCost, Colors.orange[800]!)),
                            const SizedBox(width: 8),
                            Expanded(child: _summaryCard('Laba Bersih', totalProfit, const Color(0xFF00ADEF))),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Search Bar
                        TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                              _applySearch();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari laporan...',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Results List Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Hasil Laporan (${_filteredData.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                            Text(
                              _types.firstWhere((t) => t['value'] == _selectedType)['label']!,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Grouped lists
                        if (_filteredData.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(Icons.insert_chart_outlined_outlined, size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text('Tidak ada data laporan ditemukan', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                              ],
                            ),
                          )
                        else
                          ..._filteredData.map((item) => _buildGroupCard(item)),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey[500])),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currency.format(value),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(dynamic item) {
    String title = '';
    String subtitle = '';
    double sales = _toDouble(item['total_sales'] ?? item['sales_amount']);
    double profit = _toDouble(item['total_profit'] ?? item['profit']);

    List<dynamic> subItems = [];
    String subItemsTitle = 'Detail Barang';

    if (_selectedType == 'per_tanggal') {
      title = '${item['day_name'] ?? ''}, ${_formatDate(item['date'])}';
      subItems = item['items'] as List? ?? [];
    } else if (_selectedType == 'per_nota') {
      title = 'Nota: ${item['order_number'] ?? ''}';
      subtitle = 'Pelanggan: ${item['customer_name'] ?? ''}';
      subItems = item['items'] as List? ?? [];
    } else if (_selectedType == 'per_item') {
      title = item['product_name'] ?? '';
      subtitle = 'Total Terjual: ${item['total_sold'] ?? 0} ${item['unit'] ?? ''}';
      subItems = item['transactions'] as List? ?? [];
      subItemsTitle = 'Riwayat Penjualan';
    } else if (_selectedType == 'per_pelanggan') {
      title = item['customer_name'] ?? 'Umum';
      subtitle = item['customer_address'] != null && item['customer_address'].toString().isNotEmpty
          ? 'Alamat: ${item['customer_address']}'
          : '';
      subItems = item['items'] as List? ?? [];
    } else if (_selectedType == 'per_username') {
      title = 'Kasir: ${item['username'] ?? ''}';
      subItems = item['items'] as List? ?? [];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF00ADEF),
          collapsedIconColor: Colors.grey[400],
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          subtitle: subtitle.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                )
              : null,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            // Group summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat('Total Omset', sales, Colors.green),
                _miniStat('Total Laba', profit, const Color(0xFF00ADEF)),
              ],
            ),
            const SizedBox(height: 16),
            // Details Header
            Row(
              children: [
                Container(width: 3, height: 10, decoration: BoxDecoration(color: const Color(0xFF94A3B8), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 6),
                Text(subItemsTitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
              ],
            ),
            const SizedBox(height: 8),
            // Details List
            if (subItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Tidak ada detail', style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic)),
              )
            else
              ...subItems.map((sub) => _buildSubItemRow(sub)),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(_currency.format(val), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildSubItemRow(dynamic sub) {
    if (_selectedType == 'per_item') {
      // sub is a transaction
      final customer = sub['customer_name'] ?? 'Umum';
      final date = _formatDate(sub['order_date']);
      final qty = sub['quantity'] ?? 0;
      final total = _toDouble(sub['sales_amount']);

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC), width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pelanggan: $customer', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(height: 2),
                  Text(date, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_currency.format(total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                const SizedBox(height: 2),
                Text('Qty: $qty', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      );
    } else {
      // sub is an item detail
      final prod = sub['product_name'] ?? '';
      final qty = sub['quantity'] ?? 0;
      final unit = sub['unit'] ?? '';
      final total = _toDouble(sub['sales_amount']);

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC), width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('$prod ($qty $unit)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            ),
            const SizedBox(width: 10),
            Text(_currency.format(total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
          ],
        ),
      );
    }
  }

  // Helpers
  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
  }
}
