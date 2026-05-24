import 'package:flutter/material.dart';

/// Widget pagination reusable — tampilan seperti: < 1 2 3 ... 11 >
class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final void Function(int page) onPageChanged;

  static const _cyan  = Color(0xFF00ADEF);
  static const _btnSz = 34.0;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.onPageChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (lastPage <= 1) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ← Prev
          _ArrowBtn(
            icon: Icons.chevron_left,
            enabled: currentPage > 1 && !isLoading,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 4),

          // Nomor halaman
          ..._buildPageNumbers(),

          const SizedBox(width: 4),
          // Next →
          _ArrowBtn(
            icon: Icons.chevron_right,
            enabled: currentPage < lastPage && !isLoading,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    // Kumpulkan halaman yang akan ditampilkan
    final Set<int> pages = {};

    if (lastPage <= 7) {
      // Halaman sedikit — tampilkan semua
      for (int i = 1; i <= lastPage; i++) pages.add(i);
    } else {
      // Selalu tampilkan halaman 1 dan lastPage
      pages.add(1);
      pages.add(lastPage);
      // Tampilkan halaman di sekitar currentPage
      for (int i = currentPage - 1; i <= currentPage + 1; i++) {
        if (i >= 1 && i <= lastPage) pages.add(i);
      }
    }

    final sorted = pages.toList()..sort();
    final widgets = <Widget>[];
    int? prev;

    for (final p in sorted) {
      if (prev != null && p - prev > 1) {
        // Ellipsis
        widgets.add(
          SizedBox(
            width: _btnSz,
            child: Center(
              child: Text('...', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      }
      widgets.add(_PageBtn(
        page: p,
        isCurrent: p == currentPage,
        isLoading: isLoading,
        onTap: p == currentPage ? null : () => onPageChanged(p),
        size: _btnSz,
        activeColor: _cyan,
      ));
      prev = p;
    }

    return widgets;
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ArrowBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: PaginationWidget._btnSz,
        height: PaginationWidget._btnSz,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? Colors.grey.shade300 : Colors.grey.shade200),
        ),
        child: Icon(icon, size: 20, color: enabled ? Colors.grey[700] : Colors.grey[400]),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final int page;
  final bool isCurrent;
  final bool isLoading;
  final VoidCallback? onTap;
  final double size;
  final Color activeColor;

  const _PageBtn({
    required this.page,
    required this.isCurrent,
    required this.isLoading,
    required this.onTap,
    required this.size,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isCurrent ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent ? activeColor : Colors.grey.shade300,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
              color: isCurrent ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mixin helper untuk pagination state
mixin PaginationMixin {
  int currentPage = 1;
  int lastPage = 1;
  int total = 0;

  Map<String, String> paginationParams({int perPage = 15, String? search}) => {
    'page': '$currentPage',
    'per_page': '$perPage',
    if (search != null && search.isNotEmpty) 'search': search,
  };

  void updateMeta(Map<String, dynamic>? meta) {
    if (meta == null) return;
    currentPage = meta['current_page'] as int? ?? currentPage;
    lastPage    = meta['last_page'] as int? ?? 1;
    total       = meta['total'] as int? ?? 0;
  }
}
