import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/utils/action_utils.dart';
import 'package:primo_secreto_app/utils/format_utils.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/field_widget.dart';
import 'package:primo_secreto_app/widgets/common/section_card_widget.dart';

class DeadlineSettingsWidget extends StatefulWidget {
  final String title;
  final String description;
  final String? deadline;
  final bool locked;
  final String lockLabel;
  final String unlockLabel;

  final Future<ExchangeModel> Function(String? deadline, bool locked) onSave;
  final ValueChanged<ExchangeModel> onChanged;

  final List<Widget> extra;

  const DeadlineSettingsWidget({
    super.key,
    required this.title,
    required this.description,
    required this.deadline,
    required this.locked,
    required this.lockLabel,
    required this.unlockLabel,
    required this.onSave,
    required this.onChanged,
    this.extra = const [],
  });

  @override
  State<DeadlineSettingsWidget> createState() => _DeadlineSettingsWidgetState();
}

class _DeadlineSettingsWidgetState extends State<DeadlineSettingsWidget> {
  final _dateController = TextEditingController();

  String? _deadline;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _syncDeadline();
  }

  @override
  void didUpdateWidget(DeadlineSettingsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) _syncDeadline();
  }

  void _syncDeadline() {
    _deadline = widget.deadline?.substring(0, 10);
    _dateController.text = _deadline == null ? "" : formatEventDate(_deadline!);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final date = await pickDate(context, initial: _deadline);
    if (date != null) {
      setState(() {
        _deadline = date;
        _dateController.text = formatEventDate(date);
      });
    }
  }

  Future<void> _save({
    String? deadline,
    bool? locked,
    required String success,
  }) async {
    setState(() => _busy = true);
    final updated = await runAction(
      context,
      () => widget.onSave(deadline, locked ?? widget.locked),
      success: success,
    );
    if (mounted) setState(() => _busy = false);
    if (updated != null) widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      title: widget.title,
      children: [
        Text(widget.description, style: Theme.of(context).textTheme.bodySmall),
        SizedBox(height: 12),
        FieldWidget(
          controller: _dateController,
          label: "Fecha límite (opcional)",
          function: _pick,
          suffixIcon: _deadline == null
              ? Icon(Icons.calendar_today)
              : IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _deadline = null;
                    _dateController.clear();
                  }),
                ),
        ),
        ButtonWidget(
          text: "Guardar fecha límite",
          isLoading: _busy,
          function: () => _save(
            deadline: _deadline,
            success: _deadline == null
                ? "Quitamos la fecha límite."
                : "Guardamos la fecha límite.",
          ),
        ),
        SizedBox(height: 8),
        ButtonWidget(
          text: widget.locked ? widget.unlockLabel : widget.lockLabel,
          icon: widget.locked ? Icons.lock_open : Icons.lock_outline,
          isOutlined: true,
          function: _busy
              ? null
              : () => _save(
                  deadline: widget.deadline,
                  locked: !widget.locked,
                  success: widget.locked
                      ? "Se pueden editar de nuevo."
                      : "Las bloqueamos.",
                ),
        ),
        ...widget.extra,
      ],
    );
  }
}
