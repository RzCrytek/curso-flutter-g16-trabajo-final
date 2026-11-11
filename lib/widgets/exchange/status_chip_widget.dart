import 'package:flutter/material.dart';

class StatusChipWidget extends StatelessWidget {
  final String status;
  final String label;

  const StatusChipWidget({
    super.key,
    required this.status,
    required this.label,
  });

  Color get _color {
    switch (status) {
      case "in_progress":
        return Colors.blue;
      case "closed":
        return Colors.amber.shade800;
      case "finished":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
