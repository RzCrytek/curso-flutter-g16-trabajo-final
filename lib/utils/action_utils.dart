import 'package:flutter/material.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';

Future<T?> runAction<T>(
  BuildContext context,
  Future<T> Function() request, {
  String? success,
  String fallback = "No se pudo completar la acción. Inténtalo de nuevo.",
}) async {
  try {
    final result = await request();
    if (context.mounted && success != null) {
      showMessage(context, success);
    }
    return result;
  } on ApiException catch (e) {
    if (context.mounted) {
      showMessage(context, e.describe(fallback), isError: true);
    }
    return null;
  }
}

Future<bool> runVoidAction(
  BuildContext context,
  Future<void> Function() request, {
  String? success,
  String fallback = "No se pudo completar la acción. Inténtalo de nuevo.",
}) async {
  try {
    await request();
    if (context.mounted && success != null) {
      showMessage(context, success);
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      showMessage(context, e.describe(fallback), isError: true);
    }
    return false;
  }
}
