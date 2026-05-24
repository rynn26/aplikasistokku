import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../screens/auth/login_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.white, foregroundColor: Colors.blue[800], elevation: 0),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Profile card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Row(children: [
            CircleAvatar(radius: 28, backgroundColor: Colors.blue[100],
              child: Text(user?.name[0].toUpperCase() ?? 'U', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[700]))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.name ?? 'User', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text(user?.email ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                child: Text(user?.roleDisplayName ?? (user?.isAdmin == true ? 'Admin' : 'Kasir'),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[700]))),
            ])),
          ]),
        ),
        const SizedBox(height: 24),

        _sectionTitle('Akun'),
        _menuItem(Icons.person_outline, 'Profil Saya', () {}),
        _menuItem(Icons.lock_outline, 'Ganti Password', () {}),
        const SizedBox(height: 24),

        _sectionTitle('Aplikasi'),
        _menuItem(Icons.info_outline, 'Tentang Aplikasi', () {
          showAboutDialog(context: context, applicationName: 'StokKu', applicationVersion: '1.0.0',
            applicationLegalese: '© 2025 StokKu - Inventory & Kasir');
        }),
        const SizedBox(height: 24),

        // Logout
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            onTap: () async {
              final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Logout'), content: const Text('Yakin ingin keluar?'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Keluar', style: TextStyle(color: Colors.red)))],
              ));
              if (confirm == true && context.mounted) {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                }
              }
            },
            leading: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.logout, color: Colors.red[400], size: 20)),
            title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white,
          ),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1)));

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    child: ListTile(
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.blue[400], size: 20)),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: Colors.white,
    ),
  );
}