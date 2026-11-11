import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/nomination_model.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/services/nominations_service.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/banner_widget.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/field_widget.dart';

Future<NominationModel?> showNominationForm(
  BuildContext context, {
  required String exchangeUuid,
  NominationModel? nomination,
}) {
  return showModalBottomSheet<NominationModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: NominationFormWidget(
        exchangeUuid: exchangeUuid,
        nomination: nomination,
      ),
    ),
  );
}

class NominationFormWidget extends StatefulWidget {
  final String exchangeUuid;
  final NominationModel? nomination;

  const NominationFormWidget({
    super.key,
    required this.exchangeUuid,
    this.nomination,
  });

  @override
  State<NominationFormWidget> createState() => _NominationFormWidgetState();
}

class _NominationFormWidgetState extends State<NominationFormWidget> {
  final NominationsService _nominationsService = NominationsService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _selectionController = TextEditingController();
  final _typeController = TextEditingController();

  String _selection = "single";
  String _type = "text";
  bool _isLoading = false;
  String? _message;
  Map<String, List<String>> _errors = {};

  bool get _canChangeType =>
      widget.nomination == null || widget.nomination!.canChangeType;

  @override
  void initState() {
    super.initState();
    final nomination = widget.nomination;
    if (nomination != null) {
      _titleController.text = nomination.title;
      _selection = nomination.selection;
      _type = nomination.type;
    }
    _selectionController.text = selectionLabels[_selection]!;
    _typeController.text = typeLabels[_type]!;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _selectionController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _pickSelection() async {
    final value = await pickOption(
      context,
      title: "Cantidad de nominados",
      options: selectionLabels,
      selected: _selection,
    );
    if (value != null) {
      _selection = value;
      _selectionController.text = selectionLabels[value]!;
    }
  }

  Future<void> _pickType() async {
    final value = await pickOption(
      context,
      title: "Tipo de nominación",
      options: {
        for (final type in ["text", "participants", "images"])
          type: typeLabels[type]!,
      },
      selected: _type,
    );
    if (value != null) {
      _type = value;
      _typeController.text = typeLabels[value]!;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _message = null;
      _errors = {};
    });

    final title = _titleController.text.trim();
    final nomination = widget.nomination;
    try {
      final saved = nomination == null
          ? await _nominationsService.create(
              widget.exchangeUuid,
              title,
              _selection,
              _type,
            )
          : await _nominationsService.update(
              widget.exchangeUuid,
              nomination.uuid,
              title,
              _selection,
              _type,
            );
      if (mounted) Navigator.pop(context, saved);
    } on ApiException catch (e) {
      setState(() {
        _errors = e.errors;
        _message = e.errors.isEmpty
            ? e.describe("No se pudo guardar la nominación.")
            : null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.nomination == null
                  ? "Nueva nominación"
                  : "Editar nominación",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12),
            if (_message != null) BannerWidget(text: _message!, isError: true),
            FieldWidget(
              controller: _titleController,
              label: "Nombre de la nominación",
              hintText: "El más divertido",
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
              errorText: _errors["title"]?.first,
              validator: (value) => (value ?? "").trim().isEmpty
                  ? "Escribe el nombre de la nominación."
                  : null,
            ),
            FieldWidget(
              controller: _selectionController,
              label: "Nominados",
              function: _pickSelection,
              errorText: _errors["selection"]?.first,
            ),
            FieldWidget(
              controller: _typeController,
              label: "Se nomina a",
              function: _canChangeType
                  ? _pickType
                  : () => showMessage(
                      context,
                      "El tipo ya no se puede cambiar porque hay nominados.",
                    ),
              errorText: _errors["type"]?.first,
            ),
            ButtonWidget(
              text: "Guardar",
              function: _submit,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
