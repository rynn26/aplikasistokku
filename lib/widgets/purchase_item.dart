import 'package:flutter/material.dart';

class PurchaseItem extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String weight;
  final String date;
  final String status;
  final Color statusColor;
  final Color statusTextColor;

  const PurchaseItem({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.weight,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.statusTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              imageUrl,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 54,
                  height: 54,
                  color: Colors.grey[300],
                  child: const Icon(Icons.shopping_bag, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.scale_outlined, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(weight, style: const TextStyle(color: Colors.black54, fontSize: 11)),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(date, style: const TextStyle(color: Colors.black54, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Status', style: TextStyle(color: Colors.black45, fontSize: 10)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
