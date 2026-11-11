import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/services/exchange_service.dart';
import 'package:primo_secreto_app/utils/action_utils.dart';
import 'package:primo_secreto_app/utils/email_utils.dart';
import 'package:primo_secreto_app/utils/format_utils.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/avatar_widget.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/field_widget.dart';
import 'package:primo_secreto_app/widgets/common/section_card_widget.dart';

class MembersWidget extends StatefulWidget {
  final ExchangeModel exchange;
  final bool manage;
  final ValueChanged<ExchangeModel> onChanged;

  final VoidCallback? onLeft;

  const MembersWidget({
    super.key,
    required this.exchange,
    this.manage = false,
    required this.onChanged,
    this.onLeft,
  });

  @override
  State<MembersWidget> createState() => _MembersWidgetState();
}

class _MembersWidgetState extends State<MembersWidget> {
  final ExchangeService _exchangeService = ExchangeService();
  final _addController = TextEditingController();

  bool _busy = false;

  ExchangeModel get _exchange => widget.exchange;
  bool get _isEditing => widget.manage && _exchange.canManageMembers;
  int get _participantsCount =>
      _exchange.members.where((m) => m.participates).length;
  int get _adminsCount => _exchange.members.where((m) => m.isAdmin).length;

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  bool _canRemove(MemberModel member) {
    final soleAdmin = _adminsCount <= 1;
    final atMinimum = _participantsCount <= minParticipants;
    return !(member.isAdmin && soleAdmin) &&
        !(member.participates && atMinimum);
  }

  Future<void> _run(
    Future<ExchangeModel> Function() request,
    String success,
  ) async {
    setState(() => _busy = true);
    final updated = await runAction(context, request, success: success);
    if (mounted) setState(() => _busy = false);
    if (updated != null) widget.onChanged(updated);
  }

  Future<void> _add() async {
    final parsed = parseEmails(_addController.text);
    final known = _exchange.members
        .map((m) => normalizeEmail(m.email ?? ""))
        .toSet();
    final fresh = <String>[];
    final problems = <String>[];

    for (final email in parsed.valid) {
      final normalized = normalizeEmail(email);
      if (known.contains(normalized)) {
        problems.add("$email ya participa en el sorteo.");
      } else {
        known.add(normalized);
        fresh.add(email);
      }
    }
    if (parsed.invalid.isNotEmpty) {
      problems.add("Correos no válidos: ${parsed.invalid.join(', ')}.");
    }

    if (problems.isNotEmpty) {
      showMessage(context, problems.join(" "), isError: true);
    }
    _addController.text = parsed.invalid.join(" ");
    if (fresh.isEmpty) return;

    await _run(
      () => _exchangeService.addMembers(_exchange.uuid, fresh),
      pluralize(
        fresh.length,
        "participante agregado",
        "participantes agregados",
      ),
    );
    if (fresh.isNotEmpty && problems.isEmpty) _addController.clear();
  }

  Future<void> _remove(MemberModel member) async {
    final confirmed = await confirmDialog(
      context,
      title: member.isMe ? "Salir del sorteo" : "Quitar participante",
      message: member.isMe
          ? "¿Seguro que quieres salir de este sorteo?"
          : "¿Quitar a ${member.label} del sorteo?",
      confirmLabel: member.isMe ? "Salir" : "Quitar",
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final updated = await _exchangeService.removeMember(
        _exchange.uuid,
        member.uuid,
      );
      if (!mounted) return;
      if (updated == null) {
        widget.onLeft?.call();
        return;
      }
      showMessage(context, "Se quitó a ${member.label}.");
      widget.onChanged(updated);
    } on ApiException catch (e) {
      if (mounted) {
        showMessage(
          context,
          e.describe("No se pudo actualizar a los participantes."),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onMenu(String action, MemberModel member) {
    switch (action) {
      case "make_admin":
        _run(
          () => _exchangeService.updateMember(
            _exchange.uuid,
            member.uuid,
            isAdmin: true,
          ),
          "${member.label} ahora es administrador.",
        );
      case "remove_admin":
        _run(
          () => _exchangeService.updateMember(
            _exchange.uuid,
            member.uuid,
            isAdmin: false,
          ),
          "${member.label} ya no es administrador.",
        );
      case "participate":
        _run(
          () => _exchangeService.updateMember(
            _exchange.uuid,
            member.uuid,
            participates: true,
          ),
          "Ahora participas en el sorteo.",
        );
      case "not_participate":
        _run(
          () => _exchangeService.updateMember(
            _exchange.uuid,
            member.uuid,
            participates: false,
          ),
          "Ya no participas en el sorteo.",
        );
      case "remove":
        _remove(member);
    }
  }

  List<PopupMenuEntry<String>> _menuItems(MemberModel member) {
    return [
      if (!member.isAdmin)
        PopupMenuItem(
          value: "make_admin",
          child: Text("Hacer administrador"),
        )
      else if (_adminsCount > 1)
        PopupMenuItem(
          value: "remove_admin",
          child: Text("Quitar administrador"),
        ),
      if (member.isMe && member.isAdmin)
        member.participates
            ? PopupMenuItem(
                value: "not_participate",
                child: Text("Dejar de participar"),
              )
            : PopupMenuItem(
                value: "participate",
                child: Text("Participar en el sorteo"),
              ),
      if (_canRemove(member))
        PopupMenuItem(
          value: "remove",
          child: Text(member.isMe ? "Salir del sorteo" : "Quitar del sorteo"),
        ),
    ];
  }

  String _subtitle(MemberModel member) {
    return [
      if (member.isAdmin) "Administrador",
      if (member.isPending) "Invitación pendiente",
      if (!member.participates) "No participa en el sorteo",
      if (member.email != null && member.fullName.isNotEmpty) member.email!,
    ].join(" · ");
  }

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      title: "Participantes ($_participantsCount)",
      children: [
        if (_exchange.members.isEmpty) Text("Aún no hay participantes."),
        for (final member in _exchange.members)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: AvatarWidget(
              src: member.avatar,
              name: member.name ?? member.email ?? "",
              lastName: member.lastName,
            ),
            title: Text(member.isMe ? "${member.label} (tú)" : member.label),
            subtitle: _subtitle(member).isEmpty
                ? null
                : Text(_subtitle(member)),
            trailing: _isEditing && _menuItems(member).isNotEmpty
                ? PopupMenuButton<String>(
                    enabled: !_busy,
                    onSelected: (action) => _onMenu(action, member),
                    itemBuilder: (context) => _menuItems(member),
                  )
                : null,
          ),
        if (_isEditing) ...[
          Divider(height: 32),
          FieldWidget(
            controller: _addController,
            label: "Agregar participantes",
            hintText: "Correos separados por comas",
            keyboardType: TextInputType.emailAddress,
            maxLines: 2,
          ),
          ButtonWidget(
            text: "Agregar",
            icon: Icons.person_add,
            function: _add,
            isLoading: _busy,
          ),
        ] else if (widget.manage)
          Text(
            "Ya no se pueden cambiar los participantes de este sorteo.",
          ),
      ],
    );
  }
}
