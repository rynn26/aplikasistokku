import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E), // Navy gelap sesuai referensi
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildMenuItem(Icons.grid_view_rounded, 'Beranda', active: true),
                _buildMenuItem(Icons.inventory_2_outlined, 'Inventaris'),
                _buildMenuItem(Icons.people_outline, 'Pelanggan'),
                
                // Menu Lainnya dengan Sub-menu
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: const Icon(Icons.more_horiz, color: Colors.white70),
                    title: const Text('Lainnya', 
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                    iconColor: Colors.white70,
                    collapsedIconColor: Colors.white70,
                    childrenPadding: const EdgeInsets.only(left: 12),
                    children: [
                      _buildSubMenuItem(Icons.badge_outlined, 'Pegawai'),
                      _buildSubMenuItem(Icons.shopping_cart_outlined, 'Pembelian'),
                      _buildSubMenuItem(Icons.local_shipping_outlined, 'Supplier'),
                      _buildSubMenuItem(Icons.precision_manufacturing_outlined, 'Produksi'),
                      _buildSubMenuItem(Icons.account_balance_wallet_outlined, 'Pengeluaran'),
                      _buildSubMenuItem(Icons.bar_chart_rounded, 'Rekap Transaksi'),
                      _buildSubMenuItem(Icons.settings_outlined, 'Pengaturan'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.architecture, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'POS Architect',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: active ? Colors.blue[400] : Colors.white70, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: active ? Colors.blue[400] : Colors.white70,
            fontSize: 14,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildSubMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 20),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
      ),
      onTap: () {},
    );
  }
}