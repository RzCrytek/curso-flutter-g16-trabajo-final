import 'package:flutter/material.dart';

ImageErrorWidgetBuilder brokenImageOf([double? size]) {
  return (BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined),
    );
  };
}

Widget brokenImage(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
) => brokenImageOf()(context, error, stackTrace);
