import 'package:flutter/material.dart';
import '../../../services/data_service.dart';
import '../../../models/user.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});
  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  bool _isLoading = true;
  List<User> _users = [];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await DataService.getUsers();
      if (mounted) setState(() { _users = data; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  void _showForm({User? user}) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passCtrl = TextEditingController();
    int roleId = user?.roleId ?? 2;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(user == null ? 'Tambah Karyawan' : 'Edit Karyawan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _field('Nama', nameCtrl),
          const SizedBox(height: 12),
          _field('Email', emailCtrl, type: TextInputType.emailAddress),
          const SizedBox(height: 12),
          if (user == null) ...[_field('Password', passCtrl), const SizedBox(height: 12)],
          Text('Role', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Row(children: [
            ChoiceChip(label: const Text('Admin'), selected: roleId == 1, onSelected: (_) => setModalState(() => roleId = 1), selectedColor: Colors.blue[100]),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('Kasir'), selected: roleId == 2, onSelected: (_) => setModalState(() => roleId = 2), selectedColor: Colors.blue[100]),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('Manufacture'), selected: roleId == 3, onSelected: (_) => setModalState(() => roleId = 3), selectedColor: Colors.blue[100]),
          ]),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final data = <String, dynamic>{'name': nameCtrl.text, 'email': emailCtrl.text, 'role_id': roleId};
              if (passCtrl.text.isNotEmpty) data['password'] = passCtrl.text;
              final res = user == null ? await DataService.createUser(data) : await DataService.updateUser(user.id, data);
              if (ctx.mounted) Navigator.pop(ctx);
              if (res.success) _loadData();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.success ? 'Berhasil' : res.message)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
        ])),
      )),
    );
  }

  Widget _field(String label, TextEditingController c, {TextInputType? type}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      const SizedBox(height: 6),
      TextField(controller: c, keyboardType: type, decoration: InputDecoration(
        filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      )),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(title: const Text('Karyawan', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.white, foregroundColor: Colors.blue[800], elevation: 0),
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(), backgroundColor: Colors.blue[700], child: const Icon(Icons.add, color: Colors.white)),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _loadData,
        child: _users.isEmpty ? const Center(child: Text('Belum ada karyawan')) : ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: _users.length,
          itemBuilder: (_, i) {
            final u = _users[i];
            final roleLabel = u.roleDisplayName ?? (u.isAdmin ? 'Admin' : 'Kasir');
            final roleColor = u.isAdmin ? Colors.purple : Colors.teal;
            return GestureDetector(
              onTap: () => _showForm(user: u),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
                child: Row(children: [
                  CircleAvatar(backgroundColor: roleColor.withOpacity(0.1), child: Text(u.name[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: roleColor))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(u.email, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(roleLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor))),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}