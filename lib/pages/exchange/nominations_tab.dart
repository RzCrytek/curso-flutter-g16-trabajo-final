import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/models/nomination_model.dart';
import 'package:primo_secreto_app/pages/exchange/ceremony_page.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/services/nominations_service.dart';
import 'package:primo_secreto_app/utils/action_utils.dart';
import 'package:primo_secreto_app/utils/format_utils.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/banner_widget.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/nominations/nomination_card_widget.dart';
import 'package:primo_secreto_app/widgets/nominations/nomination_form_widget.dart';
import 'package:primo_secreto_app/widgets/nominations/nominee_form_widget.dart';

class NominationsTab extends StatefulWidget {
  final ExchangeModel exchange;

  const NominationsTab({super.key, required this.exchange});

  @override
  State<NominationsTab> createState() => _NominationsTabState();
}

class _NominationsTabState extends State<NominationsTab>
    with AutomaticKeepAliveClientMixin {
  final NominationsService _nominationsService = NominationsService();

  List<NominationModel>? _list;
  bool _loadFailed = false;
  bool _busy = false;

  @override
  bool get wantKeepAlive => true;

  ExchangeModel get _exchange => widget.exchange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(NominationsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.exchange;
    if (old.votingStarted != _exchange.votingStarted ||
        old.votingClosed != _exchange.votingClosed ||
        old.nominationsClosed != _exchange.nominationsClosed) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      _list = await _nominationsService.list(_exchange.uuid);
      _loadFailed = false;
    } on ApiException catch (_) {
      _loadFailed = _list == null;
    }
    if (mounted) setState(() {});
  }

  void _replace(NominationModel saved) {
    setState(() {
      _list = (_list ?? [])
          .map(
            (nomination) => nomination.uuid == saved.uuid ? saved : nomination,
          )
          .toList();
    });
  }

  Future<void> _create() async {
    final saved = await showNominationForm(
      context,
      exchangeUuid: _exchange.uuid,
    );
    if (saved == null || !mounted) return;
    setState(() => _list = [...?_list, saved]);
    showMessage(context, "Creamos la nominación.");
  }

  Future<void> _edit(NominationModel nomination) async {
    final saved = await showNominationForm(
      context,
      exchangeUuid: _exchange.uuid,
      nomination: nomination,
    );
    if (saved == null || !mounted) return;
    _replace(saved);
    showMessage(context, "Guardamos los cambios.");
  }

  Future<void> _delete(NominationModel nomination) async {
    final confirmed = await confirmDialog(
      context,
      title: "Eliminar nominación",
      message:
          "¿Eliminar la nominación «${nomination.title}» con todos sus nominados y votos?",
      confirmLabel: "Eliminar",
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final done = await runVoidAction(
      context,
      () => _nominationsService.remove(_exchange.uuid, nomination.uuid),
      success: "Eliminamos la nominación.",
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (done) {
        _list = (_list ?? [])
            .where((item) => item.uuid != nomination.uuid)
            .toList();
      }
    });
  }

  Future<void> _addNominee(NominationModel nomination) async {
    final nominated = nomination.nominees
        .map((nominee) => nominee.person?.uuid)
        .toSet();
    final candidates = _exchange.members
        .where(
          (member) =>
              member.participates &&
              !member.isPending &&
              !nominated.contains(member.uuid),
        )
        .toList();

    final saved = await showNomineeForm(
      context,
      exchangeUuid: _exchange.uuid,
      nomination: nomination,
      candidates: candidates,
    );
    if (saved == null || !mounted) return;
    _replace(saved);
    showMessage(context, "Agregamos el nominado.");
  }

  Future<void> _removeNominee(
    NominationModel nomination,
    NomineeModel nominee,
  ) async {
    setState(() => _busy = true);
    final done = await runVoidAction(
      context,
      () => _nominationsService.removeNominee(
        _exchange.uuid,
        nomination.uuid,
        nominee.uuid,
      ),
      success: "Quitamos el nominado.",
    );
    if (done) await _load();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _vote(NominationModel nomination, NomineeModel nominee) async {
    final others = nomination.nominees
        .where((item) => item.voted && item.uuid != nominee.uuid)
        .map((item) => item.uuid)
        .toList();
    final isSingle = nomination.selection == "single";
    final chosen = isSingle
        ? [nominee.uuid]
        : [...others, if (!nominee.voted) nominee.uuid];

    setState(() => _busy = true);
    final saved = await runAction(
      context,
      () => _nominationsService.vote(
        _exchange.uuid,
        nomination.uuid,
        nominee.voted && isSingle ? [] : chosen,
      ),
      success: nominee.voted ? "Quitamos tu voto." : "Guardamos tu voto.",
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved != null) {
      _replace(saved);
    }
  }

  String? _statusNote() {
    if (_exchange.votingClosed) {
      return "La votación terminó. ¡Mira los resultados!";
    }
    if (_exchange.votingStarted) {
      return "La votación está abierta: vota por tus favoritos.";
    }
    if (_exchange.nominationsClosed) {
      return _exchange.nominationsLocked ||
              _exchange.nominationsDeadline == null
          ? "Las nominaciones están cerradas: ya no se pueden cambiar."
          : "Las nominaciones se cerraron el ${formatEventDate(_exchange.nominationsDeadline!)}: ya no se pueden cambiar.";
    }
    if (_exchange.nominationsDeadline != null) {
      return "Puedes nominar y votar hasta el ${formatEventDate(_exchange.nominationsDeadline!)}.";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("No se pudieron cargar las nominaciones."),
            TextButton(onPressed: _load, child: Text("Reintentar")),
          ],
        ),
      );
    }
    final list = _list;
    if (list == null) return Center(child: CircularProgressIndicator());

    final note = _statusNote();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          if (note != null) BannerWidget(text: note),
          if (_exchange.votingClosed && list.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ButtonWidget(
                text: "Ver los resultados",
                icon: Icons.emoji_events,
                function: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CeremonyPage(title: _exchange.title, nominations: list),
                  ),
                ),
              ),
            ),
          if (!_exchange.nominationsClosed)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ButtonWidget(
                text: "Nueva nominación",
                icon: Icons.add,
                isOutlined: true,
                function: _busy ? null : _create,
              ),
            ),
          if (list.isEmpty)
            Text("Todavía no hay nominaciones. Crea la primera."),
          for (final nomination in list)
            NominationCardWidget(
              exchange: _exchange,
              nomination: nomination,
              busy: _busy,
              onEdit: () => _edit(nomination),
              onDelete: () => _delete(nomination),
              onAddNominee: () => _addNominee(nomination),
              onVote: (nominee) => _vote(nomination, nominee),
              onRemoveNominee: (nominee) => _removeNominee(nomination, nominee),
            ),
        ],
      ),
    );
  }
}
