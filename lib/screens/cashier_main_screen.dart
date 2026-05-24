import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_tab.dart';
import 'customer_tab.dart';
import 'purchase_tab.dart';
import 'produksi_tab.dart';
import 'supplier_tab.dart';
import 'ecommerce_unit_tab.dart';
import 'ecommerce_kategori_tab.dart';
import 'ecommerce_produk_tab.dart';
import 'ecommerce_pesanan_tab.dart';
import 'transaksi_tab.dart';
import 'pos_screen.dart';
import 'purchase_form_screen.dart';
import 'bahan_baku_tab.dart';
import 'pengeluaran_tab.dart';
import 'notification_screen.dart';
import '../services/data_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'profile_screen.dart';
class CashierMainScreen extends StatefulWidget {
  const CashierMainScreen({super.key});

  @override
  State<CashierMainScreen> createState() => _CashierMainScreenState();
}

class _CashierMainScreenState extends State<CashierMainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _customerKey = GlobalKey();
  final GlobalKey _supplierKey = GlobalKey();
  final GlobalKey _produksiKey = GlobalKey();
  final GlobalKey _unitKey = GlobalKey();
  final GlobalKey _kategoriKey = GlobalKey();
  final GlobalKey _produkKey = GlobalKey();
  final GlobalKey _transaksiKey  = GlobalKey();
  final GlobalKey _purchaseKey   = GlobalKey();
  final GlobalKey _bahanBakuKey  = GlobalKey();
  final GlobalKey _pengeluaranKey = GlobalKey();
  int _selectedIndex = 0;
  int _unreadNotif = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await DataService.getNotificationUnreadCount();
      if (mounted) setState(() => _unreadNotif = count);
    } catch (_) {}
  }
  
  void _onNavTapped(int index) {
    if (index == 3) {
      // Tombol 'Lainnya' akan selalu membuka Laci / Drawer
      _scaffoldKey.currentState?.openDrawer();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
  
  void _onMenuDrawerTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Judul AppBar per index — sesuai nama menu di config/menu.php Laravel
  static const _pageTitles = {
    3: 'Daftar Barang Masuk',
    4: 'Daftar Produksi',
    5: 'Data Supplier',
    6: 'Unit',
    7: 'Kategori',
    8: 'Produk',
    9: 'Pesanan',
    10: 'Bahan Baku',
    11: 'Pengeluaran',
  };

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    if (_selectedIndex >= 3) {
      final titleText = _pageTitles[_selectedIndex] ?? 'Lainnya';

      List<Widget> actions = [];
      if (_selectedIndex == 3) {
        // Pembelian – tidak ada action tambahan di AppBar
        actions = [];
      } else if (_selectedIndex == 5) {
        actions = [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Call showAddForm on SupplierTab
                  final state = _supplierKey.currentState;
                  if (state != null) {
                    (state as dynamic).showAddForm();
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Supplier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          )
        ];
      }

      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00ADEF)),
          onPressed: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        ),
        title: Text(
          titleText,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: actions,
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF00ADEF)),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text(
        'StokKu Cashier',
        style: TextStyle(
          color: Color(0xFF00ADEF),
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
      centerTitle: false,
      actions: [
        // Notification bell with badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF00ADEF)),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                _loadUnreadCount(); // refresh setelah kembali
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
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Consumer<AuthService>(
            builder: (context, auth, _) {
              final userName = auth.currentUser?.name ?? 'Julian';
              return PopupMenuButton<String>(

                onSelected: (value) async {
                  if (value == 'logout') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Yakin ingin keluar dari aplikasi?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      }
                    }
                  } else if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  }
                },
                offset: const Offset(0, 40),
                child: CircleAvatar(
                  backgroundColor: Colors.blue[800],
                  radius: 16,
                  backgroundImage: NetworkImage(
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=0D8ABC&color=fff',
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 8), Text('Profil Saya')]),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(children: [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 8), Text('Keluar', style: TextStyle(color: Colors.red))]),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 1:
        return TransaksiTab(key: _transaksiKey);
      case 2:
        return CustomerTab(key: _customerKey);
      case 3:
        return PurchaseTab(key: _purchaseKey);
      case 4:
        return ProduksiTab(key: _produksiKey);
      case 5:
        return SupplierTab(key: _supplierKey);
      case 6:
        return EcommerceUnitTab(key: _unitKey);
      case 7:
        return EcommerceKategoriTab(key: _kategoriKey);
      case 8:
        return EcommerceProdukTab(key: _produkKey);
      case 9:
        return const EcommercePesananTab();
      case 10:
        return BahanBakuTab(key: _bahanBakuKey);
      case 11:
        return PengeluaranTab(key: _pengeluaranKey);
      case 0:
      default:
        return const HomeTab();
    }
  }

  Widget? _buildFloatingActionButton() {
    if (_selectedIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () async {
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const POSScreen()),
          );
          if (refresh == true) {
            (_transaksiKey.currentState as dynamic)?.reload();
          }
        },
        backgroundColor: const Color(0xFF00ADEF),
        elevation: 4,
        icon: const Icon(Icons.point_of_sale, color: Colors.white, size: 20),
        label: const Text('BUAT TRANSAKSI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      );
    } else if (_selectedIndex == 2) {
      return FloatingActionButton(
        onPressed: () {
          final state = _customerKey.currentState;
          if (state != null) {
            (state as dynamic).showAddForm();
          }
        },
        backgroundColor: const Color(0xFF00ADEF),
        elevation: 4,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      );
    } else if (_selectedIndex == 3) {
      return FloatingActionButton.extended(
        onPressed: () async {
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PurchaseFormScreen()),
          );
          if (refresh == true) {
            (_purchaseKey.currentState as dynamic)?.reload();
          }
        },
        backgroundColor: const Color(0xFF00ADEF),
        elevation: 4,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
        label: const Text('BUAT PESANAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      );
    } else if (_selectedIndex == 4) {
      return FloatingActionButton.extended(
        onPressed: () {
          final state = _produksiKey.currentState;
          if (state != null) {
            (state as dynamic).showAddForm();
          }
        },
        backgroundColor: const Color(0xFF00ADEF),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: const Text('Tambah Produksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      );
    } else if (_selectedIndex == 6) {
      return FloatingActionButton(
        onPressed: () {
          final state = _unitKey.currentState;
          if (state != null) (state as dynamic).showAddForm();
        },
        backgroundColor: const Color(0xFF00ADEF),
        child: const Icon(Icons.add, color: Colors.white),
      );
    } else if (_selectedIndex == 7) {
      return FloatingActionButton(
        onPressed: () {
          final state = _kategoriKey.currentState;
          if (state != null) (state as dynamic).showAddForm();
        },
        backgroundColor: const Color(0xFF00ADEF),
        child: const Icon(Icons.add, color: Colors.white),
      );
    } else if (_selectedIndex == 8) {
      return FloatingActionButton(
        onPressed: () {
          final state = _produkKey.currentState;
          if (state != null) (state as dynamic).showAddForm();
        },
        backgroundColor: const Color(0xFF00ADEF),
        child: const Icon(Icons.add, color: Colors.white),
      );
    } else if (_selectedIndex == 10) {
      return FloatingActionButton(
        onPressed: () {
          final state = _bahanBakuKey.currentState;
          if (state != null) (state as dynamic).showAddForm();
        },
        backgroundColor: const Color(0xFF00ADEF),
        child: const Icon(Icons.add, color: Colors.white),
      );
    } else if (_selectedIndex == 11) {
      return FloatingActionButton(
        onPressed: () {
          final state = _pengeluaranKey.currentState;
          if (state != null) (state as dynamic).showAddForm();
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(context),
      drawer: _selectedIndex >= 3 ? null : AppDrawer(onMenuSelected: _onMenuDrawerTapped),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
      extendBody: true,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onNavTapped: _onNavTapped,
        items: [
          NavItem(icon: Icons.home_filled, label: 'Beranda'),
          NavItem(icon: Icons.receipt_long_outlined, label: 'Transaksi'),
          NavItem(icon: Icons.people, label: 'Pelanggan'),
          NavItem(icon: Icons.more_horiz, label: 'Lainnya'),
        ],
      ),
    );
  }
}
