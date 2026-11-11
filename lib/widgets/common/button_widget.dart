import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? function;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const ButtonWidget({
    super.key,
    required this.text,
    required this.function,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                SizedBox(width: 8),
              ],
              Flexible(child: Text(text, textAlign: TextAlign.center)),
            ],
          );
    final onPressed = isLoading ? null : function;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    );
    const padding = EdgeInsets.symmetric(vertical: 14, horizontal: 20);

    return SizedBox(
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(shape: shape, padding: padding),
              child: child,
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(shape: shape, padding: padding),
              child: child,
            ),
    );
  }
}
