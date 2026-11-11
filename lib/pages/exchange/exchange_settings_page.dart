import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/services/exchange_service.dart';
import 'package:primo_secreto_app/utils/action_utils.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/exchange_settings/deadline_settings_widget.dart';
import 'package:primo_secreto_app/widgets/exchange_settings/draw_settings_widget.dart';
import 'package:primo_secreto_app/widgets/exchange/exchange_form_widget.dart';
import 'package:primo_secreto_app/widgets/exchange/members_widget.dart';

class ExchangeSettingsPage extends StatefulWidget {
  final ExchangeModel exchange;

  const ExchangeSettingsPage({super.key, required this.exchange});

  @override
  State<ExchangeSettingsPage> createState() => _ExchangeSettingsPageState();
}

class _ExchangeSettingsPageState extends State<ExchangeSettingsPage> {
  final ExchangeService _exchangeService = ExchangeService();

  late ExchangeModel _exchange;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _exchange = widget.exchange;
  }

  void _update(ExchangeModel exchange) => setState(() => _exchange = exchange);

  void _left() => Navigator.of(context).popUntil((route) => route.isFirst);

  Future<void> _saveInfo(ExchangeFormData data) async {
    final updated = await _exchangeService.update(
      _exchange.uuid,
      title: data.title,
      description: data.description,
      budgetAmount: data.budgetAmount,
      budgetCurrency: data.budgetCurrency,
      eventDate: data.eventDate,
      location: data.location,
      latitude: data.latitude,
      longitude: data.longitude,
      imagePath: data.imagePath,
      removeImage: data.removeImage,
    );
    if (!mounted) return;
    showMessage(context, "Guardamos los cambios.");
    _update(updated);
  }

  Future<void> _votingAction(
    Future<ExchangeModel> Function() request,
    String success,
  ) async {
    setState(() => _busy = true);
    final updated = await runAction(context, request, success: success);
    if (mounted) setState(() => _busy = false);
    if (updated != null) _update(updated);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <String, Widget>{
      if (_exchange.canEdit)
        "Información": ListView(
          padding: EdgeInsets.all(16),
          children: [
            ExchangeFormWidget(
              key: ValueKey(
                "${_exchange.title}${_exchange.image}${_exchange.eventDate}${_exchange.budget?.amount}${_exchange.latitude}${_exchange.longitude}",
              ),
              exchange: _exchange,
              submitLabel: "Guardar cambios",
              onSubmit: _saveInfo,
            ),
          ],
        ),
      if (_exchange.canEdit || _exchange.canManageMembers)
        "Participantes": ListView(
          padding: EdgeInsets.all(16),
          children: [
            MembersWidget(
              exchange: _exchange,
              manage: true,
              onChanged: _update,
              onLeft: _left,
            ),
          ],
        ),
      if (_exchange.canEdit)
        "Sorteo": ListView(
          padding: EdgeInsets.all(16),
          children: [
            DrawSettingsWidget(exchange: _exchange, onChanged: _update),
          ],
        ),
      if (_exchange.canEdit)
        "Deseos": ListView(
          padding: EdgeInsets.all(16),
          children: [
            DeadlineSettingsWidget(
              title: "Listas de deseos",
              description:
                  "Cierra las listas en un día (inclusive) o bloquéalas ahora. Después nadie podrá editar la suya.",
              deadline: _exchange.wishlistDeadline,
              locked: _exchange.wishlistLocked,
              lockLabel: "Bloquear las listas ahora",
              unlockLabel: "Permitir editar de nuevo",
              onSave: (deadline, locked) =>
                  _exchangeService.updateWishlistSettings(
                    _exchange.uuid,
                    deadline: deadline,
                    locked: locked,
                  ),
              onChanged: _update,
            ),
          ],
        ),
      if (_exchange.canEdit)
        "Nominaciones": ListView(
          padding: EdgeInsets.all(16),
          children: [
            DeadlineSettingsWidget(
              title: "Nominaciones",
              description:
                  "Cierra las nominaciones en un día (inclusive) o bloquéalas ahora. Cuando estén cerradas podrás iniciar la votación.",
              deadline: _exchange.nominationsDeadline,
              locked: _exchange.nominationsLocked,
              lockLabel: "Bloquear las nominaciones ahora",
              unlockLabel: "Permitir cambiar de nuevo",
              onSave: (deadline, locked) =>
                  _exchangeService.updateNominationsSettings(
                    _exchange.uuid,
                    deadline: deadline,
                    locked: locked,
                  ),
              onChanged: _update,
              extra: [
                Divider(height: 32),
                if (_exchange.votingClosed)
                  Text("La votación terminó.")
                else if (_exchange.votingStarted)
                  Text("La votación está abierta.")
                else
                  Text(
                    "Al iniciar la votación las nominaciones quedan congeladas.",
                  ),
                SizedBox(height: 8),
                if (_exchange.canStartVoting)
                  ButtonWidget(
                    text: "Iniciar la votación",
                    icon: Icons.how_to_vote,
                    isLoading: _busy,
                    function: () => _votingAction(
                      () => _exchangeService.startVoting(_exchange.uuid),
                      "Iniciamos las votaciones.",
                    ),
                  ),
                if (_exchange.canCloseVoting)
                  ButtonWidget(
                    text: "Cerrar la votación",
                    icon: Icons.emoji_events,
                    isLoading: _busy,
                    function: () => _votingAction(
                      () => _exchangeService.closeVoting(_exchange.uuid),
                      "Cerramos las votaciones.",
                    ),
                  ),
              ],
            ),
          ],
        ),
    };

    return DefaultTabController(
      key: ValueKey(tabs.length),
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Configuración"),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final title in tabs.keys) Tab(text: title)],
          ),
        ),
        body: TabBarView(children: tabs.values.toList()),
      ),
    );
  }
}
