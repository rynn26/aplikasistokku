import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/data_service.dart';
import '../../models/pegawai.dart';
import '../../widgets/pagination_widget.dart';

class PegawaiScreen extends StatefulWidget {
  const PegawaiScreen({super.key});
  @override
  State<PegawaiScreen> createState() => _PegawaiScreenState();
}

class _PegawaiScreenState extends State<PegawaiScreen> {
  bool _isLoading = true, _isPageLoading = false;
  List<Pegawai> _all = [], _filtered = [];
  int _currentPage = 1, _lastPage = 1, _total = 0;
  String _search = '', _filterStatus = 'semua';
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const _blue = Color(0xFF00ADEF);

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadPage(int page) async {
    setState(() => page == 1 && _all.isEmpty ? _isLoading = true : _isPageLoading = true);
    try {
      final res = await DataService.getPegawaiPaged(
        search: _search.isEmpty ? null : _search,
        status: _filterStatus == 'semua' ? null : _filterStatus,
        page: page, perPage: 15,
      );
      if (mounted) setState(() {
        _all = res['data'] as List<Pegawai>;
        _filtered = _all;
        final meta = res['meta'] as Map<String, dynamic>;
        _currentPage = meta['current_page'] as int? ?? page;
        _lastPage    = meta['last_page'] as int? ?? 1;
        _total       = meta['total'] as int? ?? _all.length;
        _isLoading = false; _isPageLoading = false;
      });
    } catch (_) { if (mounted) setState(() { _isLoading = false; _isPageLoading = false; }); }
  }

  void _load() => _loadPage(1);

