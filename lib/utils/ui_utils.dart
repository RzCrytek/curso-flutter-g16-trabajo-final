import 'package:flutter/material.dart';
import 'package:primo_secreto_app/utils/format_utils.dart';

void showMessage(BuildContext context, String text, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = "Aceptar",
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("Cancelar"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> pickOption(
  BuildContext context, {
  required String title,
  required Map<String, String> options,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: options.entries
                    .map(
                      (option) => ListTile(
                        title: Text(option.value),
                        trailing: option.key == selected
                            ? Icon(Icons.check)
                            : null,
                        onTap: () => Navigator.pop(context, option.key),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<String?> pickDate(
  BuildContext context, {
  String? initial,
  bool allowPast = false,
}) async {
  final today = DateUtils.dateOnly(DateTime.now());
  final current = initial == null || initial.isEmpty
      ? null
      : DateTime.parse(initial);
  final first = current != null && current.isBefore(today) ? current : today;

  final date = await showDatePicker(
    context: context,
    initialDate: current ?? today,
    firstDate: allowPast ? DateTime(2000) : first,
    lastDate: DateTime(today.year + 5),
    locale: Locale("es"),
  );
  return date == null ? null : toApiDate(date);
}
