import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/models/nomination_model.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/services/nominations_service.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/banner_widget.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/field_widget.dart';
import 'package:primo_secreto_app/widgets/common/image_picker_widget.dart';

Future<NominationModel?> showNomineeForm(
  BuildContext context, {
  required String exchangeUuid,
  required NominationModel nomination,
  required List<MemberModel> candidates,
}) {
  return showModalBottomSheet<NominationModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: NomineeFormWidget(
        exchangeUuid: exchangeUuid,
        nomination: nomination,
        candidates: candidates,
      ),
    ),
  );
}

class NomineeFormWidget extends StatefulWidget {
  final String exchangeUuid;
  final NominationModel nomination;

  final List<MemberModel> candidates;

  const NomineeFormWidget({
    super.key,
    required this.exchangeUuid,
    required this.nomination,
    required this.candidates,
  });

  @override
  State<NomineeFormWidget> createState() => _NomineeFormWidgetState();
}

class _NomineeFormWidgetState extends State<NomineeFormWidget> {
  final NominationsService _nominationsService = NominationsService();
  final _textController = TextEditingController();
  final _memberController = TextEditingController();

  String? _memberUuid;
  String? _imagePath;
  bool _isLoading = false;
  String? _message;

  String get _type => widget.nomination.type;

  @override
  void dispose() {
    _textController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  Future<void> _pickMember() async {
    final value = await pickOption(
      context,
      title: "¿A quién nominas?",
      options: {
        for (final member in widget.candidates) member.uuid: member.label,
      },
      selected: _memberUuid,
    );
    if (value != null) {
      _memberUuid = value;
      _memberController.text = widget.candidates
          .firstWhere((member) => member.uuid == value)
          .label;
    }
  }

  Future<void> _pickImage(String? path) async {
    if (path != null) {
      final problem = await imageProblem(path);
      if (problem != null) {
        setState(() => _message = problem);
        return;
      }
    }
    setState(() {
      _imagePath = path;
      _message = null;
    });
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    final missing = switch (_type) {
      "participants" when _memberUuid == null =>
        "Elige a la persona que quieres nominar.",
      "text" when text.isEmpty => "Escribe el nominado.",
      "images" when _imagePath == null =>
        "Elige la imagen que quieres nominar.",
      _ => null,
    };
    if (missing != null) {
      setState(() => _message = missing);
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final saved = await _nominationsService.addNominee(
        widget.exchangeUuid,
        widget.nomination.uuid,
        member: _type == "participants" ? _memberUuid : null,
        text: _type == "participants" ? null : text,
        imagePath: _type == "images" ? _imagePath : null,
      );
      if (mounted) Navigator.pop(context, saved);
    } on ApiException catch (e) {
      setState(() {
        _message = e.describe("No se pudo agregar el nominado.");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Agregar nominado",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            widget.nomination.title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 12),
          if (_message != null) BannerWidget(text: _message!, isError: true),
          if (_type == "participants")
            FieldWidget(
              controller: _memberController,
              label: "Persona",
              function: _pickMember,
            ),
          if (_type == "text")
            FieldWidget(
              controller: _textController,
              label: "Nominado",
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
            ),
          if (_type == "images") ...[
            ImagePickerWidget(
              label: "Imagen",
              newPath: _imagePath,
              onChanged: _pickImage,
            ),
            FieldWidget(
              controller: _textController,
              label: "Descripción (opcional)",
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
          ButtonWidget(
            text: "Agregar",
            function: _submit,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
