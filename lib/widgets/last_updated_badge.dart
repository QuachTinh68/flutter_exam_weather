import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LastUpdatedBadge extends StatelessWidget {
  final DateTime? lastUpdated;

  const LastUpdatedBadge({
    super.key,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (lastUpdated == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final diff = now.difference(lastUpdated!);
    
    String text;
    if (diff.inMinutes < 1) {
      text = 'Vừa cập nhật';
    } else if (diff.inMinutes < 60) {
      text = 'Cập nhật ${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      text = 'Cập nhật ${diff.inHours} giờ trước';
    } else {
      text = 'Cập nhật ${DateFormat('dd/MM HH:mm').format(lastUpdated!)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.update_rounded,
            size: 14,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

