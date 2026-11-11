import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/services/exchange_service.dart';
import 'package:primo_secreto_app/utils/action_utils.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/section_card_widget.dart';

class DrawSettingsWidget extends StatefulWidget {
  final ExchangeModel exchange;
  final ValueChanged<ExchangeModel> onChanged;

  const DrawSettingsWidget({
    super.key,
    required this.exchange,
    required this.onChanged,
  });

  @override
  State<DrawSettingsWidget> createState() => _DrawSettingsWidgetState();
}

class _DrawSettingsWidgetState extends State<DrawSettingsWidget> {
  final ExchangeService _exchangeService = ExchangeService();

  String _method = "random";
  bool _busy = false;

  ExchangeModel get _exchange => widget.exchange;

  String? get _startBlocker {
    final participants = _exchange.participants;
    if (participants.length < minParticipants) {
      return "El sorteo necesita al menos $minParticipants participantes.";
    }
    if (participants.any((member) => member.isPending)) {
      return "Todos los participantes deben tener una cuenta con el correo verificado antes de iniciar el sorteo.";
    }
    return null;
  }

  String? get _lockBlocker {
    final participants = _exchange.participants;
    if (participants.any((member) => !member.hasGiftee)) {
      return "Todos los participantes deben elegir a quién regalar.";
    }
    if (participants.any((member) => member.hasDuplicateGiftee)) {
      return "Hay asignaciones duplicadas: resuélvelas primero.";
    }
    return null;
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

  Future<void> _start() async {
    final confirmed = await confirmDialog(
      context,
      title: "Iniciar el sorteo",
      message: _method == "random"
          ? "La aplicación emparejará a todos los participantes. Después no podrás cambiar a los participantes."
          : "Los participantes (o tú) indicarán las parejas. Después no podrás cambiar a los participantes.",
      confirmLabel: "Iniciar",
    );
    if (!confirmed || !mounted) return;
    await _run(
      () => _exchangeService.startDraw(_exchange.uuid, _method),
      _method == "random"
          ? "Se realizó el sorteo."
          : "El sorteo quedó iniciado.",
    );
  }

  Future<void> _lock() async {
    final confirmed = await confirmDialog(
      context,
      title: "Bloquear las asignaciones",
      message: "Nadie podrá cambiar las parejas después de bloquearlas.",
      confirmLabel: "Bloquear",
    );
    if (!confirmed || !mounted) return;
    await _run(
      () => _exchangeService.lockAssignments(_exchange.uuid),
      "Las asignaciones quedaron bloqueadas.",
    );
  }

  Future<void> _undo() async {
    final confirmed = await confirmDialog(
      context,
      title: "Deshacer el sorteo",
      message:
          "Se borrarán las parejas y el sorteo volverá a «Creado», para que puedas hacerlo de nuevo.",
      confirmLabel: "Deshacer",
    );
    if (!confirmed || !mounted) return;
    await _run(
      () => _exchangeService.undoDraw(_exchange.uuid),
      "Deshicimos el sorteo.",
    );
  }

  Widget _methodOption(String value, String title, String subtitle) {
    final selected = _method == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => setState(() => _method = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocker = _startBlocker;
    final lockBlocker = _lockBlocker;

    return SectionCardWidget(
      title: "Sorteo",
      children: [
        if (_exchange.canStartDraw) ...[
          _methodOption(
            "random",
            "Sortear aquí",
            "La aplicación empareja a todos los participantes.",
          ),
          _methodOption(
            "manual",
            "Ya lo sorteamos fuera",
            "Cada participante elige a quién regala, o tú asignas las parejas.",
          ),
          if (blocker != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(blocker),
            ),
          ButtonWidget(
            text: "Iniciar el sorteo",
            icon: Icons.casino,
            function: blocker == null ? _start : null,
            isLoading: _busy,
          ),
        ] else if (_exchange.drawMethod != null) ...[
          Text(
            _exchange.drawMethod == "random"
                ? "El sorteo ya se realizó."
                : "El sorteo se hizo fuera de la aplicación.",
          ),
          if (_exchange.assignmentsLocked)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text("Las asignaciones están bloqueadas."),
            )
          else if (_exchange.canLockAssignments) ...[
            SizedBox(height: 8),
            if (lockBlocker != null)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(lockBlocker),
              ),
            ButtonWidget(
              text: "Bloquear las asignaciones",
              icon: Icons.lock_outline,
              isOutlined: true,
              function: lockBlocker == null ? _lock : null,
              isLoading: _busy,
            ),
          ],
        ] else
          Text("El sorteo todavía no puede iniciarse."),
        if (_exchange.canUndoDraw) ...[
          SizedBox(height: 12),
          ButtonWidget(
            text: "Deshacer el sorteo",
            icon: Icons.undo,
            isOutlined: true,
            function: _undo,
            isLoading: _busy,
          ),
        ],
      ],
    );
  }
}
