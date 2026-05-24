import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/data_service.dart';

class LaporanLabaScreen extends StatefulWidget {
  const LaporanLabaScreen({super.key});
  @override
  State<LaporanLabaScreen> createState() => _LaporanLabaScreenState();
}

class _LaporanLabaScreenState extends State<LaporanLabaScreen> {
  static const _blue  = Color(0xFF00ADEF);
  static const _green = Color(0xFF22C55E);
  static const _red   = Color(0xFFEF4444);
  static const _amber = Color(0xFFF59E0B);

  final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _fmtDate = DateFormat('d MMM yyyy', 'id_ID');
  final _fmtDateShort = DateFormat('d MMM', 'id_ID');

  String _period = 'this_month';
  DateTime? _fromDate, _toDate;
  bool _isLoading = false;
  Map<String, dynamic>? _data;

  final _periods = [
    ('today',      'Hari Ini'),
    ('this_week',  'Minggu Ini'),
    ('this_month', 'Bulan Ini'),
    ('this_year',  'Tahun Ini'),
    ('custom',     'Custom'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await DataService.getLaporanLaba(
        period: _period,
        fromDate: _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null,
        toDate:   _toDate   != null ? DateFormat('yyyy-MM-dd').format(_toDate!)   : null,
      );
      if (mounted) setState(() { _data = res; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: _fromDate ?? now.subtract(const Duration(days: 30)),
        end:   _toDate   ?? now,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _blue)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _fromDate = picked.start; _toDate = picked.end; });
      _load();
    }
  }

  // ─── Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Laporan Laba', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _periodSelector(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
            ? const Center(child: Text('Gagal memuat data'))
            : _buildBody(),
      ),
    );
  }

  // ─── Period Selector Chips ────────────────────────────────
  Widget _periodSelector() {
    return Container(
      color: Colors.white,
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        children: _periods.map((p) {
          final isActive = _period == p.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () async {
                if (p.$1 == 'custom') {
                  setState(() => _period = 'custom');
                  await _pickDateRange();
                } else {
                  setState(() { _period = p.$1; _fromDate = null; _toDate = null; });
                  _load();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? _blue : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(p.$2,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : Colors.grey[600])),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Main Body ────────────────────────────────────────────
  Widget _buildBody() {
    final d = _data!;
    final omset      = (d['omset']      as num).toDouble();
    final hpp        = (d['hpp']        as num).toDouble();
    final labaKotor  = (d['laba_kotor'] as num).toDouble();
    final pengeluaran= (d['pengeluaran']as num).toDouble();
    final labaBersih = (d['laba_bersih']as num).toDouble();
    final transaksi  = d['total_transaksi'] as int;
    final from       = d['from_date'] as String;
    final to         = d['to_date'] as String;
    final daily      = (d['daily'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── Period Info ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _blue.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.date_range_outlined, size: 16, color: _blue),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _period == 'custom' && _fromDate != null && _toDate != null
                ? '${_fmtDate.format(_fromDate!)} – ${_fmtDate.format(_toDate!)}'
                : '${_fmtDate.format(DateTime.parse(from))} – ${_fmtDate.format(DateTime.parse(to))}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _blue))),
            Text('$transaksi transaksi', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Summary Cards ─────────────────────────────────────
        _summaryCard('Omset Penjualan', omset, Icons.store_outlined, _blue, 'Total penjualan (lunas)'),
        const SizedBox(height: 10),
        _summaryCard('Modal / HPP', hpp, Icons.inventory_2_outlined, _amber, 'Harga beli produk terjual'),
        const SizedBox(height: 10),
        _dividerCard(label: 'Laba Kotor', value: labaKotor, subtitle: 'Omset – Modal'),
        const SizedBox(height: 10),
        _summaryCard('Pengeluaran', pengeluaran, Icons.receipt_long_outlined, _red, 'Biaya operasional'),
        const SizedBox(height: 10),
        _resultCard(label: 'Laba Bersih', value: labaBersih),
        const SizedBox(height: 24),

        // ── Daily Breakdown ───────────────────────────────────
        if (daily.isNotEmpty) ...[
          const Text('Rincian Harian',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: Column(
              children: daily.asMap().entries.map((entry) {
                final i   = entry.key;
                final row = entry.value;
                final dayOmset = (row['omset'] as num).toDouble();
                final dayExp   = (row['pengeluaran'] as num).toDouble();
                final dayLaba  = (row['laba'] as num).toDouble();
                final dateStr  = row['date'] as String;
                final dateObj  = DateTime.tryParse(dateStr);

                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      SizedBox(
                        width: 52,
                        child: Text(dateObj != null ? _fmtDateShort.format(dateObj) : dateStr,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_fmt.format(dayOmset),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        if (dayExp > 0)
                          Text('Pengeluaran: ${_fmt.format(dayExp)}',
                            style: TextStyle(fontSize: 10, color: _red.withValues(alpha: 0.8))),
                      ])),
                      Text(_fmt.format(dayLaba),
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800,
                          color: dayLaba >= 0 ? _green : _red)),
                    ]),
                  ),
                  if (i < daily.length - 1) const Divider(height: 1, indent: 76),
                ]);
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Card Helpers ─────────────────────────────────────────
  Widget _summaryCard(String label, double value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ])),
        Text(_fmt.format(value),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }

  Widget _dividerCard({required String label, required double value, required String subtitle}) {
    final isPositive = value >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isPositive ? _green : _red).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isPositive ? _green : _red).withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ])),
        Text(_fmt.format(value),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
            color: isPositive ? _green : _red)),
      ]),
    );
  }

  Widget _resultCard({required String label, required double value}) {
    final isPositive = value >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
            ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
            : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          const Text('Setelah semua pengeluaran',
            style: TextStyle(fontSize: 10, color: Colors.white70)),
        ]),
        const Spacer(),
        Text(_fmt.format(value),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
      ]),
    );
  }
}
