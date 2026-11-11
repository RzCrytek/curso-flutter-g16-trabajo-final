import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? src;
  final String name;
  final String? lastName;
  final double size;

  const AvatarWidget({
    super.key,
    this.src,
    required this.name,
    this.lastName,
    this.size = 40,
  });

  String get _initials {
    final first = name.trim().isEmpty ? "" : name.trim()[0];
    final second = (lastName ?? "").trim().isEmpty ? "" : lastName!.trim()[0];
    final initials = "$first$second".toUpperCase();
    return initials.isEmpty ? "?" : initials;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.primaryContainer,
      foregroundImage: src == null ? null : NetworkImage(src!),
      onForegroundImageError: src == null ? null : (_, _) {},
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size / 2.6,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}
