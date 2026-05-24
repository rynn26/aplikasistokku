import 'package:flutter/material.dart';

class CustomerCard extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final String metricLabel;
  final String metricValue;
  final Color metricValueColor;

  const CustomerCard({
    super.key,
    required this.name,
    required this.avatarUrl,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
    required this.metricLabel,
    required this.metricValue,
    required this.metricValueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    badge!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: badgeTextColor,
                          fontSize: 8,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola komunitas pecinta organik Anda.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metricLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.black38,
                          fontSize: 8,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metricValue,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: metricValueColor,
                          fontSize: 13,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right, color: Colors.black45, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
