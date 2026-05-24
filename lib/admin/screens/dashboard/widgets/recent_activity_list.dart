import 'package:flutter/material.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktivitas Terbaru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            iconBgColor: Colors.green.withOpacity(0.1),
            title: 'Pesanan #1234 Berhasil',
            subtitle: 'Pembayaran via e-Wallet berhasil diterima',
            trailingTitle: 'Rp 120.000',
            trailingSubtitle: '5 menit yang lalu',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          _buildActivityItem(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            iconBgColor: Colors.orange.withOpacity(0.1),
            title: 'Stok Kopi Menipis',
            subtitle: 'Varian: Arabica Gayo Premium (Sisa 2 kg)',
            trailingWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Low Stock',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          _buildActivityItem(
            icon: Icons.person_add_outlined,
            iconColor: Colors.blue,
            iconBgColor: Colors.blue.withOpacity(0.1),
            title: 'Pelanggan Baru Terdaftar',
            subtitle: 'Andi Wijaya bergabung ke Membership',
            trailingTitle: '+10 Poin',
            trailingSubtitle: '1 jam yang lalu',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          _buildActivityItem(
            icon: Icons.sync,
            iconColor: Colors.grey[600]!,
            iconBgColor: Colors.grey.withOpacity(0.1),
            title: 'Sinkronisasi Inventaris Selesai',
            subtitle: 'Tersinkronisasi otomatis dengan database pusat',
            trailingSubtitle: '2 jam yang lalu',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    String? trailingTitle,
    String? trailingSubtitle,
    Widget? trailingWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        if (trailingTitle != null ||
            trailingSubtitle != null ||
            trailingWidget != null) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (trailingWidget != null) trailingWidget,
              if (trailingTitle != null)
                Text(
                  trailingTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              if (trailingSubtitle != null) ...[
                if (trailingTitle != null || trailingWidget != null)
                  const SizedBox(height: 4),
                Text(
                  trailingSubtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
