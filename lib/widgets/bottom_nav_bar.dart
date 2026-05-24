import 'package:flutter/material.dart';

class NavItem {
  final IconData icon;
  final String label;
  NavItem({required this.icon, required this.label});
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavTapped;
  final List<NavItem> items;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onNavTapped,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) => _buildNavItem(
          index: index,
          icon: items[index].icon,
          label: items[index].label,
        )),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon, required String label}) {
    bool isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => onNavTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
             decoration: BoxDecoration(
               color: isActive ? const Color(0xFFE0F7FF) : Colors.transparent,
               borderRadius: BorderRadius.circular(20),
             ),
             child: Icon(
               icon,
               color: isActive ? const Color(0xFF00ADEF) : Colors.black54,
               size: 24,
             ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF00ADEF) : Colors.black54,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
