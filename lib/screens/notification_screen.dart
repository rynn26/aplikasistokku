import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/data_service.dart';
import '../../models/app_notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<AppNotification> _notifications = [];
  static const _blue = Color(0xFF00ADEF);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await DataService.getNotifications();
      if (mounted) setState(() { _notifications = data; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    await DataService.markNotificationRead(n.id);
    _load();
  }

  Future<void> _markAllRead() async {
    await DataService.markAllNotificationsRead();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Notifikasi', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 18)),
          if (unread > 0)
            Text('$unread belum dibaca', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.normal)),
        ]),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tandai Semua', style: TextStyle(color: _blue, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : RefreshIndicator(
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Tidak ada notifikasi', style: TextStyle(color: Colors.grey[500])),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _notifications.length,
                      itemBuilder: (_, i) {
                        final n = _notifications[i];
                        return _buildNotifItem(n);
                      },
                    ),
            ),
    );
  }

  Widget _buildNotifItem(AppNotification n) {
    final typeIcon = _getIcon(n.type);
    final typeColor = _getColor(n.type);
    String timeAgo = '';
    if (n.createdAt != null) {
      try {
        final dt = DateTime.parse(n.createdAt!).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) timeAgo = '${diff.inMinutes} menit lalu';
        else if (diff.inHours < 24) timeAgo = '${diff.inHours} jam lalu';
        else timeAgo = DateFormat('d MMM', 'id_ID').format(dt);
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _markRead(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : const Color(0xFFE8F6FF),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
          border: n.isRead ? null : Border.all(color: const Color(0xFF00ADEF).withOpacity(0.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: typeColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(typeIcon, size: 18, color: typeColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(n.title,
                style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                  color: const Color(0xFF1E293B)))),
              if (!n.isRead)
                Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 4),
            Text(n.body, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(timeAgo, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ])),
        ]),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'order': return Icons.receipt_long_outlined;
      case 'stock': return Icons.inventory_2_outlined;
      case 'payment': return Icons.payments_outlined;
      case 'Pelanggan': return Icons.people_outline;
      default: return Icons.notifications_outlined;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'order': return Colors.blue[700]!;
      case 'stock': return Colors.orange[700]!;
      case 'payment': return Colors.green[700]!;
      case 'Pelanggan': return Colors.purple[700]!;
      default: return const Color(0xFF00ADEF);
    }
  }
}
