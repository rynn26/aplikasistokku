import 'package:flutter/material.dart';
import 'package:inventoryy/admin/screens/employee/employee_list_screen.dart';
import 'package:inventoryy/admin/screens/expense/expense_management_screen.dart';
import 'package:inventoryy/admin/screens/inventory/ingredient_history_screen.dart';
import 'package:inventoryy/admin/screens/prouction/production_screen.dart';
import 'package:inventoryy/admin/screens/purchase/purchase_screen.dart';
import 'package:inventoryy/admin/screens/supplier/supplier_list_screen.dart';
import 'package:inventoryy/admin/screens/setting/setting_screen.dart';
import 'package:inventoryy/admin/screens/transaction/transaction_summary_screen.dart';
import 'package:inventoryy/admin/screens/customer/customer_tab.dart';
import 'package:inventoryy/screens/profile_screen.dart';
import 'package:inventoryy/admin/screens/laporan/laporan_screen.dart';
import 'package:inventoryy/screens/pegawai_screen.dart';
import 'package:inventoryy/screens/notification_screen.dart';
import 'package:inventoryy/screens/ecommerce_unit_tab.dart';
import 'package:inventoryy/screens/ecommerce_kategori_tab.dart';
import 'package:inventoryy/screens/ecommerce_produk_tab.dart';
import 'package:inventoryy/screens/ecommerce_pesanan_tab.dart';
import 'package:inventoryy/screens/bahan_baku_tab.dart';
import 'package:provider/provider.dart';
import 'package:inventoryy/services/auth_service.dart';
import 'package:inventoryy/screens/auth/login_screen.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            // Header
            const Text('MENU ADMIN', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8), letterSpacing: 1.5)),
            const SizedBox(height: 4),
            const Text('Menu Lainnya', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text('Kelola seluruh fitur operasional sistem.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 24),

            // ─── SECTION: eCommerce ─────────────────────────────────
            _sectionLabel('eCommerce'),
            _menuGroup(context, [
              _MenuItem('Unit',      Icons.straighten_outlined,         const Color(0xFFE8F5E9), Colors.green[700]!,
                  () => _pushTab(context, 'Unit', const EcommerceUnitTab())),
              _MenuItem('Kategori',  Icons.category_outlined,           const Color(0xFFFFF3E0), Colors.orange[700]!,
                  () => _pushTab(context, 'Kategori', const EcommerceKategoriTab())),
              _MenuItem('Produk',    Icons.inventory_2_outlined,         const Color(0xFFE3F2FD), const Color(0xFF1976D2),
                  () => _pushTab(context, 'Produk', const EcommerceProdukTab())),
              _MenuItem('Pesanan',   Icons.receipt_outlined,             const Color(0xFFE0F7FF), const Color(0xFF00ADEF),
                  () => _pushTab(context, 'Pesanan', const EcommercePesananTab())),
            ]),
            const SizedBox(height: 20),

            // ─── SECTION: Pelanggan ─────────────────────────────────
            _sectionLabel('Pelanggan'),
            _menuList(context, [
              _MenuItem('Daftar Pelanggan', Icons.people_outline, const Color(0xFFE0F7FF), const Color(0xFF00ADEF),
                  () => _pushTab(context, 'Daftar Pelanggan', const CustomerTab())),
            ]),
            const SizedBox(height: 20),

            // ─── SECTION: Pegawai ───────────────────────────────────
            _sectionLabel('Pegawai'),
            _menuList(context, [
              _MenuItem('Daftar Pegawai', Icons.badge_outlined, const Color(0xFFE0F7FF), const Color(0xFF00ADEF),
                  () => _push(context, const PegawaiScreen())),
            ]),
            const SizedBox(height: 20),

            // ─── SECTION: Pembelian ─────────────────────────────────
            _sectionLabel('Pembelian'),
            _menuList(context, [
              _MenuItem('Daftar Barang Masuk', Icons.local_shipping_outlined, const Color(0xFFF3E5F5), Colors.purple[600]!,
                  () => _push(context, PurchaseScreen())),
              _MenuItem('Pesanan Pembelian',   Icons.add_shopping_cart_outlined, const Color(0xFFFFF8E1), Colors.amber[700]!,
                  () => _push(context, PurchaseScreen())),
            ]),
            const SizedBox(height: 20),

            // ─── SECTION: Data Supplier ─────────────────────────────
            _sectionLabel('Data Supplier'),
            _menuList(context, [
              _MenuItem('Daftar Supplier', Icons.local_shipping_outlined, const Color(0xFFE0F7FF), const Color(0xFF00ADEF),
                  () => _push(context, SupplierListScreen())),
            ]),
            const SizedBox(height: 20),

            // ─── SECTION: Data Produksi ─────────────────────────────
            _sectionLabel('Data Produksi'),
            _menuList(context, [
              _MenuItem('Daftar Produksi', Icons.precision_manufacturing_outlined, const Color(0xFFFFF3E0), Colors.orange[800]!,
                  () => _push(context, const ProductionScreen())),
              _MenuItem('Bahan Baku',      Icons.science_outlined,                 const Color(0xFFF3E5F5), Colors.purple[700]!,
                  () => _pushTab(context, 'Bahan Baku', const BahanBakuTab())),
            ]),
            const SizedBox(height: 20),

            // ─── SECTION: Pengeluaran ────────────────────────────────
            _sectionLabel('Pengeluaran'),
            _menuList(context, [
              _MenuItem('Data Pengeluaran', Icons.account_balance_wallet_outlined, const Color(0xFFE8F5E9), Colors.green[700]!,
                  () => _push(context, const ExpenseManagementScreen())),
            ]),
            const SizedBox(height: 20),

            // ─── SECTION: Rekap Transaksi ────────────────────────────
            _sectionLabel('Rekap Transaksi'),
            _menuList(context, [
              _MenuItem('Rekap Kasir',    Icons.receipt_long_outlined,   const Color(0xFFE0F7FF), const Color(0xFF00ADEF),
                  () => _push(context, const TransactionSummaryScreen())),
              _MenuItem('Riwayat Bahan',  Icons.history_edu_outlined,    const Color(0xFFF3E5F5), Colors.purple[700]!,
                  () => _push(context, const IngredientHistoryScreen())),
            ]),
            const SizedBox(height: 20),

            // ─── SECTION: Laporan ───────────────────────────────────
            _sectionLabel('Laporan'),
            _menuList(context, [
              _MenuItem('Laporan Penjualan', Icons.bar_chart_rounded, const Color(0xFFE8F5E9), Colors.green[700]!,
                  () => _push(context, const LaporanScreen())),
            ]),
            const SizedBox(height: 20),

            // ─── SECTION: Pengaturan ─────────────────────────────────
            _sectionLabel('Pengaturan'),
            _menuList(context, [
              _MenuItem('Daftar Pengguna', Icons.manage_accounts_outlined, const Color(0xFFE0F7FF), const Color(0xFF00ADEF),
                  () => _push(context, const EmployeeListScreen())),
              _MenuItem('Notifikasi',      Icons.notifications_outlined,   const Color(0xFFFFF8E1), Colors.amber[700]!,
                  () => _push(context, const NotificationScreen())),
              _MenuItem('Pengaturan',      Icons.settings_outlined,         const Color(0xFFF0F0F0), const Color(0xFF4A4A4A),
                  () => _push(context, const SettingScreen())),
              _MenuItem('Profil Saya',     Icons.person_outline,            const Color(0xFFE8F5E9), Colors.green[700]!,
                  () => _push(context, const ProfileScreen())),
            ]),
            const SizedBox(height: 20),

            // ─── Logout ──────────────────────────────────────────────
            _logoutTile(context),
            const SizedBox(height: 20),

            // ─── Info card ───────────────────────────────────────────
            _infoCard(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  /// Wrap tab widget (yang tidak punya Scaffold sendiri) dengan Scaffold+AppBar
  void _pushTab(BuildContext context, String title, Widget tab) =>
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFF8F9FE),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(title, style: const TextStyle(
              color: Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 17)),
            leading: const BackButton(color: Color(0xFF00ADEF)),
          ),
          body: tab,
        ),
      ));

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 3, height: 14,
        decoration: BoxDecoration(color: const Color(0xFF00ADEF), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5)),
    ]),
  );

  /// 2-column grid untuk section dengan banyak item (eCommerce)
  Widget _menuGroup(BuildContext context, List<_MenuItem> items) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: items.map((item) => _buildGridCard(item)).toList(),
    );
  }

  Widget _buildGridCard(_MenuItem item) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: item.iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(item.icon, color: item.iconColor, size: 24),
          ),
          const SizedBox(height: 10),
          Text(item.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        ]),
      ),
    ),
  );

  /// List vertikal untuk section dengan sedikit item
  Widget _menuList(BuildContext context, List<_MenuItem> items) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(
      children: items.asMap().entries.map((entry) {
        final idx  = entry.key;
        final item = entry.value;
        return Column(children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.only(
                topLeft:    idx == 0                   ? const Radius.circular(14) : Radius.zero,
                topRight:   idx == 0                   ? const Radius.circular(14) : Radius.zero,
                bottomLeft: idx == items.length - 1    ? const Radius.circular(14) : Radius.zero,
                bottomRight:idx == items.length - 1    ? const Radius.circular(14) : Radius.zero,
              ),
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: item.iconBg, borderRadius: BorderRadius.circular(10)),
                    child: Icon(item.icon, color: item.iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(item.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                  const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
                ]),
              ),
            ),
          ),
          if (idx < items.length - 1)
            const Divider(height: 1, indent: 68, endIndent: 0),
        ]);
      }).toList(),
    ),
  );

  Widget _logoutTile(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _handleLogout(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Text('Keluar', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red))),
          ]),
        ),
      ),
    ),
  );

  Widget _infoCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF00C2FF), Color(0xFF0062A8)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.cloud_done_outlined, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text('Sinkronisasi Cloud', style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
      const SizedBox(height: 8),
      const Text('Semua data transaksi dan inventaris dicadangkan\nsecara real-time ke server.',
        style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.5)),
      const SizedBox(height: 12),
      Row(children: [
        _infoBadge('STATUS: ONLINE'),
        const SizedBox(width: 8),
        _infoBadge('v2.4.0'),
      ]),
    ]),
  );

  Widget _infoBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(
      fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
  );

  Future<void> _handleLogout(BuildContext context) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await auth.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false);
      }
    }
  }
}

// ─── Data class untuk menu item ───────────────────────────────
class _MenuItem {
  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  const _MenuItem(this.title, this.icon, this.iconBg, this.iconColor, this.onTap);
}