  void _showDetail(Pegawai p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              // Header
              Row(children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: p.isAktif ? _blue.withValues(alpha: 0.12) : Colors.grey[200],
                  child: Text(p.nama.isNotEmpty ? p.nama[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                      color: p.isAktif ? _blue : Colors.grey[500])),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  if (p.jabatan != null) Text(p.jabatan!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.isAktif ? Colors.green.withValues(alpha: 0.1) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(p.isAktif ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: p.isAktif ? Colors.green[700] : Colors.grey[600])),
                  ),
                ])),
              ]),
              const Divider(height: 32),
              // Detail info rows
              if (p.jenisKelamin != null) _detailRow(Icons.wc_outlined, 'Jenis Kelamin', p.jenisKelaminLabel),
              if (p.tanggalLahir != null) _detailRow(Icons.cake_outlined, 'Tgl Lahir', '${p.tempatLahir != null ? "${p.tempatLahir}, " : ""}${p.tanggalLahir!}'),
              if (p.tanggalMasuk != null) _detailRow(Icons.calendar_today_outlined, 'Tgl Masuk', p.tanggalMasuk!),
              if (p.noHp != null) _detailRow(Icons.phone_outlined, 'No. HP', p.noHp!),
              if (p.email != null) _detailRow(Icons.email_outlined, 'Email', p.email!),
              if (p.alamat != null) _detailRow(Icons.location_on_outlined, 'Alamat', p.alamat!),
              if (p.gaji > 0) _detailRow(Icons.payments_outlined, 'Gaji', _currency.format(p.gaji)),
              if (p.catatan != null && p.catatan!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Catatan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.amber)),
                    const SizedBox(height: 4),
                    Text(p.catatan!, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              // Action buttons
              Row(children: [
                if (p.noHp != null && p.noHp!.isNotEmpty)
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () {
                      // Launch WhatsApp
                      final phone = p.noHp!.replaceAll(RegExp(r'[^0-9]'), '');
                      final waNumber = phone.startsWith('0') ? '62${phone.substring(1)}' : phone;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Buka WA: $waNumber')));
                    },
                    icon: const Icon(Icons.chat_outlined, size: 16, color: Colors.green),
                    label: const Text('WhatsApp', style: TextStyle(color: Colors.green)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  )),
                if (p.noHp != null && p.noHp!.isNotEmpty) const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _showForm(pegawai: p); },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Icon(icon, size: 16, color: _blue),
      const SizedBox(width: 10),
      Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        overflow: TextOverflow.ellipsis)),
    ]),
  );

  void _showForm({Pegawai? pegawai}) {
    final namaCtrl    = TextEditingController(text: pegawai?.nama ?? '');
    final jabatanCtrl = TextEditingController(text: pegawai?.jabatan ?? '');
    final gajiCtrl    = TextEditingController(text: pegawai != null && pegawai.gaji > 0 ? pegawai.gaji.toStringAsFixed(0) : '');
    final noHpCtrl    = TextEditingController(text: pegawai?.noHp ?? '');
    final alamatCtrl  = TextEditingController(text: pegawai?.alamat ?? '');
    final emailCtrl   = TextEditingController(text: pegawai?.email ?? '');
    final catatanCtrl = TextEditingController(text: pegawai?.catatan ?? '');
    String jenisKelamin = pegawai?.jenisKelamin ?? 'L';
    String status       = pegawai?.status ?? 'aktif';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(pegawai == null ? 'Tambah Pegawai' : 'Edit Pegawai',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _field('Nama Lengkap *', namaCtrl),
                    const SizedBox(height: 12),
                    _field('Jabatan', jabatanCtrl),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field('No. HP', noHpCtrl, inputType: TextInputType.phone)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Email', emailCtrl, inputType: TextInputType.emailAddress)),
                    ]),
                    const SizedBox(height: 12),
                    _field('Gaji (Rp)', gajiCtrl, inputType: TextInputType.number),
                    const SizedBox(height: 12),
                    _field('Alamat', alamatCtrl, maxLines: 2),
                    const SizedBox(height: 12),
                    _field('Catatan', catatanCtrl, maxLines: 2),
                    const SizedBox(height: 16),
                    // Jenis Kelamin
                    const Text('Jenis Kelamin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
                    const SizedBox(height: 8),
                    Row(children: [
                      _radioChip('Laki-laki', 'L', jenisKelamin, (v) => setModal(() => jenisKelamin = v)),
                      const SizedBox(width: 8),
                      _radioChip('Perempuan', 'P', jenisKelamin, (v) => setModal(() => jenisKelamin = v)),
                    ]),
                    const SizedBox(height: 16),
                    // Status
                    const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
                    const SizedBox(height: 8),
                    Row(children: [
                      _radioChip('Aktif', 'aktif', status, (v) => setModal(() => status = v), activeColor: Colors.green),
                      const SizedBox(width: 8),
                      _radioChip('Nonaktif', 'nonaktif', status, (v) => setModal(() => status = v), activeColor: Colors.red),
                    ]),
                    const SizedBox(height: 24),
                    // Action buttons
                    if (pegawai != null)
                      OutlinedButton.icon(
                        onPressed: () => _delete(ctx, pegawai),
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        label: const Text('Hapus Pegawai', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    if (pegawai != null) const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (namaCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama tidak boleh kosong'), backgroundColor: Colors.red));
                          return;
                        }
                        final data = {
                          'nama': namaCtrl.text.trim(),
                          'jabatan': jabatanCtrl.text.trim().isEmpty ? null : jabatanCtrl.text.trim(),
                          'no_hp': noHpCtrl.text.trim().isEmpty ? null : noHpCtrl.text.trim(),
                          'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                          'alamat': alamatCtrl.text.trim().isEmpty ? null : alamatCtrl.text.trim(),
                          'catatan': catatanCtrl.text.trim().isEmpty ? null : catatanCtrl.text.trim(),
                          'jenis_kelamin': jenisKelamin,
                          'status': status,
                          if (gajiCtrl.text.isNotEmpty) 'gaji': double.tryParse(gajiCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
                        };
                        final res = pegawai == null
                            ? await DataService.createPegawai(data)
                            : await DataService.updatePegawai(pegawai.id, data);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res.success ? 'Berhasil disimpan' : (res.message.isNotEmpty ? res.message : 'Gagal')),
                            backgroundColor: res.success ? Colors.green : Colors.red));
                          if (res.success) _loadPage(_currentPage);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext ctx, Pegawai pegawai) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pegawai'),
        content: Text('Yakin hapus "${pegawai.nama}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(d, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await DataService.deletePegawai(pegawai.id);
    if (ctx.mounted) Navigator.pop(ctx);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success ? 'Pegawai dihapus' : (res.message.isNotEmpty ? res.message : 'Gagal')),
        backgroundColor: res.success ? Colors.green : Colors.red));
      if (res.success) _loadPage(_currentPage);
    }
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? inputType, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: inputType,
        maxLines: maxLines,
        decoration: InputDecoration(
          filled: true, fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }

  Widget _radioChip(String label, String value, String groupValue, ValueChanged<String> onChanged, {Color activeColor = const Color(0xFF00ADEF)}) {
    final selected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.12) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? activeColor : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? activeColor : Colors.grey[600])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Manajemen Pegawai',
            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _blue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: _blue),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: Column(children: [
        // Search + Filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() { _search = v; _loadPage(1); }),
              decoration: InputDecoration(
                hintText: 'Cari nama atau jabatan...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _search.isNotEmpty ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () { _searchCtrl.clear(); setState(() { _search = ''; _loadPage(1); }); }) : null,
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: ['semua', 'aktif', 'nonaktif'].map((s) {
                final sel = _filterStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() { _filterStatus = s; _loadPage(1); }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? _blue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? _blue : Colors.grey[300]!),
                      ),
                      child: Text(s[0].toUpperCase() + s.substring(1),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : Colors.grey[600])),
                    ),
                  ),
                );
              }).toList()),
            ),
          ]),
        ),
        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _blue))
              : RefreshIndicator(
                  onRefresh: () => _loadPage(1),
                  child: _filtered.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.badge_outlined, size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('Tidak ada pegawai', style: TextStyle(color: Colors.grey[500])),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
                            return GestureDetector(
                              onTap: () => _showDetail(p),
                              onLongPress: () => _showForm(pegawai: p),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Row(children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: p.isAktif ? _blue.withOpacity(0.12) : Colors.grey[200],
                                    child: Text(p.nama.isNotEmpty ? p.nama[0].toUpperCase() : '?',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                                        color: p.isAktif ? _blue : Colors.grey[500])),
                                  ),
                                  const SizedBox(width: 14),
                                  // Info
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(child: Text(p.nama,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: p.isAktif ? Colors.green.withOpacity(0.1) : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(p.isAktif ? 'Aktif' : 'Nonaktif',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                            color: p.isAktif ? Colors.green[700] : Colors.grey[600])),
                                      ),
                                    ]),
                                    if (p.jabatan != null && p.jabatan!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(p.jabatan!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ],
                                    if (p.noHp != null && p.noHp!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        Icon(Icons.phone_outlined, size: 12, color: Colors.grey[400]),
                                        const SizedBox(width: 4),
                                        Text(p.noHp!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                      ]),
                                    ],
                                    if (p.gaji > 0) ...[
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        Icon(Icons.payments_outlined, size: 12, color: Colors.grey[400]),
                                        const SizedBox(width: 4),
                                        Text(_currency.format(p.gaji),
                                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                      ]),
                                    ],
                                  ])),
                                  const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
        ),
        PaginationWidget(
          currentPage: _currentPage, lastPage: _lastPage, total: _total,
          isLoading: _isPageLoading, onPageChanged: _loadPage),
      ]),
    );
  }
}
