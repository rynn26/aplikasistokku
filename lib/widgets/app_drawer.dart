import 'package:flutter/material.dart';
import '../screens/pegawai_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/profile_screen.dart';

// ─── Drawer navigasi utama (Cashier) ─────────────────────────────────────────
// Urutan & nama disesuaikan dengan config/menu.php Laravel (role: cashier)
class AppDrawer extends StatelessWidget {
  final ValueChanged<int>? onMenuSelected;
  const AppDrawer({super.key, this.onMenuSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF181A25),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.inventory_2, color: Color(0xFF1CB5E0), size: 32),
                      const SizedBox(width: 8),
                      Text('stokku', style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: const Color(0xFF1CB5E0), fontSize: 26, letterSpacing: -1)),
                    ]),
                    IconButton(
                      icon: const Icon(Icons.keyboard_double_arrow_left, color: Colors.white54, size: 28),
                      onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),

              // ── Beranda ──────────────────────────────────────────
              _sectionItem(
                context, icon: Icons.grid_view_rounded, iconColor: const Color(0xFF1CB5E0),
                title: 'Beranda', highlight: true,
                onTap: () { Navigator.pop(context); onMenuSelected?.call(0); }),

              _divider(),

              // ── MENU label ───────────────────────────────────────
              _sectionHeader(context, 'MENU'),

              // eCommerce (sesuai Laravel: Unit, Kategori, Produk, Pesanan)
              _expandable(context,
                icon: Icons.shopping_cart_outlined,
                title: 'eCommerce',
                children: [
                  _SubItem('Unit',     () { Navigator.pop(context); onMenuSelected?.call(6); }),
                  _SubItem('Kategori', () { Navigator.pop(context); onMenuSelected?.call(7); }),
                  _SubItem('Produk',   () { Navigator.pop(context); onMenuSelected?.call(8); }),
                  _SubItem('Pesanan',  () { Navigator.pop(context); onMenuSelected?.call(9); }),
                ],
              ),

              // Pelanggan
              _drawerItem(context,
                icon: Icons.people_outline,
                title: 'Pelanggan',
                onTap: () { Navigator.pop(context); onMenuSelected?.call(2); }),

              // Pembelian (sesuai Laravel: Daftar Barang Masuk)
              _drawerItem(context,
                icon: Icons.shopping_basket_outlined,
                title: 'Daftar Barang Masuk',
                onTap: () { Navigator.pop(context); onMenuSelected?.call(3); }),

              // Data Supplier
              _drawerItem(context,
                icon: Icons.local_shipping_outlined,
                title: 'Data Supplier',
                onTap: () { Navigator.pop(context); onMenuSelected?.call(5); }),

              // Data Produksi (sesuai Laravel: Daftar Produksi, Bahan Baku)
              _expandable(context,
                icon: Icons.precision_manufacturing_outlined,
                title: 'Data Produksi',
                children: [
                  _SubItem('Daftar Produksi', () { Navigator.pop(context); onMenuSelected?.call(4); }),
                  _SubItem('Bahan Baku',       () { Navigator.pop(context); onMenuSelected?.call(10); }),
                ],
              ),

              // Pengeluaran
              _drawerItem(context,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Pengeluaran',
                onTap: () { Navigator.pop(context); onMenuSelected?.call(11); }),

              _divider(),

              // ── LAINNYA label ────────────────────────────────────
              _sectionHeader(context, 'LAINNYA'),

              // Pegawai
              _drawerItem(context,
                icon: Icons.badge_outlined,
                title: 'Daftar Pegawai',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PegawaiScreen()));
                }),

              // Notifikasi
              _drawerItem(context,
                icon: Icons.notifications_outlined,
                title: 'Notifikasi',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                }),

              // Profil
              _drawerItem(context,
                icon: Icons.person_outline,
                title: 'Profil Saya',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Widgets helper
  // ═══════════════════════════════════════════════════════════

  Widget _sectionHeader(BuildContext context, String label) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
  );

  Widget _divider() => Container(
    height: 1, margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
    color: Colors.white10);

  Widget _sectionItem(BuildContext context,
      {required IconData icon, required Color iconColor,
       required String title, bool highlight = false, VoidCallback? onTap}) {
    return Container(
      color: highlight ? const Color(0xFF222432) : Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        onTap: onTap,
      ),
    );
  }

  Widget _drawerItem(BuildContext context,
      {required IconData icon, required String title, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: Colors.white38, size: 22),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Colors.white70, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
      onTap: onTap,
    );
  }

  Widget _expandable(BuildContext context,
      {required IconData icon, required String title, required List<_SubItem> children}) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24),
        leading: Icon(icon, color: Colors.white38, size: 22),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white70, fontSize: 14)),
        iconColor: Colors.white54,
        collapsedIconColor: Colors.white38,
        children: children.map((item) => InkWell(
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 64, right: 24, top: 11, bottom: 11),
            child: Row(children: [
              Container(width: 4, height: 4,
                decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle)),
              const SizedBox(width: 14),
              Text(item.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white60, fontSize: 13)),
            ]),
          ),
        )).toList(),
      ),
    );
  }
}

// Model kecil untuk sub-item
class _SubItem {
  final String title;
  final VoidCallback onTap;
  const _SubItem(this.title, this.onTap);
}
