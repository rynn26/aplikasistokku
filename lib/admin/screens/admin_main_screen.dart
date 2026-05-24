import 'package:flutter/material.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'inventory/inventory_tab.dart';
import 'customer/customer_tab.dart';
import 'more/more_tab.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../screens/notification_screen.dart';
import '../../services/data_service.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  int _unreadNotif = 0;
  final _inventoryKey = GlobalKey<InventoryTabState>();

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const AdminDashboardScreen(),
      InventoryTab(key: _inventoryKey),
      const CustomerTab(),
      const MoreTab(),
    ];
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await DataService.getNotificationUnreadCount();
      if (mounted) setState(() => _unreadNotif = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Stokku Admin',
          style: TextStyle(
            color: Color(0xFF00ADEF),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          // Bell with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF00ADEF)),
                onPressed: () async {
                  await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()));
                  _loadUnreadCount();
                },
              ),
              if (_unreadNotif > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$_unreadNotif',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _inventoryKey.currentState?.showAddForm(),
              backgroundColor: const Color(0xFF00ADEF),
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Produk',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onNavTapped: (index) => setState(() => _currentIndex = index),
        items: [
          NavItem(icon: Icons.dashboard_rounded,   label: 'Beranda'),
          NavItem(icon: Icons.inventory_2_outlined,  label: 'Produk'),
          NavItem(icon: Icons.people_outline,        label: 'Pelanggan'),
          NavItem(icon: Icons.more_horiz,            label: 'Lainnya'),
        ],
      ),
    );
  }
}
