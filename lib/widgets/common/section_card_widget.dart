import 'package:flutter/material.dart';

class SectionCardWidget extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SectionCardWidget({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}
